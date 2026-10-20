import Foundation

/// Owns helper sessions, lifecycle gates and serialized bounded commands. Adapter experiments require separate explicit capability admission.
actor ChargeCommandExecutor {
    nonisolated enum Mode: Sendable, Equatable { case charge, hold, discharge }
    nonisolated enum State: Sendable, Equatable {
        case restorationRequired, macOS, active(Mode), nativeLimit(Int), adapterVerification
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

    /// Full isolation needs a verified physical provider; a pulse-only backend cannot advertise it.
    nonisolated struct AdapterVerificationBackend: Sendable {
        var operations: AdapterVerificationTransaction.Operations
        var journal: ChargeRecoveryJournal
        var allowsIsolationVerification = true
        var pulseRead: (@Sendable (AdapterBytePulseReport.Phase) throws -> AdapterBytePulseReport.Sample)? = nil
    }

    nonisolated static let maximumLease: Duration = .seconds(30)
    private(set) var state = State.restorationRequired
    private(set) var leaseDeadline: SuspendingClock.Instant?
    private var owner: UUID?
    private var expiry: Task<Void, Never>?
    nonisolated enum Phase: Sendable, Equatable { case starting, ready, sleeping, removing, stopped }
    private(set) var phase = Phase.starting
    private var sessions: Set<UUID> = []
    private let operations: Operations?
    private var nativeBackend: NativeBackend?
    private let nativeBackendFactory: (@Sendable () throws -> NativeBackend)?
    private var nativeTransaction: NativeChargeLimitTransaction?
    private var adapterVerificationBackend: AdapterVerificationBackend?
    private let adapterBackendFactory: (@Sendable () throws -> AdapterVerificationBackend)?
    private var adapterVerificationTransaction: AdapterVerificationTransaction?
    /// Reserves the request across awaits, including after a lifecycle event restores its lease.
    private var adapterVerificationRequestOwner: UUID?
    private let helperInstance: UUID?
    private let restartAfterIsolation: (@Sendable () throws -> Void)?
    private var startupAdapterRecovery: AdapterStartupRecovery?
    private var lifecycleDiagnostics = HelperLifecycleDiagnostics()
    private let clock = SuspendingClock()
    private let adapterDiagnosticRead: @Sendable () async -> AdapterCapabilityProbe
    private var adapterDiagnosticTask: Task<AdapterCapabilityProbe, Never>?
    private let diagnosticRead: @Sendable () async -> ChargeCapabilityProbe
    private let nativeDiagnosticRead: @Sendable () async -> NativeChargeLimit
    private var nativeDiagnosticTask: Task<NativeChargeLimit, Never>?
    private var diagnosticTask: Task<ChargeCapabilityProbe, Never>?

    /// An absent backend never claims hardware support.
    init(operations: Operations? = nil,
         diagnosticRead: @escaping @Sendable () async -> ChargeCapabilityProbe = { await ChargeCapabilityProbe.read() },
         adapterVerificationBackend: AdapterVerificationBackend? = nil,
         adapterDiagnosticRead: @escaping @Sendable () async -> AdapterCapabilityProbe = { await AdapterCapabilityProbe.read() },
         nativeDiagnosticRead: @escaping @Sendable () async -> NativeChargeLimit = { .unavailable(.notProbed) }) {
        self.operations = operations
        self.nativeBackend = nil
        self.nativeBackendFactory = nil
        self.helperInstance = nil
        self.restartAfterIsolation = nil
        self.diagnosticRead = diagnosticRead
        self.adapterVerificationBackend = adapterVerificationBackend
        self.adapterBackendFactory = nil
        self.adapterDiagnosticRead = adapterDiagnosticRead
        self.nativeDiagnosticRead = nativeDiagnosticRead
    }

    /// Journal I/O is deferred to startup on this executor, never performed by its initializer.
    init(nativeBackend: NativeBackend,
         diagnosticRead: @escaping @Sendable () async -> ChargeCapabilityProbe = { await ChargeCapabilityProbe.read() },
         adapterVerificationBackend: AdapterVerificationBackend? = nil,
         adapterDiagnosticRead: @escaping @Sendable () async -> AdapterCapabilityProbe = { await AdapterCapabilityProbe.read() },
         nativeDiagnosticRead: @escaping @Sendable () async -> NativeChargeLimit = { .unavailable(.notProbed) }) {
        self.operations = nil
        self.nativeBackend = nativeBackend
        self.nativeBackendFactory = nil
        self.helperInstance = nil
        self.restartAfterIsolation = nil
        self.diagnosticRead = diagnosticRead
        self.adapterVerificationBackend = adapterVerificationBackend
        self.adapterBackendFactory = nil
        self.adapterDiagnosticRead = adapterDiagnosticRead
        self.nativeDiagnosticRead = nativeDiagnosticRead
    }

    /// Factory runs on the executor at startup, recovering any prior verification checkpoint.
    init(nativeBackendFactory: @escaping @Sendable () throws -> NativeBackend,
         adapterVerificationBackend: AdapterVerificationBackend? = nil,
         adapterBackendFactory: (@Sendable () throws -> AdapterVerificationBackend)? = nil,
         helperInstance: UUID? = nil,
         restartAfterIsolation: (@Sendable () throws -> Void)? = nil,
         adapterDiagnosticRead: @escaping @Sendable () async -> AdapterCapabilityProbe = { await AdapterCapabilityProbe.read() },
         nativeDiagnosticRead: @escaping @Sendable () async -> NativeChargeLimit = { .unavailable(.notProbed) }) {
        self.operations = nil
        self.nativeBackend = nil
        self.nativeBackendFactory = nativeBackendFactory
        self.helperInstance = helperInstance
        self.restartAfterIsolation = restartAfterIsolation
        self.diagnosticRead = { await ChargeCapabilityProbe.read() }
        self.adapterVerificationBackend = adapterVerificationBackend
        self.adapterBackendFactory = adapterBackendFactory
        self.adapterDiagnosticRead = adapterDiagnosticRead
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
        // App and helper wake notifications can arrive in either order. Read-only
        // observers may inspect a preserved native session before didWake runs.
        let preservingNative = phase == .sleeping && nativeBackendFactory != nil && owner != nil
        guard phase == .ready || phase == .removing || preservingNative else { throw Failure.notReady }
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
            let pending = hasAdapterRecovery
            do {
                try restore()
                recordLifecycle(.removal, adapterPending: pending)
            } catch {
                recordLifecycle(.removal, adapterPending: pending, failed: true)
                throw error
            }
        }
        try checkLease()
        // No wire status claims verification is non-controlling while its injected writer is active.
        guard state != .adapterVerification, adapterVerificationTransaction?.state != .restorationRequired else { throw Failure.notReady }
        guard state == .macOS || (nativeBackendFactory != nil && nativeBackend != nil) else { throw Failure.notReady }
        var response = HelperStatus.current
        response.helperInstance = helperInstance
        if helperInstance != nil {
            response.lifecycleDiagnostics = lifecycleDiagnostics
            if adapterVerificationBackend?.pulseRead != nil {
                response.adapterRemovalVerificationAvailable = true
                response.adapterRemovalVerificationVersion = HelperContract.adapterRemovalVerificationVersion
                response.adapterSleepVerificationAvailable = true
                response.adapterSleepVerificationVersion = HelperContract.adapterSleepVerificationVersion
            }
        }
        response.adapterStartupRecovery = startupAdapterRecovery
        if restartAfterIsolation != nil, helperInstance != nil, adapterVerificationBackend?.pulseRead != nil {
            response.adapterRestartVerificationAvailable = true
            response.adapterRestartVerificationVersion = HelperContract.adapterRestartVerificationVersion
        }
        if nativeBackendFactory != nil, let backend = nativeBackend {
            let snapshot = try backend.operations.read()
            guard snapshot.isValid else { throw Failure.notReady }
            response.nativeLimitSessionAvailable = true
            response.nativeLimitSessionVersion = HelperContract.nativeLimitSessionVersion
            response.nativeChargeLimit = .available(snapshot)
            if case .nativeLimit(let limit) = state {
                guard snapshot.enabled, snapshot.configuredLimit == limit else {
                    try restore()
                    throw Failure.externalChange
                }
                response.controlState = .nativeLimit
                response.activeNativeLimit = limit
            } else if state == .restorationRequired {
                response.controlState = .restorationRequired
            }
        }
        if nativeBackendFactory != nil { response.nativeVerificationAvailable = true }
        response.adapterVerificationAvailable = adapterVerificationBackend?.allowsIsolationVerification == true
        response.adapterByteObservationAvailable = adapterVerificationBackend?.pulseRead != nil
        if response.adapterByteObservationAvailable == true { response.adapterByteObservationVersion = HelperContract.adapterByteObservationVersion }
        response.adapterBytePulseAvailable = adapterVerificationBackend?.pulseRead != nil
        if response.adapterBytePulseAvailable == true { response.adapterBytePulseVersion = HelperContract.adapterBytePulseVersion }
        if response.adapterVerificationAvailable == true { response.adapterVerificationVersion = HelperContract.adapterVerificationVersion }
        return response
    }

    /// Cache capability probes; the active native backend always supplies a fresh setting.
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
        if nativeBackendFactory == nil { response.nativeChargeLimit = nativeReport }
        return response
    }

    /// Separate opt-in probe; neither status nor the legacy six-key report starts this work.
    func diagnoseAdapter(for session: UUID) async throws -> HelperStatus {
        _ = try status(for: session)
        guard phase == .ready else { throw Failure.notReady }
        if adapterDiagnosticTask == nil { adapterDiagnosticTask = Task { await adapterDiagnosticRead() } }
        guard let adapterDiagnosticTask else { throw Failure.notReady }
        let report = await adapterDiagnosticTask.value
        // Revalidate ownership and lifecycle after the shared read suspends this actor.
        var response = try status(for: session)
        guard phase == .ready else { throw Failure.notReady }
        response.adapterDiagnostics = report
        return response
    }

    /// Native system limits persist in sleep; direct hardware modes still restore.
    func willSleep() throws {
        guard phase != .stopped else { return }
        let pending = hasAdapterRecovery
        do {
            try prepareForSleep()
            recordLifecycle(.sleep, adapterPending: pending)
        } catch {
            recordLifecycle(.sleep, adapterPending: pending, failed: true)
            throw error
        }
    }

    private func prepareForSleep() throws {
        guard phase != .stopped else { return }
        if phase == .removing {
            try restore()
            return
        }
        // Even an expired lease whose rollback fails must remain eligible for wake recovery.
        phase = .sleeping
        try checkLease()
        if nativeBackendFactory != nil, case .nativeLimit = state, owner != nil {
            // Retain the original checkpoint and connection owner, not a command to replay.
            expiry?.cancel()
            expiry = nil
            leaseDeadline = nil
            return
        }
        sessions.removeAll()
        try restore()
    }

    func didWake() throws {
        guard phase == .sleeping || phase == .removing else { return }
        let pending = hasAdapterRecovery
        do {
            if phase == .removing { try restore() }
            else { try finishWake() }
            recordLifecycle(.wake, adapterPending: pending)
        } catch {
            recordLifecycle(.wake, adapterPending: pending, failed: true)
            throw error
        }
    }

    private func finishWake() throws {
        guard phase == .sleeping else { return }
        if case .nativeLimit = state, let owner {
            do {
                // Read back only: never overwrite a setting changed outside Monny.
                _ = try status(for: owner)
                phase = .ready
                try finishCommand(state: state, owner: owner,
                                  deadline: clock.now.advanced(by: Self.maximumLease))
                return
            } catch {
                sessions.remove(owner)
                try restore()
                phase = .ready
                throw error
            }
        }
        try restore()
        phase = .ready
    }

    private var hasAdapterRecovery: Bool {
        guard let transaction = adapterVerificationTransaction else { return false }
        return transaction.state != .idle
    }

    private func recordLifecycle(_ event: HelperLifecycleDiagnostics.Event, adapterPending: Bool, failed: Bool = false) {
        let outcome: HelperLifecycleDiagnostics.Outcome
        if failed { outcome = .failed }
        else if adapterPending { outcome = .adapterRestored }
        else if case .nativeLimit = state { outcome = .nativeLimitPreserved }
        else { outcome = .noAdapterRecoveryNeeded }
        lifecycleDiagnostics.record(event, outcome: outcome)
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
        guard adapterVerificationRequestOwner == nil else { throw Failure.notReady }
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

    /// Internal admission shared by fixtures and the explicit revisioned IPC wrapper.
    func startAdapterVerification(for session: UUID) throws {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        guard phase == .ready else { throw Failure.notReady }
        try checkLease()
        guard state == .macOS, owner == nil,
              adapterVerificationRequestOwner == nil || adapterVerificationRequestOwner == session else { throw Failure.notReady }
        guard adapterVerificationBackend?.allowsIsolationVerification == true, adapterVerificationTransaction != nil else { throw Failure.unsupported }
        let deadline = try commandDeadline(owner: session, duration: AdapterVerificationTransaction.maximumDuration)
        // Arm the existing watchdog before the synchronous setter; no renewal path extends this lease.
        try finishCommand(state: .adapterVerification, owner: session, deadline: deadline)
        do {
            try adapterVerificationTransaction?.begin()
        } catch {
            if adapterVerificationTransaction?.state == .restorationRequired {
                state = .restorationRequired // Keep the watchdog for one recovery attempt on expiry.
            } else {
                revokeLease()
                state = .macOS
            }
            throw error
        }
        try checkLease()
        guard owner == session, state == .adapterVerification else { throw Failure.leaseExpired }
    }

    /// Only the original live owner may observe; successful restoration cancels the watchdog.
    func observeAdapterVerification(for session: UUID) throws -> AdapterVerificationTransaction.Observation {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        guard phase == .ready else { throw Failure.notReady }
        guard owner == session else { throw Failure.differentOwner }
        try checkLease()
        guard sessions.contains(session) else { throw Failure.invalidSession }
        guard state == .adapterVerification else { throw Failure.notReady }
        do {
            guard let observation = try adapterVerificationTransaction?.observe() else { throw Failure.unsupported }
            if observation == .restoredAfterIsolation {
                revokeLease()
                state = .macOS
            }
            return observation
        } catch {
            if adapterVerificationTransaction?.state == .restorationRequired {
                state = .restorationRequired
            } else {
                revokeLease()
                state = .macOS
            }
            throw error
        }
    }

    /// One explicit attempt, using the existing non-renewable watchdog and authenticated owner.
    /// The live daemon has no adapter backend, so it cannot advertise or execute this request.
    func verifyAdapterIsolation(for session: UUID,
                                pause: @Sendable () async throws -> Void = {
                                    try await Task.sleep(for: .milliseconds(100), clock: .suspending)
                                }) async throws -> HelperStatus {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        guard let backend = adapterVerificationBackend, backend.allowsIsolationVerification else { throw Failure.unsupported }
        guard phase == .ready, state == .macOS, owner == nil, adapterVerificationRequestOwner == nil else {
            throw Failure.notReady
        }
        adapterVerificationRequestOwner = session
        defer { adapterVerificationRequestOwner = nil }
        var observed = false
        do {
            try startAdapterVerification(for: session)
            while true {
                if try observeAdapterVerification(for: session) == .restoredAfterIsolation {
                    observed = true
                    break
                }
                try await pause()
                // No ownership/lifecycle assumptions survive suspension. Watchdog may have restored/revoked.
                guard sessions.contains(session), owner == session, phase == .ready else { throw Failure.notReady }
            }
        } catch {
            // A foreign session can never take the reserved request. Lifecycle recovery may already be complete.
            if owner == session || (owner == nil && state == .restorationRequired) { try? restore() }
        }
        var report = AdapterVerificationReport(outcome: .unavailable)
        report.before = adapterVerificationTransaction?.beforeEnvironment.map(AdapterVerificationReport.Reading.init)
        report.during = adapterVerificationTransaction?.observedEnvironment.map(AdapterVerificationReport.Reading.init)
        if state == .restorationRequired {
            report.outcome = .restorationRequired
        } else if state == .macOS, adapterVerificationTransaction?.state == .idle, report.before != nil {
            // The transaction cleared its checkpoint only after an actual CHIE=0 read-back.
            report.restoredByte = 0
            report.outcome = observed ? .restoredAfterObservation : .failedRestored
            if !Task.isCancelled, phase == .ready, sessions.contains(session),
               let environment = try? backend.operations.readEnvironment() {
                let reading = AdapterVerificationReport.Reading(environment)
                if reading.isValid, environment.age >= .zero,
                   environment.age <= AdapterVerificationTransaction.maximumReadingAge { report.after = reading }
            }
        }
        var response = HelperStatus.current
        response.adapterVerificationAvailable = true
        response.adapterVerificationVersion = HelperContract.adapterVerificationVersion
        response.adapterVerification = report
        if report.outcome == .restorationRequired { response.controlState = .restorationRequired }
        return try response.validated()
    }

    /// One synchronous actor turn: no suspension, dwell, retry or native setter.
    func verifyAdapterBytePulse(for session: UUID) throws -> HelperStatus {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        try checkLease()
        guard phase == .ready, state == .macOS, owner == nil, adapterVerificationRequestOwner == nil else {
            throw Failure.notReady
        }
        guard let read = adapterVerificationBackend?.pulseRead, adapterVerificationTransaction != nil else { throw Failure.unsupported }
        adapterVerificationRequestOwner = session
        defer { adapterVerificationRequestOwner = nil }
        let deadline = try commandDeadline(owner: session, duration: AdapterVerificationTransaction.maximumDuration)
        try finishCommand(state: .adapterVerification, owner: session, deadline: deadline)
        let report: AdapterBytePulseReport
        do {
            guard let result = try adapterVerificationTransaction?.pulse(observe: read) else { throw Failure.unsupported }
            report = result
        } catch {
            try restore()
            throw error
        }
        if report.outcome == .restorationRequired {
            state = .restorationRequired // Keep the watchdog for one recovery attempt, plus persistent restart intent.
        } else {
            revokeLease()
            state = .macOS
        }
        var response = HelperStatus.current
        response.adapterBytePulseAvailable = true
        response.adapterBytePulseVersion = HelperContract.adapterBytePulseVersion
        response.adapterBytePulse = report
        if report.outcome == .restorationRequired { response.controlState = .restorationRequired }
        return try response.validated()
    }

    /// One write, up to eight reads/two seconds; source selection is evidence, not physical presence.
    func observeAdapterByte(for session: UUID,
                            pause: @Sendable () async throws -> Void = {
                                try await Task.sleep(for: .milliseconds(250), clock: .suspending)
                            }) async throws -> HelperStatus {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        try checkLease()
        guard phase == .ready, state == .macOS, owner == nil, adapterVerificationRequestOwner == nil else { throw Failure.notReady }
        guard let read = adapterVerificationBackend?.pulseRead, adapterVerificationTransaction != nil else { throw Failure.unsupported }
        adapterVerificationRequestOwner = session
        defer { adapterVerificationRequestOwner = nil }
        let deadline = try commandDeadline(owner: session, duration: AdapterVerificationTransaction.maximumDuration)
        let observationEnd = clock.now.advanced(by: AdapterByteObservationReport.observationDuration)
        try finishCommand(state: .adapterVerification, owner: session, deadline: deadline)
        var report = AdapterByteObservationReport(byteEvidence: .init(outcome: .unavailable))
        do {
            try adapterVerificationTransaction?.beginByteObservation(observe: read, report: &report.byteEvidence)
            while report.sampleCount < AdapterByteObservationReport.maximumSamples, clock.now < observationEnd {
                guard sessions.contains(session), owner == session, phase == .ready, state == .adapterVerification else { throw Failure.notReady }
                guard let sample = try adapterVerificationTransaction?.readByteObservation(observe: read) else { throw Failure.unsupported }
                report.byteEvidence.during = sample
                report.sampleCount += 1
                if sample.source == .battery, sample.isCharging == false {
                    report.batterySourceObserved = true
                    break
                }
                if report.sampleCount == AdapterByteObservationReport.maximumSamples { break }
                try await pause()
                // No state/ownership assumptions survive the suspension, including after rollback on sleep.
                guard sessions.contains(session), owner == session, phase == .ready, state == .adapterVerification else { throw Failure.notReady }
                try checkLease()
            }
        } catch { /* Always recover below; failed telemetry never prolongs observation. */ }
        if owner == session || (owner == nil && state == .restorationRequired) { try? restore() }
        if state == .restorationRequired {
            armExpiry(at: deadline) // One bounded recovery retry; never another isolation attempt.
            report.byteEvidence.outcome = .restorationRequired
        } else if state == .macOS, adapterVerificationTransaction?.state == .idle, report.byteEvidence.before != nil {
            report.byteEvidence.restoredByte = 0
            report.byteEvidence.outcome = .failedRestored
            // Hardware rollback is complete before this independent read-only settling window.
            let returnEnd = clock.now.advanced(by: AdapterByteObservationReport.returnObservationDuration)
            report.returnObservation = .boundReached
            while report.returnSampleCount < AdapterByteObservationReport.maximumSamples, clock.now < returnEnd {
                guard !Task.isCancelled, phase == .ready, state == .macOS, sessions.contains(session) else {
                    report.returnObservation = .interrupted
                    break
                }
                do {
                    // Never infer a zero byte from source telemetry or issue a setter to refresh it.
                    guard let backend = adapterVerificationBackend,
                          try AdapterIsolationCommand.value(backend.operations.readCHIE()) == 0 else {
                        throw Failure.notReady
                    }
                    let sample = try read(.after)
                    guard clock.now < returnEnd else { break }
                    guard sample.isFresh, sample.reading.isValid, !sample.reading.nativeSessionActive else { throw Failure.notReady }
                    report.byteEvidence.after = sample.reading
                    report.returnSampleCount += 1
                    guard sample.reading.nativeLimit == report.byteEvidence.before?.nativeLimit else { throw Failure.externalChange }
                    if sample.reading.source == .adapter {
                        report.returnObservation = .adapterObserved
                        break
                    }
                    guard report.returnSampleCount < AdapterByteObservationReport.maximumSamples else { break }
                    try await pause()
                    // Reservation survives suspension; lifecycle/ownership must still be rechecked above.
                } catch {
                    report.returnObservation = Task.isCancelled ? .interrupted : .unavailable
                    break
                }
            }
            if report.sampleCount > 0, report.byteEvidence.appliedByte == 8,
               let before = report.byteEvidence.before, let after = report.byteEvidence.after,
               before.nativeLimit == after.nativeLimit, after.nativeSessionActive == false {
                report.byteEvidence.outcome = .byteRoundTripRestored
            }
        }
        var response = HelperStatus.current
        response.adapterByteObservationAvailable = true
        response.adapterByteObservationVersion = HelperContract.adapterByteObservationVersion
        response.adapterByteObservation = report
        if report.byteEvidence.outcome == .restorationRequired { response.controlState = .restorationRequired }
        return try response.validated()
    }

    /// The same bounded preparation serves removal; only the existing restoration acknowledgement may permit unregister.
    func prepareAdapterRemoval(for session: UUID) throws -> AdapterLifecyclePreparation {
        try prepareAdapterSleep(for: session)
    }

    /// A fixed, non-renewable preparation. The caller retains this owner connection until lifecycle recovery.
    func prepareAdapterSleep(for session: UUID) throws -> AdapterLifecyclePreparation {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        try checkLease()
        guard phase == .ready, state == .macOS, owner == nil, adapterVerificationRequestOwner == nil else { throw Failure.notReady }
        guard let helperInstance, let read = adapterVerificationBackend?.pulseRead,
              adapterVerificationTransaction != nil else { throw Failure.unsupported }
        let deadline = try commandDeadline(owner: session, duration: AdapterVerificationTransaction.maximumDuration)
        try finishCommand(state: .adapterVerification, owner: session, deadline: deadline)
        var report = AdapterBytePulseReport(outcome: .unavailable)
        do {
            try adapterVerificationTransaction?.beginByteObservation(observe: read, report: &report)
            guard report.appliedByte == 8, let native = report.before?.nativeLimit else { throw Failure.commandFailed }
            return .init(helperInstance: helperInstance, nativeLimit: native, lifecycleBefore: lifecycleDiagnostics)
        } catch {
            do { try restore() }
            catch { armExpiry(at: deadline); throw Failure.restorationFailed }
            throw error
        }
    }

    /// Cancellation can only restore the authenticated owner's adapter experiment, never a foreign session.
    func cancelAdapterSleep(for session: UUID) throws -> HelperStatus {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        guard owner == nil || owner == session else { throw Failure.differentOwner }
        guard adapterVerificationRequestOwner == nil else { throw Failure.notReady }
        if case .nativeLimit = state { throw Failure.notReady }
        try restore()
        return try status(for: session)
    }

    /// Explicit engineering failure injection only: durable intent and known eight before self-termination.
    /// The live callback never returns. Any return/throw is a failed test and restores normally.
    func verifyAdapterRestart(for session: UUID) throws -> HelperStatus {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        try checkLease()
        guard phase == .ready, state == .macOS, owner == nil, adapterVerificationRequestOwner == nil else { throw Failure.notReady }
        guard helperInstance != nil, let terminate = restartAfterIsolation,
              let read = adapterVerificationBackend?.pulseRead, adapterVerificationTransaction != nil else { throw Failure.unsupported }
        adapterVerificationRequestOwner = session
        defer { adapterVerificationRequestOwner = nil }
        let deadline = try commandDeadline(owner: session, duration: AdapterVerificationTransaction.maximumDuration)
        try finishCommand(state: .adapterVerification, owner: session, deadline: deadline)
        var report = AdapterBytePulseReport(outcome: .unavailable)
        do {
            try adapterVerificationTransaction?.beginByteObservation(observe: read, report: &report)
            guard report.appliedByte == 8 else { throw Failure.commandFailed }
            try terminate()
        } catch {
            do { try restore() }
            catch { armExpiry(at: deadline); throw Failure.restorationFailed }
            throw error
        }
        do { try restore() }
        catch { armExpiry(at: deadline); throw Failure.restorationFailed }
        throw Failure.commandFailed
    }

    /// Native transactions accept only live authenticated owners and bounded leases.
    func applyNativeLimit(_ limit: Int, owner: UUID, leaseFor duration: Duration,
                          expectedInitial: NativeChargeLimit.Snapshot? = nil) throws {
        guard sessions.contains(owner) else { throw Failure.invalidSession }
        guard phase == .ready else { throw Failure.notReady }
        guard nativeBackend != nil else { throw Failure.unsupported }
        guard adapterVerificationRequestOwner == nil else { throw Failure.notReady }
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

    /// Live commands use the authenticated connection's owner and a fixed bounded lease.
    func setNativeLimit(_ limit: Int, for session: UUID) throws -> HelperStatus {
        guard nativeBackendFactory != nil else { throw Failure.unsupported }
        if phase == .sleeping {
            guard sessions.contains(session) else { throw Failure.invalidSession }
            guard owner == session else { throw Failure.differentOwner }
            guard state == .nativeLimit(limit) else { throw Failure.notReady }
            // A renewal racing the power notification is a read, never a sleep-time write.
            return try status(for: session)
        }
        try applyNativeLimit(limit, owner: session, leaseFor: Self.maximumLease)
        return try status(for: session)
    }

    func releaseNativeLimit(for session: UUID) throws -> HelperStatus {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        guard owner == nil || owner == session else { throw Failure.differentOwner }
        try restore()
        return try status(for: session)
    }

    /// One actor turn: explicit temporary target, fresh read-back, then immediate original restoration.
    func verifyNativeLimit(_ limit: Int, for session: UUID) throws -> HelperStatus {
        guard sessions.contains(session) else { throw Failure.invalidSession }
        guard nativeBackendFactory != nil, let backend = nativeBackend else { throw Failure.unsupported }
        guard phase == .ready, state == .macOS, owner == nil, adapterVerificationRequestOwner == nil else { throw Failure.notReady }
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

    private func commandDeadline(owner: UUID, duration: Duration) throws -> SuspendingClock.Instant {
        try checkLease()
        guard sessions.contains(owner) else { throw Failure.invalidSession }
        if let current = self.owner, current != owner { throw Failure.differentOwner }
        guard state != .restorationRequired, state != .adapterVerification else { throw Failure.notReady }
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

    private func finishCommand(state requestedState: State, owner: UUID, deadline: SuspendingClock.Instant) throws {
        guard !Task.isCancelled else {
            try restore()
            throw Failure.cancelled
        }
        guard clock.now < deadline else {
            sessions.remove(owner)
            try restore()
            throw Failure.leaseExpired
        }
        self.owner = owner
        state = requestedState
        armExpiry(at: deadline)
    }

    private func armExpiry(at deadline: SuspendingClock.Instant) {
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
    /// SuspendingClock excludes system sleep; native sleep explicitly suspends its deadline.
    func checkLease(at instant: SuspendingClock.Instant? = nil) throws {
        guard let deadline = leaseDeadline, (instant ?? clock.now) >= deadline else { return }
        // Restoring alone leaves an authenticated connection able to revive an expired
        // command on its next queued renewal. Expiry permanently revokes that owner.
        if let owner { sessions.remove(owner) }
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
        // Restore adapter input before native settings, even if the native backend cannot open.
        if adapterVerificationBackend == nil, let adapterBackendFactory {
            do { adapterVerificationBackend = try adapterBackendFactory() } catch { throw Failure.restorationFailed }
        }
        if let adapterVerificationBackend {
            do {
                if adapterVerificationTransaction == nil {
                    adapterVerificationTransaction = try AdapterVerificationTransaction(
                        operations: adapterVerificationBackend.operations, journal: adapterVerificationBackend.journal)
                }
                if phase == .starting, helperInstance != nil, startupAdapterRecovery == nil {
                    let pending = adapterVerificationTransaction?.state == .restorationRequired
                    let initial = pending ? try AdapterIsolationCommand.value(adapterVerificationBackend.operations.readCHIE()) : nil
                    try adapterVerificationTransaction?.restore()
                    startupAdapterRecovery = .init(checkpointFound: pending, initialByte: initial, restoredByte: pending ? 0 : nil)
                } else {
                    try adapterVerificationTransaction?.restore()
                }
            } catch { throw Failure.restorationFailed }
        }
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
