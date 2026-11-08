import Foundation

nonisolated enum OpenCodeGoUsage {
    static func credential(home: URL, now: Date) throws -> String {
        let folder = home.appending(path: ".local/share/opencode")
        let database = folder.appending(path: "opencode.db")
        if FileManager.default.fileExists(atPath: database.path) {
            let table = try AILocalDatabase.rows(database, sql: "SELECT name FROM sqlite_master WHERE type='table' AND name='credential'")
            if !table.isEmpty {
                let rows = try AILocalDatabase.rows(
                    database,
                    sql: """
                        SELECT integration_id,value FROM credential WHERE active=1 AND integration_id IN ('opencode-go','opencode')
                        ORDER BY CASE integration_id WHEN 'opencode-go' THEN 0 ELSE 1 END LIMIT 2
                        """)
                guard let first = rows.first, rows.count == 1 || rows[1][0] != first[0] else { throw AIUsageProblem.signedOut }
                return try token(Data(first[1].utf8), now: now)
            }
        }
        guard let data = SavedAISession.data(at: folder.appending(path: "auth.json")),
            let root = try? AIServiceJSON.object(data), let entry = root["opencode-go"] as? [String: Any],
            entry["type"] as? String == "api", let token = SavedAISession.token(entry["key"])
        else { throw AIUsageProblem.signedOut }
        return token
    }

    static func token(_ data: Data, now: Date) throws -> String {
        let entry = try AIServiceJSON.object(data)
        if entry["type"] as? String == "key", let token = SavedAISession.token(entry["key"]) { return token }
        guard entry["type"] as? String == "oauth", let token = SavedAISession.token(entry["access"]) else { throw AIUsageProblem.signedOut }
        guard let expiry = AIServiceJSON.number(entry["expires"]), expiry / 1_000 > now.timeIntervalSince1970 + 60,
            !SavedAISession.isExpired(token, now: now.addingTimeInterval(60))
        else { throw AIUsageProblem.expired }
        return token
    }

    static func usage(_ data: Data, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        guard let usage = root["usage"] as? [String: Any] else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        let definitions: [(String, AIQuotaWindow.Kind, TimeInterval)] = [
            ("rolling", .session, 18_000), ("weekly", .weekly, 604_800), ("monthly", .monthly, 0),
        ]
        let windows = definitions.compactMap { key, kind, duration -> AIQuotaWindow? in
            guard let entry = usage[key] as? [String: Any], let percent = AIServiceJSON.number(entry["percent"]) else { return nil }
            return AIQuotaParsing.ratio(kind: kind, used: percent / 100, reset: entry["resetsAt"], duration: duration)
        }
        return try AIQuotaParsing.usage(windows, now: now)
    }
}
