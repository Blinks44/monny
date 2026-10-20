import Foundation
import Synchronization
import Testing
@testable import monny

/// Injected settings and journal only; no PowerUI or privileged service is called.
private nonisolated final class NativeLifecycleFixture: Sendable {
    struct Storage: Sendable {
        var snapshot = NativeChargeLimit.Snapshot(availableLimits: [80, 85, 90, 95, 100], configuredLimit: 85, enabled: false)
        var journal: Data?
        var failRestoration = false
        var failLoad = false
        var writes = 0
    }
    let storage = Mutex(Storage())
    private let onWrite: @Sendable () -> Void
    init(onWrite: @escaping @Sendable () -> Void = {}) { self.onWrite = onWrite }

    var backend: ChargeCommandExecutor.NativeBackend {
        .init(operations: .init(read: { self.storage.withLock { $0.snapshot } }, setLimit: { limit in
            try self.storage.withLock {
                if limit == 85 && $0.failRestoration { throw CocoaError(.fileWriteUnknown) }
                $0.snapshot.configuredLimit = limit
                $0.writes += 1
            }
            self.onWrite()
        }, setEnabled: { enabled in
            self.storage.withLock { $0.snapshot.enabled = enabled; $0.writes += 1 }
            self.onWrite()
        }), journal: .init(load: {
            try self.storage.withLock {
                if $0.failLoad { throw CocoaError(.fileReadNoPermission) }
                return $0.journal
            }
        }, save: { data in self.storage.withLock { $0.journal = data } },
           clear: { self.storage.withLock { $0.journal = nil } }))
    }

    func expectOriginal() {
        #expect(storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(storage.withLock { $0.snapshot.enabled } == false)
        #expect(storage.withLock { $0.journal } == nil)
    }
}

