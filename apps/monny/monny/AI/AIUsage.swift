import Foundation

/// A coding assistant whose plan limits Monny can show (Settings › AI limits).
nonisolated enum AITool: String, CaseIterable, Codable, CodingKeyRepresentable, Sendable {
    case claude, codex, cursor, grok
}

/// One rolling limit of a plan, as the service reports it.
nonisolated struct AIQuotaWindow: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable { case session, weekly, monthly }

    var kind: Kind
    /// Share of the limit used, 0…1.
    var used: Double
    var resetsAt: Date?
    /// The window's length: 5 hours, 7 days or a billing cycle.
    var duration: TimeInterval
    /// Cursor's included usage in dollars, for "$12.40 of $20 left".
    var dollarsUsed: Double?
    var dollarsLimit: Double?
    /// The model or feature of a limit beside the plan's own, such as "Opus" or "Spark".
    var model: String?

    var id: String { "\(kind.rawValue).\(model ?? "")" }

    /// "Running low" below this share of the quota left, whatever the pace (user decision 2026-10-22).
    static let lowThreshold = 0.1

    var left: Double { min(max(1 - used, 0), 1) }

    /// Share of the period still to run, where the pace mark sits; `nil` without a reset time.
    func timeLeft(at now: Date = .now) -> Double? {
        guard let resetsAt, duration > 0 else { return nil }
        return min(max(resetsAt.timeIntervalSince(now) / duration, 0), 1)
    }

    /// True once the reset time has passed: the reading no longer describes this window.
    func hasReset(at now: Date = .now) -> Bool { resetsAt.map { $0 <= now } ?? false }

    var isExhausted: Bool { left <= 0 }

    var isRunningLow: Bool { !isExhausted && left < Self.lowThreshold }

    /// When the limit runs out at the average pace since the window started, if before the reset.
    func runsOut(at now: Date = .now) -> Date? {
        guard let resetsAt, let timeLeft = timeLeft(at: now), used > 0, !isExhausted else { return nil }
        let elapsed = duration * (1 - timeLeft)
        guard elapsed > 0 else { return nil }
        let date = now.addingTimeInterval(left / (used / elapsed))
        return date < resetsAt ? date : nil
    }
}

/// The last successful reading of one tool.
nonisolated struct AIUsage: Codable, Equatable, Sendable {
    /// The plan's name as the service gives it, such as "pro" or "max".
    var plan: String?
    var windows: [AIQuotaWindow]
    var date: Date
    /// Codex credits left, when the account has any; `.infinity` for unlimited.
    var credits: Double?

    /// Older readings are drawn as stale.
    static let freshness: TimeInterval = 15 * 60

    func isStale(at now: Date = .now) -> Bool { now.timeIntervalSince(date) > Self.freshness }

    func window(_ kind: AIQuotaWindow.Kind) -> AIQuotaWindow? { windows.first { $0.kind == kind && $0.model == nil } }
}

/// Why a tool has no current reading.
nonisolated enum AIUsageProblem: Error, Equatable {
    /// No sign-in found, or the service rejected it.
    case signedOut
    /// Signed in with an API key, which is billed per use and has no plan limits.
    case apiKey
    /// The saved sign-in has expired; the tool renews it the next time it is used.
    case expired
    /// The service or the network failed; `retryAfter` when the service asked to wait.
    case unavailable(retryAfter: Date?)

    /// The tool has no plan to show, so a reading kept from before is hidden.
    var hidesReading: Bool { self == .signedOut || self == .apiKey }
}

// MARK: - Service responses

