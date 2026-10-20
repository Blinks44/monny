import Foundation
import Synchronization
import Testing
@testable import monny

private nonisolated enum ChargeWrite: Sendable, Equatable {
    case adapter(Bool), charging(Bool)
}

/// Acknowledged writes and partial failures only; no IOKit or real charging operations.
private nonisolated final class ChargeHardwareFixture: Sendable {
    private struct Storage {
        var writes: [ChargeWrite] = []
        var failures: Set<Int> = []
    }
    private enum Failure: Error { case injected }
    private let storage = Mutex(Storage())
    private let onWrite: @Sendable (ChargeWrite) -> Void

    init(onWrite: @escaping @Sendable (ChargeWrite) -> Void = { _ in }) { self.onWrite = onWrite }

    var writes: [ChargeWrite] { storage.withLock { $0.writes } }

    func reset(failingAt failures: Set<Int> = []) {
        storage.withLock { $0 = Storage(failures: failures) }
    }

    private func write(_ write: ChargeWrite) throws {
        let fails = storage.withLock {
            $0.writes.append(write)
            return $0.failures.contains($0.writes.count)
        }
        if fails { throw Failure.injected }
        onWrite(write)
    }

    var operations: ChargeCommandExecutor.Operations {
        .init(setAdapterEnabled: { try self.write(.adapter($0)) },
              setChargingAllowed: { try self.write(.charging($0)) })
    }
}

