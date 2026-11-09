import Foundation

/// Tracks only exhausted quotas observed during this run with recovery notifications enabled.
nonisolated struct AIRecoveredWindows {
    private var exhausted: [AITool: [String: Date]] = [:]
    private var plans: [AITool: String] = [:]
    private var contexts: [AITool: String] = [:]

    mutating func remove(_ tool: AITool) {
        exhausted[tool] = nil
        plans[tool] = nil
        contexts[tool] = nil
    }
    mutating func retain(_ tools: [AITool]) {
        exhausted = exhausted.filter { tools.contains($0.key) }
        plans = plans.filter { tools.contains($0.key) }
        contexts = contexts.filter { tools.contains($0.key) }
    }

    mutating func update(_ tool: AITool, usage: AIUsage, now: Date) -> [AIQuotaWindow] {
        guard !usage.isStale(at: now), usage.date <= now else { return [] }
        guard let context = usage.recoveryContext else {
            remove(tool)
            return []
        }
        if let old = contexts[tool], old != context { remove(tool) }
        let plan = usage.plan ?? ""
        if let old = plans[tool], old != plan { remove(tool) }
        contexts[tool] = context
        plans[tool] = plan
        var armed = exhausted[tool] ?? [:]
        let ids = Set(usage.windows.map(\.id))
        armed = armed.filter { ids.contains($0.key) }
        var recovered: [AIQuotaWindow] = []
        for window in usage.windows where !window.hasReset(at: now) && window.used.isFinite {
            if window.isExhausted {
                armed[window.id] = usage.date
            } else if let observed = armed[window.id], usage.date > observed {
                recovered.append(window)
                armed[window.id] = nil
            }
        }
        exhausted[tool] = armed
        return recovered
    }
}
