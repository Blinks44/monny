import Foundation
import Synchronization
import Testing
@testable import monny

private typealias Transaction = NativeChargeLimitTransaction

/// Entirely injected settings: no PowerUI, helper installation or hardware writes.
private nonisolated final class NativeLimitFixture: Sendable {
    enum Write: Sendable, Equatable { case limit(Int), enabled(Bool) }
    enum Effect: Sendable { case failBefore, failAfter, ignore, external(Transaction.Setting) }
    private enum Failure: Error { case injected }
    struct Storage: Sendable {
        var snapshot: NativeChargeLimit.Snapshot
        var writes: [Write] = []
        var effects: [Int: Effect] = [:]
        var unreadable = false
        var recovery: Data?
    }
    let storage: Mutex<Storage>
    private let onWrite: @Sendable () -> Void

    init(enabled: Bool = true, onWrite: @escaping @Sendable () -> Void = {}) {
        storage = Mutex(Storage(snapshot: .init(availableLimits: [80, 85, 90, 95, 100], configuredLimit: 85, enabled: enabled)))
        self.onWrite = onWrite
    }

    var snapshot: NativeChargeLimit.Snapshot { storage.withLock { $0.snapshot } }
    var writes: [Write] { storage.withLock { $0.writes } }

    private func write(_ command: Write) throws {
        let fails = storage.withLock { state in
            state.writes.append(command)
            let effect = state.effects[state.writes.count]
            if case .failBefore = effect { return true }
            if case .ignore = effect { return false }
            switch command {
            case .limit(let limit): state.snapshot.configuredLimit = limit
            case .enabled(let enabled): state.snapshot.enabled = enabled
            }
            if case .external(let setting) = effect {
                state.snapshot.configuredLimit = setting.limit
                state.snapshot.enabled = setting.enabled
            }
            if case .failAfter = effect { return true }
            return false
        }
        onWrite()
        if fails { throw Failure.injected }
    }

    var journal: NativeChargeLimitJournal {
        .init(load: { self.storage.withLock { $0.recovery } },
              save: { data in self.storage.withLock { $0.recovery = data } },
              clear: { self.storage.withLock { $0.recovery = nil } })
    }

    var operations: Transaction.Operations {
        .init(read: {
            try self.storage.withLock {
                if $0.unreadable { throw Failure.injected }
                return $0.snapshot
            }
        }, setLimit: { try self.write(.limit($0)) }, setEnabled: { try self.write(.enabled($0)) })
    }
}

struct NativeChargeLimitTransactionTests {
    @Test(arguments: [true, false])
    func multipleTargetsRestoreTheOriginalPair(enabled: Bool) throws {
        let fixture = NativeLimitFixture(enabled: enabled)
        let original = fixture.snapshot
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        try transaction.apply(limit: 80)
        try transaction.apply(limit: 90)
        #expect(transaction.state == .active(limit: 90))
        #expect(fixture.snapshot.configuredLimit == 90)
        #expect(fixture.snapshot.enabled == true)
        try transaction.restore()
        #expect(fixture.snapshot == original)
        #expect(transaction.state == .idle)
        if enabled {
            #expect(fixture.writes == [.limit(80), .limit(90), .limit(85)])
        } else {
            #expect(fixture.writes == [.limit(80), .enabled(true), .limit(90), .enabled(false), .limit(85)])
        }
        let count = fixture.writes.count
        try transaction.restore()
        #expect(fixture.writes.count == count)
    }

    @Test func matchingSettingNeedsNoWriteAndDoesNotReplaceOriginalOnRenewal() throws {
        let fixture = NativeLimitFixture()
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        try transaction.apply(limit: 85)
        try transaction.apply(limit: 85)
        try transaction.restore()
        #expect(fixture.writes.isEmpty)
        #expect(transaction.state == .idle)
    }

    @Test(arguments: [50, 79, 87, 101])
    func unadvertisedTargetNeverWrites(limit: Int) throws {
        let fixture = NativeLimitFixture()
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        #expect(throws: Transaction.Failure.unsupportedLimit) { try transaction.apply(limit: limit) }
        #expect(fixture.writes.isEmpty)
        #expect(transaction.state == .idle)
    }

    @Test func malformedAndUnreadableInitialSnapshotsNeverWrite() throws {
        let fixture = NativeLimitFixture()
        fixture.storage.withLock { $0.snapshot.availableLimits = [80, 80, 100] }
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        #expect(throws: Transaction.Failure.invalidSnapshot) { try transaction.apply(limit: 80) }
        fixture.storage.withLock { $0.unreadable = true }
        #expect(throws: Transaction.Failure.unavailable) { try transaction.apply(limit: 80) }
        #expect(fixture.writes.isEmpty)
        #expect(transaction.state == .idle)
    }

    @Test(arguments: [1, 2], [false, true])
    func failedSetterBeforeOrAfterEffectRestoresTheOriginal(step: Int, afterEffect: Bool) throws {
        let fixture = NativeLimitFixture(enabled: false)
        let original = fixture.snapshot
        fixture.storage.withLock { $0.effects[step] = afterEffect ? .failAfter : .failBefore }
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        #expect(throws: Transaction.Failure.operationFailed) { try transaction.apply(limit: 80) }
        #expect(fixture.snapshot == original)
        #expect(transaction.state == .idle)
    }

