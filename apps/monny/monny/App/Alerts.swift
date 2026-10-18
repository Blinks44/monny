import Foundation
import UserNotifications

/// Decides from each snapshot when the Mac needs the user: the menu bar badge and the
/// notifications chosen in Settings. Each alert fires once per episode and re-arms only when the
/// condition has cleared, so a Mac hovering around a threshold does not repeat it.
nonisolated struct AlertMonitor {
    enum Alert: Equatable {
        /// CPU temperature in °C when the SMC reports it.
        case hot(cpuCelsius: Double?)
        case lowBattery(level: Double, timeToEmpty: Duration?)
        case memoryPressure
    }

    /// The level below which "Battery below 20%" fires.
    static let lowBatteryLevel = 0.2

    private(set) var needsAttention = false
    private var isHot = false
    private var isLow = false
    private var isPressured = false

    /// Returns the alerts that started with this snapshot, whatever the user's notification choices.
    mutating func update(with snapshot: Snapshot) -> [Alert] {
        var alerts: [Alert] = []

        // macOS's own thermal state, as the CPU chip: Serious and Critical are "hot".
        let hot = snapshot.thermalState == .serious || snapshot.thermalState == .critical
        if hot, !isHot { alerts.append(.hot(cpuCelsius: snapshot.sensors?.cpu)) }
        isHot = hot

        if let battery = snapshot.battery {
            let low = battery.state == .onBattery && battery.level < Self.lowBatteryLevel
            if low, !isLow { alerts.append(.lowBattery(level: battery.level, timeToEmpty: battery.timeToEmpty)) }
            isLow = low
        }

        // Re-arms only at Normal: pressure often moves between Warning and Critical.
        if let pressure = snapshot.memory?.pressure {
            if pressure != .normal, !isPressured { alerts.append(.memoryPressure) }
            isPressured = pressure != .normal
        }

        needsAttention = hot || snapshot.memory?.pressure == .critical
        return alerts
    }
}

extension AlertMonitor.Alert {
    /// The Settings toggle that allows this notification.
    var preferenceKey: String {
        switch self {
        case .hot: PreferenceKey.notifyHot
        case .lowBattery: PreferenceKey.notifyLowBattery
        case .memoryPressure: PreferenceKey.notifyMemoryPressure
        }
    }

    var title: String {
        switch self {
        case .hot: String(localized: "Mac is running hot")
        case .lowBattery: String(localized: "Battery below 20%")
        case .memoryPressure: String(localized: "Memory pressure is high")
        }
    }

    func body(unit: TemperatureUnit) -> String {
        switch self {
        case .hot(let celsius?):
            String(localized: "CPU is at \(celsius.temperatureText(unit)).")
        case .hot(nil):
            String(localized: "macOS is slowing the Mac down to cool it.")
        case .lowBattery(let level, let time?):
            String(localized: "\(level.percentText) left · about \(time.estimateText). Connect power soon.")
        case .lowBattery(let level, nil):
            String(localized: "\(level.percentText) left. Connect power soon.")
        case .memoryPressure:
            String(localized: "Quit apps you don’t need to free up memory.")
        }
    }
}

/// Posts alerts as user notifications when their Settings toggle is on. Permission is asked the
/// first time a notification is due, not at launch.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func post(_ alerts: [AlertMonitor.Alert]) {
        let defaults = UserDefaults.standard
        let unit = TemperatureUnit(rawValue: defaults.string(forKey: PreferenceKey.temperatureUnit) ?? "") ?? .celsius
        let allowed = alerts.filter { defaults.object(forKey: $0.preferenceKey) as? Bool ?? $0.isOnByDefault }
        guard !allowed.isEmpty else { return }
        let requests = allowed.map { alert in
            let content = UNMutableNotificationContent()
            content.title = alert.title
            content.body = alert.body(unit: unit)
            return UNNotificationRequest(identifier: alert.preferenceKey, content: content, trigger: nil)
        }
        Task { [center] in
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            for request in requests { try? await center.add(request) }
        }
    }

    /// Monny is often frontmost while its dashboard is open; show banners then too.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}

private extension AlertMonitor.Alert {
    /// Matches the `@AppStorage` defaults in Settings.
    var isOnByDefault: Bool {
        switch self {
        case .hot: true
        case .lowBattery, .memoryPressure: false
        }
    }
}
