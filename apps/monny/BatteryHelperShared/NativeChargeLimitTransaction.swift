import Foundation

/// An in-memory transaction for a future backend; the helper executor must own and serialize it.
/// Checkpoints enable explicit recovery on process restart; no production operations are provided.
nonisolated struct NativeChargeLimitTransaction: Sendable {
    /// The two settings Monny must return to their original values when relinquishing control.
    struct Setting: Codable, Sendable, Equatable {
        var limit: Int
        var enabled: Bool

        init(limit: Int, enabled: Bool) {
            self.limit = limit
            self.enabled = enabled
        }

        init(_ snapshot: NativeChargeLimit.Snapshot) {
            self.init(limit: snapshot.configuredLimit, enabled: snapshot.enabled)
        }
    }

    /// Active means settings read-back succeeded, never proof of physical charging enforcement.
    enum State: Sendable, Equatable {
        case idle, active(limit: Int), restorationRequired, externalChange
    }

    /// Recovery failure retains the original setting and prevents new commands.
    enum Failure: Error, Sendable, Equatable {
        case unavailable, invalidSnapshot, unsupportedLimit, externalChange
        case verificationFailed, operationFailed, restorationRequired, restorationFailed, cancelled
        case invalidJournal, journalFailed
    }

    /// Fresh synchronous I/O runs in one off-main executor turn, including recovery on failure.
    /// Setters may throw after taking effect; read-back must not use the diagnostic cache.
    struct Operations: Sendable {
        var read: @Sendable () throws -> NativeChargeLimit.Snapshot
        var setLimit: @Sendable (Int) throws -> Void
        var setEnabled: @Sendable (Bool) throws -> Void
    }

    private struct Ownership: Codable, Sendable {
        var version = 1
        let original: Setting
        var expected: Setting
        var attempted: Setting?
    }

    private let journal: NativeChargeLimitJournal
    private let operations: Operations
    private var ownership: Ownership?
    private(set) var state = State.idle

    /// Requires explicit operations; there is no live/default writer.
    init(operations: Operations, journal: NativeChargeLimitJournal) throws {
        self.operations = operations
        self.journal = journal
        let data: Data?
        do { data = try journal.load() } catch { throw Failure.journalFailed }
        if let data {
            guard data.count <= 4096,
                  let saved = try? JSONDecoder().decode(Ownership.self, from: data),
                  saved.version == 1,
                  (80...100).contains(saved.original.limit),
                  (80...100).contains(saved.expected.limit),
                  saved.attempted.map({ (80...100).contains($0.limit)
                      && (($0.limit == saved.expected.limit) != ($0.enabled == saved.expected.enabled)) }) ?? true
            else { throw Failure.invalidJournal }
            ownership = saved
            state = .restorationRequired
        }
    }

    /// Apply only an advertised native limit, preserving the first original setting across updates.
    mutating func apply(limit: Int, expectedInitial: NativeChargeLimit.Snapshot? = nil) throws {
        guard state != .restorationRequired else { throw Failure.restorationRequired }
        guard state != .externalChange else { throw Failure.externalChange }
        do {
            try checkCancellation()
            let snapshot = try (ownership == nil ? read() : readOwned())
            if ownership == nil, let expectedInitial, snapshot != expectedInitial {
                state = .externalChange
                throw Failure.externalChange
            }
            guard snapshot.availableLimits.contains(limit) else { throw Failure.unsupportedLimit }
            if ownership == nil {
                let initial = Setting(snapshot)
                ownership = Ownership(original: initial, expected: initial)
            }
            try move(to: Setting(limit: limit, enabled: true), checkingCancellation: true)
            try checkCancellation()
            state = .active(limit: limit)
        } catch {
            // Even a cancelled request must restore an already owned setting.
            if ownership != nil { try restore() }
            throw (error as? Failure) ?? Failure.operationFailed
        }
    }

    /// Restore only a state attributable to this transaction. A failed recovery remains retryable.
    mutating func restore() throws {
        guard let original = ownership?.original else { return }
        state = .restorationRequired
        do {
            try move(to: original, checkingCancellation: false)
            try clearJournal()
            ownership = nil
            state = .idle
        } catch {
            if state == .externalChange { throw Failure.externalChange }
            throw Failure.restorationFailed
        }
    }

    private func read() throws -> NativeChargeLimit.Snapshot {
        let snapshot: NativeChargeLimit.Snapshot
        do { snapshot = try operations.read() } catch { throw Failure.unavailable }
        guard snapshot.isValid else { throw Failure.invalidSnapshot }
        return snapshot
    }

    /// A throwing setter may have left either its previous or intended value; nothing else is owned.
    private mutating func readOwned() throws -> NativeChargeLimit.Snapshot {
        let snapshot = try read()
        let current = Setting(snapshot)
        guard var owned = ownership else { throw Failure.externalChange }
        guard current == owned.expected || current == owned.attempted else {
            try clearJournal()
            ownership = nil
            state = .externalChange
            throw Failure.externalChange
        }
        owned.expected = current
        owned.attempted = nil
        ownership = owned
        return snapshot
    }

    /// Disable first when restoring a disabled original; set the limit before enabling.
    private mutating func move(to target: Setting, checkingCancellation: Bool) throws {
        let snapshot = try readOwned()
        guard snapshot.availableLimits.contains(target.limit) else { throw Failure.unsupportedLimit }
        var current = Setting(snapshot)
        if !target.enabled && current.enabled {
            current.enabled = false
            try write(current, checkingCancellation: checkingCancellation)
        }
        if current.limit != target.limit {
            current.limit = target.limit
            try write(current, checkingCancellation: checkingCancellation)
        }
        if target.enabled && !current.enabled {
            current.enabled = true
            try write(current, checkingCancellation: checkingCancellation)
        }
    }

    /// Validate immediately before writing and read back immediately afterwards; no optimistic success.
    private mutating func write(_ next: Setting, checkingCancellation: Bool) throws {
        if checkingCancellation { try checkCancellation() }
        let snapshot = try readOwned()
        guard snapshot.availableLimits.contains(next.limit) else { throw Failure.unsupportedLimit }
        ownership?.attempted = next
        state = .restorationRequired
        do { try journal.save(JSONEncoder().encode(ownership)) } catch { throw Failure.journalFailed }
        if snapshot.configuredLimit != next.limit {
            try operations.setLimit(next.limit)
        } else {
            try operations.setEnabled(next.enabled)
        }
        let observed = try readOwned()
        guard Setting(observed) == next else { throw Failure.verificationFailed }
    }

    private func clearJournal() throws {
        do { try journal.clear() } catch { throw Failure.journalFailed }
    }

    private func checkCancellation() throws {
        if Task.isCancelled { throw Failure.cancelled }
    }
}
