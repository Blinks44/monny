import Foundation
import Testing
@testable import monny

@MainActor
struct HelperLifecycleDiagnosticTests {
    private nonisolated static func executor(_ fixture: AdapterVerificationFixture,
                                            native: VerificationFixture = VerificationFixture()) -> ChargeCommandExecutor {
        .init(nativeBackendFactory: { native.backend }, adapterVerificationBackend: fixture.backend, helperInstance: UUID())
    }

    @Test func idleSleepWakeReceiptsArePerInstanceReadOnlyAndSurviveAnonymousIPC() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = Self.executor(fixture)
        try await executor.start()
        let old = try await executor.beginSession()
        let before = try await executor.status(for: old)
        #expect(before.lifecycleDiagnostics == .init())
        try await executor.didWake() // Unpaired notifications do not invent a completed cycle.
        try await executor.willSleep()
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) { try await executor.status(for: old) }
        try await executor.didWake()
        let token = try await executor.beginSession()
        let result = try await executor.status(for: token)
        #expect(result.helperInstance == before.helperInstance)
        #expect(result.lifecycleDiagnostics?.sleepCount == 1)
        #expect(result.lifecycleDiagnostics?.wakeCount == 1)
        #expect(result.lifecycleDiagnostics?.lastSleep == .noAdapterRecoveryNeeded)
        #expect(result.lifecycleDiagnostics?.lastWake == .noAdapterRecoveryNeeded)
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
        let service = try LocalHelperService(executor: executor, clientRequirement: "identifier \"blinks44.monny\"")
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let response = try await HelperConnection(endpoint: listener.endpoint).request(requirement: "identifier \"blinks44.monny\"")
        #expect(response.lifecycleDiagnostics == result.lifecycleDiagnostics)
        #expect(try HelperStatus.decode(JSONEncoder().encode(response)) == response)
    }

    @Test(arguments: ["sleep", "removal"])
    func adapterRecoveryReceiptDoesNotDependOnEnvironmentTelemetry(event: String) async throws {
        let fixture = AdapterVerificationFixture()
        let executor = Self.executor(fixture)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.startAdapterVerification(for: owner)
        fixture.storage.withLock { $0.failEnvironment = true }
        if event == "sleep" {
            try await executor.willSleep()
            try await executor.didWake()
        } else { _ = try await executor.status(for: owner, removing: true) }
        let reader = try await executor.beginSession()
        let diagnostics = try #require(try await executor.status(for: reader).lifecycleDiagnostics)
        #expect(event == "sleep" ? diagnostics.lastSleep == .adapterRestored : diagnostics.lastRemovalPreparation == .adapterRestored)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(await executor.state == .macOS)
    }

    @Test func failedSleepRollbackIsRetriedOnWakeAndFailureReceiptRemainsDistinct() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.effects[2] = .failBefore }
        let executor = Self.executor(fixture)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.startAdapterVerification(for: owner)
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.willSleep() }
        #expect(await executor.phase == .sleeping)
        #expect(fixture.storage.withLock { $0.journal } != nil)
        try await executor.didWake()
        let token = try await executor.beginSession()
        let result = try await executor.status(for: token)
        #expect(result.lifecycleDiagnostics?.lastSleep == .failed)
        #expect(result.lifecycleDiagnostics?.lastWake == .adapterRestored)
        #expect(result.lifecycleDiagnostics?.sleepCount == 1)
        #expect(result.lifecycleDiagnostics?.wakeCount == 1)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.writes.filter { $0 }.count } == 1)
    }

    @Test func priorLeaseFailureStillRetriesOnWake() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = Self.executor(fixture)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.startAdapterVerification(for: owner)
        fixture.storage.withLock { $0.failReads = true }
        let deadline = try #require(await executor.leaseDeadline)
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.checkLease(at: deadline) }
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.willSleep() }
        #expect(await executor.phase == .sleeping)
        fixture.storage.withLock { $0.failReads = false }
        try await executor.didWake()
        let token = try await executor.beginSession()
        let result = try await executor.status(for: token)
        #expect(result.lifecycleDiagnostics?.lastSleep == .failed)
        #expect(result.lifecycleDiagnostics?.lastWake == .adapterRestored)
        #expect(fixture.storage.withLock { $0.byte } == 0)
    }

    @Test func failedRemovalCannotAcknowledgeAndWakeRecoveryKeepsRemovingGate() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = Self.executor(fixture)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.startAdapterVerification(for: owner)
        fixture.storage.withLock { $0.failReads = true }
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.status(for: owner, removing: true) }
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.willSleep() }
        #expect(await executor.phase == .removing)
        fixture.storage.withLock { $0.failReads = false }
        try await executor.didWake()
        #expect(await executor.phase == .removing)
        let result = try await executor.status(for: owner)
        #expect(result.lifecycleDiagnostics?.lastRemovalPreparation == .failed)
        #expect(result.lifecycleDiagnostics?.lastSleep == .failed)
        #expect(result.lifecycleDiagnostics?.lastWake == .adapterRestored)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.startAdapterVerification(for: owner) }
        let retry = try await executor.status(for: owner, removing: true)
        #expect(retry.lifecycleDiagnostics?.removalPreparationCount == 2)
        #expect(retry.lifecycleDiagnostics?.lastRemovalPreparation == .noAdapterRecoveryNeeded)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func nativeSleepPreservationIsNotReportedAsAdapterRecovery() async throws {
        let fixture = AdapterVerificationFixture()
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let owner = try await executor.beginSession()
        _ = try await executor.setNativeLimit(80, for: owner)
        let writes = native.storage.withLock { $0.writes }
        try await executor.willSleep()
        try await executor.didWake()
        let result = try await executor.status(for: owner)
        #expect(result.lifecycleDiagnostics?.lastSleep == .nativeLimitPreserved)
        #expect(result.lifecycleDiagnostics?.lastWake == .nativeLimitPreserved)
        #expect(native.storage.withLock { $0.writes } == writes)
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
        _ = try await executor.releaseNativeLimit(for: owner)
    }

    @Test func malformedReceiptAndUnpairedOutcomesCannotValidate() throws {
        var status = HelperStatus.current
        status.lifecycleDiagnostics = .init()
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.helperInstance = UUID()
        #expect(try status.validated() == status)
        status.lifecycleDiagnostics?.lastSleep = .adapterRestored
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.lifecycleDiagnostics?.sleepCount = 1
        #expect(try status.validated() == status)
        status.lifecycleDiagnostics?.wakeCount = -1
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        var bounded = HelperLifecycleDiagnostics()
        bounded.sleepCount = HelperLifecycleDiagnostics.maximumCount
        bounded.record(.sleep, outcome: .noAdapterRecoveryNeeded)
        #expect(bounded.sleepCount == HelperLifecycleDiagnostics.maximumCount)
        #expect(bounded.isValid)
    }
}
