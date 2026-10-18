import Foundation
import IOKit

nonisolated enum CoreKind: Sendable { case performance, efficiency }

/// CPU load over the last sampling interval. Fractions are 0...1.
nonisolated struct CPULoad: Sendable, Equatable {
    var total: Double
    /// User and system shares of the whole CPU (nice counts as user).
    var user: Double
    var system: Double
    var performance: Double?
    var efficiency: Double?
    /// One entry per logical CPU, in `logical-cpu-id` order.
    var cores: [Double]
    var kinds: [CoreKind]

    /// Builds the load from two `PROCESSOR_CPU_LOAD_INFO` tick arrays (user, system, idle, nice per CPU).
    /// Busy time is user + system + nice; tick counters are `UInt32` and may wrap.
    init?(previous: [UInt32], current: [UInt32], kinds: [CoreKind]) {
        let states = Int(CPU_STATE_MAX)
        guard previous.count == current.count, current.count % states == 0, !current.isEmpty else { return nil }
        var cores: [Double] = []
        var busyByKind: [CoreKind: (busy: UInt64, all: UInt64)] = [:]
        var busyTotal: UInt64 = 0
        var allTotal: UInt64 = 0
        var systemTotal: UInt64 = 0
        for core in 0..<(current.count / states) {
            let base = core * states
            func delta(_ state: Int32) -> UInt64 { UInt64(current[base + Int(state)] &- previous[base + Int(state)]) }
            let busy = delta(CPU_STATE_USER) + delta(CPU_STATE_SYSTEM) + delta(CPU_STATE_NICE)
            let all = busy + delta(CPU_STATE_IDLE)
            cores.append(all == 0 ? 0 : Double(busy) / Double(all))
            busyTotal += busy
            allTotal += all
            systemTotal += delta(CPU_STATE_SYSTEM)
            if core < kinds.count {
                let sums = busyByKind[kinds[core], default: (0, 0)]
                busyByKind[kinds[core]] = (sums.busy + busy, sums.all + all)
            }
        }
        func fraction(_ sums: (busy: UInt64, all: UInt64)?) -> Double? {
            guard let sums, sums.all > 0 else { return nil }
            return Double(sums.busy) / Double(sums.all)
        }
        self.total = allTotal == 0 ? 0 : Double(busyTotal) / Double(allTotal)
        self.system = allTotal == 0 ? 0 : Double(systemTotal) / Double(allTotal)
        self.user = self.total - self.system
        self.performance = fraction(busyByKind[.performance])
        self.efficiency = fraction(busyByKind[.efficiency])
        self.cores = cores
        self.kinds = kinds
    }
}

/// Reads per-CPU ticks; the load is the change since the previous call.
nonisolated struct CPUReader {
    private let host = mach_host_self()
    private let kinds = CoreTopology.kinds()
    private var previous: [UInt32]?

    mutating func read() -> CPULoad? {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        guard host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &infoCount) == KERN_SUCCESS,
              let info else { return nil }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)),
                          vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride))
        }
        let ticks = (0..<Int(infoCount)).map { UInt32(bitPattern: info[$0]) }
        defer { previous = ticks }
        guard let previous else { return nil }
        return CPULoad(previous: previous, current: ticks, kinds: kinds)
    }
}

/// Which logical CPUs are Performance or Efficiency cores.
nonisolated enum CoreTopology {
    /// From the device tree (`cluster-type` "P"/"E" per `logical-cpu-id`); if that is unreadable,
    /// Apple silicon numbers Efficiency cores first.
    static func kinds() -> [CoreKind] {
        if let kinds = deviceTreeKinds(), !kinds.isEmpty { return kinds }
        let efficiency = Array(repeating: CoreKind.efficiency, count: SystemInfo.efficiencyCores)
        return efficiency + Array(repeating: .performance, count: SystemInfo.performanceCores)
    }

    private static func deviceTreeKinds() -> [CoreKind]? {
        let cpus = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/cpus")
        guard cpus != 0 else { return nil }
        defer { IOObjectRelease(cpus) }
        var iterator: io_iterator_t = 0
        guard IORegistryEntryGetChildIterator(cpus, kIODeviceTreePlane, &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }
        var byID: [Int: CoreKind] = [:]
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            guard let type = string(entry, "cluster-type"), let id = integer(entry, "logical-cpu-id") else { continue }
            byID[id] = type == "E" ? .efficiency : .performance
        }
        guard !byID.isEmpty, byID.keys.sorted() == Array(0..<byID.count) else { return nil }
        return (0..<byID.count).compactMap { byID[$0] }
    }

    private static func property(_ entry: io_registry_entry_t, _ key: String) -> CFTypeRef? {
        IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }

    private static func string(_ entry: io_registry_entry_t, _ key: String) -> String? {
        guard let data = property(entry, key) as? Data else { return nil }
        return String(decoding: data.prefix { $0 != 0 }, as: UTF8.self)
    }

    private static func integer(_ entry: io_registry_entry_t, _ key: String) -> Int? {
        switch property(entry, key) {
        case let number as NSNumber: number.intValue
        case let data as Data where data.count >= 4: Int(data.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) })
        default: nil
        }
    }
}

/// The 1, 5 and 15 minute load averages (runnable threads), as `uptime` shows them.
nonisolated enum LoadAverage {
    static func read() -> [Double]? {
        var values = [Double](repeating: 0, count: 3)
        return getloadavg(&values, 3) == 3 ? values : nil
    }
}

/// GPU utilization and core count from the `IOAccelerator` registry entry (public, no privileges).
nonisolated struct GPUReading: Sendable, Equatable {
    /// 0...1, "Device Utilization %".
    var utilization: Double?
    var cores: Int?

    static func read() -> GPUReading? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOAccelerator"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        func property(_ key: String) -> Any? {
            IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        }
        let statistics = property("PerformanceStatistics") as? [String: Any]
        let utilization = (statistics?["Device Utilization %"] as? NSNumber).map { $0.doubleValue / 100 }
        return GPUReading(utilization: utilization, cores: (property("gpu-core-count") as? NSNumber)?.intValue)
    }
}
