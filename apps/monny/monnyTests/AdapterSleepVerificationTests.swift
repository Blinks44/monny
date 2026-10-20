import AppKit
import Foundation
import Synchronization
import Testing
@testable import monny

@MainActor
struct AdapterSleepVerificationTests {
    private let requirement = "identifier \"blinks44.monny\""
    private nonisolated static func executor(_ fixture: AdapterVerificationFixture, native: VerificationFixture) -> ChargeCommandExecutor {
        .init(nativeBackendFactory: { native.backend }, adapterVerificationBackend: AdapterBytePulseIPCTests.backend(fixture), helperInstance: UUID())
    }

    @Test func retainedAnonymousSessionRequiresActiveRecoveryAtSleepAndSameInstanceWake() async throws {
        let fixture = AdapterVerificationFixture()
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let sleepCalls = Mutex(0)
        let result = try await AdapterSleepVerificationCommand.collect(requirement: requirement,
            session: AdapterLifecycleSession(endpoint: endpoint), requestSleep: {
                sleepCalls.withLock { $0 += 1 }
                #expect(fixture.storage.withLock { $0.byte } == 8)
                #expect(fixture.storage.withLock { $0.journal } != nil)
                try await executor.willSleep()
                #expect(fixture.storage.withLock { $0.byte } == 0)
                try await executor.didWake()
            }, waitForWake: {}, status: { try await HelperConnection(endpoint: endpoint).request(requirement: "identifier \"blinks44.monny\"") },
            adapterSource: { true }, pause: {})
        #expect(result.adapterRestoredBeforeSleep && result.wakeObserved && result.nativeSettingsPreserved)
        #expect(result.controlSupport == .unverified)
        #expect(sleepCalls.withLock { $0 } == 1)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(native.storage.withLock { $0.writes } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func delayedTransitionDoesNotConsumePostWakeBudgetOrPollWhileSleeping() async throws {
        let fixture = AdapterVerificationFixture()
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let instant = Mutex(SuspendingClock().now)
        let waiting = Mutex(false)
        let calls = Mutex(0)
        let result = try await AdapterSleepVerificationCommand.collect(requirement: requirement,
            session: AdapterLifecycleSession(endpoint: listener.endpoint), requestSleep: {
                calls.withLock { $0 += 1 }
                try await executor.willSleep()
            }, waitForWake: {
                // Model more transition/DarkWake awake time than the old entire status budget.
                instant.withLock { $0 = $0.advanced(by: .seconds(20)) }
                waiting.withLock { $0 = true }
                try await executor.didWake()
            }, status: {
                #expect(waiting.withLock { $0 })
                return try await HelperConnection(endpoint: endpoint).request(requirement: "identifier \"blinks44.monny\"")
            }, adapterSource: { true }, now: { instant.withLock { $0 } }, pause: {})
        #expect(result.wakeObserved && result.adapterRestoredBeforeSleep)
        #expect(calls.withLock { $0 } == 1)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
    }

