import Foundation

/// Validates reported quota counters without inventing a ceiling or treating missing data as zero.
nonisolated enum AIQuotaParsing {
    static func window(
        kind: AIQuotaWindow.Kind, used: Any?, limit: Any?, reset: Any? = nil,
        duration: TimeInterval = 0, label: AIQuotaLabel? = nil
    ) -> AIQuotaWindow? {
        guard let used = AIServiceJSON.number(used), used >= 0,
            let limit = AIServiceJSON.number(limit), limit > 0
        else { return nil }
        return AIQuotaWindow(kind: kind, used: min(used / limit, 1), resetsAt: AIServiceJSON.date(reset), duration: duration, label: label)
    }

    static func ratio(
        kind: AIQuotaWindow.Kind, used: Any?, reset: Any? = nil,
        duration: TimeInterval = 0, label: AIQuotaLabel? = nil
    ) -> AIQuotaWindow? {
        guard let used = AIServiceJSON.number(used), used >= 0, used <= 1 else { return nil }
        return AIQuotaWindow(kind: kind, used: used, resetsAt: AIServiceJSON.date(reset), duration: duration, label: label)
    }

    static func usage(_ windows: [AIQuotaWindow], plan: String? = nil, now: Date) throws -> AIUsage {
        guard !windows.isEmpty else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        return AIUsage(plan: plan, windows: windows, date: now)
    }
}

/// Quota labels that differ from the standard five-hour/weekly/monthly plan windows.
nonisolated enum AIQuotaLabel: String, Codable, Sendable {
    case daily, messages, flowActions, overage, pro, flash, flashLite, zeroGPU
}
