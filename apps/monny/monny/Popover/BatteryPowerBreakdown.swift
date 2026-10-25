import Foundation

/// Fresh battery-gauge readings for the power panel; missing measurements never become zero.
nonisolated struct BatteryPowerBreakdown {
    let macWatts: Double?
    let chargingWatts: Double?
    let adapterWatts: Double?

    init(battery: BatteryReading?) {
        macWatts = Self.validWatts(battery?.systemLoad)
        adapterWatts = battery?.state == .onBattery ? nil : battery?.adapterWatts.flatMap { $0 > 0 ? Double($0) : nil }
        if battery?.state == .charging {
            chargingWatts = Self.validWatts(battery?.batteryPower)
        } else {
            chargingWatts = battery == nil ? nil : 0
        }
    }

    /// Total in use, including charging. An unknown charging rate makes the total unknown too.
    var totalWatts: Double? {
        guard let macWatts, let chargingWatts else { return nil }
        return Self.validWatts(macWatts + chargingWatts)
    }

    /// Adapter-capacity shares. If readings exceed the rating, fill the track while preserving
    /// their ratio; the actual watts and rating remain visible. Sub-watt charging has no segment.
    var fractions: (mac: Double, battery: Double)? {
        guard let macWatts, let chargingWatts, let adapterWatts, totalWatts != nil else { return nil }
        let visibleCharging = chargingWatts >= 1 ? chargingWatts : 0
        let scale = max(adapterWatts, macWatts + visibleCharging)
        return (macWatts / scale, visibleCharging / scale)
    }

    private static func validWatts(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }
}