struct ChargeCommandTests {
    @Test func startupAndRestartRequireRestoration() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) {
            try await executor.apply(.hold, owner: executor.beginSession(), leaseFor: .seconds(30))
        }
        #expect(hardware.writes.isEmpty)
        try await executor.start()
        #expect(hardware.writes == [.adapter(true), .charging(true)])
        try await executor.apply(.discharge, owner: executor.beginSession(), leaseFor: .seconds(30))
        let restarted = ChargeCommandExecutor(operations: hardware.operations)
        #expect(await restarted.state == .restorationRequired)
        try await restarted.start()
        #expect(hardware.writes.suffix(2) == [.adapter(true), .charging(true)])
        try await executor.restore()
    }

    @Test func switchesModesInSafeOrderAndRenewalDoesNotRewriteHardware() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        hardware.reset()
        let owner = try await executor.beginSession()
        try await executor.apply(.hold, owner: owner, leaseFor: .seconds(30))
        try await executor.apply(.hold, owner: owner, leaseFor: .seconds(30))
        #expect(hardware.writes == [.adapter(true), .charging(false)])
        try await executor.apply(.discharge, owner: owner, leaseFor: .seconds(30))
        #expect(hardware.writes.suffix(2) == [.charging(false), .adapter(false)])
        try await executor.apply(.charge, owner: owner, leaseFor: .seconds(30))
        #expect(hardware.writes.suffix(2) == [.adapter(true), .charging(true)])
        try await executor.restore()
    }

    @Test(arguments: [Duration.zero, .seconds(-1), .seconds(31)])
    func invalidLeaseReleasesControl(duration: Duration) async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.apply(.hold, owner: owner, leaseFor: .seconds(30))
        await #expect(throws: ChargeCommandExecutor.Failure.invalidLease) {
            try await executor.apply(.hold, owner: owner, leaseFor: duration)
        }
        #expect(await executor.state == .macOS)
        #expect(await executor.leaseDeadline == nil)
        #expect(hardware.writes.suffix(2) == [.adapter(true), .charging(true)])
    }

    @Test func anotherConnectionCannotTakeOrRevokeALease() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        let owner = try await executor.beginSession(), stranger = try await executor.beginSession()
        try await executor.apply(.hold, owner: owner, leaseFor: .seconds(30))
        hardware.reset()
        await #expect(throws: ChargeCommandExecutor.Failure.differentOwner) {
            try await executor.apply(.discharge, owner: stranger, leaseFor: .seconds(30))
        }
        try await executor.disconnect(owner: stranger)
        #expect(hardware.writes.isEmpty)
        #expect(await executor.state == .active(.hold))
        try await executor.disconnect(owner: owner)
        #expect(await executor.state == .macOS)
        #expect(hardware.writes == [.adapter(true), .charging(true)])
    }

    @Test func renewedDeadlineSurvivesAnOldExpiryAndThenExpires() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.apply(.hold, owner: owner, leaseFor: .seconds(5))
        let old = try #require(await executor.leaseDeadline)
        try await executor.apply(.hold, owner: owner, leaseFor: .seconds(30))
        let renewed = try #require(await executor.leaseDeadline)
        #expect(renewed > old)
        try await executor.checkLease(at: old)
        #expect(await executor.state == .active(.hold))
        try await executor.checkLease(at: renewed)
        #expect(await executor.state == .macOS)
        #expect(hardware.writes.suffix(2) == [.adapter(true), .charging(true)])
    }

    @Test func everyPartialCommandFailureAttemptsFullRestoration() async throws {
        for mode in [ChargeCommandExecutor.Mode.charge, .hold, .discharge] {
            for failedWrite in [1, 2] {
                let hardware = ChargeHardwareFixture()
                let executor = ChargeCommandExecutor(operations: hardware.operations)
                try await executor.start()
                hardware.reset(failingAt: [failedWrite])
                await #expect(throws: ChargeCommandExecutor.Failure.commandFailed) {
                    try await executor.apply(mode, owner: executor.beginSession(), leaseFor: .seconds(30))
                }
                #expect(await executor.state == .macOS)
                #expect(hardware.writes.suffix(2) == [.adapter(true), .charging(true)])
            }
        }
    }

    @Test func failedRestorationAttemptsBothWritesAndBlocksCommandsUntilRecovery() async throws {
        for failures: Set<Int> in [[1], [2], [1, 2]] {
            let hardware = ChargeHardwareFixture()
            let executor = ChargeCommandExecutor(operations: hardware.operations)
            hardware.reset(failingAt: failures)
            await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.start() }
            #expect(hardware.writes == [.adapter(true), .charging(true)])
            #expect(await executor.state == .restorationRequired)
            await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.beginSession() }
            hardware.reset()
            try await executor.start()
            #expect(await executor.state == .macOS)
        }
    }

    @Test func restorationFailureAfterPartialCommandCannotLookSuccessful() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        hardware.reset(failingAt: [2, 3])
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) {
            try await executor.apply(.discharge, owner: executor.beginSession(), leaseFor: .seconds(30))
        }
        #expect(hardware.writes == [.charging(false), .adapter(false), .adapter(true), .charging(true)])
        #expect(await executor.state == .restorationRequired)
        hardware.reset()
        try await executor.restore()
    }

    @Test func expiryRestorationFailureRemainsVisible() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        try await executor.apply(.hold, owner: executor.beginSession(), leaseFor: .seconds(30))
        let deadline = try #require(await executor.leaseDeadline)
        hardware.reset(failingAt: [1])
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) {
            try await executor.checkLease(at: deadline)
        }
        #expect(await executor.state == .restorationRequired)
        #expect(await executor.leaseDeadline == nil)
        #expect(hardware.writes == [.adapter(true), .charging(true)])
        hardware.reset()
        try await executor.restore()
    }

    @Test func cancelledRequestReleasesItsExistingCommand() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.apply(.hold, owner: owner, leaseFor: .seconds(30))
        let request = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await executor.apply(.discharge, owner: owner, leaseFor: .seconds(30))
        }
        await #expect(throws: ChargeCommandExecutor.Failure.cancelled) { try await request.value }
        #expect(await executor.state == .macOS)
    }

    @Test(.timeLimit(.minutes(1)))
    func automaticDeadlineRestoresWithoutAnAppRequest() async throws {
        let events = AsyncStream.makeStream(of: ChargeWrite.self)
        let hardware = ChargeHardwareFixture { events.continuation.yield($0) }
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        try await executor.apply(.hold, owner: executor.beginSession(), leaseFor: .milliseconds(100))
        var writes = events.stream.makeAsyncIterator()
        for expected in [ChargeWrite.adapter(true), .charging(true), .adapter(true), .charging(false),
                         .adapter(true), .charging(true)] {
            #expect(await writes.next() == expected)
        }
        #expect(await executor.state == .macOS)
        events.continuation.finish()
    }

    @Test(.timeLimit(.minutes(1)))
    func losingTheExternalOwnerDoesNotAbandonAnActiveLease() async throws {
        let events = AsyncStream.makeStream(of: ChargeWrite.self)
        let hardware = ChargeHardwareFixture { events.continuation.yield($0) }
        var executor: ChargeCommandExecutor? = ChargeCommandExecutor(operations: hardware.operations)
        try await executor?.start()
        let owner = try #require(try await executor?.beginSession())
        try await executor?.apply(.discharge, owner: owner, leaseFor: .milliseconds(100))
        executor = nil
        var writes = events.stream.makeAsyncIterator()
        for expected in [ChargeWrite.adapter(true), .charging(true), .charging(false), .adapter(false),
                         .adapter(true), .charging(true)] {
            #expect(await writes.next() == expected)
        }
        events.continuation.finish()
    }

    @Test func shippedBackendIsExplicitlyUnsupportedAndStatusOnly() async throws {
        let executor = ChargeCommandExecutor()
        try await executor.start()
        let session = try await executor.beginSession()
        #expect(try await executor.status(for: session) == .current)
        await #expect(throws: ChargeCommandExecutor.Failure.unsupported) {
            try await executor.apply(.hold, owner: session, leaseFor: .seconds(30))
        }
        #expect(try await executor.status(for: session, removing: true) == .current)
        #expect(await executor.phase == .removing)
    }

    @Test func disconnectRejectsQueuedCommandsFromTheOldSession() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.apply(.hold, owner: owner, leaseFor: .seconds(30))
        try await executor.disconnect(owner: owner)
        hardware.reset()
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) {
            try await executor.apply(.discharge, owner: owner, leaseFor: .seconds(30))
        }
        #expect(hardware.writes.isEmpty)
    }

    @Test func sleepRestoresAndWakeRequiresAnEntirelyNewSession() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        let old = try await executor.beginSession()
        try await executor.apply(.discharge, owner: old, leaseFor: .seconds(30))
        hardware.reset()
        try await executor.willSleep()
        #expect(hardware.writes == [.adapter(true), .charging(true)])
        #expect(await executor.phase == .sleeping)
        #expect(await executor.leaseDeadline == nil)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.beginSession() }
        try await executor.didWake()
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) {
            try await executor.apply(.hold, owner: old, leaseFor: .seconds(30))
        }
        #expect(await executor.state == .macOS)
        let fresh = try await executor.beginSession()
        try await executor.apply(.hold, owner: fresh, leaseFor: .seconds(30))
        try await executor.disconnect(owner: old)
        #expect(await executor.state == .active(.hold))
        try await executor.shutdown()
    }

    @Test func failedWakeCannotReopenTheCommandGate() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        try await executor.willSleep()
        hardware.reset(failingAt: [1])
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.didWake() }
        #expect(await executor.phase == .sleeping)
        #expect(await executor.state == .restorationRequired)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.beginSession() }
        hardware.reset()
        try await executor.didWake()
        #expect(await executor.phase == .ready)
    }

    @Test func failedRemovalNeverAcknowledgesSuccessAndCanBeRetried() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        let owner = try await executor.beginSession()
        try await executor.apply(.discharge, owner: owner, leaseFor: .seconds(30))
        hardware.reset(failingAt: [1])
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) {
            try await executor.status(for: owner, removing: true)
        }
        #expect(await executor.phase == .removing)
        let retry = try await executor.beginSession()
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) {
            try await executor.apply(.hold, owner: retry, leaseFor: .seconds(30))
        }
        hardware.reset()
        #expect(try await executor.status(for: retry, removing: true) == .current)
        #expect(hardware.writes == [.adapter(true), .charging(true)])
    }

    @Test func shutdownIsTerminalEvenWhenRestorationFails() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        hardware.reset(failingAt: [2])
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.shutdown() }
        #expect(await executor.phase == .stopped)
        #expect(await executor.state == .restorationRequired)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.beginSession() }
        try await executor.didWake()
        #expect(await executor.phase == .stopped)
    }

    @Test func concurrentConnectionsAreBoundedAndSlotsAreReclaimed() async throws {
        let executor = ChargeCommandExecutor()
        try await executor.start()
        var owners: [UUID] = []
        for _ in 0..<16 { owners.append(try await executor.beginSession()) }
        await #expect(throws: ChargeCommandExecutor.Failure.sessionLimit) { try await executor.beginSession() }
        let old = try #require(owners.first)
        try await executor.disconnect(owner: old)
        #expect(try await executor.beginSession() != old)
        try await executor.shutdown()
    }

    @Test func exportedSessionDoesNotReviveAfterInvalidation() async throws {
        let executor = ChargeCommandExecutor()
        try await executor.start()
        let session = HelperSession(executor: executor)
        let status: Data = await withCheckedContinuation { reply in session.readStatus { reply.resume(returning: $0) } }
        #expect(try HelperStatus.decode(status) == .current)
        await session.disconnect()
        let stale: Data = await withCheckedContinuation { reply in session.readStatus { reply.resume(returning: $0) } }
        #expect(throws: HelperConnectionError.invalidReply) { try HelperStatus.decode(stale) }
        let next = HelperSession(executor: executor)
        let removal: Data = await withCheckedContinuation { reply in next.prepareForRemoval { reply.resume(returning: $0) } }
        #expect(try HelperStatus.decode(removal) == .current)
        #expect(await executor.phase == .removing)
        await next.disconnect()
    }

    @Test func exportedRemovalFailureIsAnInvalidReplyUntilRestoreSucceeds() async throws {
        let hardware = ChargeHardwareFixture()
        let executor = ChargeCommandExecutor(operations: hardware.operations)
        try await executor.start()
        let session = HelperSession(executor: executor)
        hardware.reset(failingAt: [1])
        let refused: Data = await withCheckedContinuation { reply in
            session.prepareForRemoval { reply.resume(returning: $0) }
        }
        #expect(throws: HelperConnectionError.invalidReply) { try HelperStatus.decode(refused) }
        #expect(await executor.state == .restorationRequired)
        hardware.reset()
        let restored: Data = await withCheckedContinuation { reply in
            session.prepareForRemoval { reply.resume(returning: $0) }
        }
        #expect(try HelperStatus.decode(restored) == .current)
        await session.disconnect()
    }

}
