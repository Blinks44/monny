import Foundation
import Testing
@testable import monny

/// Injected policy observations prove decisions, not SMC writes or hardware support.
struct ChargePolicyTests {
    private var enabled: ChargePolicy.Settings { .init(isEnabled: true) }

    @Test func stopsAtLimitAndUsesSailingRange() {
        var policy = ChargePolicy()
        var settings = enabled
        settings.sailingRange = 0.05
        for (level, action) in [(0.7, ChargePolicy.Action.charge), (0.8, .hold), (0.79, .hold),
                                (0.76, .hold), (0.75, .charge), (0.79, .charge), (0.8, .hold)] {
            #expect(policy.update(settings: settings, reading: .init(level: level, isAdapterConnected: true),
                                  capability: .chargeOnly).action == action)
        }
    }

    @Test func defaultHysteresisPreventsFlapping() {
        var policy = ChargePolicy()
        for (level, action) in [(0.8, ChargePolicy.Action.hold), (0.799, .hold), (0.79, .charge)] {
            #expect(policy.update(settings: enabled, reading: .init(level: level, isAdapterConnected: true),
                                  capability: .chargeOnly).action == action)
        }
    }

    @Test(arguments: [0.8, 1.0])
    func acceptsLimitEndpoints(limit: Double) {
        var policy = ChargePolicy()
        var settings = enabled
        settings.limit = limit
        #expect(policy.update(settings: settings, reading: .init(level: limit, isAdapterConnected: true),
                              capability: .chargeOnly).action == .hold)
    }

    @Test func dischargeStopsAtLimitWithoutRechargingUntilModeChanges() {
        var policy = ChargePolicy()
        var settings = enabled
        settings.mode = .discharge
        for (level, action) in [(0.9, ChargePolicy.Action.discharge), (0.8, .hold), (0.79, .hold), (0.81, .hold)] {
            #expect(policy.update(settings: settings, reading: .init(level: level, isAdapterConnected: true),
                                  capability: .chargeAndDischarge).action == action)
        }
        settings.mode = .charge
        #expect(policy.update(settings: settings, reading: .init(level: 0.79, isAdapterConnected: true),
                              capability: .chargeOnly).action == .charge)
    }

    @Test func heatProtectionHasHysteresisAndPrecedesDischarge() {
        var policy = ChargePolicy()
        var settings = enabled
        settings.mode = .discharge
        settings.heatThreshold = 35
        for (temperature, action) in [(35.0, ChargePolicy.Action.discharge), (35.1, .hold),
                                      (80, .hold), (35, .hold), (34, .hold), (33, .discharge)] {
            #expect(policy.update(settings: settings,
                                  reading: .init(level: 0.9, isAdapterConnected: true, temperature: temperature),
                                  capability: .chargeAndDischarge).action == action)
        }
    }

    @Test(arguments: [Double.nan, .infinity, -1, 0, 151])
    func unknownHeatReadingReleasesControl(temperature: Double) {
        var policy = ChargePolicy()
        var settings = enabled
        settings.heatThreshold = 35
        #expect(policy.update(settings: settings,
                              reading: .init(level: 0.8, isAdapterConnected: true, temperature: temperature),
                              capability: .chargeOnly) == .init(action: .macOS, reason: .invalidReading))
    }

    @Test func missingTemperatureOnlyBlocksWhenProtectionIsEnabled() {
        var policy = ChargePolicy()
        var settings = enabled
        let reading = ChargePolicy.Reading(level: 0.8, isAdapterConnected: true)
        #expect(policy.update(settings: settings, reading: reading, capability: .chargeOnly).action == .hold)
        settings.heatThreshold = 35
        #expect(policy.update(settings: settings, reading: reading, capability: .chargeOnly).action == .macOS)
    }

    @Test(arguments: [Double.nan, .infinity, -0.01, 1.01])
    func invalidBatteryLevelReleasesControl(level: Double) {
        var policy = ChargePolicy()
        #expect(policy.update(settings: enabled, reading: .init(level: level, isAdapterConnected: true),
                              capability: .chargeOnly).action == .macOS)
    }

    @Test func missingStaleOrDisconnectedReadingsReleaseAndReset() {
        let invalid: [ChargePolicy.Reading?] = [nil,
            .init(level: 0.78, isAdapterConnected: false),
            .init(level: 0.78, isAdapterConnected: true, age: .seconds(31)),
            .init(level: 0.78, isAdapterConnected: true, age: .seconds(-1))]
        for reading in invalid {
            var policy = ChargePolicy()
            var settings = enabled
            settings.sailingRange = 0.05
            #expect(policy.update(settings: settings, reading: .init(level: 0.8, isAdapterConnected: true),
                                  capability: .chargeOnly).action == .hold)
            #expect(policy.update(settings: settings, reading: reading, capability: .chargeOnly).action == .macOS)
            #expect(policy.update(settings: settings, reading: .init(level: 0.78, isAdapterConnected: true),
                                  capability: .chargeOnly).action == .charge)
        }
    }

    @Test func unavailableHelperAndDisabledPolicyReleaseControl() {
        var policy = ChargePolicy()
        let reading = ChargePolicy.Reading(level: 0.8, isAdapterConnected: true)
        #expect(policy.update(settings: enabled, reading: reading, capability: .chargeOnly).action == .hold)
        #expect(policy.update(settings: enabled, reading: reading, capability: .unavailable).reason == .unavailable)
        #expect(policy.update(settings: .init(), reading: reading, capability: .chargeOnly).reason == .disabled)
        var settings = enabled
        settings.mode = .discharge
        #expect(policy.update(settings: settings, reading: reading, capability: .chargeOnly).action == .macOS)
    }

    @Test func rejectsInvalidSettingsWithoutClampingThem() {
        var settings = enabled
        var invalid: [ChargePolicy.Settings] = []
        for limit in [0.5, 0.79, 1.01, .nan, .infinity] {
            settings.limit = limit
            invalid.append(settings)
        }
        settings = enabled
        for range in [-0.01, 0.11, .nan] {
            settings.sailingRange = range
            invalid.append(settings)
        }
        settings = enabled
        for threshold in [29.0, 46, .nan] {
            settings.heatThreshold = threshold
            invalid.append(settings)
        }
        for settings in invalid {
            var policy = ChargePolicy()
            #expect(policy.update(settings: settings, reading: .init(level: 0.9, isAdapterConnected: true),
                                  capability: .chargeAndDischarge).reason == .invalidSettings)
        }
    }

    @Test func changingLimitResetsSailingEpisode() {
        var policy = ChargePolicy()
        var settings = enabled
        settings.sailingRange = 0.05
        #expect(policy.update(settings: settings, reading: .init(level: 0.8, isAdapterConnected: true),
                              capability: .chargeOnly).action == .hold)
        settings.limit = 0.85
        #expect(policy.update(settings: settings, reading: .init(level: 0.81, isAdapterConnected: true),
                              capability: .chargeOnly).action == .charge)
    }

    @Test func freshnessBoundaryAndReenabledPolicyStartANewEpisode() {
        var policy = ChargePolicy()
        var settings = enabled
        settings.sailingRange = 0.05
        #expect(policy.update(settings: settings,
                              reading: .init(level: 0.8, isAdapterConnected: true, age: .seconds(30)),
                              capability: .chargeOnly).action == .hold)
        settings.isEnabled = false
        #expect(policy.update(settings: settings, reading: .init(level: 0.78, isAdapterConnected: true),
                              capability: .chargeOnly).action == .macOS)
        settings.isEnabled = true
        #expect(policy.update(settings: settings, reading: .init(level: 0.78, isAdapterConnected: true),
                              capability: .chargeOnly).action == .charge)
    }
}
