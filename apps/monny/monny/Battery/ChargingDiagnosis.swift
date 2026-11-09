import Foundation

/// Evidence-based guidance, never a diagnosis of a cable or an inferred macOS policy.
nonisolated enum ChargingDiagnosis: Equatable {
    case draining, charging, limited, connected, unavailable

    init(battery: BatteryReading, limit: Int?) {
        guard let watts = battery.batteryPower, watts.isFinite else {
            self = .unavailable
            return
        }
        if watts <= -1 {
            self = .draining
        } else if battery.state == .charging {
            self = .charging
        } else if let limit, battery.level >= Double(limit) / 100 {
            self = .limited
        } else {
            self = .connected
        }
    }

    var title: String {
        switch self {
        case .draining: String(localized: "Battery is draining on power")
        case .charging: String(localized: "Battery is charging")
        case .limited: String(localized: "Charge limit reached")
        case .connected: String(localized: "Connected, not charging")
        case .unavailable: String(localized: "Power readings unavailable")
        }
    }

    var explanation: String {
        switch self {
        case .draining: String(localized: "Your Mac is using battery power while connected. Try connecting the charger directly.")
        case .charging: String(localized: "Power is flowing into the battery. Charging speed can change as the battery fills.")
        case .limited: String(localized: "Your battery is at the set limit. macOS manages when charging resumes.")
        case .connected: String(localized: "macOS is not charging the battery. Monny cannot confirm why. Check the power connection.")
        case .unavailable: String(localized: "Monny cannot read battery power. Check Battery Settings for the system charging status.")
        }
    }
}
