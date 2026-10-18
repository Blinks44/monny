import Observation

/// Shared UI state for the status item, the popover and the dashboard window.
@Observable
final class AppModel {
    var popoverTab: PopoverTab = .overview
    var dashboardPage: DashboardPage = .overview
    /// Set when heat or a danger state needs the user; drives the menu bar badge.
    var needsAttention = false
    let sampler = Sampler()
    @ObservationIgnored private var alerts = AlertMonitor()
    @ObservationIgnored private lazy var notifier = Notifier()

    /// Window actions, set by the app delegate, which owns the status item and the scenes.
    @ObservationIgnored var openDashboard: (DashboardPage?) -> Void = { _ in }
    @ObservationIgnored var showPopover: () -> Void = { }
    @ObservationIgnored var closePopover: () -> Void = { }

    /// Starts sampling and routes every snapshot through the alerts.
    func start() {
        sampler.onSample = { [weak self] snapshot in self?.handle(snapshot) }
        sampler.start()
    }

    private func handle(_ snapshot: Snapshot) {
        notifier.post(alerts.update(with: snapshot))
        if needsAttention != alerts.needsAttention { needsAttention = alerts.needsAttention }
    }
}

enum PopoverTab: Hashable, CaseIterable {
    case overview, battery, processes
}

/// Sidebar order of the dashboard window, as drawn in Sketch.
enum DashboardPage: Hashable, CaseIterable {
    case overview, cpu, memory, disk, network, battery, sensors, settings

    /// Pages with history charts show the time-range control.
    var showsTimeRange: Bool { self != .settings }
}
