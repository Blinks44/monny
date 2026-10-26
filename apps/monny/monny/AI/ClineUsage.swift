import Foundation
import CoreFoundation

nonisolated enum ClineUsage {
    static func usage(_ data: Data, now: Date) throws -> AIUsage {
        let root = try AIServiceJSON.object(data)
        guard let success = root["success"] as? NSNumber,
              CFGetTypeID(success) == CFBooleanGetTypeID(), success.boolValue,
              let payload = root["data"] as? [String: Any],
              let limits = payload["limits"] as? [[String: Any]] else {
            throw AIUsageProblem.unavailable(retryAfter: nil)
        }
        var windows: [AIQuotaWindow] = []
        for limit in limits {
            let kind: AIQuotaWindow.Kind
            let duration: TimeInterval
            switch limit["type"] as? String {
            case "five_hour": kind = .session; duration = 5 * 3_600
            case "weekly": kind = .weekly; duration = 7 * 86_400
            case "monthly": kind = .monthly; duration = 0
            default: continue
            }
            guard let percent = AIServiceJSON.number(limit["percentUsed"]), percent >= 0,
                  !windows.contains(where: { $0.kind == kind }) else {
                throw AIUsageProblem.unavailable(retryAfter: nil)
            }
            let reset = AIServiceJSON.date(limit["resetsAt"])
            if let value = limit["resetsAt"], !(value is NSNull), (value as? String == nil || reset == nil) {
                throw AIUsageProblem.unavailable(retryAfter: nil)
            }
            windows.append(AIQuotaWindow(kind: kind, used: min(percent / 100, 1), resetsAt: reset, duration: duration))
        }
        guard !windows.isEmpty else { throw AIUsageProblem.unavailable(retryAfter: nil) }
        let order: [AIQuotaWindow.Kind] = [.session, .weekly, .monthly]
        windows.sort { (order.firstIndex(of: $0.kind) ?? 0) < (order.firstIndex(of: $1.kind) ?? 0) }
        return AIUsage(windows: windows, date: now)
    }
}
