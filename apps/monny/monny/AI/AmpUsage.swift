import Foundation

nonisolated enum AmpQuota: String, Codable, Sendable { case free, agent, other, orb }

nonisolated enum AmpUsage {
    static func usage(_ output: String, now: Date) throws -> AIUsage {
        let text = AICommandText.clean(output)
        if let problem = AICommandText.problem(in: text, now: now) { throw problem }
        let amount = AICommandText.amount
        var windows: [AIQuotaWindow] = []
        var plan: String?
        if let free = AICommandText.groups(#"(?m)^\s*Amp Free:\s*\$?"# + amount + #"\s*/\s*\$?"# + amount + #"\s+remaining\b"#, in: text),
           let remaining = AICommandText.number(free[0]), let total = AICommandText.number(free[1]), total > 0 {
            windows.append(AIQuotaWindow(kind: .session, used: max(1 - remaining / total, 0), resetsAt: nil,
                                         duration: 0, dollarsUsed: max(total - remaining, 0), dollarsLimit: total, ampQuota: .free))
        } else if let free = AICommandText.groups(#"(?m)^\s*Amp Free:\s*"# + amount + #"%\s+remaining\b"#, in: text),
                  let remaining = AICommandText.number(free[0]), remaining <= 100 {
            windows.append(AIQuotaWindow(kind: .session, used: 1 - remaining / 100, resetsAt: nil, duration: 0, ampQuota: .free))
        }
        if let line = text.components(separatedBy: .newlines).first(where: { $0.contains(" Tier:") }),
           let tier = AICommandText.groups(#"^\s*Amp\s+(.+?)\s+Tier:\s*agent usage\s+\$"# + amount + #"\s+of\s+\$"# + amount + #"\s+remaining\b"#, in: line),
           let remaining = AICommandText.number(tier[1]), let total = AICommandText.number(tier[2]), total > 0 {
            plan = tier[0]
            var reset: Date?
            var duration: TimeInterval = 0
            if let dates = AICommandText.groups(#"\bperiod\s+([0-9]{4}-[0-9]{2}-[0-9]{2})\s+to\s+([0-9]{4}-[0-9]{2}-[0-9]{2})\b"#, in: line),
               let start = AICommandText.isoDay(dates[0]), let end = AICommandText.isoDay(dates[1]), end > start {
                reset = end
                duration = end.timeIntervalSince(start)
            }
            windows.append(AIQuotaWindow(kind: .monthly, used: max(1 - remaining / total, 0), resetsAt: reset, duration: duration,
                                         dollarsUsed: max(total - remaining, 0), dollarsLimit: total, ampQuota: .agent))
            if let orb = AICommandText.groups(#"\borb usage\s+"# + amount + #"h\s+of\s+"# + amount + #"h\s+a1\.small\s+orb hours remaining\b"#, in: line),
               let left = AICommandText.number(orb[0]), let limit = AICommandText.number(orb[1]), limit > 0 {
                windows.append(AIQuotaWindow(kind: .monthly, used: max(1 - left / limit, 0), resetsAt: reset,
                                             duration: duration, ampQuota: .orb))
            }
        } else if let legacy = AICommandText.groups(#"(?m)^\s*(?:Subscription\s+(.+?)|Amp\s+(.+?)\s+Subscription):\s*"# + amount + #"%\s+other usage and\s+"# + amount + #"%\s+orb usage remaining\b"#, in: text),
                  let other = AICommandText.number(legacy[2]), let orb = AICommandText.number(legacy[3]), other <= 100, orb <= 100 {
            plan = legacy[0].isEmpty ? legacy[1] : legacy[0]
            windows.append(AIQuotaWindow(kind: .monthly, used: 1 - other / 100, resetsAt: nil, duration: 0, ampQuota: .other))
            windows.append(AIQuotaWindow(kind: .monthly, used: 1 - orb / 100, resetsAt: nil, duration: 0, ampQuota: .orb))
        }
        let balance = try AICommandText.groups(#"(?m)^\s*Individual credits:\s*\$?"# + amount + #"\s+remaining\b"#, in: text)
            .flatMap { AICommandText.number($0[0]) }.map { try AIServiceJSON.decimal($0) }
        guard !windows.isEmpty || balance != nil else {
            throw text.contains("amp login") ? AIUsageProblem.signedOut : .unavailable(retryAfter: nil)
        }
        return AIUsage(plan: plan, windows: windows, date: now, balanceUSD: balance)
    }
}
