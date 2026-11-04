import Foundation

/// Rates × bucket duration are historical estimates, not billing counters. Missing metrics
/// and unobserved days stay nil. Calendar grouping follows local days, including DST changes.
nonisolated struct DailyTraffic: Identifiable, Sendable {
    let date: Date
    var download: Double?
    var upload: Double?
    var id: Date { date }
    var total: Double? {
        guard let download, let upload else { return nil }
        return download + upload
    }

    static func days(in tier: HistoryTier, now: Date = .now, calendar: Calendar = .current) -> [DailyTraffic] {
        var down: [Date: Double] = [:], up: [Date: Double] = [:]
        for point in tier.series(.download) {
            down[calendar.startOfDay(for: point.date), default: 0] += point.value * tier.step
        }
        for point in tier.series(.upload) {
            up[calendar.startOfDay(for: point.date), default: 0] += point.value * tier.step
        }
        let today = calendar.startOfDay(for: now)
        return (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
            .map { DailyTraffic(date: $0, download: down[$0], upload: up[$0]) }
    }
}
