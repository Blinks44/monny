import Foundation

/// Plan limits of the coding assistants on this Mac, when Settings › Show AI limits is on.
/// Polls installed tools concurrently with adaptive per-tool intervals: every 2 minutes while
/// visible, adaptively in the background (5 minutes when active with notifications on, 14 minutes
/// when idle or notifications are off, sleeping until reset when exhausted, and 30 minutes for
/// signed-out/missing tools). Off, it reads nothing and makes no requests.
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
    private var toolOrder = AIToolOrder(saved: [])

    var displayedTools: [AITool] { toolOrder.tools.filter { installed.contains($0) } }
    var detectedToolsInDisplayOrder: [AITool] { toolOrder.tools.filter { detected.contains($0) } }

    /// Called with the alerts that started with a reading.
    @ObservationIgnored var onAlerts: ([AlertMonitor.Alert]) -> Void = { _ in }

    @ObservationIgnored private let reader = AIUsageReader()
    @ObservationIgnored private let readTool: @Sendable (AITool, Date) async -> Result<AIUsage, AIUsageProblem>
    @ObservationIgnored private let persistsReadings: Bool
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var visible: Set<Surface> = []
    @ObservationIgnored private var schedule = AIPollSchedule()
    @ObservationIgnored private var lowWindows = AILowWindows()
    @ObservationIgnored private var recoveredWindows = AIRecoveredWindows()
    @ObservationIgnored private var recoveryEnabled = false
    @ObservationIgnored private var notificationsEnabled = false
    @ObservationIgnored private var defaultsObservation: NSObjectProtocol?

    /// Anthropic's usage endpoint rate-limits a token after a few requests a minute (HTTP 429,
    /// measured 2026-10-22), so a visible view does not check more often than this.
    static let visibleInterval: Duration = .seconds(Int(AIPollSchedule.visibleInterval))
    static let backgroundInterval: Duration = .seconds(Int(AIPollSchedule.backgroundActiveInterval))
    static let maxConcurrency = 6
    private static let savedKey = "aiUsage"

    /// Fixed tools and readings, for tests.
    init(
        installed: [AITool],
        states: [AITool: ToolState],
        readTool: (@Sendable (AITool, Date) async -> Result<AIUsage, AIUsageProblem>)? = nil
    ) {
        let defaultReader = AIUsageReader()
        self.readTool = readTool ?? { tool, now in await defaultReader.read(tool, now: now) }
        self.persistsReadings = false
        self.installed = installed
        detected = installed
        self.states = states.mapValues { state in
            var copy = state
            copy.usage = copy.usage?.normalized()
            return copy
        }
        isEnabled = true
    }

    init() {
        let defaultReader = reader
        readTool = { tool, now in await defaultReader.read(tool, now: now) }
        persistsReadings = true
        toolOrder = AIToolOrder(saved: UserDefaults.standard.stringArray(forKey: PreferenceKey.aiToolOrder) ?? [])
        if let data = UserDefaults.standard.data(forKey: Self.savedKey),
            let saved = try? JSONDecoder().decode([AITool: AIUsage].self, from: data)
        {
            let normalized = saved.mapValues { $0.normalized() }
            states = normalized.mapValues { ToolState(usage: $0) }
            schedule.seed(normalized)
            // A window that was already low before quitting does not alert again at launch.
            for (tool, usage) in normalized {
                _ = lowWindows.update(
                    tool,
                    usage: AIUsage(
                        plan: usage.plan, windows: usage.windows.filter { !$0.hasReset() },
                        date: usage.date))
            }
        }
    }

    func moveDisplayedTool(_ tool: AITool, to target: AITool) {
        guard tool != target, detected.contains(tool), detected.contains(target) else { return }
        toolOrder.move(tool, to: target)
        UserDefaults.standard.set(toolOrder.tools.map(\.rawValue), forKey: PreferenceKey.aiToolOrder)
    }

    /// Follows the Settings switch from now on; called once at launch.
    func start() {
        defaultsObservation = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.applyPreference() }
        }
        Task { await applyPreference() }
    }

    /// The popover AI tab and the AI usage page report when they are on screen. A set, as in
    /// `Sampler`: the popover panel only orders out, so its views get no reliable `onDisappear`.
    func setVisible(_ surface: Surface, _ isVisible: Bool) {
        let wasVisible = !visible.isEmpty
        if isVisible { visible.insert(surface) } else { visible.remove(surface) }
        // A view that opens should not wait out the rest of a background pause when any tool is due.
        guard !wasVisible, !visible.isEmpty, isEnabled else { return }
        let now = Date.now
        let notificationsOn = hasNotificationsEnabled
        let anyDue = installed.contains { tool in
            schedule.isDue(tool, problem: states[tool]?.problem, visible: true, notificationsOn: notificationsOn, now: now)
        }
        if anyDue { restart() }
    }

    /// Looks for the tools again, as Settings does when it opens.
    func refreshInstalled() async {
        let tools = await reader.installedTools()
        let hidden = Set(UserDefaults.standard.stringArray(forKey: PreferenceKey.aiHiddenTools) ?? [])
        if detected != tools { detected = tools }
        let shown = tools.filter { !hidden.contains($0.rawValue) }
        recoveredWindows.retain(shown)
        if installed != shown { installed = shown }
    }

    /// Quota left in the windows read in the last 15 minutes, for history.
    func historyValues(at now: Date = .now) -> [HistoryMetric: Double] {
        var values: [HistoryMetric: Double] = [:]
        for (tool, state) in states where installed.contains(tool) {
            guard isEnabled, state.problem?.hidesReading != true,
                let usage = state.usage, !usage.isStale(at: now)
            else { continue }
            // Model limits stay out of history: the chart draws each tool's plan windows.
            for window in usage.windows where window.isPlanLimit && !window.hasReset(at: now) {
                if tool == .antigravity && window.label != .antigravityGemini { continue }
                values[HistoryMetric.aiQuota(tool, window.kind)] = window.left
            }
        }
        return values
    }

    private var hasNotificationsEnabled: Bool {
        isEnabled
            && (UserDefaults.standard.bool(forKey: PreferenceKey.notifyAILimit)
                || UserDefaults.standard.bool(forKey: PreferenceKey.notifyAIRecovery))
    }

    private func applyPreference() async {
        let enabled = UserDefaults.standard.bool(forKey: PreferenceKey.showsAILimits)
        let recovery = enabled && UserDefaults.standard.bool(forKey: PreferenceKey.notifyAIRecovery)
        let notifications = enabled && (UserDefaults.standard.bool(forKey: PreferenceKey.notifyAILimit) || recovery)
        if recovery != recoveryEnabled {
            recoveredWindows = AIRecoveredWindows()
            recoveryEnabled = recovery
        }
        let notificationsTurnedOn = notifications && !notificationsEnabled
        notificationsEnabled = notifications
        guard enabled != isEnabled else {
            if enabled {
                let before = installed
                await refreshInstalled()
                guard isEnabled else { return }
                if notificationsTurnedOn {
                    schedule.resetForNotificationChange(now: .now)
                    restart()
                } else if installed.contains(where: { !before.contains($0) }) {
                    restart()
                }
            }
            return
        }
        isEnabled = enabled
        if enabled {
            await refreshInstalled()
            guard isEnabled else { return }
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
                guard let self, !Task.isCancelled, self.isEnabled else { return }
                let interval = self.schedule.nextWakeInterval(
                    for: self.installed,
                    problems: self.states.compactMapValues(\.problem),
                    visible: !self.visible.isEmpty,
                    notificationsOn: self.hasNotificationsEnabled,
                    now: .now)
                try? await Task.sleep(for: interval)
            }
        }
    }

    private func check(now: Date = .now) async {
        await refreshInstalled()
        guard !Task.isCancelled, isEnabled else { return }
        let hidden = Set(UserDefaults.standard.stringArray(forKey: PreferenceKey.aiHiddenTools) ?? [])
        let isVisible = !visible.isEmpty
        let notificationsOn = hasNotificationsEnabled
        let dueTools = installed.filter { tool in
            !hidden.contains(tool.rawValue)
                && schedule.isDue(
                    tool, problem: states[tool]?.problem, visible: isVisible, notificationsOn: notificationsOn, now: now)
        }
        guard !dueTools.isEmpty else { return }
        await pollTools(dueTools, notificationsOn: notificationsOn, now: now)
    }

    /// Reads `tools` concurrently (up to `maxConcurrency` in flight) and updates each tool's state
    /// as soon as its own response arrives instead of waiting for the slowest service.
    func pollTools(_ tools: [AITool], notificationsOn: Bool = false, now: Date = .now) async {
        guard !tools.isEmpty, !Task.isCancelled, isEnabled else { return }
        let readerClosure = readTool
        var alerts: [AlertMonitor.Alert] = []
        var nextIndex = 0
        let initialBatch = min(Self.maxConcurrency, tools.count)

        await withTaskGroup(of: (AITool, Result<AIUsage, AIUsageProblem>).self) { group in
            for _ in 0..<initialBatch {
                let tool = tools[nextIndex]
                nextIndex += 1
                group.addTask { (tool, await readerClosure(tool, now)) }
            }

            while let (tool, result) = await group.next() {
                guard !Task.isCancelled, isEnabled else {
                    group.cancelAll()
                    return
                }
                if nextIndex < tools.count {
                    let nextTool = tools[nextIndex]
                    nextIndex += 1
                    group.addTask { (nextTool, await readerClosure(nextTool, now)) }
                }
                guard installed.contains(tool) else { continue }
                alerts += applyResult(result, for: tool, notificationsOn: notificationsOn, now: now)
            }
        }

        guard !Task.isCancelled, isEnabled else { return }
        save()
        if !alerts.isEmpty { onAlerts(alerts) }
    }

    private func applyResult(
        _ result: Result<AIUsage, AIUsageProblem>,
        for tool: AITool,
        notificationsOn: Bool,
        now: Date
    ) -> [AlertMonitor.Alert] {
        let normalizedResult = result.map { $0.normalized() }
        schedule.record(tool, result: normalizedResult, notificationsOn: notificationsOn, now: now)
        var alerts: [AlertMonitor.Alert] = []
        var state = states[tool] ?? ToolState()
        switch normalizedResult {
        case .success(let usage):
            state = ToolState(usage: usage)
            if !usage.isStale(at: now) { alerts += lowWindows.update(tool, usage: usage, now: now) }
            if recoveryEnabled && UserDefaults.standard.bool(forKey: PreferenceKey.notifyAIRecovery) {
                let windows = recoveredWindows.update(tool, usage: usage, now: now)
                if !windows.isEmpty { alerts.append(.aiLimitRecovered(tool, windows)) }
            }
        case .failure(let problem):
            state.problem = problem
            if problem.hidesReading || problem == .expired { recoveredWindows.remove(tool) }
        }
        if states[tool] != state { states[tool] = state }
        return alerts
    }

    private func save() {
        guard persistsReadings else { return }
        let usages = states.compactMapValues(\.usage)
        if let data = try? JSONEncoder().encode(usages) { UserDefaults.standard.set(data, forKey: Self.savedKey) }
    }
}

