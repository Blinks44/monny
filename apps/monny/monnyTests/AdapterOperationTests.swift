import Foundation
import IOKit.ps
import Testing
@testable import monny

struct AdapterOperationTests {
    private func inspection(byte: UInt8 = 0, type: String = "hex_", size: UInt32 = 1,
                            attributes: UInt8 = 0xD4) -> SMCKeyInspection {
        .readable(metadata: .init(type: type, size: size, attributes: attributes),
                  value: .init(type: type, bytes: [byte]))
    }

    @Test func fixedSetterRefusesAlreadyIsolatedInputAndRestoresIdempotently() throws {
        #expect(try AdapterIsolationCommand.byte(isolated: true, inspection: inspection()) == 8)
        #expect(throws: AdapterVerificationTransaction.Failure.busy) {
            try AdapterIsolationCommand.byte(isolated: true, inspection: inspection(byte: 8))
        }
        #expect(try AdapterIsolationCommand.byte(isolated: false, inspection: inspection(byte: 8)) == 0)
        #expect(try AdapterIsolationCommand.byte(isolated: false, inspection: inspection()) == nil)
    }

    @Test(arguments: [true, false])
    func unknownStateOrChangedSignatureCannotReachEitherSetter(isolated: Bool) {
        let invalid: [SMCKeyInspection] = [
            .unavailable(.kernel(-1)), inspection(byte: 1), inspection(type: "ui8 "),
            inspection(size: 2), inspection(attributes: 0),
            .readable(metadata: .init(type: "hex_", size: 1, attributes: 0xD4),
                      value: .init(type: "hex_", bytes: [])),
            .readable(metadata: .init(type: "hex_", size: 1, attributes: 0xD4),
                      value: .init(type: "ui8 ", bytes: [0]))
        ]
        for value in invalid {
            #expect(throws: (any Error).self) { try AdapterIsolationCommand.byte(isolated: isolated, inspection: value) }
        }
    }

    private var battery: [String: Any] {
        [kIOPSTypeKey: kIOPSInternalBatteryType, kIOPSIsPresentKey: true,
         kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue, kIOPSIsChargingKey: false,
         kIOPSCurrentCapacityKey: 75, kIOPSMaxCapacityKey: 100]
    }

    @Test func sourceSelectionNeverSuppliesPhysicalPresence() throws {
        let observation = try AdapterPowerObservation.decode(battery)
        let native = NativeChargeLimit.Snapshot(availableLimits: [80, 100], configuredLimit: 80, enabled: true)
        #expect(observation.source == .battery)
        #expect(observation.isCharging == false)
        #expect(observation.level == 0.75)
        #expect(throws: AdapterVerificationTransaction.Failure.invalidObservation) {
            try observation.environment(nativeLimit: native, nativeSessionActive: false,
                                        physicalAdapterConnected: nil, age: .zero)
        }
        let connected = try observation.environment(nativeLimit: native, nativeSessionActive: false,
                                                    physicalAdapterConnected: true, age: .milliseconds(100))
        #expect(connected.isAdapterConnected)
        #expect(connected.source == .battery)
        let disconnected = try observation.environment(nativeLimit: native, nativeSessionActive: true,
                                                       physicalAdapterConnected: false, age: .zero)
        #expect(disconnected.isAdapterConnected == false)
        #expect(disconnected.nativeSessionActive)
        #expect(disconnected.nativeLimit == native)
        for age: Duration in [.milliseconds(-1), .seconds(3)] {
            #expect(throws: AdapterVerificationTransaction.Failure.invalidObservation) {
                try observation.environment(nativeLimit: native, nativeSessionActive: false,
                                            physicalAdapterConnected: true, age: age)
            }
        }
    }

    @Test func missingAndMalformedReadingsNeverDefaultToBatteryOrNotCharging() {
        for key in battery.keys {
            var invalid = battery
            invalid.removeValue(forKey: key)
            #expect(throws: AdapterVerificationTransaction.Failure.invalidObservation) {
                try AdapterPowerObservation.decode(invalid)
            }
        }
        let overrides: [(String, Any)] = [
            (kIOPSTypeKey, "UPS"), (kIOPSIsPresentKey, false), (kIOPSIsPresentKey, 1),
            (kIOPSIsChargingKey, 0), (kIOPSIsChargingKey, true), (kIOPSIsChargingKey, "false"),
            (kIOPSPowerSourceStateKey, "unknown"), (kIOPSMaxCapacityKey, 0),
            (kIOPSCurrentCapacityKey, -1), (kIOPSCurrentCapacityKey, 101),
            (kIOPSCurrentCapacityKey, true), (kIOPSMaxCapacityKey, true),
            (kIOPSCurrentCapacityKey, Double.nan), (kIOPSMaxCapacityKey, Double.infinity),
            (kIOPSCurrentCapacityKey, 75.5)
        ]
        for (key, value) in overrides {
            var invalid = battery
            invalid[key] = value
            #expect(throws: AdapterVerificationTransaction.Failure.invalidObservation) {
                try AdapterPowerObservation.decode(invalid)
            }
        }
    }

    @Test(arguments: [true, false])
    func adapterSourceAllowsBothChargingAndHolding(charging: Bool) throws {
        var value = battery
        value[kIOPSPowerSourceStateKey] = kIOPSACPowerValue
        value[kIOPSIsChargingKey] = charging
        let reading = try AdapterPowerObservation.decode(value)
        #expect(reading.source == .adapter)
        #expect(reading.isCharging == charging)
    }
}
