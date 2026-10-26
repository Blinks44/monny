import Foundation

nonisolated enum NousUsage {
    static func credential(_ data: Data, now: Date) throws -> String {
        let root = try AIServiceJSON.object(data)
        let state: [String: Any]
        if let providers = root["providers"] as? [String: Any], providers.keys.contains("nous") {
            guard let nous = providers["nous"] as? [String: Any] else { throw AIUsageProblem.signedOut }
            state = nous
        } else if let pool = root["credential_pool"] as? [String: Any], pool.keys.contains("nous") {
            guard let entries = pool["nous"] as? [[String: Any]], entries.count == 1,
                  let only = entries.first else { throw AIUsageProblem.signedOut }
            state = only
        } else { state = root }
        guard let token = SavedAISession.token(state["access_token"]) else { throw AIUsageProblem.signedOut }
        if let stored = state["portal_base_url"], !(stored is NSNull) {
            guard let raw = stored as? String, let url = URL(string: raw), url.scheme == "https",
                  url.host() == "portal.nousresearch.com", url.port == nil || url.port == 443,
                  url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
                  url.path.isEmpty || url.path == "/" else { throw AIUsageProblem.signedOut }
        }
        if let expiry = state["expires_at"], !(expiry is NSNull) {
            guard let raw = expiry as? String, let date = ClaudeUsageResponse.date(from: raw) else { throw AIUsageProblem.signedOut }
            if date.timeIntervalSince(now) <= 60 { throw AIUsageProblem.expired }
        }
        if SavedAISession.isExpired(token, now: now.addingTimeInterval(60)) { throw AIUsageProblem.expired }
        return token
    }

    static func usage(_ data: Data, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        if let error = root["error"], !(error is NSNull) { throw AIUsageProblem.unavailable(retryAfter: nil) }
        func object(_ raw: Any?) throws -> [String: Any] {
            guard let raw, !(raw is NSNull) else { return [:] }
            guard let result = raw as? [String: Any] else { throw AIUsageProblem.unavailable(retryAfter: nil) }
            return result
        }
        func amount(_ raw: Any?) throws -> Double? {
            guard let raw, !(raw is NSNull) else { return nil }
            guard let value = AIServiceJSON.number(raw), value >= 0 else { throw AIUsageProblem.unavailable(retryAfter: nil) }
            return value
        }
        let subscription = try object(root["subscription"])
        let access = try object(root["paid_service_access"])
        let grant = try amount(subscription["monthly_credits"])
        let subscriptionRemaining = try amount(subscription["credits_remaining"])
        let remaining = try subscriptionRemaining ?? amount(access["subscription_credits_remaining"])
        let purchased = try amount(root["purchased_credits_remaining"])
        let topUp = try purchased ?? amount(access["purchased_credits_remaining"])
        let total = try amount(access["total_usable_credits"])
        _ = try amount(subscription["rollover_credits"])
        var reset: Date?
        if let raw = subscription["current_period_end"], !(raw is NSNull) {
            guard let text = raw as? String, let date = ClaudeUsageResponse.date(from: text) else {
                throw AIUsageProblem.unavailable(retryAfter: nil)
            }
            reset = date
        }
        var windows: [AIQuotaWindow] = []
        if let grant, grant > 0, let remaining {
            windows.append(AIQuotaWindow(kind: .monthly, used: max(1 - remaining / grant, 0), resetsAt: reset, duration: 0))
        }
        guard !windows.isEmpty || topUp != nil || total != nil else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        return AIUsage(plan: subscription["plan"] as? String, windows: windows, date: now,
                       balanceUSD: try total.map { try AIServiceJSON.decimal($0) }, topUpUSD: try topUp.map { try AIServiceJSON.decimal($0) })
    }
}
