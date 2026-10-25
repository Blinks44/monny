import Foundation
import CoreFoundation

/// Only quota amounts and refill timing leave JetBrains' local XML/JSON records.
nonisolated struct JetBrainsQuota: Sendable {
    let used: Double
    let topUpCredits: Double?
    var reset: Date?
    var duration: TimeInterval = 0
    var date: Date

    func usage(source: String) -> AIUsage {
        AIUsage(windows: [AIQuotaWindow(kind: .monthly, used: used, resetsAt: reset, duration: duration)],
                date: date, topUpCredits: topUpCredits, source: source)
    }

    static func xml(_ data: Data, date: Date) -> Self? {
        guard data.count <= 256 * 1_024,
              !String(decoding: data, as: UTF8.self).contains("<!DOCTYPE"),
              let document = try? XMLDocument(data: data, options: [.nodeLoadExternalEntitiesNever]),
              let component = try? document.nodes(forXPath: "//component[@name='AIAssistantQuotaManager2']").first else { return nil }
        func option(_ name: String) -> [String: Any]? {
            guard let value = try? component.nodes(forXPath: "option[@name='\(name)']/@value").first?.stringValue,
                  let data = value.data(using: .utf8) else { return nil }
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
        guard let json = option("quotaInfo"), json["type"] as? String == "Available",
              var quota = decode(json, date: date, allowsLegacy: true) else { return nil }
        if let refill = option("nextRefill"), refill["type"] as? String == "Known" {
            quota.reset = (refill["next"] as? String).flatMap(ClaudeUsageResponse.date(from:))
            let tariff = refill["tariff"] as? [String: Any]
            quota.duration = seconds(refill["duration"] as? String ?? tariff?["duration"] as? String) ?? 0
        }
        return quota
    }

    /// Monthly and total balances are never paired; unknown or invalid amounts fail closed.
    static func decode(_ json: [String: Any], date: Date, allowsLegacy: Bool = false) -> Self? {
        let monthly: [String: Any]
        if let tariff = json["tariffQuota"] as? [String: Any] {
            monthly = tariff
        } else {
            guard allowsLegacy, json["tariffQuota"] == nil,
                  number((json["topUpQuota"] as? [String: Any])?["maximum"]) ?? 0 == 0 else { return nil }
            monthly = json
        }
        guard let current = number(monthly["current"]), let maximum = number(monthly["maximum"]),
              current >= 0, maximum > 0 else { return nil }
        // A present remaining amount must also be valid; the bar itself follows used / limit.
        if let available = monthly["available"], number(available).map({ $0 >= 0 }) != true { return nil }
        let extra = json["topUpQuota"] as? [String: Any]
        let balance: Double? = if let maximum = number(extra?["maximum"]), maximum > 0,
                                 let available = number(extra?["available"]), available >= 0 {
            min(available, maximum) / 100_000
        } else { nil }
        return Self(used: min(current / maximum, 1), topUpCredits: balance, date: date)
    }

    static func number(_ value: Any?) -> Double? {
        if let nested = value as? [String: Any] { return number(nested["amount"]) }
        let result: Double? = if let text = value as? String { Double(text) }
        else if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() { number.doubleValue }
        else { nil }
        return result.flatMap { $0.isFinite ? $0 : nil }
    }

    /// The known source periods are Kotlin `30d` and ISO 8601 `PT720H` / `P30D`.
    static func seconds(_ text: String?) -> TimeInterval? {
        guard let text else { return nil }
        let suffix: String
        let value: Substring
        if text.hasPrefix("PT"), let last = text.last, "HMS".contains(last) {
            suffix = String(last).lowercased()
            value = text.dropFirst(2).dropLast()
        } else if text.hasPrefix("P"), text.hasSuffix("D") {
            suffix = "d"
            value = text.dropFirst().dropLast()
        } else {
            suffix = String(text.suffix(1))
            value = text.dropLast()
        }
        guard let amount = Double(value), amount.isFinite, amount > 0,
              let multiplier = ["d": 86_400.0, "h": 3_600, "m": 60, "s": 1][suffix],
              (amount * multiplier).isFinite else { return nil }
        return amount * multiplier
    }
}
