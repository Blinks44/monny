import Foundation
import Observation

/// The macOS charge limit as System Settings › Battery shows it. It is a system preference:
/// macOS enforces it and keeps it after Monny quits.
nonisolated struct ChargeLimit: Sendable, Equatable {
    /// The targets macOS offers, for example 80, 85, 90, 95 and 100.
    var available: [Int]
    var limit: Int
    var isEnabled: Bool

    /// Rejects replies that do not look like the verified interface.
    var isValid: Bool {
        !available.isEmpty && available == available.sorted() && Set(available).count == available.count
            && available.allSatisfy { (50...100).contains($0) } && available.contains(limit)
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

    /// The target macOS is holding the battery at, `nil` while the limit is off or unknown.
    var activeLimit: Int? { setting.flatMap { $0.isEnabled ? $0.limit : nil } }

    init(store: ChargeLimitStore = ChargeLimitStore()) { self.store = store }

    func refresh() async {
        guard SystemInfo.hasBattery else { return }
        setting = await store.read()
        hasRead = true
    }

    func set(limit: Int, enabled: Bool) async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            setting = try await store.set(limit: limit, enabled: enabled)
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

        static let system = Operations(
            read: {
                guard ChargeLimit.isSupportedOS else { return nil }
                let state = MonnyReadChargeLimit()
                guard state.available else { return nil }
                let limits = withUnsafeBytes(of: state.limits) { $0.prefix(Int(state.count)).map(Int.init) }
                return ChargeLimit(available: limits, limit: Int(state.limit), isEnabled: state.enabled)
            },
            setLimit: { MonnySetChargeLimit(UInt8(clamping: $0)) },
            setEnabled: { MonnySetChargeLimitEnabled($0) })
    }

    enum Failure: Error { case unavailable, unconfirmed }

    private let operations: Operations

    init(operations: Operations = .system) { self.operations = operations }

    func read() -> ChargeLimit? { operations.read().flatMap { $0.isValid ? $0 : nil } }

    /// Turning the limit on can reset its target, so it is turned on first and the target set
    /// after. Succeeds only when reading back shows the requested state.
    func set(limit: Int, enabled: Bool) throws -> ChargeLimit {
        guard let before = read(), before.available.contains(limit) else { throw Failure.unavailable }
        if before.isEnabled != enabled {
            guard operations.setEnabled(enabled) else { throw Failure.unconfirmed }
        }
        if enabled, !before.isEnabled || before.limit != limit {
            guard operations.setLimit(limit) else { throw Failure.unconfirmed }
        }
        guard let after = read(), after.isEnabled == enabled, !enabled || after.limit == limit else {
            throw Failure.unconfirmed
        }
        return after
    }
}
