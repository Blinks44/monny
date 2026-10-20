import Foundation
import Synchronization
import Testing
@testable import monny

typealias AdapterTransaction = AdapterVerificationTransaction

/// All power flow, native settings and SMC effects are injected; no helper or hardware access.
nonisolated final class AdapterVerificationFixture: Sendable {
    enum Effect: Sendable { case failBefore, failAfter, ignore, loseReadAccess }
    enum InjectedFailure: Error { case operation }
    struct Storage: Sendable {
        var byte: UInt8 = 0
        var metadata = SMCKeyMetadata(type: "hex_", size: 1, attributes: 0xD4)
        var environment = AdapterTransaction.Environment(
            nativeLimit: .init(availableLimits: [80, 85, 90, 95, 100], configuredLimit: 85, enabled: true),
            nativeSessionActive: false, isAdapterConnected: true, source: .adapter, isCharging: true, level: 0.85)
        var time = SuspendingClock().now
        var journal: Data?
        var events: [String] = []
        var writes: [Bool] = []
        var effects: [Int: Effect] = [:]
        var failReads = false
        var failEnvironment = false
        var failSave = false
        var saveThenFail = false
        var failClear = false
        var simulateSourceTransition = true
        var advanceOnSave: Duration = .zero
        var advanceOnIsolate: Duration = .zero
        var cancelOnIsolate = false
    }
    let storage = Mutex(Storage())
    private let onRestored: @Sendable () -> Void

    init(onRestored: @escaping @Sendable () -> Void = {}) { self.onRestored = onRestored }

    var backend: ChargeCommandExecutor.AdapterVerificationBackend {
        .init(operations: operations, journal: journal)
    }

    var journal: ChargeRecoveryJournal {
        .init(load: { self.storage.withLock { $0.journal } }, save: { data in
            try self.storage.withLock {
                $0.events.append("save")
                if $0.failSave { throw InjectedFailure.operation }
                $0.journal = data
                $0.time = $0.time.advanced(by: $0.advanceOnSave)
                if $0.saveThenFail { throw InjectedFailure.operation }
            }
        }, clear: {
            try self.storage.withLock {
                $0.events.append("clear")
                if $0.failClear { throw InjectedFailure.operation }
                $0.journal = nil
            }
            // Completion means verified hardware restoration AND successful checkpoint clearance.
            self.onRestored()
        })
    }

    var operations: AdapterTransaction.Operations {
        .init(readCHIE: {
            try self.storage.withLock {
                $0.events.append("readKey")
                if $0.failReads { throw InjectedFailure.operation }
                return .readable(metadata: $0.metadata, value: .init(type: $0.metadata.type, bytes: [$0.byte]))
            }
        }, readEnvironment: {
            try self.storage.withLock {
                $0.events.append("environment")
                if $0.failEnvironment { throw InjectedFailure.operation }
                return $0.environment
            }
        }, setAdapterIsolated: { isolated in
            let cancel = try self.storage.withLock { state in
                state.events.append(isolated ? "isolate" : "allow")
                state.writes.append(isolated)
                let effect = state.effects[state.writes.count]
                if case .failBefore = effect { throw InjectedFailure.operation }
                if case .ignore = effect { return false }
                state.byte = isolated ? 8 : 0
                if state.simulateSourceTransition {
                    state.environment.source = isolated ? .battery : .adapter
                    state.environment.isCharging = false
                }
                if isolated { state.time = state.time.advanced(by: state.advanceOnIsolate) }
                if case .loseReadAccess = effect { state.failReads = true }
                if case .failAfter = effect { throw InjectedFailure.operation }
                return isolated && state.cancelOnIsolate
            }
            if cancel { withUnsafeCurrentTask { $0?.cancel() } }
        })
    }

    func transaction(journal: ChargeRecoveryJournal? = nil) throws -> AdapterTransaction {
        try AdapterTransaction(operations: operations, journal: journal ?? self.journal,
                               now: { self.storage.withLock { $0.time } })
    }
}

