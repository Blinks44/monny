import Foundation

/// Plan limits of the coding assistants on this Mac, when Settings › Show AI limits is on.
/// Checks every 2 minutes while a view shows them and every 5 minutes otherwise, for the history
/// chart and the running-low notification. Off, it reads nothing and makes no requests.
@Observable
final class AIUsageMonitor {
    enum Surface: Hashable { case popover, dashboard }

    struct ToolState: Equatable {
        /// The last successful reading, kept across launches so a stale one can still be shown.
        var usage: AIUsage?
        var problem: AIUsageProblem?
    }

    private(set) var isEnabled = false
    /// Tools set up on this Mac and not hidden in Settings; only these are read.
    private(set) var installed: [AITool] = []
    /// Every supported tool set up on this Mac, for Settings.
    private(set) var detected: [AITool] = []
    private(set) var states: [AITool: ToolState] = [:]
    /// Called with the alerts that started with a reading.
    @ObservationIgnored var onAlerts: ([AlertMonitor.Alert]) -> Void = { _ in }

    @ObservationIgnored private let reader = AIUsageReader()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var visible: Set<Surface> = []
    @ObservationIgnored private var lastCheck: Date?
    @ObservationIgnored private var lowWindows = AILowWindows()
    @ObservationIgnored private var defaultsObservation: NSObjectProtocol?

    /// Anthropic's usage endpoint rate-limits a token after a few requests a minute (HTTP 429,
    /// measured 2026-10-22), so a visible view does not check more often than this.
    static let visibleInterval: Duration = .seconds(120)
    static let backgroundInterval: Duration = .seconds(5 * 60)
    private static let savedKey = "aiUsage"

    /// Fixed tools and readings, for tests.
    init(installed: [AITool], states: [AITool: ToolState]) {
        self.installed = installed
        detected = installed
        self.states = states
        isEnabled = true
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.savedKey),
           let saved = try? JSONDecoder().decode([AITool: AIUsage].self, from: data) {
            states = saved.mapValues { ToolState(usage: $0) }
            // A window that was already low before quitting does not alert again at launch.
            for (tool, usage) in saved {
                _ = lowWindows.update(tool, usage: AIUsage(plan: usage.plan, windows: usage.windows.filter { !$0.hasReset() },
                                                           date: usage.date))
            }
        }
    }

    /// Follows the Settings switch from now on; called once at launch.
    func start() {
        defaultsObservation = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.applyPreference() }
        }
        applyPreference()
    }

    /// The popover AI tab and the AI usage page report when they are on screen. A set, as in
    /// `Sampler`: the popover panel only orders out, so its views get no reliable `onDisappear`.
    func setVisible(_ surface: Surface, _ isVisible: Bool) {
        let wasVisible = !visible.isEmpty
        if isVisible { visible.insert(surface) } else { visible.remove(surface) }
        // A view that opens should not wait out the rest of a 5-minute pause.
        if !wasVisible, !visible.isEmpty, isEnabled, lastCheck.map({ Date.now.timeIntervalSince($0) >= 120 }) ?? true { restart() }
    }

    /// Looks for the tools again, as Settings does when it opens.
    func refreshInstalled() {
        let tools = AIUsageReader.installedTools()
        let hidden = Set(UserDefaults.standard.stringArray(forKey: PreferenceKey.aiHiddenTools) ?? [])
        if detected != tools { detected = tools }
        let shown = tools.filter { !hidden.contains($0.rawValue) }
        if installed != shown { installed = shown }
    }

    /// Quota left in the windows read in the last 15 minutes, for history.
    func historyValues(at now: Date = .now) -> [HistoryMetric: Double] {
        var values: [HistoryMetric: Double] = [:]
        for (tool, state) in states where installed.contains(tool) {
            guard isEnabled, let usage = state.usage, !usage.isStale(at: now) else { continue }
            // Model limits stay out of history: the chart draws each tool's plan windows.
            for window in usage.windows where window.model == nil && !window.hasReset(at: now) {
                values[HistoryMetric.aiQuota(tool, window.kind)] = window.left
            }
        }
        return values
    }

    private func applyPreference() {
        let enabled = UserDefaults.standard.bool(forKey: PreferenceKey.showsAILimits)
        guard enabled != isEnabled else {
            // A tool shown again in Settings is read right away.
            if enabled {
                let before = installed
                refreshInstalled()
                if installed.contains(where: { !before.contains($0) }) { restart() }
            }
            return
        }
        isEnabled = enabled
        if enabled {
            refreshInstalled()
            restart()
        } else {
            task?.cancel()
            task = nil
        }
    }

    private func restart() {
        task?.cancel()
        task = Task { [weak self] in
            while !Task.isCancelled {
                await self?.check()
                let interval = self?.visible.isEmpty == false ? Self.visibleInterval : Self.backgroundInterval
                try? await Task.sleep(for: interval)
            }
        }
    }

    private func check(now: Date = .now) async {
        lastCheck = now
        refreshInstalled()
        var alerts: [AlertMonitor.Alert] = []
        for tool in installed {
            // After a 429 the service said when to ask again.
            if case .unavailable(let retryAfter?) = states[tool]?.problem, retryAfter > now { continue }
            let result = await reader.read(tool, now: now)
            guard !Task.isCancelled, isEnabled else { return }
            var state = states[tool] ?? ToolState()
            switch result {
            case .success(let usage):
                state = ToolState(usage: usage)
                alerts += lowWindows.update(tool, usage: usage, now: now)
            case .failure(let problem):
                state.problem = problem
            }
            if states[tool] != state { states[tool] = state }
        }
        save()
        if !alerts.isEmpty { onAlerts(alerts) }
    }

    private func save() {
        let usages = states.compactMapValues(\.usage)
        if let data = try? JSONEncoder().encode(usages) { UserDefaults.standard.set(data, forKey: Self.savedKey) }
    }
}

/// Which windows are low (running low or used up) now, so each low episode alerts once and
/// re-arms only when the window recovers or resets.
nonisolated struct AILowWindows {
    private var low: Set<String> = []

    mutating func update(_ tool: AITool, usage: AIUsage, now: Date = .now) -> [AlertMonitor.Alert] {
        var alerts: [AlertMonitor.Alert] = []
        for window in usage.windows {
            let key = "\(tool.rawValue).\(window.id)"
            if window.isExhausted || window.isRunningLow {
                if low.insert(key).inserted { alerts.append(.aiLimitLow(tool, window)) }
            } else {
                low.remove(key)
            }
        }
        return alerts
    }
}

extension HistoryMetric {
    nonisolated static func aiQuota(_ tool: AITool, _ kind: AIQuotaWindow.Kind) -> HistoryMetric {
        switch (tool, kind) {
        case (.claude, .session): .claudeSession
        case (.claude, _): .claudeWeekly
        case (.codex, .session): .codexSession
        case (.codex, _): .codexWeekly
        case (.cursor, _): .cursorMonthly
        case (.grok, _): .grokCredits
        }
    }
}
