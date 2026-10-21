import Foundation
import Observation

/// A system preference, not a charging policy. macOS owns enforcement after Monny quits.
@Observable
final class ChargeLimitController {
    private(set) var snapshot: NativeChargeLimit.Snapshot?
    private(set) var isBusy = false
    private(set) var failed = false
    private let store: NativeChargeLimitStore

    init(store: NativeChargeLimitStore = NativeChargeLimitStore()) { self.store = store }

    func refresh() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        snapshot = await store.read()
    }

    func set(limit: Int, enabled: Bool) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            snapshot = try await store.set(limit: limit, enabled: enabled)
            failed = false
        } catch {
            snapshot = await store.read()
            failed = true
        }
    }
}

/// Serializes synchronous private APIs off the main actor. No launch/wake setter or recurring control loop.
actor NativeChargeLimitStore {
    struct Operations: Sendable {
        var read: @Sendable () -> NativeChargeLimit.Snapshot?
        var setLimit: @Sendable (Int) -> Bool
        var setEnabled: @Sendable (Bool) -> Bool
        static let live = Self(read: {
            guard #available(macOS 26.4, *) else { return nil }
            guard case let .available(value) = NativeChargeLimitReader.decode(MonnyReadNativeChargeLimit()) else { return nil }
            return value
        }, setLimit: { MonnySetNativeChargeLimit(UInt8($0)) == .available },
           setEnabled: { MonnySetNativeChargeLimitEnabled($0) == .available })
    }
    enum Failure: Error { case unavailable, invalidTarget, unconfirmed }
    private let operations: Operations
    init(operations: Operations = .live) { self.operations = operations }

    func read() -> NativeChargeLimit.Snapshot? { operations.read().flatMap { $0.isValid ? $0 : nil } }

    func set(limit: Int, enabled: Bool) throws -> NativeChargeLimit.Snapshot {
        try Task.checkCancellation()
        guard let before = read() else { throw Failure.unavailable }
        guard before.availableLimits.contains(limit) else { throw Failure.invalidTarget }
        // Re-enabling MCL can reset its target. Enable first, then set the requested target.
        if before.enabled != enabled {
            guard operations.setEnabled(enabled) else { throw Failure.unconfirmed }
        }
        if enabled, before.configuredLimit != limit || !before.enabled {
            guard operations.setLimit(limit) else { throw Failure.unconfirmed }
        }
        guard let after = read(), after.enabled == enabled,
              !enabled || after.configuredLimit == limit else { throw Failure.unconfirmed }
        return after
    }
}
