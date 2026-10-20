import Foundation

/// Explicit helper diagnostic only. The private synchronous getters never run on the main actor.
nonisolated enum NativeChargeLimitReader {
    @concurrent static func read() async -> NativeChargeLimit {
        decode(MonnyReadNativeChargeLimit())
    }

    /// Shared pure validation for explicit diagnostics and future fresh transaction reads.
    static func decode(_ raw: MonnyNativeLimitSnapshot) -> NativeChargeLimit {
        switch raw.status {
        case .available:
            guard raw.enabled <= 1, (1...21).contains(Int(raw.count)) else { return .unavailable(.invalidReply) }
            let limits = withUnsafeBytes(of: raw.limits) { Array($0.prefix(Int(raw.count))).map(Int.init) }
            let snapshot = NativeChargeLimit.Snapshot(availableLimits: limits.sorted(),
                                                      configuredLimit: Int(raw.configuredLimit), enabled: raw.enabled == 1)
            return snapshot.isValid ? .available(snapshot) : .unavailable(.invalidReply)
        case .frameworkUnavailable: return .unavailable(.frameworkUnavailable)
        case .interfaceUnavailable: return .unavailable(.interfaceUnavailable)
        case .unsupported: return .unavailable(.unsupported)
        case .queryFailed: return .unavailable(.queryFailed)
        default: return .unavailable(.invalidReply)
        }
    }
}
