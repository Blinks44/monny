import Foundation

/// Kimi Code's existing CLI session and quota endpoint; no renewal or credential writes.
nonisolated enum KimiUsage {
    static func credential(_ data: Data, now: Date, region: KimiSession.Region = .china) throws -> String {
        guard let root = try? AIServiceJSON.object(data),
            let token = SavedAISession.token(root["access_token"])
        else { throw AIUsageProblem.signedOut }
        guard let expiry = AIServiceJSON.number(root["expires_at"]),
            expiry > now.timeIntervalSince1970 + 60,
            !SavedAISession.isExpired(token, now: now.addingTimeInterval(60))
        else { throw AIUsageProblem.expired }
        // Kimi's issuer is an identifier, not necessarily a URL. Default CLI tokens use
        // `kimi-auth`; retain the selected region's auth-host URL form.
        // The fixed Kimi service authenticates the token and verifies its signature.
        let parts = token.split(separator: ".")
        if parts.count == 3 {
            var encoded = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            encoded += String(repeating: "=", count: (4 - encoded.count % 4) % 4)
            if let payload = Data(base64Encoded: encoded),
                let claims = try? JSONSerialization.jsonObject(with: payload) as? [String: Any],
                let issuer = claims["iss"] as? String,
                issuer != "kimi-auth",
                issuer.trimmingCharacters(in: CharacterSet(charactersIn: "/")) != region.oauthHost
            {
                throw AIUsageProblem.signedOut
            }
        }
        return token
    }

    static func usage(_ data: Data, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        if let raw = root["usages"], !(raw is NSNull), !(raw is [String: Any]) {
            throw AIUsageProblem.unavailable(retryAfter: nil)
        }
        let pools = root["usages"] as? [String: Any] ?? [:]
        var windows: [AIQuotaWindow] = []
        let kinds: [(AIQuotaWindow.Kind, String, TimeInterval)] = [
            (.session, "limit_5h", 18_000), (.weekly, "limit_7d", 604_800), (.monthly, "limit_month_total", 0),
        ]
        for (kind, key, duration) in kinds {
            if let raw = pools[key], !(raw is NSNull), !(raw is [String: Any]) {
                throw AIUsageProblem.unavailable(retryAfter: nil)
            }
            let ratio = try (pools[key] as? [String: Any]).map { try ratioWindow($0, kind: kind, duration: duration) }
            let counts: AIQuotaWindow?
            if kind == .weekly, let detail = root["usage"] as? [String: Any] {
                counts = countWindow(detail, kind: kind, duration: duration)
            } else if kind == .session, let limits = root["limits"] as? [[String: Any]] {
                let matching = limits.filter { limit in
                    guard let window = limit["window"] as? [String: Any],
                        let amount = AIServiceJSON.number(window["duration"])
                    else { return false }
                    let multiplier: Double
                    switch window["timeUnit"] as? String {
                    case "TIME_UNIT_MINUTE": multiplier = 60
                    case "TIME_UNIT_HOUR": multiplier = 3_600
                    case "TIME_UNIT_DAY": multiplier = 86_400
                    default: return false
                    }
                    return amount * multiplier == duration
                }
                counts =
                    matching.count == 1
                    ? (matching[0]["detail"] as? [String: Any])
                        .flatMap { countWindow($0, kind: kind, duration: duration) } : nil
            } else {
                counts = nil
            }
            if var ratio {
                // Counts can disagree slightly with ratios. Compare only the same reset period.
                if let counts, let reset = ratio.resetsAt, let countReset = counts.resetsAt,
                    abs(reset.timeIntervalSince(countReset)) <= 2
                {
                    ratio.used = max(ratio.used, counts.used)
                }
                windows.append(ratio)
            } else if let counts {
                windows.append(counts)
            }
        }
        guard !windows.isEmpty else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        let membership = (root["user"] as? [String: Any])?["membership"] as? [String: Any]
        let level = (membership?["level"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        // Internal LEVEL_* identifiers have been reused across membership generations.
        // Show a readable service name only; never expose an enum or guess a renamed tier.
        let plan = level.flatMap { $0.isEmpty || $0.hasPrefix("LEVEL_") ? nil : $0 }
        return AIUsage(plan: plan, windows: windows, date: now)
    }

    private static func ratioWindow(
        _ pool: [String: Any], kind: AIQuotaWindow.Kind,
        duration: TimeInterval
    ) throws -> AIQuotaWindow {
        guard let used = AIServiceJSON.number(pool["used_ratio"]), used >= 0 else {
            throw AIUsageProblem.unavailable(retryAfter: nil)
        }
        let reset = AIServiceJSON.date(pool["reset_time"])
        if let raw = pool["reset_time"], !(raw is NSNull), reset == nil {
            throw AIUsageProblem.unavailable(retryAfter: nil)
        }
        return AIQuotaWindow(kind: kind, used: min(used, 1), resetsAt: reset, duration: duration)
    }

    private static func countWindow(
        _ detail: [String: Any], kind: AIQuotaWindow.Kind,
        duration: TimeInterval
    ) -> AIQuotaWindow? {
        guard let limit = AIServiceJSON.number(detail["limit"]), limit > 0 else { return nil }
        let used: Double
        if let value = AIServiceJSON.number(detail["used"]), value >= 0 {
            used = value
        } else if detail["used"] == nil, let remaining = AIServiceJSON.number(detail["remaining"]),
            remaining >= 0, remaining <= limit
        {
            used = limit - remaining
        } else {
            return nil
        }
        let reset = AIServiceJSON.date(detail["resetTime"] ?? detail["reset_time"] ?? detail["resetAt"] ?? detail["reset_at"])
        return AIQuotaWindow(kind: kind, used: min(used / limit, 1), resetsAt: reset, duration: duration)
    }
}
