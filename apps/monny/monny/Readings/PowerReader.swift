import Foundation
import IOKit
import IOKit.ps

nonisolated struct BatteryReading: Sendable, Equatable {
    enum State: Sendable { case charging, onAdapter, onBattery }

    /// 0...1
    var level: Double
    var state: State
    var isFullyCharged: Bool
    var adapterWatts: Int?
    /// macOS's own estimates; `nil` while macOS is still calculating.
    var timeToEmpty: Duration?
    var timeToFull: Duration?
    var cycleCount: Int?
    /// mAh. Full charge capacity is today's, design capacity the new battery's.
    var designCapacity: Int?
    var fullChargeCapacity: Int?
    /// What the whole Mac consumes now, in watts, from the adapter or the battery.
    var systemLoad: Double?
    /// Watts flowing into the battery (positive while charging) or out of it (negative).
    var batteryPower: Double?
}

/// Level, state and estimates from IOPowerSources; cycles and capacities from `AppleSmartBattery`.
/// Battery temperature is no longer readable here on macOS 27 (see research).
nonisolated struct PowerReader {
    func read() -> BatteryReading? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        let battery = sources.lazy
            .compactMap { IOPSGetPowerSourceDescription(info, $0)?.takeUnretainedValue() as? [String: Any] }
            .first { $0[kIOPSTypeKey] as? String == kIOPSInternalBatteryType }
        guard let battery,
              let current = battery[kIOPSCurrentCapacityKey] as? Int,
              let maximum = battery[kIOPSMaxCapacityKey] as? Int, maximum > 0 else { return nil }

        let onAC = battery[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
        let charging = battery[kIOPSIsChargingKey] as? Bool ?? false
        let adapter = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any]
        let registry = Self.smartBattery()
        let telemetry = registry?["PowerTelemetryData"] as? [String: Any]
        let batteryData = registry?["BatteryData"] as? [String: Any]

        return BatteryReading(
            level: Double(current) / Double(maximum),
            state: charging ? .charging : onAC ? .onAdapter : .onBattery,
            isFullyCharged: battery[kIOPSIsChargedKey] as? Bool ?? false,
            adapterWatts: onAC ? adapter?[kIOPSPowerAdapterWattsKey] as? Int : nil,
            timeToEmpty: Self.estimate(battery[kIOPSTimeToEmptyKey]),
            timeToFull: Self.estimate(battery[kIOPSTimeToFullChargeKey]),
            cycleCount: registry?["CycleCount"] as? Int,
            designCapacity: batteryData?["DesignCapacity"] as? Int,
            fullChargeCapacity: (registry?["NominalChargeCapacity"] ?? batteryData?["NominalChargeCapacity"]) as? Int,
            systemLoad: (telemetry?["SystemLoad"] as? NSNumber).map { $0.doubleValue / 1000 },
            batteryPower: Self.batteryPower(voltage: registry?["Voltage"], amperage: registry?["Amperage"]))
    }

    /// Millivolts × milliamps; the battery reports a negative current while it discharges.
    static func batteryPower(voltage: Any?, amperage: Any?) -> Double? {
        guard let voltage = voltage as? Int, let amperage = amperage as? Int, voltage > 0 else { return nil }
        return Double(voltage) * Double(amperage) / 1_000_000
    }

    /// Minutes from IOPowerSources: -1 while calculating, 0 when not applicable.
    static func estimate(_ value: Any?) -> Duration? {
        guard let minutes = value as? Int, minutes > 0, minutes < 65_535 else { return nil }
        return .seconds(minutes * 60)
    }

    private static func smartBattery() -> [String: Any]? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS else { return nil }
        return properties?.takeRetainedValue() as? [String: Any]
    }
}

nonisolated struct BatteryHealth: Sendable, Equatable {
    /// "Maximum Capacity" as System Information shows it, 0...1.
    var maximumCapacity: Double
    /// For example "Good" or "Service Recommended"; shown as macOS reports it.
    var condition: String?
}

/// Battery health exactly as System Information reports it. `system_profiler` is the only
/// unprivileged source of Apple's "Maximum Capacity"; it takes about a second, so it runs rarely.
nonisolated enum BatteryHealthReader {
    /// Runs off the main actor: `system_profiler` blocks for about a second.
    @concurrent static func read() async -> BatteryHealth? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPPowerDataType", "-json"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return parse(data)
    }

    static func parse(_ data: Data) -> BatteryHealth? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = root["SPPowerDataType"] as? [[String: Any]],
              let health = items.lazy.compactMap({ $0["sppower_battery_health_info"] as? [String: Any] }).first,
              let capacity = health["sppower_battery_health_maximum_capacity"] as? String,
              let percent = Double(capacity.filter(\.isNumber)) else { return nil }
        return BatteryHealth(maximumCapacity: percent / 100, condition: health["sppower_battery_health"] as? String)
    }
}
