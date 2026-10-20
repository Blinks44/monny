import Foundation
import Darwin
import Synchronization
import Testing
@testable import monny

private nonisolated final class RecoveryFixture: Sendable {
    struct Storage: Sendable {
        var snapshot = NativeChargeLimit.Snapshot(availableLimits: [80, 85, 90, 95, 100], configuredLimit: 85, enabled: false)
        var writes = 0
    }
    let storage = Mutex(Storage())
    var operations: NativeChargeLimitTransaction.Operations {
        .init(read: { self.storage.withLock { $0.snapshot } },
              setLimit: { limit in self.storage.withLock { $0.snapshot.configuredLimit = limit; $0.writes += 1 } },
              setEnabled: { enabled in self.storage.withLock { $0.snapshot.enabled = enabled; $0.writes += 1 } })
    }
}

/// Each test owns its temporary private directory; no production paths or hardware are used.
struct NativeChargeLimitJournalTests {
    let directory: URL
    init() throws {
        directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
    }

    private func cleanup() { try? FileManager.default.removeItem(at: directory) }

    @Test func fileCheckpointRestoresOriginalAfterReconstructionWithoutReplayingTarget() throws {
        defer { cleanup() }
        let file = try NativeChargeLimitFileJournal(privateDirectory: directory)
        let fixture = RecoveryFixture()
        var first = try NativeChargeLimitTransaction(operations: fixture.operations, journal: file.journal)
        try first.apply(limit: 80)
        try first.apply(limit: 90)
        let originalWrites = fixture.storage.withLock { $0.writes }
        var restarted = try NativeChargeLimitTransaction(operations: fixture.operations,
            journal: NativeChargeLimitFileJournal(privateDirectory: directory).journal)
        #expect(restarted.state == .restorationRequired)
        #expect(throws: NativeChargeLimitTransaction.Failure.restorationRequired) { try restarted.apply(limit: 95) }
        #expect(fixture.storage.withLock { $0.writes } == originalWrites)
        try restarted.restore()
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(fixture.storage.withLock { $0.snapshot.enabled } == false)
        #expect(try file.journal.load() == nil)
        #expect(try NativeChargeLimitTransaction(operations: fixture.operations, journal: file.journal).state == .idle)
    }

