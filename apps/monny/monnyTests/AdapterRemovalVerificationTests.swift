import Foundation
import Synchronization
import Testing
@testable import monny

@MainActor
struct AdapterRemovalVerificationTests {
    private let requirement = "identifier \"blinks44.monny\""

    @Test(arguments: ["pass", "timerFirst", "wrongInstance", "changedNative", "failedReceipt", "transport", "cancel", "unregisterFailure", "registrationStuck", "noSource", "unknownByte", "expiredPreparation"])
    func removalRequiresActiveRestorationBeforeOneUnregister(condition: String) async throws {
        let (restored, continuation) = AsyncStream<Void>.makeStream()
        let fixture = AdapterVerificationFixture(onRestored: { continuation.yield(()); continuation.finish() })
        let native = VerificationFixture()
        let executor = ChargeCommandExecutor(nativeBackendFactory: { native.backend },
            adapterVerificationBackend: AdapterBytePulseIPCTests.backend(fixture), helperInstance: UUID())
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let removed = Mutex(false)
        let unregisterCalls = Mutex(0)
        let acknowledgementCalls = Mutex(0)
        let instant = Mutex(SuspendingClock().now)
        let clockReads = Mutex(0)
        do {
            let report = try await AdapterRemovalVerificationCommand.collect(requirement: requirement,
                session: AdapterLifecycleSession(purpose: .removal, endpoint: endpoint), acknowledge: {
                    acknowledgementCalls.withLock { $0 += 1 }
                    #expect(!removed.withLock { $0 })
                    if condition == "transport" { throw HelperConnectionError.connectionFailed }
                    if condition == "cancel" { throw CancellationError() }
                    if condition == "timerFirst" {
                        let deadline = try #require(await executor.leaseDeadline)
                        try await executor.checkLease(at: deadline)
                    } else { #expect(fixture.storage.withLock { $0.byte } == 8) }
                    var status = try await HelperConnection(endpoint: endpoint).request(requirement: "identifier \"blinks44.monny\"", forRemoval: true)
                    #expect(fixture.storage.withLock { $0.byte } == 0)
                    if condition == "wrongInstance" { status.helperInstance = UUID() }
                    if condition == "changedNative" {
                        status.nativeChargeLimit = .available(.init(availableLimits: [80,85,90,95,100], configuredLimit: 90, enabled: true))
                    }
                    if condition == "failedReceipt" { status.lifecycleDiagnostics?.lastRemovalPreparation = .failed }
                    return status
                }, unregister: {
                    unregisterCalls.withLock { $0 += 1 }
                    #expect(fixture.storage.withLock { $0.byte } == 0)
                    #expect(fixture.storage.withLock { $0.journal } == nil)
                    #expect(await executor.phase == .removing)
                    if condition == "unregisterFailure" { throw HelperConnectionError.connectionFailed }
                    removed.withLock { $0 = true }
                }, registration: {
                    if condition == "registrationStuck" { return .enabled }
                    return removed.withLock { $0 } ? .notRegistered : .enabled
                }, readByte: {
                    if condition == "unknownByte" { return nil }
                    return fixture.storage.withLock { $0.byte }
                }, adapterSource: { condition != "noSource" }, now: {
                    let count = clockReads.withLock { $0 += 1; return $0 }
                    if condition == "expiredPreparation", count == 2 {
                        instant.withLock { $0 = $0.advanced(by: .seconds(2)) }
                    }
                    return instant.withLock { $0 }
                }, pause: {})
            #expect(condition == "pass")
            #expect(report.adapterRestoredBeforeRemoval && report.helperUnregistered && report.restoredByte == 0)
            #expect(report.nativeSettingsPreservedBeforeRemoval && report.controlSupport == .unverified)
        } catch {
            #expect(condition != "pass")
        }
        let didPrepare = fixture.storage.withLock { $0.writes.contains(true) }
        if didPrepare { for await _ in restored { break } }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(fixture.storage.withLock { $0.writes.filter { $0 }.count } <= 1)
        #expect(native.storage.withLock { $0.writes } == 0)
        let reachedUnregister = ["pass", "unregisterFailure", "registrationStuck", "noSource"].contains(condition)
        #expect(unregisterCalls.withLock { $0 } == (reachedUnregister ? 1 : 0))
        #expect(acknowledgementCalls.withLock { $0 } == (["unknownByte", "expiredPreparation"].contains(condition) ? 0 : 1))
    }

    @Test func legacyHelperIsRefusedBeforePreparationOrUnregister() async throws {
        let service = try LocalHelperService()
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        await #expect(throws: HelperConnectionError.versionMismatch) {
            try await AdapterRemovalVerificationCommand.collect(requirement: requirement,
                session: AdapterLifecycleSession(purpose: .removal, endpoint: listener.endpoint),
                acknowledge: { Issue.record("Old helper removal requested"); return .current },
                unregister: { Issue.record("Old helper unregistered") }, registration: { .enabled },
                readByte: { Issue.record("No byte read before feature handshake"); return 0 }, adapterSource: { true }, pause: {})
        }
    }

    @Test func removalFeatureRequiresKnownVersionAndLifecycleEvidence() throws {
        var status = HelperStatus.current
        status.adapterRemovalVerificationAvailable = true
        status.adapterRemovalVerificationVersion = 1
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.helperInstance = UUID()
        status.lifecycleDiagnostics = .init()
        _ = try status.validated()
        status.adapterRemovalVerificationVersion = 2
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        try AdapterRemovalVerificationCommand.validate(arguments: ["Monny", AdapterRemovalVerificationCommand.flag])
        #expect(throws: AdapterRemovalVerificationCommand.Failure.invalidArguments) {
            try AdapterRemovalVerificationCommand.validate(arguments: ["Monny", AdapterRemovalVerificationCommand.flag, "extra"])
        }
    }
}
