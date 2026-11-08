import Foundation

nonisolated enum HuggingFaceUsage {
    static func usage(_ data: Data, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        guard let total = AIServiceJSON.number(root["base"]), total > 0,
            let remaining = AIServiceJSON.number(root["current"]), remaining >= 0, remaining <= total,
            let window = AIQuotaParsing.window(
                kind: .monthly, used: total - remaining, limit: total, reset: root["resetsAt"], label: .zeroGPU)
        else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        return AIUsage(windows: [window], date: now)
    }
}
