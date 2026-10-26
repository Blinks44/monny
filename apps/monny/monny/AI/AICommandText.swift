import Foundation

/// Bounded English usage reports, not interactive terminal screens.
nonisolated enum AICommandText {
    static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: #"\x1B\[[0-?]*[ -/]*[@-~]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "**", with: "")
    }

    static func groups(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return (1..<match.numberOfRanges).map { index in
            Range(match.range(at: index), in: text).map { String(text[$0]) } ?? ""
        }
    }

    static let amount = #"(?<![A-Za-z0-9,.+\-])((?:[0-9]{1,3}(?:,[0-9]{3})+|[0-9]+)(?:\.[0-9]+)?)"#

    static func number(_ text: String) -> Double? {
        AIServiceJSON.number(text.replacingOccurrences(of: ",", with: "")).flatMap { $0 >= 0 ? $0 : nil }
    }

    static func day(year: Int, month: Int, day: Int) -> Date? {
        guard (1970...9999).contains(year), (1...12).contains(month), (1...31).contains(day) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        let result = calendar.dateComponents([.year, .month, .day], from: date)
        return result.year == year && result.month == month && result.day == day ? date : nil
    }

    static func isoDay(_ text: String) -> Date? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return day(year: parts[0], month: parts[1], day: parts[2])
    }

    static func problem(in text: String, now: Date) -> AIUsageProblem? {
        let lower = text.lowercased()
        if ["not authenticated", "authentication failed", "not logged in", "please log in", "please login"].contains(where: lower.contains) {
            return .signedOut
        }
        if lower.contains("http 429") || lower.contains("rate limit exceeded") {
            return .unavailable(retryAfter: now.addingTimeInterval(300))
        }
        return nil
    }
}
