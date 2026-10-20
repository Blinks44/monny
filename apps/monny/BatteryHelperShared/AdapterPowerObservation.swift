import Foundation
import IOKit.ps

/// Source selection and charging evidence only; neither proves physical cable presence.
nonisolated struct AdapterPowerObservation: Sendable {
    var source: AdapterVerificationTransaction.Source
    var isCharging: Bool
    var level: Double

    /// Strict decoding: missing/unknown data must never become a successful isolation observation.
    static func decode(_ battery: [String: Any], allowsUnknownSource: Bool = false) throws -> Self {
        guard battery[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
              let present = battery[kIOPSIsPresentKey] as? NSNumber,
              CFGetTypeID(present) == CFBooleanGetTypeID(), present.boolValue,
              let charging = battery[kIOPSIsChargingKey] as? NSNumber,
              CFGetTypeID(charging) == CFBooleanGetTypeID(),
              let current = battery[kIOPSCurrentCapacityKey] as? NSNumber,
              let maximum = battery[kIOPSMaxCapacityKey] as? NSNumber,
              CFGetTypeID(current) != CFBooleanGetTypeID(), CFGetTypeID(maximum) != CFBooleanGetTypeID(),
              current.doubleValue.isFinite, maximum.doubleValue.isFinite,
              current.doubleValue.rounded() == current.doubleValue,
              maximum.doubleValue.rounded() == maximum.doubleValue,
              maximum.doubleValue > 0, (0...maximum.doubleValue).contains(current.doubleValue)
        else { throw AdapterVerificationTransaction.Failure.invalidObservation }
        let source: AdapterVerificationTransaction.Source
        switch battery[kIOPSPowerSourceStateKey] as? String {
        case kIOPSACPowerValue: source = .adapter
        case kIOPSBatteryPowerValue: source = .battery
        default:
            guard allowsUnknownSource else { throw AdapterVerificationTransaction.Failure.invalidObservation }
            source = .unknown
        }
        guard source != .battery || charging.boolValue == false else {
            throw AdapterVerificationTransaction.Failure.invalidObservation
        }
        return Self(source: source, isCharging: charging.boolValue, level: current.doubleValue / maximum.doubleValue)
    }

    /// Physical presence must come from independent, freshly acquired evidence, never source selection.
    func environment(nativeLimit: NativeChargeLimit.Snapshot, nativeSessionActive: Bool,
                     physicalAdapterConnected: Bool?, age: Duration) throws -> AdapterVerificationTransaction.Environment {
        guard let physicalAdapterConnected, nativeLimit.isValid,
              age >= .zero, age <= AdapterVerificationTransaction.maximumReadingAge else {
            throw AdapterVerificationTransaction.Failure.invalidObservation
        }
        return .init(nativeLimit: nativeLimit, nativeSessionActive: nativeSessionActive,
                     isAdapterConnected: physicalAdapterConnected, source: source,
                     isCharging: isCharging, level: level, age: age)
    }
}