    @Test func ignoredWriteCannotBeAcknowledgedAsActive() throws {
        let fixture = NativeLimitFixture()
        fixture.storage.withLock { $0.effects[1] = .ignore }
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        #expect(throws: Transaction.Failure.verificationFailed) { try transaction.apply(limit: 80) }
        #expect(fixture.snapshot.configuredLimit == 85)
        #expect(transaction.state == .idle)
    }

    @Test func failedRollbackBlocksNewCommandsAndRetainsOriginalForRetry() throws {
        let fixture = NativeLimitFixture(enabled: false)
        let original = fixture.snapshot
        fixture.storage.withLock { $0.effects = [2: .failAfter, 3: .failBefore] }
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        #expect(throws: Transaction.Failure.restorationFailed) { try transaction.apply(limit: 80) }
        #expect(transaction.state == .restorationRequired)
        let count = fixture.writes.count
        #expect(throws: Transaction.Failure.restorationRequired) { try transaction.apply(limit: 90) }
        #expect(fixture.writes.count == count)
        fixture.storage.withLock { $0.effects = [:] }
        try transaction.restore()
        #expect(fixture.snapshot == original)
        #expect(transaction.state == .idle)
    }

    @Test func unreadableRecoveryRetainsOwnershipRatherThanInventingSuccess() throws {
        let fixture = NativeLimitFixture()
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        try transaction.apply(limit: 80)
        fixture.storage.withLock { $0.unreadable = true }
        #expect(throws: Transaction.Failure.restorationFailed) { try transaction.restore() }
        #expect(transaction.state == .restorationRequired)
        #expect(fixture.writes == [.limit(80)])
        fixture.storage.withLock { $0.unreadable = false }
        try transaction.restore()
        #expect(fixture.snapshot.configuredLimit == 85)
    }

    @Test(arguments: [false, true])
    func externalSettingIsPreservedOnReleaseOrNextCommand(nextCommand: Bool) throws {
        let fixture = NativeLimitFixture()
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        try transaction.apply(limit: 80)
        fixture.storage.withLock { $0.snapshot.configuredLimit = 95; $0.snapshot.enabled = false }
        #expect(throws: Transaction.Failure.externalChange) {
            if nextCommand { try transaction.apply(limit: 90) } else { try transaction.restore() }
        }
        #expect(fixture.snapshot.configuredLimit == 95)
        #expect(fixture.snapshot.enabled == false)
        #expect(fixture.writes == [.limit(80)])
        #expect(transaction.state == .externalChange)
        #expect(throws: Transaction.Failure.externalChange) { try transaction.apply(limit: 80) }
    }

    @Test func unexpectedReadbackStopsWithoutOverwritingTheExternalSetting() throws {
        let fixture = NativeLimitFixture(enabled: false)
        fixture.storage.withLock { $0.effects[1] = .external(.init(limit: 95, enabled: false)) }
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        #expect(throws: Transaction.Failure.externalChange) { try transaction.apply(limit: 80) }
        #expect(fixture.writes == [.limit(80)])
        #expect(fixture.snapshot.configuredLimit == 95)
        #expect(fixture.snapshot.enabled == false)
        #expect(transaction.state == .externalChange)
    }

    @Test(arguments: [false, true])
    func changedCapabilitiesCannotCauseAnUnadvertisedRestorationWrite(enabled: Bool) throws {
        let fixture = NativeLimitFixture(enabled: enabled)
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        try transaction.apply(limit: 80)
        let writesBeforeRecovery = fixture.writes
        fixture.storage.withLock { $0.snapshot.availableLimits = [80, 100] }
        #expect(throws: Transaction.Failure.restorationFailed) { try transaction.restore() }
        #expect(fixture.writes == writesBeforeRecovery)
        #expect(transaction.state == .restorationRequired)
        fixture.storage.withLock { $0.snapshot.availableLimits = [80, 85, 90, 95, 100] }
        try transaction.restore()
        #expect(fixture.snapshot.configuredLimit == 85)
    }

    @Test func invalidRenewalReleasesTheOwnedSetting() throws {
        let fixture = NativeLimitFixture()
        var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
        try transaction.apply(limit: 80)
        #expect(throws: Transaction.Failure.unsupportedLimit) { try transaction.apply(limit: 50) }
        #expect(transaction.state == .idle)
        #expect(fixture.snapshot.configuredLimit == 85)
        #expect(fixture.writes == [.limit(80), .limit(85)])
    }

    @Test func cancellationAfterPartialWriteStillRestores() async throws {
        let fixture = NativeLimitFixture(enabled: false) { withUnsafeCurrentTask { $0?.cancel() } }
        let original = fixture.snapshot
        let request = Task { @MainActor in
            var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
            #expect(throws: Transaction.Failure.cancelled) { try transaction.apply(limit: 80) }
            #expect(transaction.state == .idle)
        }
        try await request.value
        #expect(fixture.snapshot == original)
        #expect(fixture.writes == [.limit(80), .limit(85)])
    }

    @Test func alreadyCancelledCommandReleasesExistingOwnership() async throws {
        let fixture = NativeLimitFixture()
        let request = Task { @MainActor in
            var transaction = try Transaction(operations: fixture.operations, journal: fixture.journal)
            try transaction.apply(limit: 80)
            withUnsafeCurrentTask { $0?.cancel() }
            #expect(throws: Transaction.Failure.cancelled) { try transaction.apply(limit: 90) }
            #expect(transaction.state == .idle)
        }
        try await request.value
        #expect(fixture.snapshot.configuredLimit == 85)
        #expect(fixture.writes == [.limit(80), .limit(85)])
    }
}
