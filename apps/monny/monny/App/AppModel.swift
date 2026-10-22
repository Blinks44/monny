import Observation

/// Shared UI state for the status item, the popover and the dashboard window.
@Observable
final class AppModel {
    var popoverTab: PopoverTab = .overview
    var dashboardPage: DashboardPage = .overview
    /// Set by the status item while the popover panel is on screen.
    var isPopoverShown = false
    /// Set when heat or a danger state needs the user; drives the menu bar badge.
    var needsAttention = false
    let sampler = Sampler()
    let chargeLimit = ChargeLimitController()
    let updater = AppUpdater(startsUpdater: !MonnyAppDelegate.runningTests)
    let aiUsage = AIUsageMonitor()
    @ObservationIgnored private var alerts = AlertMonitor()
    @ObservationIgnored private lazy var notifier = Notifier()

    /// Window actions, set by the app delegate, which owns the status item and the scenes.
    @ObservationIgnored var openDashboard: (DashboardPage?) -> Void = { _ in }
    @ObservationIgnored var showPopover: () -> Void = { }
    @ObservationIgnored var closePopover: () -> Void = { }

    /// Starts sampling and routes every snapshot through the alerts.
    func start() {
        sampler.onSample = { [weak self] snapshot in self?.handle(snapshot) }
        sampler.extraHistoryValues = { [aiUsage] in aiUsage.historyValues() }
        sampler.start()
        aiUsage.onAlerts = { [weak self] alerts in self?.notifier.post(alerts) }
        aiUsage.start()
        Task { await chargeLimit.refresh() }
    }

    private func handle(_ snapshot: Snapshot) {
        notifier.post(alerts.update(with: snapshot, chargeLimit: chargeLimit.activeLimit))
        if needsAttention != alerts.needsAttention { needsAttention = alerts.needsAttention }
    }
}

enum PopoverTab: Hashable, CaseIterable {
    case overview, battery, processes, ai
}

/// Sidebar order of the dashboard window, as drawn in Sketch.
enum DashboardPage: Hashable, CaseIterable {
    case overview, cpu, memory, disk, network, battery, sensors, aiUsage, settings

    /// Pages with history charts show the time-range control.
    var showsTimeRange: Bool { self != .settings }

    /// AI usage appears only while Settings › Show AI limits is on.
    static func visible(showsAILimits: Bool) -> [DashboardPage] {
        allCases.filter { showsAILimits || $0 != .aiUsage }
    }
}
