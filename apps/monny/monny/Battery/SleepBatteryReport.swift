import Foundation

/// Paired workspace sleep/wake events, not proof of uninterrupted sleep or its cause.
nonisolated struct SleepBatteryReport: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var start: Date
    var end: Date
    var before: Double?
    var after: Double?
    var mayIncludeCharging: Bool

    var pointsUsed: Int? {
        guard !mayIncludeCharging, let before, let after, before.isFinite, after.isFinite,
            (0...1).contains(before), (0...1).contains(after), after <= before
        else { return nil }
        return Int((before * 100).rounded()) - Int((after * 100).rounded())
    }
}

/// Pending endpoints deliberately do not survive app quit or restart.
nonisolated struct SleepBatteryRecorder {
    private var pending: (date: Date, battery: BatteryReading?)?
    private var wake: Date?
    var isWaiting: Bool { pending != nil && wake != nil }

    mutating func sleep(battery: BatteryReading?, at date: Date) {
        pending = (date, battery?.updatedAt.map { (0...120).contains(date.timeIntervalSince($0)) } == true ? battery : nil)
        wake = nil
    }

    mutating func woke(at date: Date) { if pending != nil, wake == nil { wake = date } }

    mutating func sample(_ battery: BatteryReading?, at date: Date) -> SleepBatteryReport? {
        guard let pending, let wake else { return nil }
        // Let the battery gauge refresh after wake. Stop waiting after two minutes.
        guard date.timeIntervalSince(wake) >= 60 else { return nil }
        let fresh = battery?.updatedAt.map { $0 >= wake && $0 <= date } == true
        guard fresh || date.timeIntervalSince(wake) >= 120 else { return nil }
        let battery = fresh ? battery : nil
        self.pending = nil
        self.wake = nil
        guard wake > pending.date, wake.timeIntervalSince(pending.date) <= 7 * 86_400 else { return nil }
        let before = pending.battery?.level
        let after = battery?.level
        return SleepBatteryReport(
            start: pending.date, end: wake, before: before, after: after,
            mayIncludeCharging: pending.battery?.state != .onBattery || battery?.state != .onBattery
                || (after.flatMap { value in before.map { value > $0 } } ?? false))
    }
}

@Observable
final class SleepBatteryHistory {
    private(set) var reports: [SleepBatteryReport] = []
    private(set) var recorder = SleepBatteryRecorder()
    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "sleepBatteryReports"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.key), let saved = try? JSONDecoder().decode([SleepBatteryReport].self, from: data) {
            reports = saved.filter { $0.end > Date.now.addingTimeInterval(-7 * 86_400) }.suffix(100).reversed()
        }
    }

    func sleep(battery: BatteryReading?, at date: Date = .now) { recorder.sleep(battery: battery, at: date) }
    func woke(at date: Date = .now) { recorder.woke(at: date) }

    func sample(_ battery: BatteryReading?, at date: Date = .now) {
        let oldest = date.addingTimeInterval(-7 * 86_400)
        if reports.contains(where: { $0.end <= oldest }) {
            reports.removeAll { $0.end <= oldest }
        }
        guard let report = recorder.sample(battery, at: date) else { return }
        reports.insert(report, at: 0)
        reports = Array(reports.filter { $0.end > date.addingTimeInterval(-7 * 86_400) }.prefix(100))
        if let data = try? JSONEncoder().encode(reports.reversed()) { defaults.set(data, forKey: Self.key) }
    }
}