    @Test(arguments: [false, true])
    func checkpointCoversCrashBeforeAndAfterSetterEffect(afterEffect: Bool) throws {
        defer { cleanup() }
        let file = try NativeChargeLimitFileJournal(privateDirectory: directory)
        let fixture = RecoveryFixture()
        // This is the record persisted before the first setter: either pair can be observed on restart.
        try file.journal.save(Data(#"{"version":1,"original":{"limit":85,"enabled":false},"expected":{"limit":85,"enabled":false},"attempted":{"limit":80,"enabled":false}}"#.utf8))
        if afterEffect { fixture.storage.withLock { $0.snapshot.configuredLimit = 80 } }
        var restarted = try NativeChargeLimitTransaction(operations: fixture.operations, journal: file.journal)
        try restarted.restore()
        #expect(restarted.state == .idle)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(fixture.storage.withLock { $0.snapshot.enabled } == false)
        #expect(try file.journal.load() == nil)
    }

    @Test func failedCheckpointPreventsTheFirstSetter() throws {
        defer { cleanup() }
        let fixture = RecoveryFixture()
        let journal = NativeChargeLimitJournal(load: { nil }, save: { _ in throw CocoaError(.fileWriteOutOfSpace) }, clear: {})
        var transaction = try NativeChargeLimitTransaction(operations: fixture.operations, journal: journal)
        #expect(throws: NativeChargeLimitTransaction.Failure.journalFailed) { try transaction.apply(limit: 80) }
        #expect(fixture.storage.withLock { $0.writes } == 0)
        #expect(transaction.state == .idle)
    }

    @Test func failedJournalRemovalBlocksNewTargetsAndRetrySurvivesRestart() throws {
        defer { cleanup() }
        let file = try NativeChargeLimitFileJournal(privateDirectory: directory)
        let base = file.journal
        let fixture = RecoveryFixture()
        let journal = NativeChargeLimitJournal(load: base.load, save: base.save,
            clear: { throw CocoaError(.fileWriteNoPermission) })
        var first = try NativeChargeLimitTransaction(operations: fixture.operations, journal: journal)
        try first.apply(limit: 80)
        #expect(throws: NativeChargeLimitTransaction.Failure.restorationFailed) { try first.restore() }
        #expect(first.state == .restorationRequired)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(try base.load() != nil)
        var restarted = try NativeChargeLimitTransaction(operations: fixture.operations, journal: base)
        let writes = fixture.storage.withLock { $0.writes }
        try restarted.restore()
        #expect(fixture.storage.withLock { $0.writes } == writes)
        #expect(try base.load() == nil)
    }

    @Test func externalChangeOnRestartIsPreservedAndClearsTheJournal() throws {
        defer { cleanup() }
        let file = try NativeChargeLimitFileJournal(privateDirectory: directory)
        let fixture = RecoveryFixture()
        var first = try NativeChargeLimitTransaction(operations: fixture.operations, journal: file.journal)
        try first.apply(limit: 80)
        fixture.storage.withLock { $0.snapshot.configuredLimit = 95 }
        let writes = fixture.storage.withLock { $0.writes }
        var restarted = try NativeChargeLimitTransaction(operations: fixture.operations, journal: file.journal)
        #expect(throws: NativeChargeLimitTransaction.Failure.externalChange) { try restarted.restore() }
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 95)
        #expect(fixture.storage.withLock { $0.writes } == writes)
        #expect(try file.journal.load() == nil)
    }

    @Test(arguments: ["garbage", "{}", #"{"version":2,"original":{"limit":85,"enabled":false},"expected":{"limit":80,"enabled":true}}"#,
                     #"{"version":1,"original":{"limit":50,"enabled":false},"expected":{"limit":80,"enabled":true}}"#,
                     #"{"version":1,"original":{"limit":85,"enabled":false},"expected":{"limit":85,"enabled":false},"attempted":{"limit":80,"enabled":true}}"#])
    func corruptAndUnknownRecordsCannotStartAWriter(json: String) throws {
        defer { cleanup() }
        let file = try NativeChargeLimitFileJournal(privateDirectory: directory)
        let fixture = RecoveryFixture()
        try file.journal.save(Data(json.utf8))
        #expect(throws: NativeChargeLimitTransaction.Failure.invalidJournal) {
            try NativeChargeLimitTransaction(operations: fixture.operations, journal: file.journal)
        }
        #expect(fixture.storage.withLock { $0.writes } == 0)
        #expect(try file.journal.load() != nil)
    }

    @Test func missingAndOversizedRecordsAndSymlinksAreHandledWithoutFollowingTargets() throws {
        defer { cleanup() }
        let file = try NativeChargeLimitFileJournal(privateDirectory: directory)
        #expect(try file.journal.load() == nil)
        #expect(throws: (any Error).self) { try file.journal.save(Data(repeating: 0, count: 4097)) }
        let target = directory.appending(path: "unrelated")
        try Data("preserved".utf8).write(to: target)
        let link = directory.appending(path: "native-charge-recovery.json")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        #expect(throws: (any Error).self) { try file.journal.load() }
        try file.journal.save(Data("replacement".utf8))
        #expect(try Data(contentsOf: target) == Data("preserved".utf8))
        #expect(try file.journal.load() == Data("replacement".utf8))
        try file.journal.clear()
        #expect(try file.journal.load() == nil)
    }

    @Test func failedCheckpointOnUpdateCannotWriteTheNewTargetOrLoseTheOriginal() throws {
        defer { cleanup() }
        let file = try NativeChargeLimitFileJournal(privateDirectory: directory)
        let base = file.journal
        let failing = Mutex(false)
        let fixture = RecoveryFixture()
        let journal = NativeChargeLimitJournal(load: base.load, save: { data in
            if failing.withLock({ $0 }) { throw CocoaError(.fileWriteOutOfSpace) }
            try base.save(data)
        }, clear: base.clear)
        var transaction = try NativeChargeLimitTransaction(operations: fixture.operations, journal: journal)
        try transaction.apply(limit: 80)
        let writes = fixture.storage.withLock { $0.writes }
        failing.withLock { $0 = true }
        #expect(throws: NativeChargeLimitTransaction.Failure.restorationFailed) { try transaction.apply(limit: 90) }
        #expect(transaction.state == .restorationRequired)
        #expect(fixture.storage.withLock { $0.writes } == writes)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 80)
        var restarted = try NativeChargeLimitTransaction(operations: fixture.operations, journal: base)
        try restarted.restore()
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(fixture.storage.withLock { $0.snapshot.enabled } == false)
        #expect(try base.load() == nil)
    }

    @Test(arguments: [0, 4097])
    func invalidFileSizeIsRejectedBeforeDecoding(size: Int) throws {
        defer { cleanup() }
        let file = try NativeChargeLimitFileJournal(privateDirectory: directory)
        let url = directory.appending(path: "native-charge-recovery.json")
        try Data(repeating: 0, count: size).write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        #expect(throws: (any Error).self) { try file.journal.load() }
    }

    @Test func unreadableJournalCannotBeTreatedAsMissing() throws {
        defer { cleanup() }
        let fixture = RecoveryFixture()
        let journal = NativeChargeLimitJournal(load: { throw CocoaError(.fileReadNoPermission) },
            save: { _ in Issue.record("No checkpoint may be written before reading the original journal") }, clear: {})
        #expect(throws: NativeChargeLimitTransaction.Failure.journalFailed) {
            try NativeChargeLimitTransaction(operations: fixture.operations, journal: journal)
        }
        #expect(fixture.storage.withLock { $0.writes } == 0)
    }

    private func makeSystemTree() throws -> URL {
        let support = directory.appending(path: "Library/Application Support", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o755])
        return support
    }