/// `GET https://api.anthropic.com/api/oauth/usage`, the endpoint Claude Code's `/usage` reads.
/// Undocumented: decoding tolerates missing windows, and unknown fields are ignored.
nonisolated struct ClaudeUsageResponse: Decodable, Sendable {
    struct Window: Decodable, Sendable {
        /// Percent used, 0…100.
        let utilization: Double?
        let resetsAt: String?

        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }
    }

    /// One entry of `limits`; `weekly_scoped` entries are model-specific weekly limits.
    struct Limit: Decodable, Sendable {
        struct Scope: Decodable, Sendable {
            struct Model: Decodable, Sendable {
                let displayName: String?

                enum CodingKeys: String, CodingKey { case displayName = "display_name" }
            }

            let model: Model?
        }

        let kind: String?
        let group: String?
        let percent: Double?
        let resetsAt: Date?
        let scope: Scope?

        enum CodingKeys: String, CodingKey {
            case kind, group, percent, scope
            case resetsAt = "resets_at"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            kind = try? container.decodeIfPresent(String.self, forKey: .kind)
            group = try? container.decodeIfPresent(String.self, forKey: .group)
            percent = try? container.decodeIfPresent(Double.self, forKey: .percent)
            scope = try? container.decodeIfPresent(Scope.self, forKey: .scope)
            // Seen both as ISO 8601 and as Unix seconds.
            if let seconds = try? container.decodeIfPresent(Double.self, forKey: .resetsAt) {
                resetsAt = Date(timeIntervalSince1970: seconds)
            } else {
                resetsAt = (try? container.decodeIfPresent(String.self, forKey: .resetsAt)).flatMap { $0.flatMap(ClaudeUsageResponse.date(from:)) }
            }
        }
    }

    let fiveHour: Window?
    let sevenDay: Window?
    let sevenDayOpus: Window?
    let sevenDaySonnet: Window?
    let limits: [Lossy<Limit>]?

    enum CodingKeys: String, CodingKey {
        case limits
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
    }

    /// The 5-hour and weekly windows, then each model's own weekly limit (Max plans).
    func windows() -> [AIQuotaWindow] {
        let week = 7 * 86_400.0
        var windows = [(fiveHour, AIQuotaWindow.Kind.session, 5 * 3_600.0), (sevenDay, .weekly, week)].compactMap { window, kind, duration in
            window?.utilization.map { AIQuotaWindow(kind: kind, used: $0 / 100, resetsAt: window?.resetsAt.flatMap(Self.date(from:)),
                                                    duration: duration) }
        }
        for limit in (limits ?? []).compactMap(\.value) where limit.kind == "weekly_scoped" && limit.group == "weekly" {
            guard let percent = limit.percent, percent.isFinite,
                  let model = limit.scope?.model?.displayName?.trimmingCharacters(in: .whitespaces), !model.isEmpty,
                  model.lowercased() != "all models", !windows.contains(where: { $0.model == model }) else { continue }
            windows.append(AIQuotaWindow(kind: .weekly, used: percent / 100, resetsAt: limit.resetsAt, duration: week, model: model))
        }
        // Older answers carry the model weeks as their own fields.
        for (window, model) in [(sevenDayOpus, "Opus"), (sevenDaySonnet, "Sonnet")] {
            guard let utilization = window?.utilization, !windows.contains(where: { $0.model == model }) else { continue }
            windows.append(AIQuotaWindow(kind: .weekly, used: utilization / 100, resetsAt: window?.resetsAt.flatMap(Self.date(from:)),
                                         duration: week, model: model))
        }
        return windows
    }

    /// ISO 8601 with microseconds, as in "2026-10-22T14:30:00.274954+00:00".
    static func date(from string: String) -> Date? {
        if let date = try? Date(string, strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true).timeZone(separator: .colon)) {
            return date
        }
        return try? Date(string, strategy: .iso8601)
    }
}

