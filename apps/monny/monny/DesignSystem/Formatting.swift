import Foundation

/// Display formats shared by every screen (FormatStyle only).
extension Double {
    /// 0.34 → "34%".
    var percentText: String { formatted(.percent.precision(.fractionLength(0))) }

    /// Bytes per second → "2.4 MB/s".
    var rateText: String {
        let bytes = Int64(self).formatted(.byteCount(style: .file, spellsOutZero: false))
        return String(localized: "\(bytes)/s", comment: "A transfer rate, for example 2.4 MB/s")
    }

    /// °C → "54 °C" or "130 °F" in the unit chosen in Settings, whatever the locale prefers.
    func temperatureText(_ unit: TemperatureUnit) -> String {
        Measurement(value: self, unit: UnitTemperature.celsius)
            .converted(to: unit == .celsius ? .celsius : .fahrenheit)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    /// Watts without decimals, as in “18 W”.
    var wattsText: String {
        Measurement(value: self, unit: UnitPower.watts)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                    numberFormatStyle: .number.precision(.fractionLength(0))))
    }

    /// °C → "54°" in the chosen unit, for the menu bar where the unit would only take room.
    func shortTemperatureText(_ unit: TemperatureUnit) -> String {
        let value = Measurement(value: self, unit: UnitTemperature.celsius).converted(to: unit == .celsius ? .celsius : .fahrenheit).value
        return value.formatted(.number.precision(.fractionLength(0))) + "°"
    }

    /// A process's CPU share → "14.2%" (100 % is one core, as in Activity Monitor).
    var cpuShareText: String { formatted(.percent.precision(.fractionLength(1))) }

    /// Fan speed → "1,500 rpm".
    var rpmText: String {
        String(localized: "\(Int(rounded()).formatted()) rpm", comment: "Fan speed in revolutions per minute")
    }
}

extension Int64 {
    /// Memory sizes such as "11.2 GB" (binary units, as Activity Monitor).
    var memoryText: String { Self.sizeText(Double(self), base: 1_024) }
    /// Storage sizes such as "412 GB" (decimal units, as Finder).
    var storageText: String { Self.sizeText(Double(self), base: 1_000) }

    /// One decimal below 100 and none above, in the largest unit that keeps the value ≥ 1.
    private static func sizeText(_ bytes: Double, base: Double) -> String {
        let units: [UnitInformationStorage] = [.bytes, .kilobytes, .megabytes, .gigabytes, .terabytes]
        var value = bytes
        var index = 0
        while value >= base, index < units.count - 1 {
            value /= base
            index += 1
        }
        let digits = value < 100 && index > 0 ? 0...1 : 0...0
        return Measurement(value: value, unit: units[index])
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(digits))))
    }
}

extension Duration {
    /// "1 hr 05 min" style estimates.
    var estimateText: String { formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)) }
}