struct NativeExecutorLifecycleTests {
    @Test func startupRecoversCheckpointBeforeSessionsAndNeverReplaysLimit() async throws {
        let fixture = NativeLifecycleFixture()
        var previous = try NativeChargeLimitTransaction(operations: fixture.backend.operations, journal: fixture.backend.journal)
        try previous.apply(limit: 80)
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.beginSession() }
        try await executor.start()
        fixture.expectOriginal()
        #expect(await executor.state == .macOS)
        let session = try await executor.beginSession()
        #expect(try await executor.status(for: session) == .current)
    }

    @Test(arguments: ["unreadable", "corrupt", "restore"])
    func failedStartupStaysClosedAndCanRetryAfterRepair(failure: String) async throws {
        let fixture = NativeLifecycleFixture()
        if failure == "restore" {
            var previous = try NativeChargeLimitTransaction(operations: fixture.backend.operations, journal: fixture.backend.journal)
            try previous.apply(limit: 80)
        }
        fixture.storage.withLock {
            $0.failLoad = failure == "unreadable"
            $0.failRestoration = failure == "restore"
            if failure == "corrupt" { $0.journal = Data("invalid".utf8) }
        }
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.start() }
        #expect(await executor.phase == .starting)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.beginSession() }
        fixture.storage.withLock {
            $0.failLoad = false; $0.failRestoration = false
            if failure == "corrupt" { $0.journal = nil } // Fixture repair only, never a production corruption bypass.
        }
        try await executor.start()
        fixture.expectOriginal()
        #expect(await executor.phase == .ready)
    }

    @Test(arguments: ["disconnect", "sleep", "shutdown", "removal", "expiry"])
    func lifecycleRestoresOriginalAndRevokesTheLease(event: String) async throws {
        let fixture = NativeLifecycleFixture()
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor.start()
        let session = try await executor.beginSession()
        try await executor.applyNativeLimit(80, owner: session, leaseFor: .seconds(30))
        #expect(await executor.state == .nativeLimit(80))
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.status(for: session) }
        switch event {
        case "disconnect": try await executor.disconnect(owner: session)
        case "sleep":
            try await executor.willSleep()
            try await executor.didWake()
            await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) {
                try await executor.applyNativeLimit(90, owner: session, leaseFor: .seconds(30))
            }
        case "shutdown": try await executor.shutdown()
        case "removal": #expect(try await executor.status(for: session, removing: true) == .current)
        default:
            let deadline = try #require(await executor.leaseDeadline)
            try await executor.checkLease(at: deadline)
        }
        fixture.expectOriginal()
        #expect(await executor.state == .macOS)
        #expect(await executor.leaseDeadline == nil)
    }

    @Test func foreignAndStaleSessionsCannotTakeOrRevokeNativeControl() async throws {
        let fixture = NativeLifecycleFixture()
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession(), other = try await executor.beginSession()
        try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(30))
        let writes = fixture.storage.withLock { $0.writes }
        await #expect(throws: ChargeCommandExecutor.Failure.differentOwner) {
            try await executor.applyNativeLimit(90, owner: other, leaseFor: .seconds(30))
        }
        try await executor.disconnect(owner: other)
        #expect(await executor.state == .nativeLimit(80))
        #expect(fixture.storage.withLock { $0.writes } == writes)
        try await executor.disconnect(owner: owner)
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) {
            try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(30))
        }
        fixture.expectOriginal()
    }

    @Test func renewalsPreserveOriginalAndAnOldDeadlineCannotRevokeNewLease() async throws {
        let fixture = NativeLifecycleFixture()
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(5))
        let old = try #require(await executor.leaseDeadline)
        try await executor.applyNativeLimit(90, owner: owner, leaseFor: .seconds(30))
        let renewed = try #require(await executor.leaseDeadline)
        #expect(renewed > old)
        try await executor.checkLease(at: old)
        #expect(await executor.state == .nativeLimit(90))
        try await executor.checkLease(at: renewed)
        fixture.expectOriginal()
    }

    @Test(arguments: ["sleep", "removal", "expiry", "disconnect", "shutdown"])
    func recoveryFailureNeverAcknowledgesAndRequiresExplicitRetry(event: String) async throws {
        let fixture = NativeLifecycleFixture()
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor.start()
        let session = try await executor.beginSession()
        try await executor.applyNativeLimit(80, owner: session, leaseFor: .seconds(30))
        fixture.storage.withLock { $0.failRestoration = true }
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) {
            switch event {
            case "sleep": try await executor.willSleep()
            case "removal": _ = try await executor.status(for: session, removing: true)
            case "disconnect": try await executor.disconnect(owner: session)
            case "shutdown": try await executor.shutdown()
            default:
                let deadline = try #require(await executor.leaseDeadline)
                try await executor.checkLease(at: deadline)
            }
        }
        #expect(await executor.state == .restorationRequired)
        #expect(await executor.leaseDeadline == nil)
        await #expect(throws: (any Error).self) {
            try await executor.applyNativeLimit(90, owner: session, leaseFor: .seconds(30))
        }
        fixture.storage.withLock { $0.failRestoration = false }
        if event == "sleep" { try await executor.didWake() }
        else if event == "removal" { #expect(try await executor.status(for: session, removing: true) == .current) }
        else { try await executor.restore() }
        fixture.expectOriginal()
        #expect(await executor.state == .macOS)
    }

    @Test func externalSettingsStopControlButDoNotTrapExplicitRemoval() async throws {
        let fixture = NativeLifecycleFixture()
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(30))
        fixture.storage.withLock { $0.snapshot.configuredLimit = 95 }
        let writes = fixture.storage.withLock { $0.writes }
        await #expect(throws: ChargeCommandExecutor.Failure.externalChange) {
            try await executor.applyNativeLimit(90, owner: owner, leaseFor: .seconds(30))
        }
        #expect(await executor.state == .macOS)
        #expect(await executor.leaseDeadline == nil)
        #expect(try await executor.status(for: owner) == .current)
        await #expect(throws: ChargeCommandExecutor.Failure.externalChange) {
            try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(30))
        }
        #expect(try await executor.status(for: owner, removing: true) == .current)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 95)
        #expect(fixture.storage.withLock { $0.writes } == writes)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func nativeBackendNeverImplementsHoldOrDischargeAndShippedBackendCannotSetLimit() async throws {
        let native = ChargeCommandExecutor(nativeBackend: NativeLifecycleFixture().backend)
        try await native.start()
        let session = try await native.beginSession()
        for mode in [ChargeCommandExecutor.Mode.charge, .hold, .discharge] {
            await #expect(throws: ChargeCommandExecutor.Failure.unsupported) {
                try await native.apply(mode, owner: session, leaseFor: .seconds(30))
            }
        }
        let shipped = ChargeCommandExecutor()
        try await shipped.start()
        let shippedSession = try await shipped.beginSession()
        await #expect(throws: ChargeCommandExecutor.Failure.unsupported) {
            try await shipped.applyNativeLimit(80, owner: shippedSession, leaseFor: .seconds(30))
        }
    }

    @Test(arguments: [Duration.zero, .seconds(31)])
    func invalidNativeLeaseRestoresPriorControl(duration: Duration) async throws {
        let fixture = NativeLifecycleFixture()
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(30))
        await #expect(throws: ChargeCommandExecutor.Failure.invalidLease) {
            try await executor.applyNativeLimit(90, owner: owner, leaseFor: duration)
        }
        fixture.expectOriginal()
    }

    @Test(.timeLimit(.minutes(1)))
    func automaticNativeExpiryRestoresEvenWhenExternalOwnerDisappears() async throws {
        let events = AsyncStream.makeStream(of: Void.self)
        defer { events.continuation.finish() }
        let fixture = NativeLifecycleFixture { events.continuation.yield(()) }
        var executor: ChargeCommandExecutor? = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor?.start()
        let owner = try #require(try await executor?.beginSession())
        try await executor?.applyNativeLimit(80, owner: owner, leaseFor: .milliseconds(100))
        executor = nil
        var iterator = events.stream.makeAsyncIterator()
        // Limit/enable, followed by disable/original-limit from the executor's own timer.
        for _ in 0..<4 { _ = try #require(await iterator.next()) }
        // The final callback precedes journal clear; assert settings without assuming cleanup ordering.
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(fixture.storage.withLock { $0.snapshot.enabled } == false)
    }

    @Test func cancellationInsideASetterRollsBackWithoutStartingALease() async throws {
        let fixture = NativeLifecycleFixture { withUnsafeCurrentTask { $0?.cancel() } }
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        let request = Task { try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(30)) }
        await #expect(throws: ChargeCommandExecutor.Failure.cancelled) { try await request.value }
        fixture.expectOriginal()
        #expect(await executor.state == .macOS)
        #expect(await executor.leaseDeadline == nil)
    }

    @Test func invalidTargetRollsBackAndClearsThePreviousLease() async throws {
        let fixture = NativeLifecycleFixture()
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(30))
        await #expect(throws: ChargeCommandExecutor.Failure.commandFailed) {
            try await executor.applyNativeLimit(50, owner: owner, leaseFor: .seconds(30))
        }
        fixture.expectOriginal()
        #expect(await executor.state == .macOS)
        #expect(await executor.leaseDeadline == nil)
    }

    @Test func cancelledNativeRequestRestoresAndCannotLeaveLeaseBehind() async throws {
        let fixture = NativeLifecycleFixture()
        let executor = ChargeCommandExecutor(nativeBackend: fixture.backend)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(30))
        let request = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await executor.applyNativeLimit(90, owner: owner, leaseFor: .seconds(30))
        }
        await #expect(throws: ChargeCommandExecutor.Failure.cancelled) { try await request.value }
        fixture.expectOriginal()
        #expect(await executor.leaseDeadline == nil)
    }
}
