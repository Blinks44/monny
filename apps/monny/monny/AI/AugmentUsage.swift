import Foundation

nonisolated enum AugmentUsage {
    static func usage(_ output: String, now: Date) throws -> AIUsage {
        let text = AICommandText.clean(output)
        if let problem = AICommandText.problem(in: text, now: now) { throw problem }
        let amount = AICommandText.amount
        var used: Double?
        let total: Double?
        if let legacy = AICommandText.groups(amount + #"\s+remaining\s*·\s*"# + amount + #"\s*/\s*"# + amount + #"\s+credits used\b"#, in: text) {
            used = AICommandText.number(legacy[1])
            total = AICommandText.number(legacy[2])
        } else if let current = AICommandText.groups(amount + #"\s+credits remaining\b"#, in: text),
                  let grant = AICommandText.groups(amount + #"\s+credits\s*/\s*month\b"#, in: text),
                  let remaining = AICommandText.number(current[0]), let limit = AICommandText.number(grant[0]) {
            used = max(limit - remaining, 0)
            total = limit
        } else {
            throw text.contains("auggie login") ? AIUsageProblem.signedOut : .unavailable(retryAfter: nil)
        }
        guard let used, let total, total > 0 else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        let end = AICommandText.groups(#"\bends\s+([0-9]{1,2})/([0-9]{1,2})/([0-9]{4})\b"#, in: text)
        let reset = end.flatMap { parts -> Date? in
            guard let month = Int(parts[0]), let day = Int(parts[1]), let year = Int(parts[2]) else { return nil }
            return AICommandText.day(year: year, month: month, day: day)
        }
        let window = AIQuotaWindow(kind: .monthly, used: min(used / total, 1), resetsAt: reset, duration: 0)
        return AIUsage(windows: [window], date: now)
    }
}