/// `GET https://chatgpt.com/backend-api/wham/usage`, the endpoint the Codex CLI reads its limits from.
nonisolated struct CodexUsageResponse: Decodable, Sendable {
    struct Window: Decodable, Sendable {
        /// Percent used, 0…100.
        let usedPercent: Double
        /// Unix seconds.
        let resetAt: Double?
        let limitWindowSeconds: Double?

        enum CodingKeys: String, CodingKey {
            case usedPercent = "used_percent"
            case resetAt = "reset_at"
            case limitWindowSeconds = "limit_window_seconds"
        }
    }

    struct RateLimit: Decodable, Sendable {
        let primaryWindow: Window?
        let secondaryWindow: Window?

        enum CodingKeys: String, CodingKey {
            case primaryWindow = "primary_window"
            case secondaryWindow = "secondary_window"
        }
    }

    /// A model's own limits beside the plan's, such as GPT-5.3-Codex-Spark.
    struct AdditionalLimit: Decodable, Sendable {
        let limitName: String?
        let rateLimit: RateLimit?

        enum CodingKeys: String, CodingKey {
            case limitName = "limit_name"
            case rateLimit = "rate_limit"
        }
    }

    struct Credits: Decodable, Sendable {
        let hasCredits: Bool
        let unlimited: Bool
        let balance: Double?

        enum CodingKeys: String, CodingKey {
            case unlimited, balance
            case hasCredits = "has_credits"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            hasCredits = (try? container.decodeIfPresent(Bool.self, forKey: .hasCredits)) ?? false
            unlimited = (try? container.decodeIfPresent(Bool.self, forKey: .unlimited)) ?? false
            // The balance arrives as a string, "1250".
            balance = (try? container.decodeIfPresent(Double.self, forKey: .balance))
                ?? (try? container.decodeIfPresent(String.self, forKey: .balance)).flatMap { $0.flatMap(Double.init) }
        }
    }

    let planType: String?
    let rateLimit: RateLimit?
    let additionalRateLimits: [Lossy<AdditionalLimit>]?
    let credits: Credits?

    enum CodingKeys: String, CodingKey {
        case credits
        case planType = "plan_type"
        case rateLimit = "rate_limit"
        case additionalRateLimits = "additional_rate_limits"
    }

    /// The primary window is the 5-hour one and the secondary the weekly one; each additional
    /// limit adds its own pair, named after its model.
    func windows() -> [AIQuotaWindow] {
        var windows = Self.windows(of: rateLimit, model: nil)
        for limit in (additionalRateLimits ?? []).compactMap(\.value) {
            guard let name = limit.limitName.map(Self.shortName), !name.isEmpty else { continue }
            windows += Self.windows(of: limit.rateLimit, model: name)
        }
        return windows
    }

    /// Credits left: the balance when the account has credits, infinity when unlimited.
    var creditsLeft: Double? {
        guard let credits, credits.hasCredits || credits.unlimited else { return nil }
        return credits.unlimited ? .infinity : credits.balance
    }

    private static func windows(of rateLimit: RateLimit?, model: String?) -> [AIQuotaWindow] {
        [(rateLimit?.primaryWindow, AIQuotaWindow.Kind.session, 5 * 3_600.0),
         (rateLimit?.secondaryWindow, .weekly, 7 * 86_400.0)].compactMap { window, kind, fallback in
            guard let window else { return nil }
            return AIQuotaWindow(kind: kind, used: window.usedPercent / 100,
                                 resetsAt: window.resetAt.map { Date(timeIntervalSince1970: $0) },
                                 duration: window.limitWindowSeconds ?? fallback, model: model)
        }
    }

    /// "GPT-5.3-Codex-Spark" → "Spark": the part after "Codex-", which names the model.
    static func shortName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard let range = trimmed.range(of: "Codex-", options: .backwards), range.upperBound < trimmed.endIndex else { return trimmed }
        return String(trimmed[range.upperBound...])
    }
}

/// An array element that decodes to `nil` instead of failing the whole answer.
nonisolated struct Lossy<Value: Decodable & Sendable>: Decodable, Sendable {
    let value: Value?

    init(from decoder: Decoder) throws { value = try? Value(from: decoder) }
}

/// `GET https://cursor.com/api/usage-summary`, what Cursor's dashboard shows: the included usage
/// of the current billing cycle. Percentages are in percent; amounts in cents.
nonisolated struct CursorUsageResponse: Decodable, Sendable {
    struct Usage: Decodable, Sendable {
        let used: Double?
        let limit: Double?
        let totalPercentUsed: Double?
        let autoPercentUsed: Double?
        let apiPercentUsed: Double?
    }

    struct Individual: Decodable, Sendable {
        let plan: Usage?
        /// Team and enterprise members get a personal cap here instead of `plan`.
        let overall: Usage?
    }

    let billingCycleStart: String?
    let billingCycleEnd: String?
    let membershipType: String?
    let individualUsage: Individual?

    func windows() -> [AIQuotaWindow] {
        let plan = individualUsage?.plan
        let usage = plan ?? individualUsage?.overall
        let percent: Double? = if let total = plan?.totalPercentUsed {
            total
        } else if let auto = plan?.autoPercentUsed, let api = plan?.apiPercentUsed {
            (auto + api) / 2
        } else if let used = usage?.used, let limit = usage?.limit, limit > 0 {
            used / limit * 100
        } else {
            plan?.apiPercentUsed ?? plan?.autoPercentUsed
        }
        guard let percent else { return [] }
        let start = billingCycleStart.flatMap(ClaudeUsageResponse.date(from:))
        let end = billingCycleEnd.flatMap(ClaudeUsageResponse.date(from:))
        let duration = start.flatMap { start in end.map { $0.timeIntervalSince(start) } } ?? 30 * 86_400
        let dollars = usage?.limit.flatMap { $0 > 0 ? (used: (usage?.used ?? 0) / 100, limit: $0 / 100) : nil }
        return [AIQuotaWindow(kind: .monthly, used: percent / 100, resetsAt: end, duration: max(duration, 86_400),
                              dollarsUsed: dollars?.used, dollarsLimit: dollars?.limit)]
    }
}

