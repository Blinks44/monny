import Foundation

nonisolated enum CodebuffUsage {
    static func usage(_ data: Data, subscription: Data, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        let account = try AIServiceJSON.object(subscription)
        let plan = account["subscription"] as? [String: Any]
        let rate = account["rateLimit"] as? [String: Any]
        var windows: [AIQuotaWindow] = []
        if let used = AIServiceJSON.number(rate?["weeklyUsed"] ?? rate?["used"]), used >= 0,
           let limit = AIServiceJSON.number(rate?["weeklyLimit"] ?? rate?["limit"]), limit > 0 {
            windows.append(AIQuotaWindow(kind: .weekly, used: min(used / limit, 1),
                                         resetsAt: AIServiceJSON.date(rate?["weeklyResetsAt"]), duration: 7 * 86_400))
        }
        // Prepaid balance is not the weekly subscription allowance. Never infer one from the other.
        let credits = AIServiceJSON.number(root["remainingBalance"] ?? root["remaining"]).flatMap { $0 >= 0 ? $0 : nil }
        guard !windows.isEmpty || credits != nil else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        let name = (plan?["displayName"] ?? account["displayName"] ?? plan?["tier"] ?? account["tier"]) as? String
        return AIUsage(plan: name, windows: windows, date: now, credits: credits)
    }
}
