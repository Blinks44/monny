import Foundation

/// JSON emitted by the signed-in Bailian CLI. Region/profile remain owned by the CLI.
nonisolated enum BailianUsage {
    static func usage(_ data: Data, codingPlan: Bool, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        var windows: [AIQuotaWindow] = []
        if codingPlan {
            let definitions: [(String, AIQuotaWindow.Kind, TimeInterval)] = [
                ("per5Hour", .session, 18_000), ("perWeek", .weekly, 604_800), ("perBillMonth", .monthly, 0),
            ]
            for (key, kind, duration) in definitions {
                guard let entry = root[key] as? [String: Any] else { continue }
                let hasCounters = entry["usedQuota"] != nil || entry["totalQuota"] != nil
                let parsed =
                    hasCounters
                    ? AIQuotaParsing.window(
                        kind: kind, used: entry["usedQuota"], limit: entry["totalQuota"], reset: entry["resetTime"], duration: duration)
                    : AIQuotaParsing.ratio(kind: kind, used: entry["percentage"], reset: entry["resetTime"], duration: duration)
                if let window = parsed { windows.append(window) }
            }
        } else {
            guard root["hasQuotaData"] as? Bool != false else { throw AIUsageProblem.localDataMissing }
            let definitions: [(String, AIQuotaWindow.Kind, TimeInterval)] = [
                ("per5Hour", .session, 18_000), ("per1Week", .weekly, 604_800), ("per1Month", .monthly, 0),
            ]
            for (key, kind, duration) in definitions {
                if let window = AIQuotaParsing.ratio(
                    kind: kind, used: root[key + "Percentage"], reset: root[key + "ResetTime"], duration: duration)
                {
                    windows.append(window)
                }
            }
        }
        return try AIQuotaParsing.usage(windows, plan: root["instanceType"] as? String, now: now)
    }
}
