import Foundation

/// Copilot reports separate monthly allowances; none is a model-specific limit.
nonisolated enum CopilotQuota: String, Codable, Sendable {
    case premium, chat, completions
}

/// GitHub's undocumented Copilot endpoint. Unknown quota keys are deliberately ignored rather
/// than presenting an unfamiliar allowance as premium requests.
nonisolated struct CopilotUsageResponse: Decodable, Sendable {
    struct Quota: Decodable, Sendable {
        let entitlement: Double?
        let remaining: Double?
        let percentRemaining: Double?
        let creditsUsed: Double?
        let unlimited: Bool?

        enum CodingKeys: String, CodingKey {
            case entitlement, remaining, unlimited
            case percentRemaining = "percent_remaining"
            case creditsUsed = "credits_used"
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            func number(_ key: CodingKeys) -> Double? {
                let value = (try? values.decode(Double.self, forKey: key))
                    ?? (try? values.decode(String.self, forKey: key)).flatMap(Double.init)
                return value.flatMap { $0.isFinite ? $0 : nil }
            }
            entitlement = number(.entitlement)
            remaining = number(.remaining)
            percentRemaining = number(.percentRemaining)
            creditsUsed = number(.creditsUsed).flatMap { $0 >= 0 ? $0 : nil }
            unlimited = try values.decodeIfPresent(Bool.self, forKey: .unlimited)
        }

        var used: Double? {
            guard unlimited != true, !(entitlement == 0 && remaining == 0) else { return nil }
            if let percentRemaining { return max(0, 1 - percentRemaining / 100) }
            guard let entitlement, entitlement > 0, let remaining else { return nil }
            return max(0, 1 - remaining / entitlement)
        }
    }

    let copilotPlan: String?
    let quotaSnapshots: [String: Lossy<Quota>]?
    let quotaResetDate: String?
    let tokenBasedBilling: Bool?
    let monthlyQuotas: [String: Double]?
    let limitedUserQuotas: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case copilotPlan = "copilot_plan"
        case quotaSnapshots = "quota_snapshots"
        case quotaResetDate = "quota_reset_date"
        case tokenBasedBilling = "token_based_billing"
        case monthlyQuotas = "monthly_quotas"
        case limitedUserQuotas = "limited_user_quotas"
    }

    func usage(now: Date) throws -> AIUsage {
        let keys: [(String, CopilotQuota)] = [("premium_interactions", .premium), ("chat", .chat), ("completions", .completions)]
        let reset = quotaResetDate.flatMap(Self.resetDate)
        var windows: [AIQuotaWindow] = []
        var unlimited: [CopilotQuota] = []
        for (key, category) in keys {
            let quota = quotaSnapshots?[key]?.value
            var used = quota?.used
            // Older free plans publish monthly totals and remaining chat/completion counts.
            if used == nil, category != .premium,
               let total = monthlyQuotas?[key], total.isFinite, total > 0,
               let remaining = limitedUserQuotas?[key], remaining.isFinite, remaining >= 0 {
                used = max(0, 1 - remaining / total)
            }
            if let used {
                windows.append(AIQuotaWindow(kind: .monthly, used: used, resetsAt: reset,
                                             duration: 0, copilotQuota: category))
            } else if quota?.unlimited == true {
                unlimited.append(category)
            }
        }
        // These counters can describe the same pool. Never add them together.
        let reportedCredits = quotaSnapshots?["premium_interactions"]?.value?.creditsUsed
            ?? quotaSnapshots?["chat"]?.value?.creditsUsed
        let credits = reportedCredits.flatMap { $0 > 0 || tokenBasedBilling == true || !unlimited.isEmpty ? $0 : nil }
        guard !windows.isEmpty || !unlimited.isEmpty || tokenBasedBilling == true || credits != nil else {
            throw AIUsageProblem.unavailable(retryAfter: nil)
        }
        return AIUsage(plan: copilotPlan, windows: windows, date: now,
                       creditsUsed: credits, unlimitedCopilotQuotas: unlimited)
    }

    static func resetDate(_ string: String) -> Date? {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let date = ClaudeUsageResponse.date(from: value) { return date }
        guard value.count == 10 else { return nil }
        // Date-only API values describe UTC, independent of the Mac's locale/time zone.
        return ClaudeUsageResponse.date(from: value + "T00:00:00Z")
    }
}
