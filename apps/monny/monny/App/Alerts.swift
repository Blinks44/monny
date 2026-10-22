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
        case chargeLimitReached(Int)
        case memoryPressure
        /// One app, helpers included, above `busyAppCPU` for `busyAppDuration`; `pid` is the app's.
        case busyApp(pid: pid_t, name: String)
        /// An AI plan window is running low or used up (`AILowWindows` decides).
        case aiLimitLow(AITool, AIQuotaWindow)
    }

    /// The level below which "Battery below 20%" fires.
    static let lowBatteryLevel = 0.2
    /// "An app keeps the Mac busy": share of one core, as in Activity Monitor, and how long.
    static let busyAppCPU = 0.8
    static let busyAppDuration: TimeInterval = 5 * 60

    private(set) var needsAttention = false
    private var isHot = false
    private var isLow = false
    private var isPressured = false
    private var reachedLimit: Int?
    private var busySince: [pid_t: Date] = [:]
    private var reportedBusyApps: Set<pid_t> = []

    /// Returns the alerts that started with this snapshot, whatever the user's notification choices.
    mutating func update(with snapshot: Snapshot, chargeLimit: Int? = nil, now: Date = .now) -> [Alert] {
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

        // macOS lets the level drift a little below the limit while plugged in, so the alert
        // re-arms only when the Mac is unplugged or the limit changes.
        if chargeLimit == nil || snapshot.battery?.state == .onBattery {
            reachedLimit = nil
        } else if let chargeLimit, let battery = snapshot.battery, reachedLimit != chargeLimit,
                  battery.state == .onAdapter, battery.level >= Double(chargeLimit) / 100 {
            alerts.append(.chargeLimitReached(chargeLimit))
            reachedLimit = chargeLimit
        }

        // Re-arms only at Normal: pressure often moves between Warning and Critical.
        if let pressure = snapshot.memory?.pressure {
            if pressure != .normal, !isPressured { alerts.append(.memoryPressure) }
            isPressured = pressure != .normal
        }

        // Processes are read in the background only while this alert is on and the CPU is busy
        // enough for one app to pass the threshold; without them no app counts as busy.
        let busyApps = ProcessUsage.groupedByApp(snapshot.processes).filter { $0.cpu >= Self.busyAppCPU }
        busySince = busySince.filter { pid, _ in busyApps.contains { $0.id == pid } }
        reportedBusyApps.formIntersection(busySince.keys)
        for app in busyApps {
            let since = busySince[app.id, default: now]
            busySince[app.id] = since
            if now.timeIntervalSince(since) >= Self.busyAppDuration, reportedBusyApps.insert(app.id).inserted {
                alerts.append(.busyApp(pid: app.id, name: app.name))
            }
        }

        needsAttention = hot || snapshot.memory?.pressure == .critical
        return alerts
    }
}

extension AlertMonitor.Alert {
    /// The Settings toggle that allows this notification.
    var preferenceKey: String {
        switch self {
        case .chargeLimitReached: PreferenceKey.notifyChargeLimit
        case .hot: PreferenceKey.notifyHot
        case .lowBattery: PreferenceKey.notifyLowBattery
        case .memoryPressure: PreferenceKey.notifyMemoryPressure
        case .busyApp: PreferenceKey.notifyBusyApp
        case .aiLimitLow: PreferenceKey.notifyAILimit
        }
    }

    /// Two apps can be busy at once, so each gets its own notification.
    var identifier: String {
        switch self {
        case .busyApp(let pid, _): "\(preferenceKey).\(pid)"
        case .aiLimitLow(let tool, let window): "\(preferenceKey).\(tool.rawValue).\(window.id)"
        default: preferenceKey
        }
    }

    var title: String {
        switch self {
        case .chargeLimitReached: String(localized: "Charge limit reached")
        case .hot: String(localized: "Mac is running hot")
        case .lowBattery: String(localized: "Battery below 20%")
        case .memoryPressure: String(localized: "Memory pressure is high")
        case .busyApp(_, let name): String(localized: "\(name) is keeping your Mac busy")
        case .aiLimitLow(let tool, let window) where window.isExhausted: String(localized: "\(window.serviceName(tool)) limit reached")
        case .aiLimitLow(let tool, let window): String(localized: "\(window.serviceName(tool)) limit is running low")
        }
    }

    func body(unit: TemperatureUnit) -> String {
        switch self {
        case .chargeLimitReached(let limit):
            String(localized: "Battery is at \((Double(limit) / 100).percentText). macOS has stopped charging.")
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
        case .busyApp:
            String(localized: "Over \(AlertMonitor.busyAppCPU.percentText) CPU for the last 5 minutes. Quit it if you don’t need it.")
        case .aiLimitLow(_, let window) where window.isExhausted:
            switch (window.kind, window.resetsAt) {
            case (.session, let date?): String(localized: "The 5-hour limit is used up. It resets \(date.resetText).")
            case (.weekly, let date?): String(localized: "The weekly limit is used up. It resets \(date.resetText).")
            case (.session, nil): String(localized: "The 5-hour limit is used up.")
            case (.weekly, nil): String(localized: "The weekly limit is used up.")
            case (.monthly, let date?): String(localized: "The monthly limit is used up. It resets \(date.resetText).")
            case (.monthly, nil): String(localized: "The monthly limit is used up.")
            }
        case .aiLimitLow(_, let window):
            switch (window.kind, window.resetsAt) {
            case (.session, let date?):
                String(localized: "\(window.left.percentText) of the 5-hour limit left, and it resets \(date.resetText).")
            case (.weekly, let date?):
                String(localized: "\(window.left.percentText) of the weekly limit left, and it resets \(date.resetText).")
            case (.session, nil): String(localized: "\(window.left.percentText) of the 5-hour limit left.")
            case (.weekly, nil): String(localized: "\(window.left.percentText) of the weekly limit left.")
            case (.monthly, let date?):
                String(localized: "\(window.left.percentText) of the monthly limit left, and it resets \(date.resetText).")
            case (.monthly, nil): String(localized: "\(window.left.percentText) of the monthly limit left.")
            }
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
            return UNNotificationRequest(identifier: alert.identifier, content: content, trigger: nil)
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
        case .hot, .chargeLimitReached: true
        case .lowBattery, .memoryPressure, .busyApp, .aiLimitLow: false
        }
    }
}
