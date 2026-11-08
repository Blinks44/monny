import Foundation

/// CodeRabbit's documented text report. Review counts do not establish a quota denominator.
nonisolated enum CodeRabbitUsage {
    static func usage(_ text: String, now: Date) throws -> AIUsage {
        guard text.utf8.count <= 256 * 1_024 else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        let lines = text.split(whereSeparator: \.isNewline)
        let values = lines.compactMap { line -> Double? in
            let fields = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard fields.count == 2, fields[0] == "Your reviews", let value = AICommandText.number(fields[1]), value >= 0,
                value.rounded() == value
            else { return nil }
            return value
        }
        guard values.count == 1 else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        var usage = AIUsage(windows: [], date: now)
        usage.reviewCount = values[0]
        return usage
    }
}
