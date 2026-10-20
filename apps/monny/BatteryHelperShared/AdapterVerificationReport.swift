import Foundation

/// Software observations from one bounded attempt. Never a grant of physical control support.
nonisolated struct AdapterVerificationReport: Codable, Sendable, Equatable {
    enum Outcome: String, Codable, Sendable {
        case restoredAfterObservation, failedRestored, unavailable, restorationRequired
    }
    struct Reading: Codable, Sendable, Equatable {
        var nativeLimit: NativeChargeLimit.Snapshot
        var isAdapterConnected: Bool
        var source: AdapterVerificationTransaction.Source
        var isCharging: Bool
        var level: Double

        init(_ environment: AdapterVerificationTransaction.Environment) {
            nativeLimit = environment.nativeLimit
            isAdapterConnected = environment.isAdapterConnected
            source = environment.source
            isCharging = environment.isCharging
            level = environment.level
        }

        var isValid: Bool {
            nativeLimit.isValid && level.isFinite && (0...1).contains(level)
                && source != .unknown
        }
    }
    var before: Reading?
    var during: Reading?
    var after: Reading?
    var restoredByte: UInt8?
    var outcome: Outcome

    /// An independent post-rollback source observation, not inferred from CHIE=0.
    var adapterSourceObservedAfterRestoration: Bool {
        restoredByte == 0 && after?.source == .adapter && after?.isAdapterConnected == true
    }

    var isSuccessful: Bool {
        outcome == .restoredAfterObservation && adapterSourceObservedAfterRestoration
            && before?.nativeLimit == after?.nativeLimit
    }

    var isValid: Bool {
        guard [before, during, after].allSatisfy({ $0?.isValid ?? true }),
              restoredByte == nil || restoredByte == 0 else { return false }
        switch outcome {
        case .restoredAfterObservation:
            guard let before, let during else { return false }
            return restoredByte == 0 && before.source == .adapter && before.isAdapterConnected
                && before.level >= 0.3 && during.source == .battery && during.isCharging == false
                && during.isAdapterConnected && during.level >= 0.3 && before.nativeLimit == during.nativeLimit
        case .failedRestored: return before != nil && restoredByte == 0
        case .unavailable: return before == nil && during == nil && restoredByte == nil && after == nil
        case .restorationRequired: return restoredByte == nil && after == nil
        }
    }
}
