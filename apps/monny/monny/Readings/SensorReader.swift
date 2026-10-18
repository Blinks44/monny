import Foundation

/// Temperatures in °C and fan speeds from the SMC. `nil` means this Mac does not expose the sensor.
nonisolated struct SensorReading: Sendable, Equatable {
    /// Averages of the per-core or per-cluster sensors.
    var cpu: Double?
    var gpu: Double?
    var ssd: Double?
    var battery: Double?
    /// One speed per fan in rpm, empty on a fanless Mac. 0 means stopped, which is normal at low load.
    var fanRPM: [Double]
    /// Each fan's maximum rpm (`F<n>Mx`), when the SMC reports it.
    var fanMaxRPM: [Double] = []
}

/// SMC temperature keys per Apple silicon generation. The keys are undocumented; the lists follow
/// exelban/stats (MIT, `Modules/Sensors/values.swift`, revision 5731455) and only M1 Max is checked
/// here. A chip that is not listed shows CPU and GPU temperatures as unavailable.
nonisolated enum SensorKeys {
    static func cpu(generation: Int) -> [String] {
        switch generation {
        case 1: ["Tp09", "Tp0T", "Tp01", "Tp05", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0X", "Tp0b"]
        case 2: ["Tp1h", "Tp1t", "Tp1p", "Tp1l", "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0X", "Tp0b", "Tp0f", "Tp0j"]
        case 3: ["Te05", "Te0L", "Te0P", "Te0S", "Tf04", "Tf09", "Tf0A", "Tf0B", "Tf0D", "Tf0E",
                 "Tf44", "Tf49", "Tf4A", "Tf4B", "Tf4D", "Tf4E"]
        case 4: ["Te05", "Te0S", "Te09", "Te0H", "Tp01", "Tp05", "Tp09", "Tp0D", "Tp0V", "Tp0Y", "Tp0b", "Tp0e"]
        case 5: ["Tp00", "Tp04", "Tp08", "Tp0C", "Tp0G", "Tp0K", "Tp0O", "Tp0R", "Tp0U", "Tp0X", "Tp0a", "Tp0d",
                 "Tp0g", "Tp0j", "Tp0m", "Tp0p", "Tp0u", "Tp0y"]
        default: []
        }
    }

    static func gpu(generation: Int) -> [String] {
        switch generation {
        case 1: ["Tg05", "Tg0D", "Tg0L", "Tg0T"]
        case 2: ["Tg0f", "Tg0j"]
        case 3: ["Tf14", "Tf18", "Tf19", "Tf1A", "Tf24", "Tf28", "Tf29", "Tf2A"]
        // M4 uses Tg0G/Tg0H, M4 Pro and Max Tg1U/Tg1k; keys a chip lacks are skipped.
        case 4: ["Tg0G", "Tg0H", "Tg1U", "Tg1k", "Tg0K", "Tg0L", "Tg0d", "Tg0e", "Tg0j", "Tg0k"]
        case 5: ["Tg0U", "Tg0X", "Tg0d", "Tg0g", "Tg0j", "Tg1Y", "Tg1c", "Tg1g"]
        default: []
        }
    }

    /// The same on every Apple silicon Mac that has the part.
    static let ssd = ["TH0x"]
    static let battery = ["TB0T", "TB1T", "TB2T"]

    /// "Apple M3 Pro" → 3; `nil` for chips without a key list.
    static func generation(chipName: String) -> Int? {
        guard let match = chipName.firstMatch(of: /^Apple M(\d+)/) else { return nil }
        return Int(match.1)
    }

    /// Mean of the plausible readings. Absent sensors read 0 on some Macs, so values outside
    /// 1...150 °C are ignored.
    static func average(_ values: [Double]) -> Double? {
        let valid = values.filter { (1...150).contains($0) }
        return valid.isEmpty ? nil : valid.reduce(0, +) / Double(valid.count)
    }
}

/// Reads temperatures and fans through one SMC connection kept open while sampling.
/// Each pass is a few dozen SMC calls (see verification for the cost).
nonisolated final class SensorReader {
    private let smc = SMCConnection()
    private let generation = SensorKeys.generation(chipName: SystemInfo.chipName)

    func read() -> SensorReading? {
        guard let smc else { return nil }
        func temperature(_ keys: [String]) -> Double? { SensorKeys.average(keys.compactMap { smc.read($0)?.number }) }
        let fanCount = smc.read("FNum")?.number.map(Int.init) ?? 0
        let fans = (0..<fanCount).compactMap { smc.read("F\($0)Ac")?.number }.map { max($0, 0) }
        return SensorReading(
            cpu: generation.flatMap { temperature(SensorKeys.cpu(generation: $0)) },
            gpu: generation.flatMap { temperature(SensorKeys.gpu(generation: $0)) },
            ssd: temperature(SensorKeys.ssd),
            battery: temperature(SensorKeys.battery),
            fanRPM: fans,
            fanMaxRPM: (0..<fanCount).compactMap { smc.read("F\($0)Mx")?.number }.filter { $0 > 0 })
    }
}
