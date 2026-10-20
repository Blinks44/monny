import Foundation
import IOKit
import IOKit.ps
import IOKit.pwr_mgt

/// Fixed read-only projection for the explicit pulse. Never a physical-cable provider.
nonisolated enum AdapterBytePulseReader {
    static func read(phase: AdapterBytePulseReport.Phase,
                     nativeLimit: () throws -> NativeChargeLimit.Snapshot) throws -> AdapterBytePulseReport.Sample {
        let clock = ContinuousClock()
        let start = clock.now
        // PowerUI's private getter must never run while CHIE is isolated.
        let native = try nativeSnapshot(for: phase, read: nativeLimit)
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            throw AdapterVerificationTransaction.Failure.unavailable
        }
        let batteries = sources.compactMap {
            IOPSGetPowerSourceDescription(info, $0)?.takeUnretainedValue() as? [String: Any]
        }.filter { $0[kIOPSTypeKey] as? String == kIOPSInternalBatteryType }
        guard batteries.count == 1, let battery = batteries.first else {
            throw AdapterVerificationTransaction.Failure.invalidObservation
        }
        let power = try AdapterPowerObservation.decode(battery, allowsUnknownSource: phase == .during)
        let raw = property(service: "AppleSmartBattery", key: "AppleRawExternalConnected")
        let external = property(service: "AppleSmartBattery", key: "ExternalConnected")
        let lid = property(service: "IOPMrootDomain", key: kAppleClamshellStateKey)
        return .init(reading: .init(nativeLimit: native,
            // Exclusive admission is enforced by the serialized executor, not a registry inference.
            nativeSessionActive: false, source: power.source, isCharging: power.isCharging, level: power.level,
            rawExternalConnected: raw, externalConnected: external, isLidClosed: lid),
            age: start.duration(to: clock.now))
    }

    static func nativeSnapshot(for phase: AdapterBytePulseReport.Phase,
                               read: () throws -> NativeChargeLimit.Snapshot) throws -> NativeChargeLimit.Snapshot? {
        phase == .during ? nil : try read()
    }

    static func boolean(_ value: Any?) -> Bool? {
        guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { return nil }
        return number.boolValue
    }

    private static func property(service name: String, key: String) -> Bool? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching(name), &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }
        let service = IOIteratorNext(iterator)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        let second = IOIteratorNext(iterator)
        guard second == 0 else { IOObjectRelease(second); return nil }
        return boolean(IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue())
    }
}
