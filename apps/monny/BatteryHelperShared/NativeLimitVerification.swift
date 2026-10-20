import Foundation

/// One explicit temporary setting check, not proof of physical enforcement.
nonisolated struct NativeLimitVerification: Codable, Sendable, Equatable {
    enum Outcome: String, Codable, Sendable {
        case restored, failedRestored, unavailable, externalChange, restorationRequired
    }
    var target: Int
    var before: NativeChargeLimit.Snapshot?
    var applied: NativeChargeLimit.Snapshot?
    var after: NativeChargeLimit.Snapshot?
    var outcome: Outcome

    var isValid: Bool {
        guard (80...100).contains(target),
              [before, applied, after].allSatisfy({ $0?.isValid ?? true }) else { return false }
        switch outcome {
        case .restored:
            return sameOriginal && applied?.configuredLimit == target && applied?.enabled == true
        case .failedRestored: return sameOriginal
        case .externalChange: return before != nil && after != nil
        case .restorationRequired, .unavailable: return true
        }
    }

    private var sameOriginal: Bool {
        guard let before, let after else { return false }
        return before.configuredLimit == after.configuredLimit && before.enabled == after.enabled
    }
}
