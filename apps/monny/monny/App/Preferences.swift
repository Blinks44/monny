import AppKit

/// `UserDefaults` keys and choices behind Settings. Views read them with `@AppStorage`.
enum PreferenceKey {
    static let refreshInterval = "refreshInterval"
    static let temperatureUnit = "temperatureUnit"
    static let appearance = "appearance"
    static let showsAlertBadge = "showsAlertBadge"
    static let defaultChargeLimit = "defaultChargeLimit"
    static let sailingRange = "sailingRange"
    static let heatProtectionThreshold = "heatProtectionThreshold"
    static let notifyChargeLimit = "notifyChargeLimit"
    static let notifyHot = "notifyHot"
    static let notifyCalibration = "notifyCalibration"
    static let notifyLowBattery = "notifyLowBattery"
    static let notifyMemoryPressure = "notifyMemoryPressure"
    static let historyRange = "historyRange"
}

enum TemperatureUnit: String, CaseIterable {
    case celsius, fahrenheit
}

enum AppearancePreference: String, CaseIterable {
    case system, light, dark

    var appearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

enum HistoryRange: String, CaseIterable {
    case minute, hour, day, week
}
