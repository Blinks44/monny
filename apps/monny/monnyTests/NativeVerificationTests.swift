import Foundation
import Synchronization
import Testing
@testable import monny

nonisolated final class VerificationFixture: Sendable {
    enum Fault: Sendable { case none, beforeWrite, afterWrite, restore, unavailable, external, changedBeforeWrite }
    struct Storage: Sendable {
        var snapshot = NativeChargeLimit.Snapshot(availableLimits: [80, 85, 90, 95, 100], configuredLimit: 85, enabled: true)
        var fault = Fault.none
        var journal: Data?
        var reads = 0
        var writes = 0
    }
    let storage = Mutex(Storage())
    var backend: ChargeCommandExecutor.NativeBackend {
        .init(operations: .init(read: {
            try self.storage.withLock {
                $0.reads += 1
                if $0.fault == .unavailable { throw CocoaError(.fileReadUnknown) }
                if $0.fault == .changedBeforeWrite && $0.reads == 2 { $0.snapshot.configuredLimit = 95 }
                return $0.snapshot
            }
        }, setLimit: { limit in
            try self.storage.withLock {
                $0.writes += 1
                if (limit == 80 && $0.fault == .beforeWrite) || (limit == 85 && $0.fault == .restore) {
                    throw CocoaError(.fileWriteUnknown)
                }
                $0.snapshot.configuredLimit = (limit == 80 && $0.fault == .external) ? 95 : limit
                if limit == 80 && $0.fault == .afterWrite { throw CocoaError(.fileWriteUnknown) }
            }
        }, setEnabled: { enabled in self.storage.withLock { $0.snapshot.enabled = enabled; $0.writes += 1 } }),
        journal: .init(load: { self.storage.withLock { $0.journal } },
            save: { data in self.storage.withLock { $0.journal = data } }, clear: { self.storage.withLock { $0.journal = nil } }))
    }
    func executor() -> ChargeCommandExecutor { ChargeCommandExecutor(nativeBackendFactory: { self.backend }) }
}

struct NativeVerificationTests {
    @Test(arguments: [false, true])
    func explicitVerificationReturnsOriginalAppliedAndRestoredWithoutPersistentControl(enabled: Bool) async throws {
        let fixture = VerificationFixture()
        fixture.storage.withLock { $0.snapshot.enabled = enabled }
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        #expect(try await executor.status(for: owner).nativeVerificationAvailable == true)
        #expect(fixture.storage.withLock { $0.writes } == 0)
        let response = try await executor.verifyNativeLimit(80, for: owner)
        #expect(response.nativeVerification?.outcome == .restored)
        #expect(response.nativeVerification?.before?.configuredLimit == 85)
        #expect(response.nativeVerification?.before?.enabled == enabled)
        #expect(response.nativeVerification?.applied?.configuredLimit == 80)
        #expect(response.nativeVerification?.applied?.enabled == true)
        #expect(response.nativeVerification?.after?.configuredLimit == 85)
        #expect(response.nativeVerification?.after?.enabled == enabled)
        #expect(try HelperStatus.decode(JSONEncoder().encode(response)) == response)
        #expect(await executor.state == .macOS)
        #expect(await executor.leaseDeadline == nil)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: [VerificationFixture.Fault.beforeWrite, .afterWrite])
    func failedWriteReportsVerifiedRestoration(fault: VerificationFixture.Fault) async throws {
        let fixture = VerificationFixture()
        fixture.storage.withLock { $0.fault = fault }
        let executor = fixture.executor()
        try await executor.start()
        let response = try await executor.verifyNativeLimit(80, for: executor.beginSession())
        #expect(response.nativeVerification?.outcome == .failedRestored)
        #expect(response.nativeVerification?.after?.configuredLimit == 85)
        #expect(response.controlState == .notControlling)
    }

    @Test func failedRestorationCannotClaimNonControllingOrAllowRemoval() async throws {
        let fixture = VerificationFixture()
        fixture.storage.withLock { $0.fault = .restore }
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        let response = try await executor.verifyNativeLimit(80, for: owner)
        #expect(response.nativeVerification?.outcome == .restorationRequired)
        #expect(response.controlState == .restorationRequired)
        #expect(try response.validated() == response)
        #expect(fixture.storage.withLock { $0.journal } != nil)
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await executor.status(for: owner, removing: true) }
        fixture.storage.withLock { $0.fault = .none }
        #expect(try await executor.status(for: owner, removing: true).controlState == .notControlling)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
    }

