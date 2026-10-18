import Foundation
import Testing
@testable import monny

/// SMC data types and sensor selection, with byte fixtures shaped like the M1 Max readings.
struct SensorDecodingTests {
    @Test(arguments: [
        (SMCValue(type: "flt ", bytes: [0x00, 0x00, 0x02, 0x42]), 32.5),   // TB0T, little-endian Float
        (SMCValue(type: "sp78", bytes: [0x2A, 0x80]), 42.5),               // signed 8.8 fixed point
        (SMCValue(type: "sp78", bytes: [0xFF, 0x00]), -1),
        (SMCValue(type: "fpe2", bytes: [0x17, 0x70]), 1_500),              // unsigned 14.2, older fan keys
        (SMCValue(type: "ui8 ", bytes: [0x02]), 2),                        // FNum
        (SMCValue(type: "ui16", bytes: [0x01, 0x00]), 256),
        (SMCValue(type: "ui32", bytes: [0x00, 0x00, 0x08, 0xCB]), 2_251),  // #KEY
    ] as [(SMCValue, Double)])
    func decodesNumbers(value: SMCValue, expected: Double) {
        #expect(value.number == expected)
    }

    @Test func rejectsUnknownTypesAndWrongSizes() {
        #expect(SMCValue(type: "ioft", bytes: [0, 0x80, 0x20, 0, 0, 0, 0, 0]).number == nil)
        #expect(SMCValue(type: "flt ", bytes: [0, 0]).number == nil)
        #expect(SMCValue(type: "ui8 ", bytes: []).number == nil)
    }

    @Test func fourCharacterCodesRoundTrip() {
        #expect(SMCConnection.fourCC("TB0T") == 0x5442_3054)
        #expect(SMCConnection.string(0x666C_7420) == "flt ")
    }

    @Test(arguments: [("Apple M1 Max", 1), ("Apple M3 Pro", 3), ("Apple M10", 10)])
    func chipGeneration(name: String, expected: Int) {
        #expect(SensorKeys.generation(chipName: name) == expected)
    }

    @Test func unknownChipHasNoCPUKeys() {
        #expect(SensorKeys.generation(chipName: "Apple silicon") == nil)
        #expect(SensorKeys.cpu(generation: 99).isEmpty)
    }

    @Test func averageSkipsAbsentSensors() {
        // Missing sensors read 0 on some Macs (for example Ta00 on M1 Max).
        #expect(SensorKeys.average([50, 0, 54]) == 52)
        #expect(SensorKeys.average([0, 0]) == nil)
        #expect(SensorKeys.average([]) == nil)
    }

    @Test @MainActor func temperatureFollowsTheChosenUnitNotTheLocale() {
        // The locale's own preference (°C in Russia) must not override the Settings choice.
        let fahrenheit = 54.4.temperatureText(.fahrenheit)
        #expect(fahrenheit.contains("130"))
        #expect(fahrenheit.contains("F"))
        #expect(54.4.temperatureText(.celsius).contains("54"))
    }
}
