import Foundation

/// Existing tool-owned sessions only. No API-key fallback, refresh or credential writes.
nonisolated enum SavedAISession {
    static func data(at file: URL) -> Data? {
        guard let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size > 0, size <= 256 * 1_024,
              let data = try? Data(contentsOf: file), data.count <= 256 * 1_024 else { return nil }
        return data
    }

    static func token(_ value: Any?) -> String? {
        guard let value = value as? String else { return nil }
        let token = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty, token.utf8.count <= 64 * 1_024,
              token.utf8.allSatisfy({ $0 > 32 && $0 < 127 }) else { return nil }
        return token
    }

    static func cline(_ data: Data) -> String? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let providers = root["providers"] as? [String: Any],
              let cline = providers["cline"] as? [String: Any],
              let settings = cline["settings"] as? [String: Any],
              let auth = settings["auth"] as? [String: Any],
              let access = token(auth["accessToken"]), access != "workos:" else { return nil }
        return access.hasPrefix("workos:") ? access : "workos:" + access
    }

    static func codebuff(_ data: Data) -> String? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        // An invalid selected profile must not silently choose a different account.
        if root.keys.contains("default") {
            return (root["default"] as? [String: Any]).flatMap { token($0["authToken"]) }
        }
        return token(root["authToken"])
    }

    static func isExpired(_ token: String, now: Date) -> Bool {
        let jwt = token.hasPrefix("workos:") ? String(token.dropFirst(7)) : token
        return CodexCredentials.expiry(ofJWT: jwt).map { $0 <= now } ?? false
    }
}
