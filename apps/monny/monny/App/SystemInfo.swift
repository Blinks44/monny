import Foundation
import IOKit.ps

/// Static facts about this Mac that do not change while Monny runs.
enum SystemInfo {
    /// For example "Apple M3 Pro".
    static let chipName: String = sysctlString("machdep.cpu.brand_string") ?? "Apple silicon"
    /// Without the "Apple " prefix, for example "M3 Pro", where space is tight.
    static var shortChipName: String {
        chipName.hasPrefix("Apple ") ? String(chipName.dropFirst("Apple ".count)) : chipName
    }
    static let performanceCores: Int = sysctlInt("hw.perflevel0.logicalcpu") ?? 0
    static let efficiencyCores: Int = sysctlInt("hw.perflevel1.logicalcpu") ?? 0
    static let physicalMemory = Int64(clamping: ProcessInfo.processInfo.physicalMemory)

    static var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion)"
    }

    /// Whether the Mac has an internal battery. Desktop Macs report only AC power sources.
    static let hasBattery: Bool = {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return false }
        return sources.contains { source in
            let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any]
            return description?[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
        }
    }()

    /// Uptime as two units, for example "2d 4h" or "35m".
    static func uptimeText(_ seconds: TimeInterval, locale: Locale = .autoupdatingCurrent) -> String {
        Duration.seconds(Int64(seconds)).formatted(
            .units(allowed: [.days, .hours, .minutes], width: .narrow, maximumUnitCount: 2).locale(locale))
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
    }

    private static func sysctlInt(_ name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return Int(value)
    }
}
