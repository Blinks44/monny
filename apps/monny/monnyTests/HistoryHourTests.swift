import Foundation
import Testing

@testable import monny

struct HistoryHourTests {
    private let start = Date(timeIntervalSinceReferenceDate: 360_000)
    private let step: TimeInterval = 600

    @Test func summarizesAFullWeekInto168Hours() throws {
        let points = (0..<1_008).map { point(Double($0) * step, Double($0 % 6)) }
        let hours = HistoryHour.summarize(points, step: step, in: start...start.addingTimeInterval(604_800))
        let first = try #require(hours.first)
        #expect(hours.count == 168)
        #expect(hours.allSatisfy { $0.segment == 0 && $0.average == 2.5 && $0.peak == 5 })
        #expect(first.coverage == first.hour)
        #expect(first.date == start.addingTimeInterval(1_800))
    }

    @Test func splitsMissingReadingsInsideAnHourAndAcrossSleep() {
        let points = [point(0, 0.2), point(600, 0.4), point(1_800, 0.8), point(2_400, 0.6), point(7_200, 0.3)]
        let hours = HistoryHour.summarize(points, step: step, in: start...start.addingTimeInterval(7_800))
        #expect(hours.map(\.segment) == [0, 1, 2])
        #expect(hours.map(\.peak) == [0.4, 0.8, 0.3])
        #expect(!hours.contains { $0.coverage.contains(start.addingTimeInterval(1_200)) })
        #expect(!hours.contains { $0.coverage.contains(start.addingTimeInterval(3_600)) })
        let plot = PlotPoint.hourlySeries("cpu", hours)
        #expect(Set(plot.map(\.series)).count == 3)
        #expect(PlotPoint.isolated(in: plot).count == 3)
    }

    @Test func limitsTheActiveHourToObservedDataInTheVisibleWindow() throws {
        let points = [point(-600, 100), point(0, 50), point(600, 70), point(1_200, 90)]
        let now = start.addingTimeInterval(720)
        let hours = HistoryHour.summarize(points, step: step, in: start...now)
        let hour = try #require(hours.first)
        #expect(hours.count == 1)
        #expect(hour.average == 60)
        #expect(hour.peak == 70)
        #expect(hour.coverage == start..<now)
        #expect(hour.hour == start..<start.addingTimeInterval(3_600))
    }

    private func point(_ offset: TimeInterval, _ value: Double) -> (date: Date, value: Double) {
        (start.addingTimeInterval(offset), value)
    }
}
