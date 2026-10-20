import Foundation

/// Owns helper sessions, lifecycle gates and serialized bounded commands. No SMC writer is linked yet.
actor ChargeCommandExecutor {
    nonisolated enum Mode: Sendable, Equatable { case charge, hold, discharge }
    nonisolated enum State: Sendable, Equatable {
        case restorationRequired, macOS, active(Mode), nativeLimit(Int)
    }
    nonisolated enum Failure: Error, Sendable, Equatable {
        case notReady, unsupported, invalidSession, sessionLimit, invalidLease, differentOwner, cancelled, leaseExpired, commandFailed, restorationFailed, externalChange
    }

    /// Each operation must validate support and acknowledge the actual hardware state or throw.
    /// Synchronous operations keep partial writes and recovery in one actor turn.
    nonisolated struct Operations: Sendable {
        var setAdapterEnabled: @Sendable (Bool) throws -> Void
        var setChargingAllowed: @Sendable (Bool) throws -> Void
    }

    /// Native limits do not implement arbitrary Hold, discharge or adapter switching.
    nonisolated struct NativeBackend: Sendable {
        var operations: NativeChargeLimitTransaction.Operations
        var journal: NativeChargeLimitJournal
    }

    nonisolated static let maximumLease: Duration = .seconds(30)
    private(set) var state = State.restorationRequired
    private(set) var leaseDeadline: ContinuousClock.Instant?
    private var owner: UUID?
    private var expiry: Task<Void, Never>?
    nonisolated enum Phase: Sendable, Equatable { case starting, ready, sleeping, removing, stopped }
    private(set) var phase = Phase.starting
    private var sessions: Set<UUID> = []
    private let operations: Operations?
    private var nativeBackend: NativeBackend?
    private let nativeBackendFactory: (@Sendable () throws -> NativeBackend)?
    private var nativeTransaction: NativeChargeLimitTransaction?
    private let clock = ContinuousClock()
    private let diagnosticRead: @Sendable () async -> ChargeCapabilityProbe
    private let nativeDiagnosticRead: @Sendable () async -> NativeChargeLimit
    private var nativeDiagnosticTask: Task<NativeChargeLimit, Never>?
    private var diagnosticTask: Task<ChargeCapabilityProbe, Never>?

    /// nil is the shipped status-only backend; it never claims hardware support.
    init(operations: Operations? = nil,
         diagnosticRead: @escaping @Sendable () async -> ChargeCapabilityProbe = { await ChargeCapabilityProbe.read() },
         nativeDiagnosticRead: @escaping @Sendable () async -> NativeChargeLimit = { .unavailable(.notProbed) }) {
        self.operations = operations
        self.nativeBackend = nil
        self.nativeBackendFactory = nil
        self.diagnosticRead = diagnosticRead
        self.nativeDiagnosticRead = nativeDiagnosticRead
    }

    /// Journal I/O is deferred to startup on this executor, never performed by its initializer.
    init(nativeBackend: NativeBackend,
         diagnosticRead: @escaping @Sendable () async -> ChargeCapabilityProbe = { await ChargeCapabilityProbe.read() },
         nativeDiagnosticRead: @escaping @Sendable () async -> NativeChargeLimit = { .unavailable(.notProbed) }) {
        self.operations = nil
        self.nativeBackend = nativeBackend
        self.nativeBackendFactory = nil
        self.diagnosticRead = diagnosticRead
        self.nativeDiagnosticRead = nativeDiagnosticRead
    }

    /// Factory runs on the executor at startup, recovering any prior verification checkpoint.
    init(nativeBackendFactory: @escaping @Sendable () throws -> NativeBackend,
         nativeDiagnosticRead: @escaping @Sendable () async -> NativeChargeLimit = { .unavailable(.notProbed) }) {
        self.operations = nil
        self.nativeBackend = nil
        self.nativeBackendFactory = nativeBackendFactory
        self.diagnosticRead = { await ChargeCapabilityProbe.read() }
        self.nativeDiagnosticRead = nativeDiagnosticRead
    }

    /// Restore before serving requests; initialization/restart never replays a previous command.
    func start() throws {
        guard phase == .starting else { throw Failure.notReady }
        try restore()
        phase = .ready
    }

    /// Called only after native peer requirements are installed, with no owner token accepted from IPC.
    func beginSession() throws -> UUID {
        guard phase == .ready || phase == .removing else { throw Failure.notReady }
        guard sessions.count < 16 else { throw Failure.sessionLimit }
        let token = UUID()
        sessions.insert(token)
        return token
    }

    /// Status-only replies and removal acknowledgements require a live authenticated session too.
    func status(for session: UUID, removing: Bool = false) throws -> HelperStatus {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        guard phase != .stopped, phase != .starting else { throw Failure.notReady }
        if removing {
            phase = .removing
            try restore()
        }
        try checkLease()
        guard state == .macOS else { throw Failure.notReady }
        var response = HelperStatus.current
        if nativeBackendFactory != nil { response.nativeVerificationAvailable = true }
        return response
    }

    /// Explicit diagnostic only. One cached snapshot coalesces concurrent requests and bounds I/O.
    func diagnose(for session: UUID) async throws -> HelperStatus {
        _ = try status(for: session)
        guard phase == .ready else { throw Failure.notReady }
        if diagnosticTask == nil { diagnosticTask = Task { await diagnosticRead() } }
        guard let diagnosticTask else { throw Failure.notReady }
        if nativeDiagnosticTask == nil { nativeDiagnosticTask = Task { await nativeDiagnosticRead() } }
        guard let nativeDiagnosticTask else { throw Failure.notReady }
        let report = await diagnosticTask.value
        let nativeReport = await nativeDiagnosticTask.value
        // Disconnect, removal or sleep can run while I/O is suspended.
        var response = try status(for: session)
        guard phase == .ready else { throw Failure.notReady }
        response.chargeDiagnostics = report
        response.nativeChargeLimit = nativeReport
        return response
    }

    /// Block commands before any suspension/restore; wake never replays an old lease.
    func willSleep() throws {
        guard phase != .stopped else { return }
        if phase == .removing {
            try restore()
            return
        }
        phase = .sleeping
        sessions.removeAll()
        try restore()
    }

    func didWake() throws {
        guard phase == .sleeping else { return }
        try restore()
        phase = .ready
    }

    /// SIGTERM/shutdown and explicit removal must restore before acknowledging completion.
    func shutdown() throws {
        phase = .stopped
        sessions.removeAll()
        try restore()
    }

    /// The owner is assigned by the helper per authenticated connection, never supplied by IPC data.
    func apply(_ mode: Mode, owner: UUID, leaseFor duration: Duration) throws {
        guard sessions.contains(owner) else { throw Failure.invalidSession }
        guard phase == .ready else { throw Failure.notReady }
        guard let operations else { throw Failure.unsupported }
        let deadline = try commandDeadline(owner: owner, duration: duration)
        do {
            if state != .active(mode) {
                switch mode {
                case .charge, .hold:
                    try operations.setAdapterEnabled(true)
                    try operations.setChargingAllowed(mode == .charge)
                case .discharge:
                    try operations.setChargingAllowed(false)
                    try operations.setAdapterEnabled(false)
                }
            }
        } catch {
            try restore()
            throw Failure.commandFailed
        }
        try finishCommand(state: .active(mode), owner: owner, deadline: deadline)
    }

    /// Internal only; no writable IPC or production native backend is supplied.
    func applyNativeLimit(_ limit: Int, owner: UUID, leaseFor duration: Duration,
                          expectedInitial: NativeChargeLimit.Snapshot? = nil) throws {
        guard sessions.contains(owner) else { throw Failure.invalidSession }
        guard phase == .ready else { throw Failure.notReady }
        guard nativeBackend != nil else { throw Failure.unsupported }
        guard nativeTransaction?.state != .externalChange else { throw Failure.externalChange }
        let deadline = try commandDeadline(owner: owner, duration: duration)
        guard nativeTransaction != nil else { throw Failure.notReady }
        do {
            try nativeTransaction?.apply(limit: limit, expectedInitial: expectedInitial)
        } catch {
            revokeLease()
            if nativeTransaction?.state == .restorationRequired {
                state = .restorationRequired
                throw Failure.restorationFailed
            }
            // The transaction already restored, or relinquished an observed external change.
            state = .macOS
            if nativeTransaction?.state == .externalChange { throw Failure.externalChange }
            if error as? NativeChargeLimitTransaction.Failure == .cancelled { throw Failure.cancelled }
            throw Failure.commandFailed
        }
        try finishCommand(state: .nativeLimit(limit), owner: owner, deadline: deadline)
    }

    /// One actor turn: explicit temporary target, fresh read-back, then immediate original restoration.
    func verifyNativeLimit(_ limit: Int, for session: UUID) throws -> HelperStatus {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        guard nativeBackendFactory != nil, let backend = nativeBackend else { throw Failure.unsupported }
        guard phase == .ready, state == .macOS, owner == nil else { throw Failure.notReady }
        guard (80...100).contains(limit) else { throw Failure.unsupported }
        var report = NativeLimitVerification(target: limit, outcome: .unavailable)
        if let before = try? backend.operations.read(), before.isValid, before.availableLimits.contains(limit) {
            report.before = before
            var applied = false
            do {
                try applyNativeLimit(limit, owner: session, leaseFor: .seconds(5), expectedInitial: before)
                if let reading = try? backend.operations.read(), reading.isValid { report.applied = reading }
                applied = report.applied?.configuredLimit == limit && report.applied?.enabled == true
            } catch { /* Recovery state below is authoritative, including partial failure. */ }
            do { try restore() } catch { /* Report uncertainty; never turn it into success. */ }
            if let reading = try? backend.operations.read(), reading.isValid { report.after = reading }
            if state == .restorationRequired {
                report.outcome = .restorationRequired
            } else if nativeTransaction?.state == .externalChange, report.after != nil {
                report.outcome = .externalChange
            } else if let after = report.after, before.configuredLimit == after.configuredLimit, before.enabled == after.enabled {
                report.outcome = applied ? .restored : .failedRestored
            }
        }
        var response = HelperStatus.current
        response.nativeVerificationAvailable = true
        response.nativeVerification = report
        if report.outcome == .restorationRequired { response.controlState = .restorationRequired }
        return try response.validated()
    }

    private func commandDeadline(owner: UUID, duration: Duration) throws -> ContinuousClock.Instant {
        try checkLease()
        if let current = self.owner, current != owner { throw Failure.differentOwner }
        guard state != .restorationRequired else { throw Failure.notReady }
        guard duration > .zero, duration <= Self.maximumLease else {
            try restore()
            throw Failure.invalidLease
        }
        guard !Task.isCancelled else {
            try restore()
            throw Failure.cancelled
        }
        return clock.now.advanced(by: duration)
    }

    private func finishCommand(state requestedState: State, owner: UUID, deadline: ContinuousClock.Instant) throws {
        guard !Task.isCancelled else {
            try restore()
            throw Failure.cancelled
        }
        guard clock.now < deadline else {
            try restore()
            throw Failure.leaseExpired
        }
        self.owner = owner
        state = requestedState
        leaseDeadline = deadline
        expiry?.cancel()
        // Retain the executor until expiry even if its external owner disappears.
        expiry = Task { [clock] in
            do { try await clock.sleep(until: deadline) } catch { return }
            // A cancelled old timer may already be queued on this actor after a renewal.
            guard self.leaseDeadline == deadline else { return }
            try? self.checkLease()
        }
    }

    /// Checks monotonic time; explicit instants allow expiry/renewal tests without waiting.
    /// ContinuousClock includes time spent asleep, but this alone cannot restore hardware in sleep.
    func checkLease(at instant: ContinuousClock.Instant? = nil) throws {
        guard let deadline = leaseDeadline, (instant ?? clock.now) >= deadline else { return }
        try restore()
    }

    /// A late invalidation from another connection cannot revoke the current owner's command.
    func disconnect(owner: UUID) throws {
        sessions.remove(owner)
        guard self.owner == owner else { return }
        try restore()
    }

    /// Used before startup, sleep, shutdown and removal with backend-appropriate recovery.
    /// Native settings are restored or external ownership is preserved; unknown recovery stays blocked.
    func restore() throws {
        revokeLease()
        state = .restorationRequired
        if nativeBackend == nil, let nativeBackendFactory {
            do { nativeBackend = try nativeBackendFactory() } catch { throw Failure.restorationFailed }
        }
        if let nativeBackend {
            do {
                if nativeTransaction == nil {
                    nativeTransaction = try NativeChargeLimitTransaction(operations: nativeBackend.operations, journal: nativeBackend.journal)
                }
                try nativeTransaction?.restore()
            } catch {
                // External settings mean relinquished ownership, not a successful physical rollback.
                guard nativeTransaction?.state == .externalChange else { throw Failure.restorationFailed }
            }
            state = .macOS
            return
        }
        guard let operations else {
            state = .macOS // This process has never had a writer; no hardware restoration is claimed.
            return
        }
        var failed = false
        do { try operations.setAdapterEnabled(true) } catch { failed = true }
        do { try operations.setChargingAllowed(true) } catch { failed = true }
        guard !failed else { throw Failure.restorationFailed }
        state = .macOS
    }

    private func revokeLease() {
        expiry?.cancel()
        expiry = nil
        owner = nil
        leaseDeadline = nil
    }
}
