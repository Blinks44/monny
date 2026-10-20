import Foundation
import IOKit
import IOKit.ps

/// Explicit local evidence only. No physical-presence verdict or charging capability is inferred.
nonisolated struct AdapterPowerDiagnostics: Codable, Sendable, Equatable {
    enum Availability: String, Codable, Sendable { case available, unavailable, notFound, ambiguous, invalid }
    enum BooleanReading: String, Codable, Sendable { case yes, no, missing, invalid }
    enum DictionaryReading: String, Codable, Sendable { case populated, empty, missing, invalid, unavailable }
    enum Source: String, Codable, Sendable { case adapter, battery, unknown }
    enum Support: String, Codable, Sendable { case unverified }

    struct PowerSource: Codable, Sendable, Equatable {
        var availability: Availability
        var source = Source.unknown
        var isCharging: Bool?
    }

    struct SmartBattery: Codable, Sendable, Equatable {
        var availability: Availability
        var externalConnected = BooleanReading.missing
        var rawExternalConnected = BooleanReading.missing
        var externalChargeCapable = BooleanReading.missing
        var isCharging = BooleanReading.missing
        var batteryInstalled = BooleanReading.missing
        var adapterDetails = DictionaryReading.unavailable
    }

    var formatVersion = 1
    var appBuild: String
    var physicalAdapterSupport = Support.unverified
    var powerSource: PowerSource
    var smartBattery: SmartBattery
    /// nil from the public API means either absent or a failed query, never proof of unplugging.
    var publicAdapterDetails: DictionaryReading
    /// Time spent acquiring this report, not the age of the driver's underlying telemetry.
    var acquisitionMilliseconds: Double = 0

    /// Read once on the concurrent executor, without opening AppleSMC, XPC or SMAppService.
    @concurrent static func read() async -> Self {
        let clock = ContinuousClock()
        let start = clock.now
        let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = info.flatMap { IOPSCopyPowerSourcesList($0)?.takeRetainedValue() as? [CFTypeRef] }
        let descriptions = sources.flatMap { sources -> [[String: Any]]? in
            guard let info else { return nil }
            var descriptions: [[String: Any]] = []
            for source in sources {
                guard let value = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else {
                    return nil
                }
                descriptions.append(value)
            }
            return descriptions
        }
        let (registry, registryAvailability) = readSmartBattery()
        let adapter = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any]
        var report = decode(powerSources: descriptions, smartBattery: registry,
                            registryAvailability: registryAvailability, publicAdapter: adapter,
                            appBuild: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown")
        let elapsed = start.duration(to: clock.now).components
        report.acquisitionMilliseconds = Double(elapsed.seconds) * 1_000 + Double(elapsed.attoseconds) / 1e15
        return report
    }

    /// Project a fixed allowlist; raw dictionaries, adapter identities and serials never leave this method.
    static func decode(powerSources: [[String: Any]]?, smartBattery: [String: Any]?,
                       registryAvailability: Availability, publicAdapter: [String: Any]?, appBuild: String) -> Self {
        var power = PowerSource(availability: .unavailable)
        if let powerSources {
            let batteries = powerSources.filter { $0[kIOPSTypeKey] as? String == kIOPSInternalBatteryType }
            power.availability = batteries.isEmpty ? .notFound : .ambiguous
            if batteries.count == 1, let battery = batteries.first {
                if let reading = try? AdapterPowerObservation.decode(battery) {
                    power.availability = .available
                    power.source = reading.source == .adapter ? .adapter : .battery
                    power.isCharging = reading.isCharging
                } else { power.availability = .invalid }
            }
        }
        var registry = SmartBattery(availability: registryAvailability)
        if registryAvailability == .available, let smartBattery {
            registry.externalConnected = boolean(smartBattery["ExternalConnected"])
            registry.rawExternalConnected = boolean(smartBattery["AppleRawExternalConnected"])
            registry.externalChargeCapable = boolean(smartBattery["ExternalChargeCapable"])
            registry.isCharging = boolean(smartBattery["IsCharging"])
            registry.batteryInstalled = boolean(smartBattery["BatteryInstalled"])
            registry.adapterDetails = dictionary(smartBattery["AdapterDetails"])
        } else if registryAvailability == .available { registry.availability = .invalid }
        return Self(appBuild: appBuild, powerSource: power, smartBattery: registry,
                    publicAdapterDetails: publicAdapter.map { $0.isEmpty ? .empty : .populated } ?? .unavailable)
    }

    private static func boolean(_ value: Any?) -> BooleanReading {
        guard let value else { return .missing }
        guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { return .invalid }
        return number.boolValue ? .yes : .no
    }

    private static func dictionary(_ value: Any?) -> DictionaryReading {
        guard let value else { return .missing }
        guard let dictionary = value as? [String: Any] else { return .invalid }
        return dictionary.isEmpty ? .empty : .populated
    }

    private static func readSmartBattery() -> ([String: Any]?, Availability) {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"), &iterator) == KERN_SUCCESS else {
            return (nil, .unavailable)
        }
        defer { IOObjectRelease(iterator) }
        let service = IOIteratorNext(iterator)
        guard service != 0 else { return (nil, .notFound) }
        defer { IOObjectRelease(service) }
        let second = IOIteratorNext(iterator)
        if second != 0 {
            IOObjectRelease(second)
            return (nil, .ambiguous)
        }
        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let values = properties?.takeRetainedValue() as? [String: Any] else { return (nil, .unavailable) }
        return (values, .available)
    }
}
