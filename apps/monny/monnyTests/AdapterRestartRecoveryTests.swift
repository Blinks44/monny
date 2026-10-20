import Foundation
import Synchronization
import Testing
@testable import monny

@MainActor
struct AdapterRestartRecoveryTests {
    private nonisolated static func backend(_ fixture: AdapterVerificationFixture) -> ChargeCommandExecutor.AdapterVerificationBackend {
        AdapterBytePulseIPCTests.backend(fixture)
    }

    private nonisolated static func status(instance: UUID, recovered: Bool) -> HelperStatus {
        var status = HelperStatus.current
        status.helperInstance = instance
        status.adapterStartupRecovery = recovered ? .init(checkpointFound: true, initialByte: 8, restoredByte: 0)
            : .init(checkpointFound: false)
        status.adapterRestartVerificationAvailable = true
        status.adapterRestartVerificationVersion = HelperContract.adapterRestartVerificationVersion
        status.nativeChargeLimit = .available(.init(availableLimits: [80, 85, 90, 95, 100], configuredLimit: 85, enabled: true))
        return status
    }

    @Test(arguments: [false, true])
    func persistedAdapterRecoveryReceiptPrecedesNativeFactoryAndAnonymousIPC(alreadyZero: Bool) async throws {
        let fixture = AdapterVerificationFixture()
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: directory) }
        let journal = try ChargeRecoveryFileJournal(privateDirectory: directory, record: .adapterVerification)
        let backend = Self.backend(fixture)
        do {
            var pending = try AdapterVerificationTransaction(operations: backend.operations, journal: journal.journal)
            var report = AdapterBytePulseReport(outcome: .unavailable)
            try pending.beginByteObservation(observe: try #require(backend.pulseRead), report: &report)
            #expect(report.appliedByte == 8)
        } // Discard the former value owner without cleanup; simulate losing in-process state only.
        if alreadyZero { fixture.storage.withLock { $0.byte = 0 } }
        let native = VerificationFixture()
        let instance = UUID()
        let reopened = try ChargeRecoveryFileJournal(privateDirectory: directory, record: .adapterVerification)
        var recoveredBackend = backend
        recoveredBackend.journal = reopened.journal
        let restoreBackend = recoveredBackend
        let executor = ChargeCommandExecutor(nativeBackendFactory: {
            #expect(fixture.storage.withLock { $0.byte } == 0)
            let pendingRecord = try reopened.journal.load()
            #expect(pendingRecord == nil)
            return native.backend
        }, adapterBackendFactory: { restoreBackend }, helperInstance: instance, restartAfterIsolation: {})
        try await executor.start()
        let token = try await executor.beginSession()
        let result = try await executor.status(for: token)
        #expect(result.helperInstance == instance)
        #expect(result.adapterStartupRecovery == .init(checkpointFound: true, initialByte: alreadyZero ? 0 : 8, restoredByte: 0))
        #expect(result.adapterRestartVerificationAvailable == true)
        #expect(fixture.storage.withLock { $0.writes.filter { $0 }.count } == 1)
        let service = try LocalHelperService(executor: executor, clientRequirement: "identifier \"blinks44.monny\"")
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let reply = try await HelperConnection(endpoint: listener.endpoint).request(requirement: "identifier \"blinks44.monny\"")
        #expect(reply.adapterStartupRecovery == result.adapterStartupRecovery)
        #expect(reply.helperInstance == instance)
        #expect(try HelperStatus.decode(JSONEncoder().encode(reply)) == reply)
        #expect(native.storage.withLock { $0.writes } == 0)
    }

    @Test(arguments: ["beforeWrite", "afterWrite", "ignored", "save", "returned", "threw"])
    func failureBeforeTerminationAlwaysRestoresAndCallbackCannotBypassGuards(condition: String) async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock {
            if condition == "beforeWrite" { $0.effects[1] = .failBefore }
            if condition == "afterWrite" { $0.effects[1] = .failAfter }
            if condition == "ignored" { $0.effects[1] = .ignore }
            if condition == "save" { $0.failSave = true }
        }
        let calls = Mutex(0)
        let native = VerificationFixture()
        let executor = ChargeCommandExecutor(nativeBackendFactory: { native.backend },
            adapterVerificationBackend: Self.backend(fixture), helperInstance: UUID(), restartAfterIsolation: {
                calls.withLock { $0 += 1 }
                #expect(fixture.storage.withLock { $0.byte } == 8)
                #expect(fixture.storage.withLock { $0.journal != nil })
                if condition == "threw" { throw ChargeCommandExecutor.Failure.commandFailed }
            })
        try await executor.start()
        let token = try await executor.beginSession()
        await #expect(throws: (any Error).self) { try await executor.verifyAdapterRestart(for: token) }
        #expect(calls.withLock { $0 } == (["returned", "threw"].contains(condition) ? 1 : 0))
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(await executor.state == .macOS)
        #expect(native.storage.withLock { $0.writes } == 0)
    }

    @Test func absentCapabilityForeignOwnerAndRemovalRefuseWithoutTermination() async throws {
        let fixture = AdapterVerificationFixture()
        let absent = ChargeCommandExecutor(adapterVerificationBackend: Self.backend(fixture))
        try await absent.start()
        let unsupported = try await absent.beginSession()
        await #expect(throws: ChargeCommandExecutor.Failure.unsupported) { try await absent.verifyAdapterRestart(for: unsupported) }
        let native = VerificationFixture()
        let executor = ChargeCommandExecutor(nativeBackendFactory: { native.backend }, adapterVerificationBackend: Self.backend(fixture),
            helperInstance: UUID(), restartAfterIsolation: { Issue.record("Unsafe request reached termination") })
        try await executor.start()
        let owner = try await executor.beginSession()
        let other = try await executor.beginSession()
        _ = try await executor.setNativeLimit(80, for: owner)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.verifyAdapterRestart(for: other) }
        _ = try await executor.releaseNativeLimit(for: owner)
        _ = try await executor.status(for: owner, removing: true)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.verifyAdapterRestart(for: owner) }
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) { try await executor.verifyAdapterRestart(for: UUID()) }
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
    }

    @Test func collectorRequiresNewInstanceRecoveredEightNativeMatchAndAdapterSource() async throws {
        let old = Self.status(instance: UUID(), recovered: false)
        let new = Self.status(instance: UUID(), recovered: true)
        let reads = Mutex(0)
        let writes = Mutex(0)
        let sources = Mutex(0)
        let result = try await AdapterRestartVerificationCommand.collect(requirement: "fixture", status: { _ in
            reads.withLock { $0 += 1; return $0 < 3 ? old : new }
        }, terminate: { _ in
            writes.withLock { $0 += 1 }
            throw HelperConnectionError.connectionFailed
        }, adapterSource: { sources.withLock { $0 += 1; return $0 >= 2 } }, pause: {})
        #expect(result.helperRestarted && result.nativeSettingsPreserved && result.adapterSourceObserved)
        #expect(result.startupRecovery.initialByte == 8)
        #expect(writes.withLock { $0 } == 1)
        #expect(reads.withLock { $0 } == 4)
    }

    @Test(arguments: ["sameInstance", "noCheckpoint", "initialZero", "nativeChanged", "noAdapter", "reply"])
    func collectorCannotInventRecoveryOrReplayMutation(condition: String) async {
        let old = Self.status(instance: UUID(), recovered: false)
        var next = Self.status(instance: UUID(), recovered: true)
        if condition == "sameInstance" { next.helperInstance = old.helperInstance }
        if condition == "noCheckpoint" { next.adapterStartupRecovery = .init(checkpointFound: false) }
        if condition == "initialZero" { next.adapterStartupRecovery?.initialByte = 0 }
        if condition == "nativeChanged" { next.nativeChargeLimit = .available(.init(availableLimits: [80,85,90,95,100], configuredLimit: 90, enabled: true)) }
        let after = next
        let reads = Mutex(0)
        let calls = Mutex(0)
        await #expect(throws: (any Error).self) {
            try await AdapterRestartVerificationCommand.collect(requirement: "fixture", status: { _ in
                reads.withLock { $0 += 1; return $0 == 1 ? old : after }
            }, terminate: { _ in
                calls.withLock { $0 += 1 }
                if condition == "reply" { return old }
                throw HelperConnectionError.connectionFailed
            }, adapterSource: { condition != "noAdapter" }, pause: {})
        }
        #expect(calls.withLock { $0 } == 1)
    }

    @Test(arguments: [Optional<Bool>.none, false, true])
    func unsupportedOrWrongVersionHandshakeCannotMutate(available: Bool?) async {
        var status = Self.status(instance: UUID(), recovered: false)
        status.adapterRestartVerificationAvailable = available
        // A wrong advertised revision itself fails validation before mutation.
        status.adapterRestartVerificationVersion = 999
        let handshake = status
        await #expect(throws: (any Error).self) {
            try await AdapterRestartVerificationCommand.collect(requirement: "fixture", status: { _ in handshake }, terminate: { _ in
                Issue.record("Invalid handshake sent restart selector")
                return .current
            }, adapterSource: { true }, pause: {})
        }
    }

    @Test func refusedRestartRecoveryFailureRetainsCheckpointAndRecoveryTimer() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.effects[2] = .failBefore }
        let native = VerificationFixture()
        let executor = ChargeCommandExecutor(nativeBackendFactory: { native.backend }, adapterVerificationBackend: Self.backend(fixture),
            helperInstance: UUID(), restartAfterIsolation: { throw ChargeCommandExecutor.Failure.commandFailed })
        try await executor.start()
        let token = try await executor.beginSession()
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.verifyAdapterRestart(for: token) }
        #expect(fixture.storage.withLock { $0.journal } != nil)
        let deadline = try #require(await executor.leaseDeadline)
        try await executor.checkLease(at: deadline)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(fixture.storage.withLock { $0.writes.filter { $0 }.count } == 1)
    }

    @Test func anonymousRestartSelectorWithoutCapabilityIsRefusedWithoutAnyEffects() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = ChargeCommandExecutor(adapterVerificationBackend: Self.backend(fixture))
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: "identifier \"blinks44.monny\"")
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let client = HelperConnection(endpoint: listener.endpoint)
        await #expect(throws: HelperConnectionError.invalidReply) {
            try await client.verifyAdapterRestart(requirement: "identifier \"blinks44.monny\"")
        }
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
    }

    @Test func cancelledCollectorAndInvalidReplyCannotRepeatMutation() async {
        let before = Self.status(instance: UUID(), recovered: false)
        let calls = Mutex(0)
        await #expect(throws: HelperConnectionError.invalidReply) {
            try await AdapterRestartVerificationCommand.collect(requirement: "fixture", status: { _ in before }, terminate: { _ in
                calls.withLock { $0 += 1 }
                throw HelperConnectionError.invalidReply
            }, adapterSource: { true }, pause: {})
        }
        #expect(calls.withLock { $0 } == 1)
        let request = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await AdapterRestartVerificationCommand.collect(requirement: "fixture", status: { _ in before }, terminate: { _ in
                Issue.record("Cancelled collector sent the mutation")
                return .current
            }, adapterSource: { true }, pause: {})
        }
        do { _ = try await request.value; Issue.record("Cancelled request succeeded") }
        catch { #expect(error is CancellationError) }
    }

    @Test func startupFailureNeverServesAndMalformedReceiptIsRejected() async throws {
        let fixture = AdapterVerificationFixture()
        var transaction = try fixture.transaction()
        var report = AdapterBytePulseReport(outcome: .unavailable)
        let backend = Self.backend(fixture)
        try transaction.beginByteObservation(observe: try #require(backend.pulseRead), report: &report)
        fixture.storage.withLock { $0.failReads = true }
        let native = VerificationFixture()
        let executor = ChargeCommandExecutor(nativeBackendFactory: {
            Issue.record("Native getter must not run before adapter recovery")
            return native.backend
        }, adapterVerificationBackend: backend, helperInstance: UUID(), restartAfterIsolation: {})
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.start() }
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.beginSession() }
        #expect(fixture.storage.withLock { $0.journal } != nil)
        var status = Self.status(instance: UUID(), recovered: true)
        status.adapterStartupRecovery?.restoredByte = 8
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        try AdapterRestartVerificationCommand.validate(arguments: ["Monny", AdapterRestartVerificationCommand.flag])
        #expect(throws: AdapterRestartVerificationCommand.Failure.invalidArguments) {
            try AdapterRestartVerificationCommand.validate(arguments: ["Monny", AdapterRestartVerificationCommand.flag, "CHIE"])
        }
    }
}
