import Foundation

/// Per-instance callback evidence, not an electrical reading or a persisted lifecycle guarantee.
nonisolated struct HelperLifecycleDiagnostics: Codable, Sendable, Equatable {
    enum Event: Sendable { case sleep, wake, removal }
    enum Outcome: String, Codable, Sendable {
        case noAdapterRecoveryNeeded, adapterRestored, nativeLimitPreserved, failed
    }
    static let maximumCount = 1_000_000
    var version = 1
    var sleepCount = 0
    var wakeCount = 0
    var removalPreparationCount = 0
    var lastSleep: Outcome?
    var lastWake: Outcome?
    var lastRemovalPreparation: Outcome?

    mutating func record(_ event: Event, outcome: Outcome) {
        switch event {
        case .sleep:
            sleepCount = min(sleepCount + 1, Self.maximumCount)
            lastSleep = outcome
        case .wake:
            wakeCount = min(wakeCount + 1, Self.maximumCount)
            lastWake = outcome
        case .removal:
            removalPreparationCount = min(removalPreparationCount + 1, Self.maximumCount)
            lastRemovalPreparation = outcome
        }
    }

    var isValid: Bool {
        version == 1 && [sleepCount, wakeCount, removalPreparationCount].allSatisfy { (0...Self.maximumCount).contains($0) }
            && (sleepCount == 0) == (lastSleep == nil)
            && (wakeCount == 0) == (lastWake == nil)
            && (removalPreparationCount == 0) == (lastRemovalPreparation == nil)
            && lastRemovalPreparation != .nativeLimitPreserved
    }
}
