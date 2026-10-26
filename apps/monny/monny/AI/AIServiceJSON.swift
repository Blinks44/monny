import Foundation
import CoreFoundation

/// Strict numeric parsing shared by the two additional subscription sources.
nonisolated enum AIServiceJSON {
    static func object(_ data: Data) throws -> [String: Any] {
        guard data.count <= 2 * 1_024 * 1_024,
              let value = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIUsageProblem.unavailable(retryAfter: nil)
        }
        return value
    }

    static func number(_ value: Any?) -> Double? {
        let result: Double?
        if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() {
            result = number.doubleValue
        } else if let string = value as? String {
            result = Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        } else { result = nil }
        return result.flatMap { $0.isFinite ? $0 : nil }
    }

    static func decimal(_ value: Double) throws -> Decimal {
        let result = Decimal(value)
        guard !result.isNaN else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        return result
    }

    static func date(_ value: Any?) -> Date? {
        if let string = value as? String, let date = ClaudeUsageResponse.date(from: string) { return date }
        guard let raw = number(value), raw > 0 else { return nil }
        let seconds = raw > 10_000_000_000 ? raw / 1_000 : raw
        guard seconds < 253_402_300_800 else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }
}
