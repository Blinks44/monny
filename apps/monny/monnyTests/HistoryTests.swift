import Foundation
import Testing

@testable import monny

/// Bucketing, trimming and persistence of the history tiers.
struct HistoryTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func averagesSamplesWithinABucket() {
        var tier = HistoryTier(span: 600, step: 10)
        tier.add([.cpu: 0.2, .fan: 1_000], at: start)
        tier.add([.cpu: 0.4], at: start.addingTimeInterval(5))
        tier.add([.cpu: 0.9], at: start.addingTimeInterval(10))
        let cpu = tier.series(.cpu)
        #expect(cpu.map(\.value).count == 2)
        #expect(abs(cpu[0].value - 0.3) < 1e-9)
        #expect(cpu[1].value == 0.9)
        // A metric missing from a sample is averaged over the samples that had it.
        #expect(tier.series(.fan).map(\.value) == [1_000])
    }

    @Test func dropsBucketsOlderThanTheSpan() {
        var tier = HistoryTier(span: 60, step: 10)
        for second in stride(from: 0, through: 120, by: 10) {
            tier.add([.cpu: Double(second)], at: start.addingTimeInterval(TimeInterval(second)))
        }
        let dates = tier.series(.cpu).map(\.date)
        #expect(dates.first! >= start.addingTimeInterval(60))
        #expect(dates.count <= 7)
    }

    @Test func leavesGapsAfterSleep() {
        var tier = HistoryTier(span: 3_600, step: 10)
        tier.add([.cpu: 0.1], at: start)
        tier.add([.cpu: 0.2], at: start.addingTimeInterval(1_800))
        #expect(tier.series(.cpu).count == 2)
    }

    @Test func chartBreaksAcrossMissingBuckets() {
        var tier = HistoryTier(span: 3_600, step: 10)
        for offset in [0.0, 10, 1_800, 1_810, 2_000] {
            tier.add([.battery: 0.8], at: start.addingTimeInterval(offset))
        }
        let points = PlotPoint.series("level", tier.series(.battery), tier: tier)
        #expect(points.count == 5)
        #expect(points[0].series == points[1].series)
        #expect(points[1].series != points[2].series)
        #expect(points[2].series == points[3].series)
        #expect(PlotPoint.isolated(in: points).map(\.date) == [start.addingTimeInterval(2_000)])
    }

    @Test func keepsOneBucketPerTimestampAfterAClockCorrection() {
        var tier = HistoryTier(span: 3_600, step: 10)
        tier.add([.cpu: 0.1, .fan: 1_000], at: start)
        tier.add([.cpu: 0.2], at: start.addingTimeInterval(10))
        tier.add([.cpu: 0.3], at: start)
        #expect(tier.series(.cpu).map(\.value) == [0.3, 0.2])
        tier.add([.cpu: 0.4], at: start.addingTimeInterval(20))
        #expect(tier.series(.cpu).map(\.value) == [0.3, 0.2, 0.4])
        #expect(tier.series(.fan).map(\.value) == [1_000])
    }

    @Test func sortsLegacyBucketsAndPrefersTheLastStoredValue() throws {
        let later = start.addingTimeInterval(10)
        let data = try PropertyListSerialization.data(
            fromPropertyList: [
                "span": 3_600, "step": 10, "counts": [String: Int](),
                "points": [
                    ["date": later, "values": ["cpu": 0.2]],
                    ["date": start, "values": ["cpu": 0.1, "fan": 1_000]],
                    ["date": start, "values": ["cpu": 0.3]],
                ],
            ], format: .binary, options: 0)
        var tier = try PropertyListDecoder().decode(HistoryTier.self, from: data)
        tier.sortStoredBuckets()
        #expect(tier.series(.cpu).map(\.date) == [start, later])
        #expect(tier.series(.cpu).map(\.value) == [0.3, 0.2])
        #expect(tier.series(.fan).map(\.value) == [1_000])
    }

    @Test func unavailableReadingsAreNotStored() {
        let snapshot = Snapshot(
            cpu: nil, memory: nil, disk: nil, network: NetworkRates(download: 10, upload: 2), battery: nil,
            sensors: nil, thermalState: .nominal, processes: [])
        let values = HistoryMetric.values(of: snapshot)
        #expect(values == [.download: 10, .upload: 2])
    }

    /// Views see a tier change only when a bucket closes, not on every sample.
    @MainActor @Test func publishesATierWhenABucketCloses() {
        let history = History()
        let snapshot = Snapshot(
            cpu: nil, memory: nil, disk: nil, network: NetworkRates(download: 10, upload: 2), battery: nil,
            sensors: nil, thermalState: .nominal, processes: [])
        history.record(snapshot, interval: 2, at: start)
        history.record(snapshot, interval: 2, at: start.addingTimeInterval(2))
        #expect(history.minute.series(.download).count == 2)
        #expect(history.hour.series(.download).isEmpty)
        history.record(snapshot, interval: 2, at: start.addingTimeInterval(10))
        #expect(history.hour.series(.download).count == 2)
    }

    @MainActor @Test(arguments: [1.0, 2, 5]) func minuteNetworkSeriesJoinScheduledSamplesAndBreakAfterWake(interval: TimeInterval) throws {
        let history = History()
        let snapshot = Snapshot(
            cpu: nil, memory: nil, disk: nil, network: NetworkRates(download: 10, upload: 2), battery: nil,
            sensors: nil, thermalState: .nominal, processes: [])
        // Offset the samples across second boundaries to exercise normal scheduler jitter.
        let offsets = [0.9, interval + 1.1, 2 * interval + 1.2, 3 * interval + 1.3, 4 * interval + 1.5, 7 * interval + 2]
        for (index, offset) in offsets.enumerated() {
            // The first post-wake sample can still arrive within the regular time limit.
            if index == 3 { history.markWake() }
            history.record(snapshot, interval: interval, at: start.addingTimeInterval(offset))
        }

        for metric in [HistoryMetric.download, .upload] {
            let points = PlotPoint.series(metric.rawValue, history.minute.series(metric), tier: history.minute)
            try #require(points.count == offsets.count)
            #expect(
                points.map(\.series) == [
                    metric.rawValue, metric.rawValue, metric.rawValue,
                    points[3].series, points[3].series, points[5].series,
                ])
            #expect(Set(points.map(\.series)).count == 3)
        }
    }

    @MainActor @Test func minuteSeriesUsesThePreviousSamplesCadenceAndLeavesMissingReadingsOpen() {
        let history = History()
        let reading = Snapshot(
            cpu: nil, memory: nil, disk: nil, network: NetworkRates(download: 10, upload: 2), battery: nil,
            sensors: nil, thermalState: .nominal, processes: [])
        let unavailable = Snapshot(
            cpu: nil, memory: nil, disk: nil, network: nil, battery: nil,
            sensors: nil, thermalState: .nominal, processes: [])
        history.record(reading, interval: 10, at: start)
        history.record(reading, interval: 2, at: start.addingTimeInterval(9))
        history.record(unavailable, interval: 2, at: start.addingTimeInterval(11))
        history.record(reading, interval: 2, at: start.addingTimeInterval(13))
        let tier = history.minute
        let points = PlotPoint.series("download", tier.series(.download), tier: tier)
        #expect(points.map(\.date) == [start, start.addingTimeInterval(9), start.addingTimeInterval(13)])
        #expect(points.prefix(2).allSatisfy { $0.series == "download" })
        #expect(PlotPoint.isolated(in: points).map(\.date) == [start.addingTimeInterval(13)])
    }

    @Test func roundTripsThroughAPropertyList() throws {
        var tier = HistoryTier(span: 86_400, step: 60)
        tier.add([.battery: 0.8], at: start)
        tier.add([.battery: 0.7], at: start.addingTimeInterval(60))
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let decoded = try PropertyListDecoder().decode(HistoryTier.self, from: encoder.encode(tier))
        #expect(decoded == tier)
        #expect(decoded.series(.battery).map(\.value) == [0.8, 0.7])
    }
}
