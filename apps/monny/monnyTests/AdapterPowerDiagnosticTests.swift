import Foundation
import IOKit.ps
import Testing
@testable import monny

struct AdapterPowerDiagnosticTests {
    private var battery: [String: Any] {
        [kIOPSTypeKey: kIOPSInternalBatteryType, kIOPSIsPresentKey: true,
         kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue, kIOPSIsChargingKey: false,
         kIOPSCurrentCapacityKey: 75, kIOPSMaxCapacityKey: 100]
    }

    private func report(registry: [String: Any]? = nil,
                        availability: AdapterPowerDiagnostics.Availability = .available) -> AdapterPowerDiagnostics {
        .decode(powerSources: [battery], smartBattery: registry, registryAvailability: availability,
                publicAdapter: nil, appBuild: "fixture")
    }

    @Test func independentFlagsArePreservedWithoutInferringPhysicalSupport() {
        let reading = report(registry: ["ExternalConnected": false, "AppleRawExternalConnected": true,
                                       "ExternalChargeCapable": false, "BatteryInstalled": true,
                                       "IsCharging": false, "AdapterDetails": ["Watts": 100]])
        #expect(reading.powerSource.availability == .available)
        #expect(reading.powerSource.source == .battery)
        #expect(reading.powerSource.isCharging == false)
        #expect(reading.smartBattery.externalConnected == .no)
        #expect(reading.smartBattery.rawExternalConnected == .yes)
        #expect(reading.smartBattery.externalChargeCapable == .no)
        #expect(reading.smartBattery.isCharging == .no)
        #expect(reading.smartBattery.adapterDetails == .populated)
        #expect(reading.publicAdapterDetails == .unavailable)
        #expect(reading.physicalAdapterSupport == .unverified)
    }

    @Test(arguments: [AdapterPowerDiagnostics.Availability.unavailable, .notFound, .ambiguous, .invalid])
    func failedRegistryReadNeverBecomesDisconnected(availability: AdapterPowerDiagnostics.Availability) {
        let reading = report(registry: ["AppleRawExternalConnected": false], availability: availability)
        #expect(reading.smartBattery.availability == availability)
        #expect(reading.smartBattery.rawExternalConnected == .missing)
        #expect(reading.smartBattery.externalConnected == .missing)
        #expect(reading.smartBattery.adapterDetails == .unavailable)
    }

    @Test func malformedAndMissingFlagsAreDistinctFromFalse() {
        let reading = report(registry: ["ExternalConnected": 0, "AppleRawExternalConnected": "true",
                                       "ExternalChargeCapable": 1, "IsCharging": NSNull(), "AdapterDetails": []])
        #expect(reading.smartBattery.externalConnected == .invalid)
        #expect(reading.smartBattery.rawExternalConnected == .invalid)
        #expect(reading.smartBattery.externalChargeCapable == .invalid)
        #expect(reading.smartBattery.isCharging == .invalid)
        #expect(reading.smartBattery.batteryInstalled == .missing)
        #expect(reading.smartBattery.adapterDetails == .invalid)
        #expect(report(registry: [:]).smartBattery.adapterDetails == .missing)
        #expect(report().smartBattery.availability == .invalid)
    }

    @Test func adapterDictionaryShapeDoesNotGrantCablePresence() {
        let empty = report(registry: ["AdapterDetails": [String: Any]()])
        #expect(empty.smartBattery.adapterDetails == .empty)
        #expect(empty.physicalAdapterSupport == .unverified)
        let publicReport = AdapterPowerDiagnostics.decode(powerSources: [battery], smartBattery: [:],
            registryAvailability: .available, publicAdapter: [:], appBuild: "fixture")
        #expect(publicReport.publicAdapterDetails == .empty)
        #expect(publicReport.smartBattery.rawExternalConnected == .missing)
        #expect(publicReport.physicalAdapterSupport == .unverified)
    }

    @Test func missingAmbiguousAndMalformedSourcesNeverDefaultToBattery() {
        let inputs: [([[String: Any]]?, AdapterPowerDiagnostics.Availability)] = [
            (nil, .unavailable), ([], .notFound), ([battery, battery], .ambiguous),
            ([[kIOPSTypeKey: kIOPSInternalBatteryType]], .invalid)
        ]
        for (sources, expected) in inputs {
            let reading = AdapterPowerDiagnostics.decode(powerSources: sources, smartBattery: nil,
                registryAvailability: .unavailable, publicAdapter: nil, appBuild: "fixture")
            #expect(reading.powerSource.availability == expected)
            #expect(reading.powerSource.source == .unknown)
            #expect(reading.powerSource.isCharging == nil)
        }
    }

    @Test func serializedOutputContainsOnlySanitizedReadings() throws {
        let marker = "SENSITIVE_FIXTURE_MUST_NOT_ESCAPE"
        var rawBattery = battery
        rawBattery["Serial"] = marker
        let reading = AdapterPowerDiagnostics.decode(powerSources: [rawBattery],
            smartBattery: ["Serial": marker, "BatteryData": ["UUID": marker],
                           "AdapterDetails": ["SerialString": marker, "AdapterID": marker]],
            registryAvailability: .available, publicAdapter: ["SerialString": marker], appBuild: "fixture")
        let data = try AdapterPowerDiagnosticCommand.encode(reading)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains(marker) == false)
        #expect(json.contains("Serial") == false)
        #expect(json.contains("AdapterID") == false)
        #expect(json.contains("BatteryData") == false)
        #expect(json.hasSuffix("\n"))
        #expect(try JSONDecoder().decode(AdapterPowerDiagnostics.self, from: data) == reading)
        #expect(data.count < 4_096)
    }
}