/// `GET https://cli-chat-proxy.grok.com/v1/billing?format=credits`, the Grok CLI's credits: one
/// period, weekly or monthly, with the share used.
nonisolated struct GrokBillingResponse: Decodable, Sendable {
    struct Period: Decodable, Sendable {
        let start: String?
        let end: String?
    }

    struct Amount: Decodable, Sendable {
        let val: Double?
    }

    struct Config: Decodable, Sendable {
        let creditUsagePercent: Double?
        let currentPeriod: Period?
        let billingPeriodStart: String?
        let billingPeriodEnd: String?
        let onDemandCap: Amount?
        let onDemandUsed: Amount?
        let subscriptionTier: String?
    }

    let config: Config?
    let subscriptionTier: String?

    var plan: String? { config?.subscriptionTier ?? subscriptionTier }

    func windows() -> [AIQuotaWindow] {
        guard let config else { return [] }
        let percent: Double? = if let reported = config.creditUsagePercent, reported.isFinite {
            reported
        } else if let cap = config.onDemandCap?.val, cap > 0, let used = config.onDemandUsed?.val {
            used / cap * 100
        } else {
            nil
        }
        guard let percent else { return [] }
        // The start and end of one period, never mixed across the current and the billing period.
        let usesCurrent = config.currentPeriod?.end != nil
        let end = (usesCurrent ? config.currentPeriod?.end : config.billingPeriodEnd).flatMap(ClaudeUsageResponse.date(from:))
        let start = (usesCurrent ? config.currentPeriod?.start : config.billingPeriodStart).flatMap(ClaudeUsageResponse.date(from:))
        let duration = start.flatMap { start in end.map { $0.timeIntervalSince(start) } } ?? 7 * 86_400
        return [AIQuotaWindow(kind: duration > 8 * 86_400 ? .monthly : .weekly, used: percent / 100, resetsAt: end,
                              duration: max(duration, 3_600))]
    }
}

// MARK: - Sign-in files

/// The `claudeAiOauth` entry Claude Code keeps in the Keychain item `Claude Code-credentials`
/// (or in `~/.claude/.credentials.json` on older versions).
nonisolated struct ClaudeCredentials: Decodable, Sendable {
    struct OAuth: Decodable, Sendable {
        let accessToken: String?
        /// Unix milliseconds.
        let expiresAt: Double?
        let subscriptionType: String?
    }

    let claudeAiOauth: OAuth?
}

/// `~/.codex/auth.json` after `codex login` with a ChatGPT account.
nonisolated struct CodexCredentials: Decodable, Sendable {
    struct Tokens: Decodable, Sendable {
        let accessToken: String?
        let accountID: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case accountID = "account_id"
        }
    }

    let tokens: Tokens?
    let authMode: String?
    let apiKey: String?

    enum CodingKeys: String, CodingKey {
        case tokens
        case authMode = "auth_mode"
        case apiKey = "OPENAI_API_KEY"
    }

    /// `codex login --with-api-key` writes the key and no ChatGPT tokens.
    var usesAPIKey: Bool { authMode == "apikey" || (tokens?.accessToken == nil && apiKey?.isEmpty == false) }

    /// The `exp` claim of the access token, a JWT.
    static func expiry(ofJWT token: String) -> Date? {
        (JWT.claims(of: token)?["exp"] as? Double).map { Date(timeIntervalSince1970: $0) }
    }
}

/// The unverified claims of a JWT; Monny only reads expiry and the user ID from its own tokens.
nonisolated enum JWT {
    static func claims(of token: String) -> [String: Any]? {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let data = Data(base64Encoded: payload) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

/// `~/.grok/auth.json` after `grok login`: entries keyed by sign-in scope. The SuperGrok (OIDC)
/// entry wins over the older session entry.
nonisolated enum GrokCredentials {
    static func token(from data: Data) -> (token: String, expiresAt: Date?)? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        var oidc: [String: Any]?
        var legacy: [String: Any]?
        for (scope, value) in root {
            guard let entry = value as? [String: Any], let key = entry["key"] as? String, !key.isEmpty else { continue }
            if scope.hasPrefix("https://auth.x.ai::") {
                oidc = entry
            } else if scope == "https://accounts.x.ai/sign-in" || scope.contains("/sign-in") {
                legacy = entry
            }
        }
        guard let entry = oidc ?? legacy, let key = entry["key"] as? String else { return nil }
        return (key, (entry["expires_at"] as? String).flatMap(ClaudeUsageResponse.date(from:)))
    }
}
