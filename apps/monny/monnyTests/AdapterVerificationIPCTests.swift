import Foundation
import Synchronization
import Testing
@testable import monny

actor AdapterObservationPause {
    var isPaused = false
    private var entered: CheckedContinuation<Void, Never>?
    private var pending: CheckedContinuation<Void, Never>?
    func wait() async {
        isPaused = true
        entered?.resume(); entered = nil
        await withCheckedContinuation { pending = $0 }
    }
    func waitUntilPaused() async { if !isPaused { await withCheckedContinuation { entered = $0 } } }
    func finish() { pending?.resume(); pending = nil }
}

@MainActor
struct AdapterVerificationIPCTests {
    private let requirement = "identifier \"blinks44.monny\""

    @Test func defaultHelperCannotAdvertiseOrExecuteAdapterVerification() async throws {
        let executor = ChargeCommandExecutor()
        try await executor.start()
        let token = try await executor.beginSession()
        #expect(try await executor.status(for: token).adapterVerificationAvailable == false)
        await #expect(throws: ChargeCommandExecutor.Failure.unsupported) {
            try await executor.verifyAdapterIsolation(for: token)
        }
        #expect(await executor.state == .macOS)
    }

    @Test(arguments: [Optional<Bool>.none, false, true])
    func absentDisabledOrWrongRevisionNeverSendsSelector(advertised: Bool?) async {
        var status = HelperStatus.current
        status.adapterVerificationAvailable = advertised
        status.adapterVerificationVersion = 999
        let handshake = status
        let expected: AdapterVerificationCommand.Failure = advertised == false ? .verificationNotEnabled : .helperUpdateRequired
        await #expect(throws: expected) {
            try await AdapterVerificationCommand.collect(requirement: "fixture", status: { _ in handshake }, verify: { _ in
                Issue.record("The new selector must not be sent without a positive revisioned handshake")
                return .current
            })
        }
    }

    @Test func successfulAnonymousIPCReportsSourceAndByteRestorationSeparately() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = ChargeCommandExecutor(adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let result = try await AdapterVerificationCommand.collect(requirement: requirement,
            status: { try await HelperConnection(endpoint: endpoint).request(requirement: $0) },
            verify: { try await HelperConnection(endpoint: endpoint).verifyAdapterIsolation(requirement: $0) })
        let report = try #require(result.adapterVerification)
        #expect(report.outcome == .restoredAfterObservation)
        #expect(report.before?.source == .adapter)
        #expect(report.during?.source == .battery)
        #expect(report.after?.source == .adapter)
        #expect(report.adapterSourceObservedAfterRestoration)
        #expect(report.restoredByte == 0)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
        let encoded = try JSONEncoder().encode(result)
        #expect(encoded.count < 4096)
        #expect(try HelperStatus.decode(encoded) == result)
    }

    @Test func byteRestorationDoesNotInventReturnToAdapterSource() async throws {
        let fixture = AdapterVerificationFixture()
        var backend = fixture.backend
        let original = backend.operations.readEnvironment
        let calls = Mutex(0)
        backend.operations.readEnvironment = {
            var reading = try original()
            if calls.withLock({ $0 += 1; return $0 }) >= 3 { reading.source = .battery }
            return reading
        }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: backend)
        try await executor.start()
        let token = try await executor.beginSession()
        let response = try await executor.verifyAdapterIsolation(for: token)
        let report = try #require(response.adapterVerification)
        #expect(report.outcome == .restoredAfterObservation)
        #expect(report.restoredByte == 0)
        #expect(report.after?.source == .battery)
        #expect(report.adapterSourceObservedAfterRestoration == false)
    }

    @Test(arguments: ["disconnect", "sleep", "removal", "shutdown", "expiry", "cancellation"])
    func suspendedRequestRestoresThroughEveryExitAndRejectsCompetitors(event: String) async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.simulateSourceTransition = false }
        let (events, continuation) = AsyncStream<Void>.makeStream()
        var backend = fixture.backend
        let original = backend.operations.readEnvironment
        backend.operations.readEnvironment = {
            let environment = try original()
            if fixture.storage.withLock({ $0.byte }) == 8 { continuation.yield(()); continuation.finish() }
            return environment
        }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        let foreign = try await executor.beginSession()
        let request = Task { try await executor.verifyAdapterIsolation(for: owner) }
        for await _ in events { break }
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.verifyAdapterIsolation(for: foreign) }
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.verifyAdapterIsolation(for: owner) }
        switch event {
        case "disconnect": try await executor.disconnect(owner: owner)
        case "sleep": try await executor.willSleep()
        case "removal": _ = try await executor.status(for: foreign, removing: true)
        case "shutdown": try await executor.shutdown()
        case "cancellation": request.cancel()
        default:
            let deadline = try #require(await executor.leaseDeadline)
            try await executor.checkLease(at: deadline)
        }
        let result = try await request.value
        #expect(result.adapterVerification?.outcome == .failedRestored)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(await executor.state == .macOS)
    }

    @Test(.timeLimit(.minutes(1)))
    func nonTransitioningRequestExpiresWithoutRenewal() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.simulateSourceTransition = false }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        let result = try await executor.verifyAdapterIsolation(for: owner)
        #expect(result.adapterVerification?.outcome == .failedRestored)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) {
            try await executor.verifyAdapterIsolation(for: owner)
        }
    }

    @Test func completedLifecycleRollbackCannotAdmitAWriterBeforeRequestRevalidation() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.simulateSourceTransition = false }
        let native = VerificationFixture()
        let pause = AdapterObservationPause()
        let executor = ChargeCommandExecutor(nativeBackendFactory: { native.backend }, adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let token = try await executor.beginSession()
        let request = Task { try await executor.verifyAdapterIsolation(for: token, pause: { await pause.wait() }) }
        await pause.waitUntilPaused()
        try await executor.willSleep()
        try await executor.didWake()
        #expect(await executor.state == .macOS)
        let fresh = try await executor.beginSession()
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.setNativeLimit(80, for: fresh) }
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.verifyAdapterIsolation(for: fresh) }
        await pause.finish()
        #expect(try await request.value.adapterVerification?.outcome == .failedRestored)
        _ = try await executor.setNativeLimit(80, for: fresh)
        _ = try await executor.releaseNativeLimit(for: fresh)
    }

    @Test func changedNativeSettingAfterRollbackPreventsSuccessExit() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = ChargeCommandExecutor(adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let token = try await executor.beginSession()
        var report = try #require(try await executor.verifyAdapterIsolation(for: token).adapterVerification)
        #expect(report.isSuccessful)
        report.after?.nativeLimit.configuredLimit = 90
        #expect(report.isValid)
        #expect(report.adapterSourceObservedAfterRestoration)
        #expect(report.isSuccessful == false)
        report.after?.isAdapterConnected = false
        #expect(report.adapterSourceObservedAfterRestoration == false)
    }

    @Test func failedRestorationRetainsCheckpointAndBlocksRemoval() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.effects[1] = .loseReadAccess }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        let response = try await executor.verifyAdapterIsolation(for: owner)
        #expect(response.adapterVerification?.outcome == .restorationRequired)
        #expect(response.controlState == .restorationRequired)
        #expect(fixture.storage.withLock { $0.journal != nil })
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) {
            try await executor.status(for: owner, removing: true)
        }
        fixture.storage.withLock { $0.failReads = false }
        #expect(try await executor.status(for: owner, removing: true).controlState == .notControlling)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func malformedReportsCannotClaimSuccessOrRemoval() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = ChargeCommandExecutor(adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        let good = try await executor.verifyAdapterIsolation(for: owner)
        var invalid = Array(repeating: good, count: 9)
        invalid[0].adapterVerification?.restoredByte = nil
        invalid[1].adapterVerification?.during?.source = .adapter
        invalid[2].adapterVerification?.during?.isCharging = true
        invalid[3].adapterVerificationAvailable = false
        invalid[4].adapterVerificationVersion = 999
        invalid[5].controlState = .restorationRequired
        invalid[6].adapterVerification?.outcome = .failedRestored
        invalid[6].adapterVerification?.before = nil
        invalid[7].adapterVerification?.restoredByte = 8
        invalid[8].nativeVerificationAvailable = true
        invalid[8].nativeVerification = .init(target: 85, before: good.adapterVerification?.before?.nativeLimit,
                                               after: good.adapterVerification?.before?.nativeLimit, outcome: .failedRestored)
        for response in invalid {
            #expect(throws: HelperConnectionError.invalidReply) { try response.validated() }
        }
    }

    @Test func wrongPeerAndTimeoutCannotLeaveAdapterIsolated() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.simulateSourceTransition = false }
        let (disconnected, onDisconnect) = AsyncStream<Void>.makeStream()
        let executor = ChargeCommandExecutor(adapterVerificationBackend: fixture.backend)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement,
            onDisconnect: { onDisconnect.yield(()); onDisconnect.finish() })
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let client = HelperConnection(endpoint: listener.endpoint, timeout: .milliseconds(300))
        await #expect(throws: HelperConnectionError.timedOut) {
            try await client.verifyAdapterIsolation(requirement: requirement)
        }
        for await _ in disconnected { break }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        let writes = fixture.storage.withLock { $0.writes }
        // Reject the caller on the service side. A client's requirement for the server is not
        // an authorization check on that client's outgoing request, which can race reply validation.
        let rejecting = NSXPCListener.anonymous()
        rejecting.delegate = service
        rejecting.setConnectionCodeSigningRequirement("identifier \"blinks44.monny.untrusted\"")
        rejecting.activate()
        defer { withExtendedLifetime(service) { rejecting.invalidate() } }
        let wrong = HelperConnection(endpoint: rejecting.endpoint, timeout: .milliseconds(300))
        await #expect(throws: (any Error).self) {
            try await wrong.verifyAdapterIsolation(requirement: requirement)
        }
        #expect(fixture.storage.withLock { $0.writes } == writes)
    }

    @Test func exactArgumentsAndOneAttemptOnly() async throws {
        for arguments in [["Monny"], ["Monny", AdapterVerificationCommand.flag, "CHIE"],
                          ["Monny", AdapterVerificationCommand.flag, "--adapter-power-diagnostics"]] {
            #expect(throws: AdapterVerificationCommand.Failure.invalidArguments) { try AdapterVerificationCommand.validate(arguments: arguments) }
        }
        try AdapterVerificationCommand.validate(arguments: ["Monny", AdapterVerificationCommand.flag])
        let calls = Mutex(0)
        var status = HelperStatus.current
        status.adapterVerificationAvailable = true
        status.adapterVerificationVersion = HelperContract.adapterVerificationVersion
        let handshake = status
        await #expect(throws: HelperConnectionError.timedOut) {
            try await AdapterVerificationCommand.collect(requirement: "fixture", status: { _ in handshake }, verify: { _ in
                calls.withLock { $0 += 1 }
                throw HelperConnectionError.timedOut
            })
        }
        #expect(calls.withLock { $0 } == 1)
        await #expect(throws: HelperConnectionError.invalidReply) {
            try await AdapterVerificationCommand.collect(requirement: "fixture", status: { _ in handshake }, verify: { _ in handshake })
        }
    }
}