struct AdapterVerificationTests {
    @Test func checkpointPrecedesSetterAndObservedIsolationRestoresWithoutChangingNativeLimit() throws {
        let fixture = AdapterVerificationFixture()
        let original = fixture.storage.withLock { $0.environment.nativeLimit }
        var transaction = try fixture.transaction()
        try transaction.begin()
        #expect(transaction.state == .awaitingObservation)
        let events = fixture.storage.withLock { $0.events }
        #expect(try #require(events.firstIndex(of: "save")) < #require(events.firstIndex(of: "isolate")))
        #expect(try transaction.observe() == .restoredAfterIsolation)
        #expect(transaction.state == .idle)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(fixture.storage.withLock { $0.environment.nativeLimit } == original)
        try transaction.restore()
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
    }

    @Test func acknowledgedByteIsNotPhysicalEvidenceAndNewBeginCannotRenewDeadline() throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.simulateSourceTransition = false }
        var transaction = try fixture.transaction()
        try transaction.begin()
        #expect(try transaction.observe() == .awaitingTransition)
        #expect(throws: AdapterTransaction.Failure.busy) { try transaction.begin() }
        fixture.storage.withLock { $0.time = $0.time.advanced(by: .seconds(3)) }
        #expect(throws: AdapterTransaction.Failure.expired) { try transaction.observe() }
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(transaction.state == .idle)
    }

    @Test(arguments: ["type", "size", "attributes", "unknownByte", "alreadyIsolated", "nativeOwner", "unplugged", "low", "nan", "stale", "unknownSource", "invalidNative"])
    func unsafeInitialStatesNeverCheckpointOrWrite(problem: String) throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock {
            switch problem {
            case "type": $0.metadata.type = "ui8 "
            case "size": $0.metadata.size = 2
            case "attributes": $0.metadata.attributes = 0
            case "unknownByte": $0.byte = 4
            case "alreadyIsolated": $0.byte = 8
            case "nativeOwner": $0.environment.nativeSessionActive = true
            case "unplugged": $0.environment.isAdapterConnected = false
            case "low": $0.environment.level = 0.29
            case "nan": $0.environment.level = .nan
            case "stale": $0.environment.age = .seconds(3)
            case "unknownSource": $0.environment.source = .unknown
            default: $0.environment.nativeLimit.configuredLimit = 50
            }
        }
        var transaction = try fixture.transaction()
        #expect(throws: (any Error).self) { try transaction.begin() }
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: [AdapterVerificationFixture.Effect.failBefore, .failAfter, .ignore])
    fileprivate func partialSetterFailureRestoresAndNeverReportsObservedIsolation(effect: AdapterVerificationFixture.Effect) throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.effects[1] = effect }
        var transaction = try fixture.transaction()
        #expect(throws: (any Error).self) { try transaction.begin() }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(transaction.state == .idle)
    }

    @Test(arguments: [false, true])
    func checkpointFailureBeforeOrAfterPersistenceCannotReachTheSetter(afterPersistence: Bool) throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.failSave = afterPersistence == false; $0.saveThenFail = afterPersistence }
        var transaction = try fixture.transaction()
        #expect(throws: AdapterTransaction.Failure.journalFailed) { try transaction.begin() }
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: ["native", "nativeOwner", "telemetry", "unplugged", "chargingOnBattery", "stale"])
    func changedEnvironmentStopsProbeAndPreservesExternalNativeSettings(change: String) throws {
        let fixture = AdapterVerificationFixture()
        var transaction = try fixture.transaction()
        try transaction.begin()
        fixture.storage.withLock {
            switch change {
            case "native": $0.environment.nativeLimit.configuredLimit = 95
            case "nativeOwner": $0.environment.nativeSessionActive = true
            case "telemetry": $0.failEnvironment = true
            case "unplugged": $0.environment.isAdapterConnected = false
            case "stale": $0.environment.age = .seconds(3)
            default: $0.environment.isCharging = true
            }
        }
        #expect(throws: (any Error).self) { try transaction.observe() }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(fixture.storage.withLock { $0.environment.nativeLimit.configuredLimit } == (change == "native" ? 95 : 85))
    }

    @Test(arguments: ["read", "write", "clear", "unknown"])
    func failedRecoveryRetainsCheckpointAndBlocksNewWorkUntilRetry(failure: String) throws {
        let fixture = AdapterVerificationFixture()
        var transaction = try fixture.transaction()
        try transaction.begin()
        fixture.storage.withLock {
            switch failure {
            case "read": $0.failReads = true
            case "write": $0.effects[2] = .failAfter
            case "clear": $0.failClear = true
            default: $0.byte = 4
            }
        }
        #expect(throws: AdapterTransaction.Failure.restorationFailed) { try transaction.restore() }
        #expect(transaction.state == .restorationRequired)
        #expect(fixture.storage.withLock { $0.journal != nil })
        #expect(throws: AdapterTransaction.Failure.restorationRequired) { try transaction.begin() }
        fixture.storage.withLock { $0.failReads = false; $0.failClear = false; if failure == "unknown" { $0.byte = 8 } }
        try transaction.restore()
        #expect(transaction.state == .idle)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(fixture.storage.withLock { $0.byte } == 0)
    }

    @Test func lostReadAccessAfterIsolationNeverPretendsRecoverySucceeded() throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.effects[1] = .loseReadAccess }
        var transaction = try fixture.transaction()
        #expect(throws: AdapterTransaction.Failure.restorationFailed) { try transaction.begin() }
        #expect(transaction.state == .restorationRequired)
        #expect(fixture.storage.withLock { $0.journal != nil })
        fixture.storage.withLock { $0.failReads = false }
        try transaction.restore()
        #expect(fixture.storage.withLock { $0.byte } == 0)
    }

    @Test(arguments: [false, true])
    func elapsedSaveOrSetterCannotExtendObservationBudget(duringSetter: Bool) throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock {
            if duringSetter { $0.advanceOnIsolate = .seconds(4) }
            else { $0.advanceOnSave = .seconds(4) }
        }
        var transaction = try fixture.transaction()
        #expect(throws: AdapterTransaction.Failure.expired) { try transaction.begin() }
        #expect(fixture.storage.withLock { $0.writes } == (duringSetter ? [true, false] : []))
        #expect(fixture.storage.withLock { $0.byte } == 0)
    }

    @Test func cancellationAfterSetterStillRestores() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.cancelOnIsolate = true }
        let state = try await Task {
            var transaction = try fixture.transaction()
            #expect(throws: AdapterTransaction.Failure.cancelled) { try transaction.begin() }
            return transaction.state
        }.value
        #expect(state == .idle)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: [false, true])
    func privateFileRecoveryCoversRestartWithoutTouchingNativeJournal(afterSetter: Bool) throws {
        let fixture = AdapterVerificationFixture()
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: directory) }
        let native = try ChargeRecoveryFileJournal(privateDirectory: directory)
        let sentinel = Data("native checkpoint remains independent".utf8)
        try native.journal.save(sentinel)
        let file = try ChargeRecoveryFileJournal(privateDirectory: directory, record: .adapterVerification)
        var first = try fixture.transaction(journal: file.journal)
        try first.begin()
        // Reconstruct from the durable intent with either possible pre/post-setter hardware state.
        fixture.storage.withLock { if afterSetter == false { $0.byte = 0 }; $0.failEnvironment = true }
        let reopened = try ChargeRecoveryFileJournal(privateDirectory: directory, record: .adapterVerification)
        var restarted = try fixture.transaction(journal: reopened.journal)
        #expect(restarted.state == .restorationRequired)
        let writes = fixture.storage.withLock { $0.writes }
        #expect(throws: AdapterTransaction.Failure.restorationRequired) { try restarted.begin() }
        #expect(fixture.storage.withLock { $0.writes } == writes)
        try restarted.restore()
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(try reopened.journal.load() == nil)
        #expect(try native.journal.load() == sentinel)
    }

    @Test(arguments: ["{}", "{\"version\":2,\"key\":\"CHIE\",\"originalValue\":0,\"attemptedValue\":8}",
                      "{\"version\":1,\"key\":\"CH0J\",\"originalValue\":0,\"attemptedValue\":8}",
                      "{\"version\":1,\"key\":\"CHIE\",\"originalValue\":8,\"attemptedValue\":0}"])
    func invalidCheckpointCannotReachHardware(json: String) {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.journal = Data(json.utf8) }
        #expect(throws: AdapterTransaction.Failure.invalidJournal) { try fixture.transaction() }
        #expect(fixture.storage.withLock { $0.events.isEmpty })
    }
}


