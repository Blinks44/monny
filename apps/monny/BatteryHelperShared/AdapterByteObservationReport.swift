import Foundation

/// Bounded source observations, never a physical-cable verdict or production capability.
nonisolated struct AdapterByteObservationReport: Codable, Sendable, Equatable {
    static let maximumSamples = 8
    static let observationDuration: Duration = .seconds(2)
    enum ReturnObservation: String, Codable, Sendable {
        case notAttempted, adapterObserved, boundReached, interrupted, unavailable
    }
    static let returnObservationDuration: Duration = .seconds(2)
    var returnObservation = ReturnObservation.notAttempted
    var returnSampleCount = 0
    var byteEvidence: AdapterBytePulseReport
    var sampleCount = 0
    var batterySourceObserved = false

    var isValid: Bool {
        guard (0...Self.maximumSamples).contains(returnSampleCount),
              returnObservation != .notAttempted || returnSampleCount == 0,
              returnSampleCount == 0 || byteEvidence.restoredByte == 0,
              returnObservation != .adapterObserved || (returnSampleCount > 0 && byteEvidence.after?.source == .adapter),
              byteEvidence.isValid, (0...Self.maximumSamples).contains(sampleCount),
              (byteEvidence.during == nil) == (sampleCount == 0) else { return false }
        if batterySourceObserved {
            return byteEvidence.appliedByte == 8 && byteEvidence.during?.source == .battery
                && byteEvidence.during?.isCharging == false && sampleCount > 0
        }
        return byteEvidence.during?.source != .battery || byteEvidence.during?.isCharging != false
    }
    var isSuccessful: Bool {
        returnObservation == .adapterObserved && batterySourceObserved && byteEvidence.outcome == .byteRoundTripRestored
            && byteEvidence.after?.source == .adapter
    }
}
