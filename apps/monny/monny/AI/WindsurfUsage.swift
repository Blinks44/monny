import Foundation

nonisolated enum WindsurfUsage {
    static func usage(_ data: Data, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        var windows: [AIQuotaWindow] = []
        if let quota = root["quotaUsage"] as? [String: Any] {
            for (key, kind, label) in [("daily", AIQuotaWindow.Kind.session, AIQuotaLabel.daily), ("weekly", .weekly, nil)] {
                guard let left = AIServiceJSON.number(quota[key + "RemainingPercent"]), left >= 0, left <= 100 else { continue }
                if let window = AIQuotaParsing.ratio(kind: kind, used: 1 - left / 100, reset: quota[key + "ResetAtUnix"], label: label) {
                    windows.append(window)
                }
            }
        } else if let counters = root["usage"] as? [String: Any] {
            for (key, label) in [("messages", AIQuotaLabel.messages), ("flowActions", .flowActions)] {
                let usedKey = key == "messages" ? "usedMessages" : "usedFlowActions"
                if let window = AIQuotaParsing.window(
                    kind: label == .messages ? .session : .weekly, used: counters[usedKey], limit: counters[key], label: label)
                {
                    windows.append(window)
                }
            }
        }
        var usage = try AIQuotaParsing.usage(windows, plan: root["planName"] as? String, now: now)
        // Database mtime can change for unrelated reasons. No trustworthy snapshot timestamp is exposed.
        usage.sourceDateUnknown = true
        return usage
    }
}
