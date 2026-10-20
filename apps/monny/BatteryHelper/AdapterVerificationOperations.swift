import Foundation
import IOKit.ps

/// Fixed helper hardware operations; full physical-mode acquisition still needs an independent provider.
nonisolated enum AdapterVerificationOperations {
    /// The future serialized executor must supply current ownership and independently verified cable evidence.
    /// No default physical-presence provider: source selection/adapter details alone cannot establish it.
    static func make(physicalAdapterConnected: @escaping @Sendable () throws -> Bool?,
                     nativeSessionActive: @escaping @Sendable () -> Bool) -> AdapterVerificationTransaction.Operations {
        .init(readCHIE: {
            guard let connection = SMCConnection() else { throw AdapterVerificationTransaction.Failure.unavailable }
            return connection.inspect("CHIE")
        }, readEnvironment: {
            let clock = ContinuousClock()
            let start = clock.now
            guard case let .available(native) = NativeChargeLimitReader.decode(MonnyReadNativeChargeLimit()),
                  let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
                  let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
                throw AdapterVerificationTransaction.Failure.unavailable
            }
            let batteries = sources.compactMap {
                IOPSGetPowerSourceDescription(info, $0)?.takeUnretainedValue() as? [String: Any]
            }.filter { $0[kIOPSTypeKey] as? String == kIOPSInternalBatteryType }
            guard batteries.count == 1, let battery = batteries.first else {
                throw AdapterVerificationTransaction.Failure.invalidObservation
            }
            let observation = try AdapterPowerObservation.decode(battery)
            let physical = try physicalAdapterConnected()
            return try observation.environment(nativeLimit: native, nativeSessionActive: nativeSessionActive(),
                                               physicalAdapterConnected: physical, age: start.duration(to: clock.now))
        }, setAdapterIsolated: { isolated in
            // Local connection ownership avoids sharing a mutable IOKit/cache handle across closures/tasks.
            guard let connection = SMCConnection() else { throw AdapterVerificationTransaction.Failure.unavailable }
            try connection.setAdapterIsolated(isolated)
        })
    }
}
