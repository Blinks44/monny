import Testing
@testable import monny

struct BatteryPowerBreakdownTests {
    private func reading(_ state: BatteryReading.State = .charging, mac: Double? = 17,
                         charging: Double? = 12, adapter: Int? = 96) -> BatteryReading {
        BatteryReading(level: 0.64, state: state, isFullyCharged: false, adapterWatts: adapter,
                       systemLoad: mac, batteryPower: charging)
    }

    @Test func chargingIncludesBothFlowsAndScalesToAdapterRating() throws {
        let power = BatteryPowerBreakdown(battery: reading())
        #expect(power.totalWatts == 29)
        let fractions = try #require(power.fractions)
        #expect(abs(fractions.mac - 17.0 / 96) < 1e-9)
        #expect(abs(fractions.battery - 12.0 / 96) < 1e-9)
    }

    @Test func missingReadingsNeverProduceAnInventedTotalOrBar() {
        for battery in [nil, reading(mac: nil), reading(charging: nil)] as [BatteryReading?] {
            let power = BatteryPowerBreakdown(battery: battery)
            #expect(power.totalWatts == nil)
            #expect(power.fractions == nil)
        }
        let power = BatteryPowerBreakdown(battery: reading(adapter: nil))
        #expect(power.totalWatts == 29)
        #expect(power.fractions == nil)
    }

    @Test func idleAdapterAndBatteryDoNotAddAChargingFlow() {
        let adapter = BatteryPowerBreakdown(battery: reading(.onAdapter, charging: -4))
        #expect(adapter.totalWatts == 17)
        #expect(adapter.fractions?.battery == 0)
        let battery = BatteryPowerBreakdown(battery: reading(.onBattery, charging: -17))
        #expect(battery.macWatts == 17)
        #expect(battery.adapterWatts == nil)
        #expect(battery.fractions == nil)
    }

    @Test func subWattChargingIsIncludedInTotalButHasNoBatterySegment() {
        let power = BatteryPowerBreakdown(battery: reading(charging: 0.5))
        #expect(power.totalWatts == 17.5)
        #expect(power.fractions?.battery == 0)
        #expect(BatteryPowerBreakdown(battery: reading(charging: 1)).fractions?.battery == 1.0 / 96)
    }

    @Test func overRatingAndInvalidValuesCannotOverflowTheTrack() throws {
        let overRating = BatteryPowerBreakdown(battery: reading(mac: 60, charging: 40, adapter: 50))
        #expect(overRating.totalWatts == 100)
        let fractions = try #require(overRating.fractions)
        #expect(fractions.mac == 0.6)
        #expect(fractions.battery == 0.4)
        for invalid in [-1, Double.infinity, Double.nan] {
            #expect(BatteryPowerBreakdown(battery: reading(mac: invalid)).totalWatts == nil)
            #expect(BatteryPowerBreakdown(battery: reading(charging: invalid)).fractions == nil)
        }
        #expect(BatteryPowerBreakdown(battery: reading(adapter: 0)).fractions == nil)
    }
}
