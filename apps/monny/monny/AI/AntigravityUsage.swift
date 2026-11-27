import Foundation

/// Reads Antigravity CLI's saved OAuth session and decodes the direct `retrieveUserQuotaSummary`
/// response without running `agy -p` (whose print-mode eligibility gate aborts in unsupported
/// locations even when interactive `/usage` still reports quotas).
nonisolated enum AntigravityUsage {
    static let endpoint = URL(string: "https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary")!
    static let userAgent = "antigravity/hub/2.9.1 darwin/arm64"

    private static let keyringBase64Prefix = "go-keyring-base64:"

    static func token(_ data: Data, now: Date) throws(AIUsageProblem) -> String {
        guard !data.isEmpty, data.count <= 256 * 1_024 else { throw .signedOut }
        let jsonData: Data
        if let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
            text.hasPrefix(keyringBase64Prefix)
        {
            let encoded = String(text.dropFirst(keyringBase64Prefix.count))
            guard let decoded = Data(base64Encoded: encoded), !decoded.isEmpty, decoded.count <= 256 * 1_024 else {
                throw .signedOut
            }
            jsonData = decoded
        } else {
            jsonData = data
        }

        guard let credential = try? JSONDecoder().decode(StoredCredential.self, from: jsonData),
            let accessToken = SavedAISession.token(credential.token?.accessToken)
        else { throw .signedOut }

        let threshold = now.addingTimeInterval(60)
        if let rawExpiry = credential.token?.expiry?.trimmingCharacters(in: .whitespacesAndNewlines), !rawExpiry.isEmpty {
            guard let expiry = ClaudeUsageResponse.date(from: rawExpiry), expiry > threshold else { throw .expired }
        }
        if SavedAISession.isExpired(accessToken, now: threshold) { throw .expired }
        return accessToken
    }

    static func request(token: String) -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = Data("{}".utf8)
        return request
    }

    static func usage(_ data: Data, now: Date) throws(AIUsageProblem) -> AIUsage {
        guard let summary = try? JSONDecoder().decode(Summary.self, from: data) else {
            throw .unavailable(retryAfter: nil)
        }
        var windows: [AIQuotaWindow] = []
        for group in summary.groups {
            for bucket in group.buckets.compactMap(\.value) {
                guard let window = bucket.window, !windows.contains(where: { $0.id == window.id }) else { continue }
                windows.append(window)
            }
        }
        guard !windows.isEmpty else { throw .unavailable(retryAfter: nil) }
        return AIUsage(windows: AIQuotaWindow.normalized(windows), date: now)
    }

    private struct StoredCredential: Decodable {
        struct OAuthToken: Decodable {
            let accessToken: String?
            let expiry: String?

            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case expiry
            }
        }

        let token: OAuthToken?
    }

    private struct Summary: Decodable {
        struct Group: Decodable {
            let buckets: [Lossy<Bucket>]
        }

        let groups: [Group]
    }

    private struct Bucket: Decodable, Sendable {
        let bucketId: String
        let remainingFraction: Double?
        let resetTime: String?
        let disabled: Bool?

        var window: AIQuotaWindow? {
            guard disabled != true, let remainingFraction, remainingFraction.isFinite,
                (0...1).contains(remainingFraction)
            else { return nil }
            let kind: AIQuotaWindow.Kind
            let label: AIQuotaLabel
            switch bucketId {
            case "gemini-5h": (kind, label) = (.session, .antigravityGemini)
            case "gemini-weekly": (kind, label) = (.weekly, .antigravityGemini)
            case "3p-5h": (kind, label) = (.session, .antigravityClaudeGPT)
            case "3p-weekly": (kind, label) = (.weekly, .antigravityClaudeGPT)
            case "gemini-argon-wtu-weekly": (kind, label) = (.weekly, .antigravityArgon)
            default: return nil
            }
            return AIQuotaWindow(
                kind: kind, used: 1 - remainingFraction, resetsAt: resetTime.flatMap(ClaudeUsageResponse.date(from:)),
                duration: kind == .session ? 5 * 3_600 : 7 * 86_400, label: label)
        }
    }
}
