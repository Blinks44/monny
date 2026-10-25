import Foundation

/// Decodes only known complete quota records from an already bounded, transient IDE log tail.
nonisolated enum JetBrainsQuotaLog {
    static let quotaMarker = "QuotaManager2Impl - New quota state is: "
    static let refillMarker = "QuotaManager2Impl - New quota refill state is: "
    static let junieMarker = "AiaActivationTransmitter - Received message from junie: quota_update:"
    static let disabledState = "Error(exception=com.intellij.ml.llm.core.AIAssistantForbiddenException"

    static func latest(in text: String) -> JetBrainsQuota? {
        var quota: JetBrainsQuota?
        var refill: (reset: Date?, duration: TimeInterval)?
        for line in text.split(whereSeparator: \.isNewline).reversed() {
            if let state = state(line, marker: quotaMarker) {
                if state.hasPrefix(disabledState) { continue }
                guard quota == nil else { break }
                guard let date = timestamp(String(line.prefix(23))),
                      let fields = fields(String(state), type: "Available") else { return nil }
                let values = fields["quota"].flatMap { self.fields($0, type: "JbaiQuota") } ?? fields
                guard let monthly = values["tariffQuota"].flatMap(details) else { return nil }
                var amounts: [String: Any] = ["tariffQuota": monthly]
                if let extra = values["topUpQuota"].flatMap(details) { amounts["topUpQuota"] = extra }
                guard var parsed = JetBrainsQuota.decode(amounts, date: date) else { return nil }
                parsed.reset = refill?.reset
                parsed.duration = refill?.duration ?? 0
                quota = parsed
            } else if let state = state(line, marker: junieMarker) {
                guard quota == nil else { break }
                guard let date = timestamp(String(line.prefix(23))),
                      let json = try? JSONSerialization.jsonObject(with: Data(state.utf8)) as? [String: Any],
                      let parsed = JetBrainsQuota.decode(json, date: date) else { return nil }
                // Junie does not report a refill. Its `until` is subscription expiry, never a reset.
                return parsed
            } else if refill == nil, let state = state(line, marker: refillMarker) {
                let known = fields(String(state), type: "Known")
                let values = known?["refill"].flatMap { fields($0, type: "JbaiQuotaRefill") } ?? known
                let tariff = values?["tariff"].flatMap {
                    fields($0, type: "JbaiQuotaTariff") ?? fields($0, type: "QuotaRefillInfoTariff")
                }
                refill = ((values?["next"]).flatMap(ClaudeUsageResponse.date(from:)),
                          JetBrainsQuota.seconds(tariff?["period"] ?? tariff?["duration"]) ?? 0)
            }
            if quota != nil, let refill {
                quota?.reset = refill.reset
                quota?.duration = refill.duration
                break
            }
        }
        return quota
    }

    private static func state(_ line: Substring, marker: String) -> Substring? {
        line.range(of: marker).map { line[$0.upperBound...] }
    }

    /// Splits a Kotlin data-class record at outer commas, preserving nested records as values.
    private static func fields(_ text: String, type: String) -> [String: String]? {
        guard text.hasPrefix(type + "("), text.hasSuffix(")") else { return nil }
        let body = text.dropFirst(type.count + 1).dropLast()
        var depth = 0
        var start = body.startIndex
        var parts: [Substring] = []
        for index in body.indices {
            switch body[index] {
            case "(": depth += 1
            case ")": depth -= 1
            case "," where depth == 0:
                parts.append(body[start..<index])
                start = body.index(after: index)
            default: break
            }
            guard depth >= 0 else { return nil }
        }
        guard depth == 0 else { return nil }
        parts.append(body[start...])
        var result: [String: String] = [:]
        for part in parts {
            guard let equals = part.firstIndex(of: "=") else { return nil }
            let key = part[..<equals].trimmingCharacters(in: .whitespaces)
            guard result[key] == nil else { return nil }
            result[key] = part[part.index(after: equals)...].trimmingCharacters(in: .whitespaces)
        }
        return result
    }

    private static func details(_ text: String) -> [String: String]? {
        fields(text, type: "QuotaDetails") ?? fields(text, type: "Details")
    }

    static func timestamp(_ text: String, timeZone: TimeZone = .current) -> Date? {
        let strategy = Date.ParseStrategy(
            format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits),\(secondFraction: .fractional(3))",
            locale: Locale(identifier: "en_US_POSIX"), timeZone: timeZone, isLenient: false)
        return try? Date(text, strategy: strategy)
    }
}