/// Adaptive per-tool polling schedule:
/// - Visible UI (popover or dashboard): every 2 minutes.
/// - Background with AI notifications on: 5 minutes while usage changes, 14 minutes after 2
///   unchanged readings (just inside `AIUsage.freshness` so history stays continuous), sleep until
///   `resetsAt + 15 s` (clamped 2 min..6 hr) when all windows are exhausted, and 30 minutes for
///   signed-out / API-key / missing / expired tools.
/// - Background with AI notifications off: 14 minutes for continuous history, still sleeping until
///   reset when exhausted or 30 minutes when missing/signed-out.
/// - HTTP 429 `retryAfter` always overrides every cadence, including visible UI.
nonisolated struct AIPollSchedule {
    static let visibleInterval: TimeInterval = 2 * 60
    static let backgroundActiveInterval: TimeInterval = 5 * 60
    /// Stays just under `AIUsage.freshness` (15 min) so background history samples never gap.
    static let backgroundIdleInterval: TimeInterval = 14 * 60
    static let backgroundMissingInterval: TimeInterval = 30 * 60
    static let resetWakeBuffer: TimeInterval = 15
    static let maxExhaustedSleep: TimeInterval = 6 * 3_600
    static let idleAfterUnchanged = 2

    struct Entry: Equatable {
        var lastCheck: Date?
        var nextDue: Date?
        var unchangedCount = 0
        var lastSignature = ""
    }

    private(set) var entries: [AITool: Entry] = [:]

    /// Seeds schedule from persisted readings loaded at launch so a recent cache (< 2 min)
    /// skips an immediate network pass on startup.
    mutating func seed(_ saved: [AITool: AIUsage], now: Date = .now) {
        for (tool, usage) in saved {
            guard usage.date <= now else { continue }
            var entry = entries[tool] ?? Entry()
            entry.lastCheck = usage.date
            entry.lastSignature = Self.signature(for: usage)
            if now.timeIntervalSince(usage.date) < Self.visibleInterval {
                entry.nextDue = usage.date.addingTimeInterval(Self.visibleInterval)
            }
            entries[tool] = entry
        }
    }

    func isDue(
        _ tool: AITool,
        problem: AIUsageProblem?,
        visible: Bool,
        notificationsOn: Bool,
        now: Date
    ) -> Bool {
        if case .unavailable(let retryAfter?) = problem, retryAfter > now {
            return false
        }
        guard let entry = entries[tool] else { return true }
        if visible {
            guard let lastCheck = entry.lastCheck else { return true }
            return now.timeIntervalSince(lastCheck) >= Self.visibleInterval
        }
        if let nextDue = entry.nextDue {
            return now >= nextDue
        }
        guard let lastCheck = entry.lastCheck else { return true }
        let base = notificationsOn ? Self.backgroundActiveInterval : Self.backgroundIdleInterval
        return now.timeIntervalSince(lastCheck) >= base
    }

    mutating func record(
        _ tool: AITool,
        result: Result<AIUsage, AIUsageProblem>,
        notificationsOn: Bool,
        now: Date
    ) {
        var entry = entries[tool] ?? Entry()
        entry.lastCheck = now
        switch result {
        case .success(let usage):
            let sig = Self.signature(for: usage)
            if sig == entry.lastSignature {
                entry.unchangedCount += 1
            } else {
                entry.unchangedCount = 0
                entry.lastSignature = sig
            }
            if let wakeup = Self.exhaustedWakeup(for: usage, now: now) {
                entry.nextDue = wakeup
            } else if !notificationsOn || entry.unchangedCount >= Self.idleAfterUnchanged {
                entry.nextDue = now.addingTimeInterval(Self.backgroundIdleInterval)
            } else {
                entry.nextDue = now.addingTimeInterval(Self.backgroundActiveInterval)
            }
        case .failure(let problem):
            switch problem {
            case .unavailable(let retryAfter?):
                entry.nextDue = max(retryAfter, now.addingTimeInterval(Self.backgroundActiveInterval))
            case .unavailable(nil):
                entry.nextDue = now.addingTimeInterval(
                    notificationsOn ? Self.backgroundActiveInterval : Self.backgroundIdleInterval)
            case .signedOut, .apiKey, .localDataMissing, .expired:
                entry.nextDue = now.addingTimeInterval(Self.backgroundMissingInterval)
            }
        }
        entries[tool] = entry
    }

    func nextWakeInterval(
        for tools: [AITool],
        problems: [AITool: AIUsageProblem],
        visible: Bool,
        notificationsOn: Bool,
        now: Date
    ) -> Duration {
        let fallback = visible ? Self.visibleInterval : Self.backgroundIdleInterval
        guard !tools.isEmpty else { return .seconds(fallback) }
        var earliest: Date?
        for tool in tools {
            let due = nextDueDate(
                for: tool, problem: problems[tool], visible: visible, notificationsOn: notificationsOn, now: now)
            if let current = earliest {
                if due < current { earliest = due }
            } else {
                earliest = due
            }
        }
        guard let earliest else { return .seconds(fallback) }
        let delay = max(earliest.timeIntervalSince(now), 5)
        return .seconds(min(delay, Self.backgroundMissingInterval))
    }

    mutating func resetForNotificationChange(now: Date) {
        for (tool, var entry) in entries {
            if let nextDue = entry.nextDue, nextDue > now.addingTimeInterval(Self.backgroundActiveInterval) {
                entry.nextDue = now
                entries[tool] = entry
            }
        }
    }

    private func nextDueDate(
        for tool: AITool,
        problem: AIUsageProblem?,
        visible: Bool,
        notificationsOn: Bool,
        now: Date
    ) -> Date {
        let retryAfter: Date? =
            if case .unavailable(let date?) = problem, date > now { date } else { nil }
        guard let entry = entries[tool] else { return retryAfter ?? now }
        let baseDue: Date
        if visible {
            baseDue = (entry.lastCheck ?? .distantPast).addingTimeInterval(Self.visibleInterval)
        } else if let nextDue = entry.nextDue {
            baseDue = nextDue
        } else {
            let interval = notificationsOn ? Self.backgroundActiveInterval : Self.backgroundIdleInterval
            baseDue = (entry.lastCheck ?? .distantPast).addingTimeInterval(interval)
        }
        if let retryAfter { return max(baseDue, retryAfter) }
        return baseDue
    }

    static func exhaustedWakeup(for usage: AIUsage, now: Date) -> Date? {
        guard !usage.windows.isEmpty else { return nil }
        var earliestReset: Date?
        for window in usage.windows {
            if window.hasReset(at: now) || !window.isExhausted { return nil }
            guard let reset = window.resetsAt, reset > now else { return nil }
            if let current = earliestReset {
                if reset < current { earliestReset = reset }
            } else {
                earliestReset = reset
            }
        }
        guard let earliestReset else { return nil }
        let target = earliestReset.addingTimeInterval(Self.resetWakeBuffer)
        let minWake = now.addingTimeInterval(Self.visibleInterval)
        let maxWake = now.addingTimeInterval(Self.maxExhaustedSleep)
        return min(max(target, minWake), maxWake)
    }

    static func signature(for usage: AIUsage) -> String {
        let windows = usage.windows.map { window in
            let pct = Int((window.left * 1_000).rounded())
            let reset = window.resetsAt.map { Int($0.timeIntervalSince1970 / 60) } ?? 0
            return "\(window.id)=\(pct)@\(reset)"
        }.joined(separator: ";")
        let credits = usage.credits.map { $0.isInfinite ? "inf" : String(format: "%.2f", $0) } ?? ""
        let reviews = usage.reviewCount.map { String(Int($0.rounded())) } ?? ""
        return "\(usage.plan ?? "")|\(windows)|\(credits)|\(reviews)"
    }
}

