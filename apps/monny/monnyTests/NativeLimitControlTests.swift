import Foundation
import Testing
@testable import monny

struct NativeLimitControlTests {
    @Test func nativeSleepPreservesSettingJournalAndOwnerWithoutWrites() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        _ = try await executor.setNativeLimit(80, for: owner)
        let oldDeadline = try #require(await executor.leaseDeadline)
        let journal = fixture.storage.withLock { $0.journal }
        let writes = fixture.storage.withLock { $0.writes }
        try await executor.willSleep()
        try await executor.willSleep()
        try await executor.checkLease(at: oldDeadline.advanced(by: .seconds(3600)))
        #expect(await executor.phase == .sleeping)
        #expect(await executor.leaseDeadline == nil)
        let observer = try await executor.beginSession()
        #expect(try await executor.status(for: observer).activeNativeLimit == 80)
        await #expect(throws: ChargeCommandExecutor.Failure.differentOwner) {
            try await executor.setNativeLimit(80, for: observer)
        }
        try await executor.disconnect(owner: observer)
        #expect(try await executor.setNativeLimit(80, for: owner).activeNativeLimit == 80)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) {
            try await executor.setNativeLimit(90, for: owner)
        }
        try await executor.didWake()
        #expect(try await executor.status(for: owner).activeNativeLimit == 80)
        #expect(await executor.leaseDeadline != nil)
        #expect(fixture.storage.withLock { $0.writes } == writes)
        #expect(fixture.storage.withLock { $0.journal } == journal)
        _ = try await executor.releaseNativeLimit(for: owner)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: ["disconnect", "removal", "shutdown", "external", "unavailable", "restart", "wakeExpiry"])
    func preservedSleepStillHonorsRecoveryAndExternalChanges(event: String) async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        _ = try await executor.setNativeLimit(80, for: owner)
        try await executor.willSleep()
        switch event {
        case "disconnect": try await executor.disconnect(owner: owner); try await executor.didWake()
        case "removal": _ = try await executor.status(for: owner, removing: true)
        case "shutdown": try await executor.shutdown()
        case "external":
            fixture.storage.withLock { $0.snapshot.configuredLimit = 95 }
            await #expect(throws: ChargeCommandExecutor.Failure.externalChange) { try await executor.didWake() }
        case "unavailable":
            fixture.storage.withLock { $0.fault = .unavailable }
            await #expect(throws: (any Error).self) { try await executor.didWake() }
            #expect(await executor.state == .restorationRequired)
            fixture.storage.withLock { $0.fault = .none }
            try await executor.didWake()
        case "restart":
            let restarted = fixture.executor()
            try await restarted.start()
            #expect(await restarted.state == .macOS)
            try await executor.shutdown()
        default:
            try await executor.didWake()
            let deadline = try #require(await executor.leaseDeadline)
            try await executor.checkLease(at: deadline)
            await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) {
                try await executor.setNativeLimit(80, for: owner)
            }
        }
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == (event == "external" ? 95 : 85))
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(await executor.state == .macOS)
    }

    @Test(arguments: [false, true])
    func expiredNativeOwnerCannotReplayEvenAfterRestorationRecovers(failsRestoration: Bool) async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        _ = try await executor.setNativeLimit(80, for: owner)
        let deadline = try #require(await executor.leaseDeadline)
        if failsRestoration {
            fixture.storage.withLock { $0.fault = .restore }
            await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) {
                try await executor.checkLease(at: deadline)
            }
            fixture.storage.withLock { $0.fault = .none }
            try await executor.restore()
        } else { try await executor.checkLease(at: deadline) }
        let writes = fixture.storage.withLock { $0.writes }
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) {
            try await executor.setNativeLimit(80, for: owner)
        }
        #expect(fixture.storage.withLock { $0.writes } == writes)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        let newOwner = try await executor.beginSession()
        _ = try await executor.setNativeLimit(90, for: newOwner)
        _ = try await executor.releaseNativeLimit(for: newOwner)
    }

    @Test func diagnosticsPreserveTheCurrentNativeSetting() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        _ = try await executor.diagnose(for: owner)
        _ = try await executor.setNativeLimit(80, for: owner)
        let response = try await executor.diagnose(for: owner)
        #expect(response.activeNativeLimit == 80)
        #expect(try response.validated() == response)
        guard case .available(let snapshot) = response.nativeChargeLimit else {
            Issue.record("Active diagnostics must include the live native setting")
            return
        }
        #expect(snapshot.configuredLimit == 80)
        _ = try await executor.releaseNativeLimit(for: owner)
    }

    @Test(arguments: ["disconnect", "shutdown", "removal", "expiry"])
    func nativeSessionRestoresOriginalAcrossLifecycle(event: String) async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        #expect(try await executor.setNativeLimit(80, for: owner).controlState == .nativeLimit)
        switch event {
        case "disconnect": try await executor.disconnect(owner: owner)
        case "shutdown": try await executor.shutdown()
        case "removal": #expect(try await executor.status(for: owner, removing: true).controlState == .notControlling)
        default:
            let deadline = try #require(await executor.leaseDeadline)
            try await executor.checkLease(at: deadline)
        }
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(await executor.state == .macOS)
    }

    @Test func otherSessionCannotStealOrReleaseControl() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        let other = try await executor.beginSession()
        _ = try await executor.setNativeLimit(80, for: owner)
        await #expect(throws: ChargeCommandExecutor.Failure.differentOwner) {
            try await executor.setNativeLimit(90, for: other)
        }
        await #expect(throws: ChargeCommandExecutor.Failure.differentOwner) {
            try await executor.releaseNativeLimit(for: other)
        }
        try await executor.disconnect(owner: other)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 80)
        _ = try await executor.releaseNativeLimit(for: owner)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
    }

    @Test func externalSettingIsPreservedAndControlStops() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        _ = try await executor.setNativeLimit(80, for: owner)
        fixture.storage.withLock { $0.snapshot.configuredLimit = 95 }
        await #expect(throws: ChargeCommandExecutor.Failure.externalChange) { try await executor.status(for: owner) }
        #expect(await executor.state == .macOS)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 95)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func failedRestorationNeverAcknowledgesSafeStopOrRemoval() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        _ = try await executor.setNativeLimit(80, for: owner)
        fixture.storage.withLock { $0.fault = .restore }
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) {
            try await executor.releaseNativeLimit(for: owner)
        }
        let response = try await executor.status(for: owner)
        #expect(response.controlState == .restorationRequired)
        #expect(try HelperStatus.decode(JSONEncoder().encode(response)).controlState == .restorationRequired)
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) {
            try await executor.status(for: owner, removing: true)
        }
        #expect(fixture.storage.withLock { $0.journal } != nil)
        fixture.storage.withLock { $0.fault = .none }
        try await executor.disconnect(owner: owner)
    }

    @Test func nativeControlRejectsUnsupportedTargetsAndInactiveBackend() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        await #expect(throws: ChargeCommandExecutor.Failure.commandFailed) {
            try await executor.setNativeLimit(81, for: owner)
        }
        #expect(fixture.storage.withLock { $0.writes } == 0)
        let readOnly = ChargeCommandExecutor()
        try await readOnly.start()
        let token = try await readOnly.beginSession()
        await #expect(throws: ChargeCommandExecutor.Failure.unsupported) {
            try await readOnly.setNativeLimit(80, for: token)
        }
    }
    @Test func malformedControlRepliesAreRejected() throws {
        var status = HelperStatus.current
        status.controlState = .nativeLimit
        status.nativeLimitSessionAvailable = true
        status.nativeChargeLimit = .available(.init(availableLimits: [80, 85, 100], configuredLimit: 80, enabled: true))
        status.activeNativeLimit = 80
        #expect(try status.validated() == status)
        status.activeNativeLimit = 85
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.activeNativeLimit = 80
        status.nativeLimitSessionAvailable = nil
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.nativeLimitSessionAvailable = true
        status.controlState = .notControlling
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
    }

}
