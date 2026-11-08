import Foundation

/// Existing supported work-account OAuth only. No consumer-web source or client-secret extraction.
nonisolated enum GeminiUsage {
    static func token(_ data: Data, now: Date) throws -> String {
        let root = try AIServiceJSON.object(data)
        guard let token = SavedAISession.token(root["access_token"]) else { throw AIUsageProblem.signedOut }
        guard let expiry = AIServiceJSON.number(root["expiry_date"]), expiry / 1_000 > now.timeIntervalSince1970 + 60,
            !SavedAISession.isExpired(token, now: now.addingTimeInterval(60))
        else { throw AIUsageProblem.expired }
        return token
    }

    static func project(_ data: Data) throws -> String? {
        let root = try AIServiceJSON.object(data)
        let ineligible = root["ineligibleTiers"] as? [[String: Any]] ?? []
        let paid = root["paidTier"] as? [String: Any]
        let current = root["currentTier"] as? [String: Any]
        if ineligible.contains(where: { $0["reasonCode"] as? String == "UNSUPPORTED_CLIENT" }),
            paid?["name"] == nil, current?["id"] as? String != "standard-tier"
        {
            throw AIUsageProblem.localDataMissing
        }
        if let project = root["cloudaicompanionProject"] as? String { return project }
        return (root["cloudaicompanionProject"] as? [String: Any])?["id"] as? String
    }

    static func usage(_ data: Data, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        guard let buckets = root["buckets"] as? [[String: Any]] else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        var selected: [AIQuotaLabel: AIQuotaWindow] = [:]
        for bucket in buckets {
            guard let model = bucket["modelId"] as? String,
                let left = AIServiceJSON.number(bucket["remainingFraction"]), left >= 0, left <= 1
            else { continue }
            let label: AIQuotaLabel
            if model.contains("flash-lite") {
                label = .flashLite
            } else if model.contains("flash") {
                label = .flash
            } else if model.contains("pro") {
                label = .pro
            } else {
                continue
            }
            if let window = AIQuotaParsing.ratio(kind: .monthly, used: 1 - left, reset: bucket["resetTime"], label: label),
                selected[label].map({ $0.used < window.used }) ?? true
            {
                selected[label] = window
            }
        }
        return try AIQuotaParsing.usage([AIQuotaLabel.pro, .flash, .flashLite].compactMap { selected[$0] }, now: now)
    }
}