    @Test(arguments: [VerificationFixture.Fault.external, .changedBeforeWrite])
    func externalChangeIsPreservedEvenBetweenPreflightAndFirstWrite(fault: VerificationFixture.Fault) async throws {
        let fixture = VerificationFixture()
        fixture.storage.withLock { $0.fault = fault }
        let executor = fixture.executor()
        try await executor.start()
        let response = try await executor.verifyNativeLimit(80, for: executor.beginSession())
        #expect(response.nativeVerification?.outcome == .externalChange)
        #expect(response.nativeVerification?.after?.configuredLimit == 95)
        #expect(fixture.storage.withLock { $0.writes } == (fault == .external ? 1 : 0))
        #expect(await executor.state == .macOS)
    }

    @Test func unsupportedUnavailableAndInvalidRequestsCannotMutate() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let owner = try await executor.beginSession()
        for target in [0, 50, 101] {
            await #expect(throws: ChargeCommandExecutor.Failure.unsupported) { try await executor.verifyNativeLimit(target, for: owner) }
        }
        #expect(try await executor.verifyNativeLimit(87, for: owner).nativeVerification?.outcome == .unavailable)
        fixture.storage.withLock { $0.fault = .unavailable }
        #expect(try await executor.verifyNativeLimit(80, for: owner).nativeVerification?.outcome == .unavailable)
        #expect(fixture.storage.withLock { $0.writes } == 0)
        try await executor.disconnect(owner: owner)
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) { try await executor.verifyNativeLimit(80, for: owner) }
        let readOnly = ChargeCommandExecutor()
        try await readOnly.start()
        await #expect(throws: ChargeCommandExecutor.Failure.unsupported) {
            try await readOnly.verifyNativeLimit(80, for: readOnly.beginSession())
        }
    }

    @Test func wireRejectsInventedRestorationAndUnadvertisedReports() throws {
        let before = NativeChargeLimit.Snapshot(availableLimits: [80, 85], configuredLimit: 85, enabled: true)
        var status = HelperStatus.current
        status.nativeVerificationAvailable = true
        status.nativeVerification = .init(target: 80, before: before, applied: before, after: before, outcome: .restored)
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.nativeVerification?.outcome = .failedRestored
        #expect(try status.validated() == status)
        status.controlState = .restorationRequired
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.nativeVerification?.outcome = .restorationRequired
        #expect(try status.validated() == status)
        status.nativeVerificationAvailable = nil
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        #expect(HelperOperations.live.requiresRemovalAcknowledgement == true)
    }

    @Test(arguments: [["app"], ["app", "--verify-native-limit"], ["app", "--verify-native-limit", "50"],
                     ["app", "--verify-native-limit", "080"], ["app", "--verify-native-limit", "80", "extra"]])
    func malformedCLIArgumentsFailBeforeAnyServiceCall(arguments: [String]) {
        #expect(throws: NativeLimitVerificationCommand.Failure.invalidArguments) { try NativeLimitVerificationCommand.target(in: arguments) }
    }

    @Test func CLIHandshakeNeverCallsAnOldHelperOrRetriesFailedWrites() async throws {
        await #expect(throws: NativeLimitVerificationCommand.Failure.helperUpdateRequired) {
            try await NativeLimitVerificationCommand.collect(target: 80, requirement: "unused", status: { _ in .current }, verify: { _, _ in
                Issue.record("Old helper must not receive the selector")
                return .current
            })
        }
        let calls = Mutex(0)
        await #expect(throws: HelperConnectionError.timedOut) {
            try await NativeLimitVerificationCommand.collect(target: 80, requirement: "unused", status: { _ in
                var status = HelperStatus.current; status.nativeVerificationAvailable = true; return status
            }, verify: { _, _ in calls.withLock { $0 += 1 }; throw HelperConnectionError.timedOut })
        }
        #expect(calls.withLock { $0 } == 1)
        #expect(try NativeLimitVerificationCommand.target(in: ["app", "--verify-native-limit", "80"]) == 80)
    }
}
