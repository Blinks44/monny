import Foundation

nonisolated enum KiroUsage {
    struct Session: Sendable {
        let token: String
        let profile: String
        let endpoint: URL
    }

    static func session(database: URL, now: Date) throws -> Session {
        let tokens = try AILocalDatabase.rows(database, sql: "SELECT value FROM auth_kv WHERE key='kirocli:odic:token'", limit: 1)
        let profiles = try AILocalDatabase.rows(database, sql: "SELECT value FROM state WHERE key='api.codewhisperer.profile'", limit: 1)
        guard let tokenJSON = tokens.first?.first, let profileJSON = profiles.first?.first else { throw AIUsageProblem.signedOut }
        let credential = try AIServiceJSON.object(Data(tokenJSON.utf8))
        let profile = try AIServiceJSON.object(Data(profileJSON.utf8))
        guard let token = SavedAISession.token(credential["access_token"]), let arn = profile["arn"] as? String else {
            throw AIUsageProblem.signedOut
        }
        if SavedAISession.isExpired(token, now: now.addingTimeInterval(60)) { throw AIUsageProblem.expired }
        if let expiry = AIServiceJSON.date(credential["expires_at"]), expiry <= now.addingTimeInterval(60) { throw AIUsageProblem.expired }
        return Session(token: token, profile: arn, endpoint: try endpoint(profile: arn))
    }

    static func endpoint(profile: String) throws -> URL {
        let parts = profile.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 6, parts[0] == "arn", parts[1] == "aws", parts[2] == "codewhisperer",
            profile.rangeOfCharacter(from: .whitespacesAndNewlines.union(.controlCharacters)) == nil,
            parts[4].allSatisfy(\.isNumber), parts[5].hasPrefix("profile/"), parts[5].count > 8
        else { throw AIUsageProblem.signedOut }
        let host: String
        switch parts[3] {
        case "us-east-1": host = "codewhisperer.us-east-1.amazonaws.com"
        case "eu-central-1": host = "q.eu-central-1.amazonaws.com"
        default: throw AIUsageProblem.signedOut
        }
        guard let url = URL(string: "https://\(host)/") else { throw AIUsageProblem.signedOut }
        return url
    }

    static func usage(_ data: Data, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        let credits = (root["usageBreakdownList"] as? [[String: Any]] ?? []).filter { $0["resourceType"] as? String == "CREDIT" }
        guard credits.count == 1, let credit = credits.first,
            (credit["bonuses"] as? [Any] ?? []).isEmpty,
            let totalUsed = AIServiceJSON.number(credit["currentUsageWithPrecision"]), totalUsed >= 0,
            let limit = AIServiceJSON.number(credit["usageLimitWithPrecision"]), limit > 0
        else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        let overage: Double
        if let raw = credit["currentOveragesWithPrecision"] {
            guard let value = AIServiceJSON.number(raw) else { throw AIUsageProblem.unavailable(retryAfter: nil) }
            overage = value
        } else {
            overage = 0
        }
        guard overage >= 0, totalUsed >= overage, totalUsed - overage <= limit else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        if let raw = credit["bonuses"], !(raw is [[String: Any]]) { throw AIUsageProblem.unavailable(retryAfter: nil) }
        let reset = credit["nextDateReset"] ?? root["nextDateReset"]
        var windows: [AIQuotaWindow] = []
        if let plan = AIQuotaParsing.window(kind: .monthly, used: totalUsed - overage, limit: limit, reset: reset) { windows.append(plan) }
        let configuration = root["overageConfiguration"] as? [String: Any]
        if configuration?["overageStatus"] as? String == "ENABLED",
            let window = AIQuotaParsing.window(
                kind: .monthly, used: overage, limit: credit["overageCapWithPrecision"], reset: reset, label: .overage)
        {
            windows.append(window)
        }
        return try AIQuotaParsing.usage(windows, now: now)
    }
}
