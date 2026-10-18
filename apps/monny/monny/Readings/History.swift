import Foundation
import OSLog

nonisolated private let historyLogger = Logger(subsystem: "blinks44.monny", category: "History")

/// A metric kept in history. Values use the snapshot's units: fractions 0…1, bytes per second,
/// °C and rpm. `charging` is 1 while charging and 0 otherwise, so a bucket's average is the
/// share of it spent charging.
nonisolated enum HistoryMetric: String, CaseIterable, Codable, CodingKeyRepresentable, Sendable {
    case cpu, cpuPerformance, cpuEfficiency, memory, diskRead, diskWrite, download, upload, battery, charging
    case cpuTemperature, gpuTemperature, ssdTemperature, batteryTemperature, fan

    /// The values of one snapshot; unavailable readings are left out, never stored as zero.
    static func values(of snapshot: Snapshot) -> [HistoryMetric: Double] {
        var values: [HistoryMetric: Double] = [:]
        values[.cpu] = snapshot.cpu?.total
        values[.cpuPerformance] = snapshot.cpu?.performance
        values[.cpuEfficiency] = snapshot.cpu?.efficiency
        values[.memory] = snapshot.memory?.fraction
        values[.diskRead] = snapshot.disk?.readRate
        values[.diskWrite] = snapshot.disk?.writeRate
        values[.download] = snapshot.network?.download
        values[.upload] = snapshot.network?.upload
        values[.battery] = snapshot.battery?.level
        values[.charging] = snapshot.battery.map { $0.state == .charging ? 1 : 0 }
        values[.cpuTemperature] = snapshot.sensors?.cpu
        values[.gpuTemperature] = snapshot.sensors?.gpu
        values[.ssdTemperature] = snapshot.sensors?.ssd
        values[.batteryTemperature] = snapshot.sensors?.battery
        values[.fan] = snapshot.sensors?.fanRPM.max()
        return values
    }
}

/// One averaged bucket. `date` is the start of the bucket.
nonisolated struct HistoryPoint: Codable, Equatable, Sendable {
    var date: Date
    var values: [HistoryMetric: Double]
}

/// A bounded series for one time range: samples are averaged into buckets of `step` seconds,
/// and buckets older than `span` are dropped. Gaps (sleep, quit) stay gaps.
nonisolated struct HistoryTier: Codable, Equatable, Sendable {
    let span: TimeInterval
    let step: TimeInterval
    private(set) var points: [HistoryPoint] = []
    /// The bucket being filled: its start, value sums and sample counts.
    private var pending: HistoryPoint?
    private var counts: [HistoryMetric: Int] = [:]

    init(span: TimeInterval, step: TimeInterval) {
        self.span = span
        self.step = step
    }

    mutating func add(_ values: [HistoryMetric: Double], at date: Date) {
        let start = Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / step).rounded(.down) * step)
        if let pending, pending.date != start {
            points.append(average(pending))
            self.pending = nil
            counts = [:]
        }
        var bucket = pending ?? HistoryPoint(date: start, values: [:])
        for (metric, value) in values where value.isFinite {
            bucket.values[metric, default: 0] += value
            counts[metric, default: 0] += 1
        }
        pending = bucket
        let oldest = date.addingTimeInterval(-span)
        if let first = points.firstIndex(where: { $0.date >= oldest }) {
            points.removeFirst(first)
        } else {
            points.removeAll()
        }
    }

    /// Finished buckets plus the one being filled, oldest first.
    func series(_ metric: HistoryMetric) -> [(date: Date, value: Double)] {
        (points + [pending.map(average)].compactMap(\.self)).compactMap { point in
            point.values[metric].map { (point.date, $0) }
        }
    }

    private func average(_ bucket: HistoryPoint) -> HistoryPoint {
        var point = bucket
        for (metric, sum) in bucket.values {
            point.values[metric] = sum / Double(max(counts[metric] ?? 1, 1))
        }
        return point
    }
}

/// History for the 1m, 1h, 24h and 7d ranges ([research](docs/research/README.md#history-storage-decision)).
/// The 24h and 7d tiers survive a restart in a small file in Application Support.
@Observable
final class History {
    private(set) var minute = HistoryTier(span: 60, step: 1)
    private(set) var hour = HistoryTier(span: 3_600, step: 10)
    private(set) var day = HistoryTier(span: 86_400, step: 60)
    private(set) var week = HistoryTier(span: 7 * 86_400, step: 600)

    @ObservationIgnored private var lastSave = Date.now

    func tier(_ range: HistoryRange) -> HistoryTier {
        switch range {
        case .minute: minute
        case .hour: hour
        case .day: day
        case .week: week
        }
    }

    func record(_ snapshot: Snapshot, at date: Date = .now) {
        let values = HistoryMetric.values(of: snapshot)
        minute.add(values, at: date)
        hour.add(values, at: date)
        day.add(values, at: date)
        week.add(values, at: date)
        if date.timeIntervalSince(lastSave) >= 300 {
            lastSave = date
            save()
        }
    }

    // MARK: Persistence

    nonisolated private struct Saved: Codable, Sendable {
        var day: HistoryTier
        var week: HistoryTier
    }

    static var fileURL: URL {
        URL.applicationSupportDirectory.appending(components: "blinks44.monny", "History.plist")
    }

    /// Restores the 24h and 7d tiers; reads and decodes off the main actor.
    func load() async {
        let url = Self.fileURL
        let saved = await Task.detached(priority: .utility) { () -> Saved? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? PropertyListDecoder().decode(Saved.self, from: data)
        }.value
        guard let saved, saved.day.step == day.step, saved.week.step == week.step else { return }
        day = saved.day
        week = saved.week
    }

    /// Writes in the background; `synchronously` is for quitting, when there is no later.
    func save(synchronously: Bool = false) {
        let saved = Saved(day: day, week: week)
        let url = Self.fileURL
        let write: @Sendable () -> Void = {
            do {
                let encoder = PropertyListEncoder()
                encoder.outputFormat = .binary
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try encoder.encode(saved).write(to: url, options: .atomic)
            } catch {
                historyLogger.error("Saving history failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        if synchronously { write() } else { Task.detached(priority: .utility, operation: write) }
    }
}
