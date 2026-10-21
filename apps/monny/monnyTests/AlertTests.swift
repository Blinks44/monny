import Foundation
import Testing
@testable import monny

/// When alerts fire and re-arm.
struct AlertTests {
    private func snapshot(thermal: ProcessInfo.ThermalState = .nominal, cpu: Double? = nil,
                          battery: BatteryReading? = nil, pressure: MemoryUsage.Pressure? = nil) -> Snapshot {
        Snapshot(memory: pressure.map { MemoryUsage(used: 0, total: 1, swapUsed: 0, pressure: $0) },
                 battery: battery,
                 sensors: cpu.map { SensorReading(cpu: $0, fanRPM: []) },
                 thermalState: thermal, processes: [])
    }

    private func battery(_ level: Double, _ state: BatteryReading.State) -> BatteryReading {
        BatteryReading(level: level, state: state, isFullyCharged: false)
    }

    @Test func heatFiresOncePerEpisode() {
        var monitor = AlertMonitor()
        #expect(monitor.update(with: snapshot()).isEmpty)
        #expect(monitor.update(with: snapshot(thermal: .serious, cpu: 92)) == [.hot(cpuCelsius: 92)])
        #expect(monitor.needsAttention)
        #expect(monitor.update(with: snapshot(thermal: .critical, cpu: 95)).isEmpty)
        // Fair is no longer hot, so the next Serious is a new episode.
        #expect(monitor.update(with: snapshot(thermal: .fair)).isEmpty)
        #expect(!monitor.needsAttention)
        #expect(monitor.update(with: snapshot(thermal: .serious)) == [.hot(cpuCelsius: nil)])
    }

    @Test func busyAppFiresAfterFiveMinutesOncePerEpisode() {
        var monitor = AlertMonitor()
        let xcode = AppOwner(pid: 7, name: "Xcode")
        func pass(_ cpu: Double, at minute: Double) -> [AlertMonitor.Alert] {
            var reading = snapshot()
            // Helpers count toward their app: 0.5 + 0.4 is over the 0.8 threshold.
            reading.processes = [ProcessUsage(id: 7, name: "Xcode", app: xcode, cpu: cpu / 2, memory: 0, power: 0),
                                 ProcessUsage(id: 8, name: "SourceKitService", app: xcode, cpu: cpu / 2, memory: 0, power: 0)]
            return monitor.update(with: reading, now: Date(timeIntervalSinceReferenceDate: minute * 60))
        }
        #expect(pass(0.9, at: 0).isEmpty)
        #expect(pass(0.9, at: 4.9).isEmpty)
        #expect(pass(0.9, at: 5) == [.busyApp(pid: 7, name: "Xcode")])
        #expect(pass(0.9, at: 6).isEmpty)
        // Dropping below the threshold ends the episode and restarts the five minutes.
        #expect(pass(0.5, at: 7).isEmpty)
        #expect(pass(0.9, at: 8).isEmpty)
        #expect(pass(0.9, at: 13) == [.busyApp(pid: 7, name: "Xcode")])
    }

    @Test func lowBatteryOnlyOnBatteryPower() {
        var monitor = AlertMonitor()
        #expect(monitor.update(with: snapshot(battery: battery(0.15, .charging))).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.19, .onBattery))) == [.lowBattery(level: 0.19, timeToEmpty: nil)])
        #expect(monitor.update(with: snapshot(battery: battery(0.12, .onBattery))).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.13, .charging))).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.12, .onBattery))).count == 1)
        // A pass without a battery reading keeps the episode.
        #expect(monitor.update(with: snapshot()).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.11, .onBattery))).isEmpty)
    }

    @Test func chargeLimitFiresOncePerPlugIn() {
        var monitor = AlertMonitor()
        #expect(monitor.update(with: snapshot(battery: battery(0.80, .onBattery)), chargeLimit: 80).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.79, .onAdapter)), chargeLimit: 80).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.80, .onAdapter)), chargeLimit: 80) == [.chargeLimitReached(80)])
        #expect(monitor.update(with: snapshot(battery: battery(0.80, .onAdapter)), chargeLimit: 80).isEmpty)
        // macOS lets the level drift below the limit while plugged in; that is the same episode.
        #expect(monitor.update(with: snapshot(battery: battery(0.79, .onAdapter)), chargeLimit: 80).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.80, .onAdapter)), chargeLimit: 80).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.78, .onBattery)), chargeLimit: 80).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.80, .onAdapter)), chargeLimit: 80) == [.chargeLimitReached(80)])
        #expect(monitor.update(with: snapshot(battery: battery(0.80, .onAdapter))).isEmpty)
        #expect(monitor.update(with: snapshot(battery: battery(0.80, .onAdapter)), chargeLimit: 80) == [.chargeLimitReached(80)])
    }

    @Test func memoryPressureRearmsAtNormal() {
        var monitor = AlertMonitor()
        #expect(monitor.update(with: snapshot(pressure: .warning)) == [.memoryPressure])
        #expect(!monitor.needsAttention)
        #expect(monitor.update(with: snapshot(pressure: .critical)).isEmpty)
        #expect(monitor.needsAttention)
        #expect(monitor.update(with: snapshot(pressure: .warning)).isEmpty)
        #expect(monitor.update(with: snapshot(pressure: .normal)).isEmpty)
        #expect(monitor.update(with: snapshot(pressure: .critical)) == [.memoryPressure])
    }

    @Test @MainActor func chargeLimitBodyAddsTheLevelInsteadOfRepeatingTheTitle() {
        let alert = AlertMonitor.Alert.chargeLimitReached(80)
        let body = alert.body(unit: .celsius)
        #expect(body.contains(0.8.percentText))
        #expect(!body.contains(alert.title))
    }
}