    @Test func fixedJournalCreatesOnlyMonnyAndReopensTheCheckpoint() throws {
        defer { cleanup() }
        let support = try makeSystemTree()
        let first = try NativeChargeLimitFileJournal.inTrustedRoot(directory, owner: geteuid())
        try first.journal.save(Data("checkpoint".utf8))
        let reopened = try NativeChargeLimitFileJournal.inTrustedRoot(directory, owner: geteuid())
        #expect(try reopened.journal.load() == Data("checkpoint".utf8))
        let attributes = try FileManager.default.attributesOfItem(atPath: support.appending(path: "Monny").path)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == 0o700)
        try reopened.journal.clear()
    }

    @Test(arguments: ["Library", "Library/Application Support", "Library/Application Support/Monny"])
    func fixedJournalRejectsSymlinksInEveryComponent(component: String) throws {
        defer { cleanup() }
        _ = try makeSystemTree()
        let path = directory.appending(path: component)
        if FileManager.default.fileExists(atPath: path.path) { try FileManager.default.removeItem(at: path) }
        let destination = directory.appending(path: "outside", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        try FileManager.default.createSymbolicLink(at: path, withDestinationURL: destination)
        #expect(throws: (any Error).self) {
            try NativeChargeLimitFileJournal.inTrustedRoot(directory, owner: geteuid())
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: destination.path).isEmpty)
    }

    @Test(arguments: ["Library", "Library/Application Support", "Library/Application Support/Monny"])
    func fixedJournalRefusesWritableAncestorsAndPublicExistingMonny(component: String) throws {
        defer { cleanup() }
        let support = try makeSystemTree()
        let monny = support.appending(path: "Monny", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: monny, withIntermediateDirectories: false,
                                                attributes: [.posixPermissions: 0o700])
        let path = directory.appending(path: component)
        let mode = component.hasSuffix("Monny") ? 0o755 : 0o777
        try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: path.path)
        #expect(throws: (any Error).self) {
            try NativeChargeLimitFileJournal.inTrustedRoot(directory, owner: geteuid())
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: path.path)
        #expect((attributes[.posixPermissions] as? NSNumber)?.intValue == mode)
    }

    @Test func fixedJournalRejectsWrongOwnershipAndNonRootProductionUse() throws {
        defer { cleanup() }
        _ = try makeSystemTree()
        #expect(throws: (any Error).self) {
            try NativeChargeLimitFileJournal.inTrustedRoot(directory, owner: geteuid() == 0 ? 1 : 0)
        }
        if geteuid() != 0 {
            #expect(throws: POSIXError(.EPERM)) { try NativeChargeLimitFileJournal.systemJournal() }
        }
    }

    @Test func directoryMustBePrivateAndOwned() throws {
        defer { cleanup() }
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
        #expect(throws: (any Error).self) { try NativeChargeLimitFileJournal(privateDirectory: directory) }
    }
}
