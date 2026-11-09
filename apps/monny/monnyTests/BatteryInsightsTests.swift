import Foundation
import Testing

@testable import monny

struct BatteryInsightsTests {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    private func battery(_ level: Double, state: BatteryReading.State = .onBattery, power: Double? = -8, at date: Date) -> BatteryReading {
        BatteryReading(level: level, state: state, isFullyCharged: false, adapterWatts: 30, batteryPower: power, updatedAt: date)
    }

    @Test func dischargeTakesPriorityOverLimitAndMissingPowerIsUnknown() {
        #expect(ChargingDiagnosis(battery: battery(0.8, state: .onAdapter, at: now), limit: 80) == .draining)
        #expect(ChargingDiagnosis(battery: battery(0.8, state: .onAdapter, power: nil, at: now), limit: 80) == .unavailable)
        #expect(ChargingDiagnosis(battery: battery(0.8, state: .onAdapter, power: 0, at: now), limit: 80) == .limited)
        #expect(ChargingDiagnosis(battery: battery(0.5, state: .onAdapter, power: 0, at: now), limit: 80) == .connected)
    }

    @Test func pairedSleepRequiresFreshEndpointsAndReportsPercentagePoints() throws {
        var recorder = SleepBatteryRecorder()
        recorder.sleep(battery: battery(0.8, at: now), at: now)
        let wake = now.addingTimeInterval(8 * 3600)
        recorder.woke(at: wake)
        #expect(recorder.sample(battery(0.8, at: now), at: wake.addingTimeInterval(60)) == nil)
        let result = recorder.sample(battery(0.72, at: wake), at: wake.addingTimeInterval(70))
        let report = try #require(result)
        #expect(report.pointsUsed == 8)
        #expect(report.end == wake)
        #expect(recorder.sample(battery(0.72, at: wake), at: wake.addingTimeInterval(80)) == nil)
    }

    @Test func noPairAndMissingWakeReadingDoNotInventLoss() throws {
        var recorder = SleepBatteryRecorder()
        recorder.woke(at: now)
        #expect(recorder.sample(battery(0.7, at: now), at: now.addingTimeInterval(120)) == nil)
        recorder.sleep(battery: battery(0.8, at: now), at: now)
        let wake = now.addingTimeInterval(3600)
        recorder.woke(at: wake)
        let result = recorder.sample(battery(0.8, at: now), at: wake.addingTimeInterval(120))
        let report = try #require(result)
        #expect(report.after == nil)
        #expect(report.pointsUsed == nil)
    }

    @Test func chargeGainCannotBeCalledDrain() throws {
        var recorder = SleepBatteryRecorder()
        recorder.sleep(battery: battery(0.72, at: now), at: now)
        let wake = now.addingTimeInterval(3600)
        recorder.woke(at: wake)
        let result = recorder.sample(battery(0.8, at: wake), at: wake.addingTimeInterval(60))
        let report = try #require(result)
        #expect(report.mayIncludeCharging)
        #expect(report.pointsUsed == nil)
    }
    @MainActor @Test func completedReportSurvivesRestartButPendingSleepDoesNot() throws {
        let name = "monny.sleep-test." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let history = SleepBatteryHistory(defaults: defaults)
        let start = Date.now.addingTimeInterval(-3600)
        let wake = Date.now.addingTimeInterval(-70)
        history.sleep(battery: battery(0.8, at: start), at: start)
        history.woke(at: wake)
        history.sample(battery(0.72, at: wake))
        let restored = SleepBatteryHistory(defaults: defaults)
        #expect(restored.reports.count == 1)
        #expect(restored.reports.first?.pointsUsed == 8)
        #expect(restored.recorder.isWaiting == false)
        history.sample(nil, at: Date.now.addingTimeInterval(8 * 86400))
        #expect(history.reports.isEmpty)
    }

}
