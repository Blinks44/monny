import Foundation
import Observation

/// The macOS charge limit as System Settings › Battery shows it. It is a system preference:
/// macOS enforces it and keeps it after Monny quits.
nonisolated struct ChargeLimit: Sendable, Equatable {
    /// The target that means no limit, as in System Settings.
    static let noLimit = 100

    /// The targets macOS offers, for example 80, 85, 90, 95 and 100.
    var available: [Int]
    var limit: Int
    var isEnabled: Bool
    /// Optimized Battery Charging, `nil` when it cannot be read.
    var isOptimized: Bool? = nil

    /// The target as System Settings shows it: 100% while the limit is off.
    var target: Int { isEnabled ? limit : Self.noLimit }

    /// Rejects replies that do not look like the verified interface.
    var isValid: Bool {
        !available.isEmpty && available == available.sorted() && Set(available).count == available.count
            && available.allSatisfy { (50...100).contains($0) } && available.contains(limit)
            && available.last == Self.noLimit
    }

    static var isSupportedOS: Bool {
        if #available(macOS 26.4, *) { true } else { false }
    }
}

/// Shared state of the charge-limit controls in the popover, Battery page, Settings and menu.
@Observable
final class ChargeLimitController {
    /// `nil` before the first read and when this Mac does not offer a charge limit.
    private(set) var setting: ChargeLimit?
    private(set) var hasRead = false
    private(set) var isBusy = false
    /// The last change could not be confirmed by reading the setting back.
    private(set) var failed = false
    private let store: ChargeLimitStore

    /// The target macOS is holding the battery at, `nil` while there is no limit or it is unknown.
    var activeLimit: Int? { setting.flatMap { $0.target < ChargeLimit.noLimit ? $0.target : nil } }

    init(store: ChargeLimitStore = ChargeLimitStore()) { self.store = store }

    func refresh() async {
        guard SystemInfo.hasBattery else { return }
        setting = await store.read()
        hasRead = true
    }

    /// Sets the target; 100% turns the limit off.
    func set(target: Int) async {
        await change { try await $0.set(target: target) }
    }

    func setOptimized(_ isOn: Bool) async {
        await change { try await $0.setOptimized(isOn) }
    }

    private func change(_ write: (ChargeLimitStore) async throws -> ChargeLimit) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            setting = try await write(store)
            failed = false
        } catch {
            setting = await store.read()
            failed = true
        }
        hasRead = true
    }
}

/// Calls the synchronous PowerUI client off the main actor, one call at a time. Only explicit
/// user actions write; launch, wake and opening a view only read.
actor ChargeLimitStore {
    struct Operations: Sendable {
        var read: @Sendable () -> ChargeLimit?
        var setLimit: @Sendable (Int) -> Bool
        var setEnabled: @Sendable (Bool) -> Bool
        var setOptimized: @Sendable (Bool) -> Bool

        static let system = Operations(
            read: {
                guard ChargeLimit.isSupportedOS else { return nil }
                let state = MonnyReadChargeLimit()
                guard state.available else { return nil }
                let limits = withUnsafeBytes(of: state.limits) { $0.prefix(Int(state.count)).map(Int.init) }
                return ChargeLimit(available: limits, limit: Int(state.limit), isEnabled: state.enabled,
                                   isOptimized: state.optimizedKnown ? state.optimized : nil)
            },
            setLimit: { MonnySetChargeLimit(UInt8(clamping: $0)) },
            setEnabled: { MonnySetChargeLimitEnabled($0) },
            setOptimized: { MonnySetOptimizedCharging($0) })
    }

    enum Failure: Error { case unavailable, unconfirmed }

    private let operations: Operations

    init(operations: Operations = .system) { self.operations = operations }

    func read() -> ChargeLimit? { operations.read().flatMap { $0.isValid ? $0 : nil } }

    /// 100% turns the limit off. Any other target turns it on first, because turning it on can
    /// reset the target, and then sets the target. Succeeds only when reading back shows it.
    func set(target: Int) throws -> ChargeLimit {
        guard let before = read(), before.available.contains(target) else { throw Failure.unavailable }
        let enabled = target < ChargeLimit.noLimit
        if before.isEnabled != enabled {
            guard operations.setEnabled(enabled) else { throw Failure.unconfirmed }
        }
        if enabled, !before.isEnabled || before.limit != target {
            guard operations.setLimit(target) else { throw Failure.unconfirmed }
        }
        guard let after = read(), after.target == target else { throw Failure.unconfirmed }
        return after
    }

    func setOptimized(_ isOn: Bool) throws -> ChargeLimit {
        guard let before = read(), let current = before.isOptimized else { throw Failure.unavailable }
        if current != isOn {
            guard operations.setOptimized(isOn) else { throw Failure.unconfirmed }
        }
        guard let after = read(), after.isOptimized == isOn else { throw Failure.unconfirmed }
        return after
    }
}