struct AdapterVerificationLifecycleTests {
    @Test(arguments: ["sleep", "disconnect", "removal", "shutdown", "expiry"])
    func existingLifecycleRestoresAndPreventsOwnerReplay(event: String) async throws {
        let fixture = AdapterVerificationFixture()
        let executor = ChargeCommandExecutor(adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let token = try await executor.beginSession()
        try await executor.startAdapterVerification(for: token)
        #expect(await executor.state == .adapterVerification)
        let deadline = try #require(await executor.leaseDeadline)
        switch event {
        case "sleep": try await executor.willSleep()
        case "disconnect": try await executor.disconnect(owner: token)
        case "removal": _ = try await executor.status(for: token, removing: true)
        case "shutdown": try await executor.shutdown()
        default: try await executor.checkLease(at: deadline)
        }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(await executor.state == .macOS)
        await #expect(throws: (any Error).self) { try await executor.startAdapterVerification(for: token) }
    }

    @Test(.timeLimit(.minutes(1)))
    func watchdogRestoresWithoutAnyObservationRequest() async throws {
        let (events, continuation) = AsyncStream<Void>.makeStream()
        let fixture = AdapterVerificationFixture(onRestored: { continuation.yield(()); continuation.finish() })
        let executor = ChargeCommandExecutor(adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let token = try await executor.beginSession()
        try await executor.startAdapterVerification(for: token)
        for await _ in events { break }
        // Await the actor after the setter signal so checkpoint acknowledgement has finished too.
        #expect(await executor.state == .macOS)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) {
            try await executor.startAdapterVerification(for: token)
        }
    }

    @Test func nativeControlAndForeignOwnerCannotOverlapAdapterProbe() async throws {
        let fixture = AdapterVerificationFixture()
        let native = VerificationFixture()
        let executor = ChargeCommandExecutor(nativeBackendFactory: { native.backend }, adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        let foreign = try await executor.beginSession()
        try await executor.setNativeLimit(80, for: owner)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) {
            try await executor.startAdapterVerification(for: owner)
        }
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
        _ = try await executor.releaseNativeLimit(for: owner)
        try await executor.startAdapterVerification(for: owner)
        let adapterWrites = fixture.storage.withLock { $0.writes }
        await #expect(throws: ChargeCommandExecutor.Failure.differentOwner) {
            try await executor.observeAdapterVerification(for: foreign)
        }
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) {
            try await executor.setNativeLimit(90, for: owner)
        }
        try await executor.disconnect(owner: foreign)
        #expect(fixture.storage.withLock { $0.writes } == adapterWrites)
        #expect(try await executor.observeAdapterVerification(for: owner) == .restoredAfterIsolation)
        #expect(await executor.state == .macOS)
        #expect(await executor.leaseDeadline == nil)
    }

    @Test func startupRecoversAdapterBeforeFailingNativeBackendAndRefusesAdmission() async throws {
        let fixture = AdapterVerificationFixture()
        var interrupted = try fixture.transaction()
        try interrupted.begin()
        let executor = ChargeCommandExecutor(nativeBackendFactory: { throw AdapterVerificationFixture.InjectedFailure.operation },
                                             adapterVerificationBackend: fixture.backend)
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.start() }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.beginSession() }
    }

    @Test func recoveryFailureBlocksCommandsAndAllowsExplicitRemovalRetry() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = ChargeCommandExecutor(adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let token = try await executor.beginSession()
        try await executor.startAdapterVerification(for: token)
        fixture.storage.withLock { $0.failReads = true }
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) {
            try await executor.status(for: token, removing: true)
        }
        #expect(await executor.state == .restorationRequired)
        #expect(fixture.storage.withLock { $0.journal != nil })
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) {
            try await executor.startAdapterVerification(for: token)
        }
        fixture.storage.withLock { $0.failReads = false }
        #expect(try await executor.status(for: token, removing: true).controlState == .notControlling)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }
}