    @Test func workspaceWakeIsBufferedAndRequiresPrecedingSleep() async throws {
        let center = NotificationCenter()
        let observer = SystemWakeObserver(center: center)
        defer { observer.stop() }
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        // An unrelated wake alone must time out, rather than becoming a successful barrier.
        await #expect(throws: AdapterSleepVerificationCommand.Failure.wakeNotObserved) {
            try await observer.wait(timeout: .zero)
        }
        let paired = SystemWakeObserver(center: center)
        defer { paired.stop() }
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        // The OS callback may arrive before the sleep API returns or before wait starts.
        try await paired.wait()
    }

    @Test func cancelledWakeWaitDoesNotHangAndStoppedObserverCannotComplete() async throws {
        let observer = SystemWakeObserver(center: NotificationCenter())
        let task = Task { try await observer.wait() }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        observer.stop()
        observer.stop()
        await #expect(throws: CancellationError.self) { try await observer.wait() }
    }

    @Test(arguments: [false, true])
    func failedWakeBarrierRestoresWithoutPollingOrRepeatingPreparation(cancelled: Bool) async throws {
        let fixture = AdapterVerificationFixture()
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let calls = Mutex(0)
        await #expect(throws: (any Error).self) {
            try await AdapterSleepVerificationCommand.collect(requirement: requirement,
                session: AdapterLifecycleSession(endpoint: listener.endpoint), requestSleep: {
                    calls.withLock { $0 += 1 }
                }, waitForWake: {
                    if cancelled { throw CancellationError() }
                    throw AdapterSleepVerificationCommand.Failure.wakeNotObserved
                }, status: { Issue.record("No polling before wake"); return .current }, adapterSource: { true }, pause: {})
        }
        #expect(calls.withLock { $0 } == 1)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func rejectedSystemSleepRequestCancelsOnceAndRestoresOverSameConnection() async throws {
        let fixture = AdapterVerificationFixture()
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        await #expect(throws: ChargeCommandExecutor.Failure.commandFailed) {
            try await AdapterSleepVerificationCommand.collect(requirement: requirement,
                session: AdapterLifecycleSession(endpoint: listener.endpoint), requestSleep: {
                    #expect(fixture.storage.withLock { $0.byte } == 8)
                    throw ChargeCommandExecutor.Failure.commandFailed
                }, waitForWake: {}, status: { Issue.record("Rejected sleep must not enter wake polling"); return .current }, adapterSource: { true }, pause: {})
        }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: ["disconnect", "cancel", "expiry", "removal"])
    func preparedOwnerCannotRenewAndEveryExitRestores(event: String) async throws {
        let (restored, continuation) = AsyncStream<Void>.makeStream()
        let fixture = AdapterVerificationFixture(onRestored: { continuation.yield(()); continuation.finish() })
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let session = AdapterLifecycleSession(endpoint: listener.endpoint)
        _ = try await session.open(requirement: requirement)
        let prepared = try await session.prepare()
        #expect(prepared.isValid && prepared.appliedByte == 8)
        let foreign = try await executor.beginSession()
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.prepareAdapterSleep(for: foreign) }
        await #expect(throws: ChargeCommandExecutor.Failure.differentOwner) { try await executor.cancelAdapterSleep(for: foreign) }
        switch event {
        case "disconnect":
            await session.close()
            // The service invalidation handler runs asynchronously; await the fixture's actual restoration signal.
            for await _ in restored { break }
        case "cancel": try await session.cancel()
        case "expiry":
            let deadline = try #require(await executor.leaseDeadline)
            try await executor.checkLease(at: deadline)
            await session.close()
        default:
            _ = try await executor.status(for: foreign, removing: true)
            await session.close()
        }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: ["expiredBeforeSleep", "changedNative", "newInstance", "failedSleep", "noSource"])
    func unrelatedWakeOrRecoveryCannotProduceSuccess(condition: String) async throws {
        let fixture = AdapterVerificationFixture()
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let endpoint = listener.endpoint
        await #expect(throws: (any Error).self) {
            try await AdapterSleepVerificationCommand.collect(requirement: requirement,
                session: AdapterLifecycleSession(endpoint: endpoint), requestSleep: {
                    if condition == "expiredBeforeSleep" {
                        let deadline = try #require(await executor.leaseDeadline)
                        try await executor.checkLease(at: deadline)
                    }
                    try await executor.willSleep()
                    try await executor.didWake()
                    if condition == "changedNative" { native.storage.withLock { $0.snapshot.configuredLimit = 90 } }
                }, waitForWake: {}, status: {
                    var status = try await HelperConnection(endpoint: endpoint).request(requirement: "identifier \"blinks44.monny\"")
                    if condition == "newInstance" { status.helperInstance = UUID() }
                    if condition == "failedSleep" { status.lifecycleDiagnostics?.lastSleep = .failed }
                    return status
                }, adapterSource: { condition != "noSource" }, pause: {})
        }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.writes.filter { $0 }.count } == 1)
        #expect(native.storage.withLock { $0.writes } == 0)
    }

    @Test func oldHelperOrUnsafePreparationCannotRequestSleep() async throws {
        let oldService = try LocalHelperService()
        let oldListener = NSXPCListener.anonymous()
        oldListener.delegate = oldService
        oldListener.activate()
        defer { withExtendedLifetime(oldService) { oldListener.invalidate() } }
        await #expect(throws: HelperConnectionError.versionMismatch) {
            try await AdapterSleepVerificationCommand.collect(requirement: requirement,
                session: AdapterLifecycleSession(endpoint: oldListener.endpoint), requestSleep: { Issue.record("Old helper requested OS sleep") },
                waitForWake: {}, status: { .current }, adapterSource: { true }, pause: {})
        }
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.environment.level = 0.29 }
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        await #expect(throws: HelperConnectionError.invalidReply) {
            try await AdapterSleepVerificationCommand.collect(requirement: requirement,
                session: AdapterLifecycleSession(endpoint: listener.endpoint), requestSleep: { Issue.record("Unsafe preparation requested OS sleep") },
                waitForWake: {}, status: { .current }, adapterSource: { true }, pause: {})
        }
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
    }

    @Test func cancelledSleepPreparationClosesOwnerAndRestoresWithoutRequestReplay() async throws {
        let (restored, continuation) = AsyncStream<Void>.makeStream()
        let fixture = AdapterVerificationFixture(onRestored: { continuation.yield(()); continuation.finish() })
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let calls = Mutex(0)
        let task = Task {
            try await AdapterSleepVerificationCommand.collect(requirement: "identifier \"blinks44.monny\"",
                session: AdapterLifecycleSession(endpoint: endpoint), requestSleep: {
                    calls.withLock { $0 += 1 }
                    withUnsafeCurrentTask { $0?.cancel() }
                    throw CancellationError()
                }, waitForWake: {}, status: { .current }, adapterSource: { true }, pause: {})
        }
        do { _ = try await task.value; Issue.record("Cancelled sleep request succeeded") }
        catch { #expect(error is CancellationError) }
        for await _ in restored { break }
        #expect(calls.withLock { $0 } == 1)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func admissionPartialFailureRetainsRecoveryTimerAndNeverReturnsPreparation() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.effects[1] = .loseReadAccess }
        let native = VerificationFixture()
        let executor = Self.executor(fixture, native: native)
        try await executor.start()
        let owner = try await executor.beginSession()
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.prepareAdapterSleep(for: owner) }
        #expect(fixture.storage.withLock { $0.journal } != nil)
        let deadline = try #require(await executor.leaseDeadline)
        fixture.storage.withLock { $0.failReads = false }
        try await executor.checkLease(at: deadline)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(fixture.storage.withLock { $0.writes.filter { $0 }.count } == 1)
    }

    @Test func preparationAndWireRepliesCannotClaimIdleOrAcceptMalformedData() throws {
        var preparation = AdapterLifecyclePreparation(helperInstance: UUID(), nativeLimit: .init(availableLimits: [80,85,90,95,100], configuredLimit: 85, enabled: true), lifecycleBefore: .init())
        #expect(try AdapterLifecyclePreparation.decode(JSONEncoder().encode(preparation)) == preparation)
        preparation.appliedByte = 0
        #expect(throws: HelperConnectionError.invalidReply) { try AdapterLifecyclePreparation.decode(JSONEncoder().encode(preparation)) }
        #expect(throws: HelperConnectionError.invalidReply) { try AdapterLifecyclePreparation.decode(JSONEncoder().encode(HelperStatus.current)) }
        try AdapterSleepVerificationCommand.validate(arguments: ["Monny", AdapterSleepVerificationCommand.flag])
        #expect(throws: AdapterSleepVerificationCommand.Failure.invalidArguments) {
            try AdapterSleepVerificationCommand.validate(arguments: ["Monny", AdapterSleepVerificationCommand.flag, "60"])
        }
    }
}
