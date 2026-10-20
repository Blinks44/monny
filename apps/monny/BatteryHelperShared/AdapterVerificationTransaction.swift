import Foundation

/// Checkpointed core, driven by the serialized executor/watchdog only with an explicit backend.
/// Full physical verification remains disabled; explicit byte research shares this recovery path.
nonisolated struct AdapterVerificationTransaction: Sendable {
    enum State: Sendable, Equatable { case idle, awaitingObservation, restorationRequired }
    enum Observation: Sendable, Equatable { case awaitingTransition, restoredAfterIsolation }
    enum Source: String, Codable, Sendable { case adapter, battery, unknown }
    enum Failure: Error, Sendable, Equatable {
        case busy, notStarted, unavailable, unsupportedSignature, unknownAdapterValue
        case invalidObservation, adapterDisconnected, lowBattery, nativeChanged
        case verificationFailed, operationFailed, cancelled, expired
        case invalidJournal, journalFailed, restorationRequired, restorationFailed
    }

    /// Source selection is separate from the physical connector, especially during isolation.
    struct Environment: Sendable {
        var nativeLimit: NativeChargeLimit.Snapshot
        var nativeSessionActive: Bool
        var isAdapterConnected: Bool
        var source: Source
        var isCharging: Bool
        var level: Double
        /// Must be measured with a monotonic clock, not derived from a wall-clock timestamp.
        var age: Duration = .zero
    }

    /// Fresh synchronous operations only, serialized with checkpoint and read-back.
    /// The semantic setter may throw after taking effect; it accepts no raw key or arbitrary byte.
    struct Operations: Sendable {
        var readCHIE: @Sendable () throws -> SMCKeyInspection
        var readEnvironment: @Sendable () throws -> Environment
        var setAdapterIsolated: @Sendable (Bool) throws -> Void
    }

    /// A short observation budget, not a hard deadline for a stalled synchronous system API.
    static let maximumDuration: Duration = .seconds(3)
    static let maximumReadingAge: Duration = .seconds(2)

    private struct Checkpoint: Codable {
        var version = 1
        var key = "CHIE"
        var originalValue: UInt8 = 0
        var attemptedValue: UInt8 = 8
        var isValid: Bool { version == 1 && key == "CHIE" && originalValue == 0 && attemptedValue == 8 }
    }

    private let operations: Operations
    private let journal: ChargeRecoveryJournal
    private let now: @Sendable () -> SuspendingClock.Instant
    private var ownsCheckpoint = false
    private var deadline: SuspendingClock.Instant?
    private var originalNative: NativeChargeLimit.Snapshot?
    private(set) var state = State.idle
    private(set) var beforeEnvironment: Environment?
    private(set) var observedEnvironment: Environment?

    /// Loads recovery intent without reading or writing hardware; pending work must restore first.
    init(operations: Operations, journal: ChargeRecoveryJournal,
         now: @escaping @Sendable () -> SuspendingClock.Instant = { SuspendingClock().now }) throws {
        self.operations = operations
        self.journal = journal
        self.now = now
        let data: Data?
        do { data = try journal.load() } catch { throw Failure.journalFailed }
        if let data {
            guard data.count <= 4096,
                  let record = try? JSONDecoder().decode(Checkpoint.self, from: data), record.isValid
            else { throw Failure.invalidJournal }
            ownsCheckpoint = true
            state = .restorationRequired
        }
    }

    /// Arms one observation from an initially allowed adapter input; it never changes native limits.
    mutating func begin() throws {
        guard state != .restorationRequired else { throw Failure.restorationRequired }
        guard state == .idle else { throw Failure.busy }
        beforeEnvironment = nil
        observedEnvironment = nil
        do {
            if Task.isCancelled { throw Failure.cancelled }
            guard try adapterValue() == 0 else { throw Failure.busy }
            let initial = try environment()
            guard initial.source == .adapter else { throw Failure.invalidObservation }
            beforeEnvironment = initial
            try checkpoint(native: initial.nativeLimit)
            try operations.setAdapterIsolated(true)
            guard try adapterValue() == 8 else { throw Failure.verificationFailed }
            try checkBudget()
            state = .awaitingObservation
        } catch {
            if ownsCheckpoint { try restore() }
            throw (error as? Failure) ?? Failure.operationFailed
        }
    }

    /// Research-only pulse: capture candidate flags without requiring their unproven isolation semantics.
    /// No dwell/poll/retry. The caller must serialize ownership; this method never grants control support.
    mutating func pulse(observe: @Sendable (AdapterBytePulseReport.Phase) throws -> AdapterBytePulseReport.Sample) throws -> AdapterBytePulseReport {
        guard state != .restorationRequired else { throw Failure.restorationRequired }
        guard state == .idle else { throw Failure.busy }
        beforeEnvironment = nil
        observedEnvironment = nil
        var report = AdapterBytePulseReport(outcome: .unavailable)
        var capturedWithinBudget = false
        do {
            try beginByteObservation(observe: observe, report: &report)
            let sample = try observe(.during)
            if sample.isFresh, sample.reading.isValid { report.during = sample.reading }
            try checkBudget()
            capturedWithinBudget = report.during != nil
        } catch { /* Recovery is mandatory even if observation/cancellation/setter acknowledgement failed. */ }
        if ownsCheckpoint {
            do { try restore() }
            catch {
                report.outcome = .restorationRequired
                return report
            }
        }
        guard report.before != nil else { return report }
        // restore() clears the checkpoint only after a real zero-byte read-back.
        report.restoredByte = 0
        report.outcome = .failedRestored
        // This is post-restoration observation; no delay can prolong adapter isolation here.
        if !Task.isCancelled, let sample = try? observe(.after), sample.isFresh, sample.reading.isValid {
            report.after = sample.reading
        }
        if capturedWithinBudget, report.appliedByte == 8,
           let before = report.before, let during = report.during, let after = report.after,
           (during.nativeLimit == nil || before.nativeLimit == during.nativeLimit), before.nativeLimit == after.nativeLimit,
           during.nativeSessionActive == false, after.nativeSessionActive == false {
            report.outcome = .byteRoundTripRestored
        }
        return report
    }

    /// Arms one research attempt without assuming physical cable semantics. The executor owns its bound.
    mutating func beginByteObservation(
        observe: @Sendable (AdapterBytePulseReport.Phase) throws -> AdapterBytePulseReport.Sample,
        report: inout AdapterBytePulseReport
    ) throws {
        guard state != .restorationRequired else { throw Failure.restorationRequired }
        guard state == .idle else { throw Failure.busy }
        if Task.isCancelled { throw Failure.cancelled }
        guard try adapterValue() == 0 else { throw Failure.busy }
        let initial = try observe(.before)
        guard initial.isFresh, initial.reading.admitsPulse, let native = initial.reading.nativeLimit else { throw Failure.invalidObservation }
        report.before = initial.reading
        try checkpoint(native: native)
        report.attemptedByte = 8 // A throwing setter may already have taken effect.
        try operations.setAdapterIsolated(true)
        guard try adapterValue() == 8 else { throw Failure.verificationFailed }
        report.appliedByte = 8
        try checkBudget()
        state = .awaitingObservation
    }

    /// Reads one candidate sample; missing/unsafe data is an exit condition, never a reason to wait longer.
    func readByteObservation(
        observe: @Sendable (AdapterBytePulseReport.Phase) throws -> AdapterBytePulseReport.Sample
    ) throws -> AdapterBytePulseReport.Reading {
        guard state == .awaitingObservation else { throw Failure.notStarted }
        try checkBudget()
        guard try adapterValue() == 8 else { throw Failure.verificationFailed }
        let sample = try observe(.during)
        guard sample.isFresh, sample.reading.isValid, sample.reading.nativeSessionActive == false,
              sample.reading.isLidClosed == false, sample.reading.level >= 0.3,
              sample.reading.nativeLimit == nil || sample.reading.nativeLimit == originalNative else { throw Failure.invalidObservation }
        try checkBudget()
        return sample.reading
    }

    /// Confirms fresh battery-source/no-charge evidence, then immediately restores adapter input.
    /// An acknowledged SMC byte alone never counts as physical isolation evidence.
    mutating func observe() throws -> Observation {
        guard state != .restorationRequired else { throw Failure.restorationRequired }
        guard state == .awaitingObservation else { throw Failure.notStarted }
        do {
            try checkBudget()
            guard try adapterValue() == 8 else { throw Failure.verificationFailed }
            let current = try environment()
            observedEnvironment = current
            guard current.nativeLimit == originalNative else { throw Failure.nativeChanged }
            try checkBudget()
            guard current.source == .battery else { return .awaitingTransition }
            guard current.isCharging == false else { throw Failure.invalidObservation }
        } catch {
            if ownsCheckpoint { try restore() }
            throw (error as? Failure) ?? Failure.operationFailed
        }
        try restore()
        return .restoredAfterIsolation
    }

    /// Recovery ignores cancellation and missing telemetry; only the known CHIE signature/value is used.
    /// Failed setters/reads/clears retain a retryable checkpoint and prevent another begin.
    mutating func restore() throws {
        guard ownsCheckpoint else { return }
        state = .restorationRequired
        do {
            if try adapterValue() == 8 { try operations.setAdapterIsolated(false) }
            guard try adapterValue() == 0 else { throw Failure.verificationFailed }
            try journal.clear()
            ownsCheckpoint = false
            originalNative = nil
            deadline = nil
            state = .idle
        } catch { throw Failure.restorationFailed }
    }

    /// Save may throw after persistence; retain ownership until zero read-back and clear acknowledge recovery.
    private mutating func checkpoint(native: NativeChargeLimit.Snapshot) throws {
        originalNative = native
        deadline = now().advanced(by: Self.maximumDuration)
        ownsCheckpoint = true
        state = .restorationRequired
        do { try journal.save(JSONEncoder().encode(Checkpoint())) } catch { throw Failure.journalFailed }
        try checkBudget()
    }

    private func adapterValue() throws -> UInt8 {
        let inspection: SMCKeyInspection
        do { inspection = try operations.readCHIE() } catch { throw Failure.unavailable }
        return try AdapterIsolationCommand.value(inspection)
    }

    private func environment() throws -> Environment {
        let value: Environment
        do { value = try operations.readEnvironment() } catch { throw Failure.unavailable }
        guard value.nativeLimit.isValid, value.age >= .zero, value.age <= Self.maximumReadingAge,
              value.level.isFinite, (0...1).contains(value.level), value.source != .unknown
        else { throw Failure.invalidObservation }
        guard value.nativeSessionActive == false else { throw Failure.busy }
        guard value.isAdapterConnected else { throw Failure.adapterDisconnected }
        // A one-shot engineering probe must not deliberately spend a nearly depleted battery.
        guard value.level >= 0.3 else { throw Failure.lowBattery }
        return value
    }

    private func checkBudget() throws {
        if Task.isCancelled { throw Failure.cancelled }
        guard let deadline, now() < deadline else { throw Failure.expired }
    }
}
