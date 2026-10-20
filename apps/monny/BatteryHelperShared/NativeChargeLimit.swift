import Foundation

/// A native setting snapshot, never proof that Monny can write or enforce charging.
nonisolated enum NativeChargeLimit: Codable, Sendable, Equatable {
    enum Failure: String, Codable, Sendable {
        case notProbed, frameworkUnavailable, interfaceUnavailable, unsupported, queryFailed, invalidReply
    }
    struct Snapshot: Codable, Sendable, Equatable {
        var availableLimits: [Int]
        var configuredLimit: Int
        var enabled: Bool

        var isValid: Bool {
            !availableLimits.isEmpty && availableLimits.count <= 21
                && availableLimits == availableLimits.sorted()
                && Set(availableLimits).count == availableLimits.count
                && availableLimits.allSatisfy { (80...100).contains($0) }
                && availableLimits.contains(configuredLimit)
        }
    }

    case available(Snapshot)
    case unavailable(Failure)

    var isValid: Bool {
        switch self {
        case .available(let snapshot): snapshot.isValid
        case .unavailable: true
        }
    }
}
