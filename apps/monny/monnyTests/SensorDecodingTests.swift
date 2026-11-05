import Foundation
import Testing

@testable import monny

/// SMC data types and sensor selection, with byte fixtures shaped like the M1 Max readings.
struct SensorDecodingTests {
    @Test(
        arguments: [
            (SMCValue(type: "flt ", bytes: [0x00, 0x00, 0x02, 0x42]), 32.5),  // TB0T, little-endian Float
            (SMCValue(type: "sp78", bytes: [0x2A, 0x80]), 42.5),  // signed 8.8 fixed point
            (SMCValue(type: "sp78", bytes: [0xFF, 0x00]), -1),
            (SMCValue(type: "fpe2", bytes: [0x17, 0x70]), 1_500),  // unsigned 14.2, older fan keys
            (SMCValue(type: "ui8 ", bytes: [0x02]), 2),  // FNum
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

    @Test func idleCorePlaceholdersDoNotLowerDieTemperatures() {
        let values = [
            "Tp09": 44.0, "Tp0T": 46, "Tp01": 1.5, "Tp05": 3, "Tp0D": 5,
            "Tp0H": 0, "Tp0L": -4, "Tp0P": 150, "Tg05": 2, "Tg0D": 48,
            "TB0T": 5, "TH0x": 8,
        ]
        let reading = SensorReader.read(generation: 1, value: { values[$0] })
        #expect(reading.cpu == 45)
        #expect(reading.gpu == 48)
        // The die-specific filter must not erase legitimate cold battery/SSD measurements.
        #expect(reading.battery == 5)
        #expect(reading.ssd == 8)
    }

    @Test func invalidDieSampleIsUnavailableAndDoesNotReuseLastReading() {
        let good = SensorReader.read(generation: 4, value: { $0 == "Tp01" ? 45 : nil })
        let idle = SensorReader.read(generation: 4, value: { _ in 3 })
        let recovered = SensorReader.read(generation: 4, value: { $0 == "Tp01" ? 47 : nil })
        #expect(good.cpu == 45)
        #expect(idle.cpu == nil)
        #expect(idle.gpu == nil)
        #expect(recovered.cpu == 47)
    }

    @Test func dieFilterPreservesValidColdAndHotReadings() {
        let values = ["Tp09": 10.0, "Tp0T": 120, "Tp01": 9.9, "Tp05": 120.1]
        #expect(SensorReader.read(generation: 1, value: { values[$0] }).cpu == 65)
    }

    @Test func rejectsNonfiniteSMCFloats() {
        #expect(SMCValue(type: "flt ", bytes: [0, 0, 0x80, 0x7F]).number == nil)
        #expect(SMCValue(type: "flt ", bytes: [0, 0, 0xC0, 0x7F]).number == nil)
        #expect(SensorKeys.average([.nan, .infinity, -.infinity, 45]) == 45)
    }

    @Test func unknownFanIsNotFanlessOrStopped() {
        #expect(SensorReader.read(generation: nil, value: { _ in nil }).fanRPM == nil)
        #expect(SensorReader.read(generation: nil, value: { $0 == "FNum" ? 0 : nil }).fanRPM == [])
        #expect(SensorReader.read(generation: nil, value: { $0 == "FNum" ? 1 : nil }).fanRPM == nil)
        let stopped = SensorReader.read(generation: nil, value: { ["FNum": 1.0, "F0Ac": 0, "F0Mx": 5_000][$0] })
        #expect(stopped.fanRPM == [0])
        #expect(stopped.fanMaxRPM == [5_000])
        let partial = SensorReader.read(generation: nil, value: { ["FNum": 2.0, "F0Ac": 1_000, "F1Ac": -1][$0] })
        #expect(partial.fanRPM == nil)
    }

    @Test(arguments: [Double.nan, .infinity, -1, 1.5, 100])
    func invalidFanCountIsUnavailable(count: Double) {
        #expect(SensorReader.read(generation: nil, value: { $0 == "FNum" ? count : 0 }).fanRPM == nil)
    }

    @Test @MainActor func temperatureFollowsTheChosenUnitNotTheLocale() {
        // The locale's own preference (°C in Russia) must not override the Settings choice.
        let fahrenheit = 54.4.temperatureText(.fahrenheit)
        #expect(fahrenheit.contains("130"))
        #expect(fahrenheit.contains("F"))
        #expect(54.4.temperatureText(.celsius).contains("54"))
    }

    @Test @MainActor func menuBarTemperatureDropsTheUnitLetter() {
        #expect(54.4.shortTemperatureText(.celsius) == "54°")
        #expect(54.4.shortTemperatureText(.fahrenheit) == "130°")
    }
}
