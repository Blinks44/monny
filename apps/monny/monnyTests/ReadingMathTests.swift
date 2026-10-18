import Foundation
import Testing
@testable import monny

/// Fixture values for the reading math; the readers only add the system calls around it.
struct ReadingMathTests {
    @Test func cpuLoadSplitsClusters() throws {
        // Two cores (E, P), ticks per core: user, system, idle, nice.
        let previous: [UInt32] = [100, 50, 850, 0, 1_000, 0, 1_000, 0]
        let current: [UInt32] = [110, 60, 930, 0, 1_060, 20, 1_020, 0]
        let load = try #require(CPULoad(previous: previous, current: current, kinds: [.efficiency, .performance]))
        #expect(load.cores == [0.2, 0.8])
        #expect(load.efficiency == 0.2)
        #expect(load.performance == 0.8)
        #expect(load.total == 0.5)
        #expect(abs(load.system - 0.15) < 1e-9)
        #expect(abs(load.user - 0.35) < 1e-9)
    }

    @Test func cpuTicksSurviveCounterWrap() throws {
        let previous: [UInt32] = [UInt32.max - 9, 0, 0, 0]
        let current: [UInt32] = [10, 0, 20, 0]
        let load = try #require(CPULoad(previous: previous, current: current, kinds: [.performance]))
        #expect(load.total == 0.5)
    }

    @Test func memoryUsedMatchesActivityMonitorFormula() {
        let used = MemoryUsage.used(internalPages: 1_000, purgeable: 100, wired: 200, compressed: 300, pageSize: 16_384)
        #expect(used == 1_400 * 16_384)
    }

    @Test func ratesAreBytesPerSecondAndResetOnDecrease() {
        var counter = RateCounter()
        let start = ContinuousClock.now
        #expect(counter.rates(for: [1_000, 0], at: start) == nil)
        #expect(counter.rates(for: [3_000, 500], at: start + .seconds(2)) == [1_000, 250])
        #expect(counter.rates(for: [10, 600], at: start + .seconds(4)) == nil)
    }

    @Test(arguments: [(-1, nil), (0, nil), (65_535, nil), (95, Duration.seconds(95 * 60))])
    func powerSourceEstimates(minutes: Int, expected: Duration?) {
        #expect(PowerReader.estimate(minutes) == expected)
    }

    @Test func batteryHealthFromSystemProfiler() throws {
        let json = """
        {"SPPowerDataType":[{"_name":"spbattery_information","sppower_battery_health_info":\
        {"sppower_battery_cycle_count":96,"sppower_battery_health":"Good","sppower_battery_health_maximum_capacity":"97 %"}}]}
        """
        let health = try #require(BatteryHealthReader.parse(Data(json.utf8)))
        #expect(health.maximumCapacity == 0.97)
        #expect(health.condition == "Good")
    }
}
