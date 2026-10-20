import Foundation

/// A byte round trip for mechanism research, never verified adapter isolation or a product mode.
nonisolated struct AdapterBytePulseReport: Codable, Sendable, Equatable {
    enum Phase: Sendable { case before, during, after }
    enum Outcome: String, Codable, Sendable {
        case byteRoundTripRestored, failedRestored, unavailable, restorationRequired
    }
    struct Reading: Codable, Sendable, Equatable {
        /// During isolation this may be absent: do not call a private native getter merely to fill the report.
        var nativeLimit: NativeChargeLimit.Snapshot?
        var nativeSessionActive: Bool
        var source: AdapterVerificationTransaction.Source
        var isCharging: Bool
        var level: Double
        var rawExternalConnected: Bool?
        var externalConnected: Bool?
        var isLidClosed: Bool?

        var isValid: Bool {
            (nativeLimit?.isValid ?? true) && level.isFinite && (0...1).contains(level)
        }
        var admitsPulse: Bool {
            isValid && nativeLimit != nil && nativeSessionActive == false && source == .adapter && level >= 0.3
                && rawExternalConnected == true && isLidClosed == false
        }
    }
    /// Acquisition age remains monotonic and local; a query interval is not firmware publication age.
    struct Sample: Sendable {
        var reading: Reading
        var age: Duration = .zero
        var isFresh: Bool { age >= .zero && age <= AdapterVerificationTransaction.maximumReadingAge }
    }
    var controlSupport = ChargeCapabilityProbe.ControlSupport.unverified
    var before: Reading?
    var during: Reading?
    var after: Reading?
    var attemptedByte: UInt8?
    var appliedByte: UInt8?
    var restoredByte: UInt8?
    var outcome: Outcome

    var isValid: Bool {
        guard [before, during, after].allSatisfy({ $0?.isValid ?? true }),
              attemptedByte == nil || attemptedByte == 8,
              appliedByte == nil || (appliedByte == 8 && attemptedByte == 8),
              restoredByte == nil || restoredByte == 0 else { return false }
        switch outcome {
        case .byteRoundTripRestored:
            guard let before, let during, let after else { return false }
            return before.admitsPulse && appliedByte == 8 && restoredByte == 0
                && (during.nativeLimit == nil || before.nativeLimit == during.nativeLimit)
                && before.nativeLimit == after.nativeLimit
                && during.nativeSessionActive == false && after.nativeSessionActive == false
        case .failedRestored: return before?.admitsPulse == true && restoredByte == 0
        case .unavailable:
            return before == nil && during == nil && after == nil
                && attemptedByte == nil && appliedByte == nil && restoredByte == nil
        case .restorationRequired: return restoredByte == nil && after == nil
        }
    }
}