/// Which windows are low (running low or used up) now, so each low episode alerts once and
/// re-arms only when the window recovers or resets.
nonisolated struct AILowWindows {
    private var low: [String: Date] = [:]

    mutating func update(_ tool: AITool, usage: AIUsage, now: Date = .now) -> [AlertMonitor.Alert] {
        var alerts: [AlertMonitor.Alert] = []
        for window in usage.windows {
            let key = "\(tool.rawValue).\(window.id)"
            if window.hasReset(at: now) {
                low.removeValue(forKey: key)
                continue
            }
            if window.isExhausted || window.isRunningLow {
                let previousReset = low[key]
                // A reset timestamp can be refined between checks. It is not an episode ID:
                // re-arm only after the old reset or when the new period starts beyond it.
                let newPeriod =
                    previousReset.map { previous in
                        previous <= now
                            || (window.duration > 0
                                && window.resetsAt.map {
                                    $0.addingTimeInterval(-window.duration) >= previous
                                } == true)
                    } ?? true
                low[key] = window.resetsAt ?? previousReset ?? .distantFuture
                if newPeriod { alerts.append(.aiLimitLow(tool, window)) }
            } else {
                low.removeValue(forKey: key)
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
        case (.jetBrains, _): .jetBrainsMonthly
        case (.copilot, _): .copilotPremium
        case (.cline, .session): .clineSession
        case (.cline, .weekly): .clineWeekly
        case (.cline, .monthly): .clineMonthly
        case (.codebuff, _): .codebuffWeekly
        case (.amp, .session): .ampFree
        case (.amp, _): .ampMonthly
        case (.augment, _): .augmentMonthly
        case (.nous, _): .nousMonthly
        case (.kimi, .session): .kimiSession
        case (.kimi, .weekly): .kimiWeekly
        case (.kimi, .monthly): .kimiMonthly
        case (.openCodeGo, .session): .openCodeSession
        case (.openCodeGo, .weekly): .openCodeWeekly
        case (.openCodeGo, .monthly): .openCodeMonthly
        case (.alibabaToken, .session): .alibabaTokenSession
        case (.alibabaToken, .weekly): .alibabaTokenWeekly
        case (.alibabaToken, .monthly): .alibabaTokenMonthly
        case (.alibabaCoding, .session): .alibabaCodingSession
        case (.alibabaCoding, .weekly): .alibabaCodingWeekly
        case (.alibabaCoding, .monthly): .alibabaCodingMonthly
        case (.kilo, _): .kiloMonthly
        case (.kiro, _): .kiroMonthly
        case (.windsurf, _): .windsurfWeekly
        case (.codeRabbit, _): .codeRabbitUsage
        case (.gemini, _): .geminiPro
        case (.huggingFace, _): .huggingFaceGPU
        case (.antigravity, .session): .antigravitySession
        case (.antigravity, _): .antigravityWeekly
        }
    }
}
