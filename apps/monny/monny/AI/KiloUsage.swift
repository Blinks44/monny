import Foundation

nonisolated enum KiloUsage {
    static func token(_ data: Data, now: Date) throws -> String {
        let root = try AIServiceJSON.object(data)
        guard let session = root["kilo"] as? [String: Any], let token = SavedAISession.token(session["access"]) else {
            throw AIUsageProblem.signedOut
        }
        if SavedAISession.isExpired(token, now: now.addingTimeInterval(60)) { throw AIUsageProblem.expired }
        return token
    }

    static func request(token: String) throws -> URLRequest {
        var components = URLComponents(string: "https://app.kilo.ai/api/trpc/user.getCreditBlocks,kiloPass.getState")
        components?.queryItems = [
            URLQueryItem(name: "batch", value: "1"), URLQueryItem(name: "input", value: #"{"0":{"json":null},"1":{"json":null}}"#),
        ]
        guard let url = components?.url else { throw AIUsageProblem.signedOut }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    static func usage(_ data: Data, now: Date) throws -> AIUsage {
        guard data.count <= 2 * 1_024 * 1_024,
            let entries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]], entries.count == 2
        else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        let payloads = try entries.map { entry -> [String: Any] in
            guard let result = entry["result"] as? [String: Any], let body = result["data"] as? [String: Any] else {
                throw AIUsageProblem.unavailable(retryAfter: nil)
            }
            return body["json"] as? [String: Any] ?? body
        }
        var usage = AIUsage(windows: [], date: now)
        let balance = payloads[0]
        if let raw = AIServiceJSON.number(balance["totalBalance_mUsd"]), raw >= 0 {
            usage.balanceUSD = try AIServiceJSON.decimal(raw / 1_000_000)
        } else if let blocks = balance["creditBlocks"] as? [[String: Any]], !blocks.isEmpty {
            let values = blocks.compactMap { AIServiceJSON.number($0["balance_mUsd"]) }
            if values.count == blocks.count, values.allSatisfy({ $0 >= 0 }), values.reduce(0, +).isFinite {
                usage.balanceUSD = try AIServiceJSON.decimal(values.reduce(0, +) / 1_000_000)
            }
        }
        if let subscription = payloads[1]["subscription"] as? [String: Any] {
            let bonus: Double
            if let raw = subscription["currentPeriodBonusCreditsUsd"] {
                guard let value = AIServiceJSON.number(raw), value >= 0 else { throw AIUsageProblem.unavailable(retryAfter: nil) }
                bonus = value
            } else {
                bonus = 0
            }
            if let base = AIServiceJSON.number(subscription["currentPeriodBaseCreditsUsd"]), base >= 0, bonus >= 0,
                var window = AIQuotaParsing.window(
                    kind: .monthly, used: subscription["currentPeriodUsageUsd"], limit: base + bonus,
                    reset: subscription["nextBillingAt"] ?? subscription["nextRenewalAt"])
            {
                window.dollarsUsed = AIServiceJSON.number(subscription["currentPeriodUsageUsd"])
                window.dollarsLimit = base + bonus
                usage.windows = [window]
            }
        }
        guard !usage.windows.isEmpty || usage.balanceUSD != nil else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        return usage
    }
}
