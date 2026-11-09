import CoreGraphics
import Foundation
import Testing

@testable import monny

struct AIQuotaHistoryTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1000)
    private var domain: ClosedRange<Date> { start...start.addingTimeInterval(100) }
    private let size = CGSize(width: 100, height: 100)

    private func series(_ tool: AITool, _ values: [(Double, Double)]) -> AIQuotaHistory.Series {
        .init(tool: tool, metric: .aiQuota(tool, .weekly), points: values.map { (start.addingTimeInterval($0.0), $0.1) })
    }

    @Test func selectsRecordedPointAcrossRefillAndPreservesItsTime() throws {
        let data = [series(.codex, [(10, 0.02), (30, 0.98)])]
        let point = try #require(AIQuotaHistory.nearest(in: data, to: CGPoint(x: 22, y: 3), size: size, domain: domain, current: nil))
        #expect(point.date == start.addingTimeInterval(30))
        #expect(point.value == 0.98)
    }

    @Test func nearestCurveAndCoincidentServicesRemainReachable() throws {
        let data = [series(.claude, [(20, 0.2)]), series(.codex, [(20, 0.8)]), series(.copilot, [(20, 0.8)])]
        let codex = try #require(AIQuotaHistory.nearest(in: data, to: CGPoint(x: 20, y: 20), size: size, domain: domain, current: nil))
        #expect(codex.tool == .codex)
        let copilot = try #require(AIQuotaHistory.moved(codex, in: data, service: 1))
        #expect(copilot.tool == .copilot)
        #expect(AIQuotaHistory.nearest(in: data, to: CGPoint(x: 20, y: 20), size: size, domain: domain, current: copilot)?.tool == .copilot)
    }

    @Test func noSelectionOutsidePlotOrWithoutValidHistory() {
        let data = [series(.codex, [(20, 0.8)])]
        #expect(AIQuotaHistory.nearest(in: data, to: CGPoint(x: -1, y: 20), size: size, domain: domain, current: nil) == nil)
        #expect(AIQuotaHistory.nearest(in: [], to: .zero, size: size, domain: domain, current: nil) == nil)
        #expect(
            AIQuotaHistory.nearest(
                in: [series(.codex, [(-10, 0.8), (110, 0.8), (20, .nan)])], to: CGPoint(x: 20, y: 20), size: size, domain: domain,
                current: nil) == nil)
        #expect(AIQuotaHistory.moved(nil, in: []) == nil)
    }

    @Test func keyboardClampsAndSwitchesAtNearestRecordedTime() throws {
        let data = [series(.claude, [(10, 0.2), (30, 0.3)]), series(.codex, [(12, 0.8), (32, 0.7)])]
        let latest = try #require(AIQuotaHistory.moved(nil, in: data))
        #expect(latest.date == start.addingTimeInterval(30))
        let earlier = try #require(AIQuotaHistory.moved(latest, in: data, time: -1))
        #expect(earlier.date == start.addingTimeInterval(10))
        #expect(AIQuotaHistory.moved(earlier, in: data, time: -1) == earlier)
        #expect(AIQuotaHistory.moved(latest, in: data, service: 1)?.date == start.addingTimeInterval(32))
        #expect(AIQuotaHistory.resolved(latest, in: [series(.codex, [(32, 0.7)])]) == nil)
        #expect(AIQuotaHistory.resolved(latest, in: [series(.claude, [(30, 0.4)])])?.value == 0.4)
    }

    @Test func periodBelongsToHistoricalMetricWithoutInventingUnknownDurations() {
        #expect(AIQuotaHistory.Series(tool: .kimi, metric: .kimiSession, points: []).period == .session)
        #expect(AIQuotaHistory.Series(tool: .kimi, metric: .kimiMonthly, points: []).period == .monthly)
        #expect(AIQuotaHistory.Series(tool: .codex, metric: .codexWeekly, points: []).period == .weekly)
        #expect(AIQuotaHistory.Series(tool: .amp, metric: .ampFree, points: []).period == nil)
        #expect(AIQuotaHistory.Series(tool: .gemini, metric: .geminiPro, points: []).period == nil)
    }

    @Test func tooltipStaysInsidePlotAtAllFourCorners() {
        let plot = CGRect(x: 40, y: 10, width: 440, height: 190)
        let tip = CGSize(width: 176, height: 66)
        for point in [CGPoint(x: 40, y: 10), CGPoint(x: 480, y: 10), CGPoint(x: 40, y: 200), CGPoint(x: 480, y: 200)] {
            let center = AIQuotaHistory.tooltipCenter(point: point, size: tip, plot: plot)
            let rect = CGRect(x: center.x - tip.width / 2, y: center.y - tip.height / 2, width: tip.width, height: tip.height)
            #expect(plot.insetBy(dx: 12, dy: 12).contains(rect))
            #expect(rect.contains(point) == false)
        }
    }
}
