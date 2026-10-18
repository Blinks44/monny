import Darwin

nonisolated struct MemoryUsage: Sendable, Equatable {
    enum Pressure: Sendable { case normal, warning, critical }

    var used: Int64
    var total: Int64
    var swapUsed: Int64
    var pressure: Pressure

    var fraction: Double { total > 0 ? Double(used) / Double(total) : 0 }

    /// Activity Monitor's "Memory Used": app memory (internal − purgeable) + wired + compressed.
    static func used(internalPages: UInt64, purgeable: UInt64, wired: UInt64, compressed: UInt64, pageSize: UInt64) -> Int64 {
        let app = internalPages > purgeable ? internalPages - purgeable : 0
        return Int64(clamping: (app + wired + compressed) * pageSize)
    }
}

nonisolated struct MemoryReader {
    private let host = mach_host_self()
    private let pageSize = UInt64(sysconf(_SC_PAGESIZE))

    func read() -> MemoryUsage? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(host, HOST_VM_INFO64, $0, &count) }
        }
        guard result == KERN_SUCCESS else { return nil }
        let used = MemoryUsage.used(internalPages: UInt64(stats.internal_page_count), purgeable: UInt64(stats.purgeable_count),
                                    wired: UInt64(stats.wire_count), compressed: UInt64(stats.compressor_page_count),
                                    pageSize: pageSize)
        return MemoryUsage(used: used, total: SystemInfo.physicalMemory, swapUsed: swapUsed(), pressure: pressure())
    }

    private func pressure() -> MemoryUsage.Pressure {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else { return .normal }
        switch level {
        case 4: return .critical
        case 2: return .warning
        default: return .normal
        }
    }

    private func swapUsed() -> Int64 {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &usage, &size, nil, 0) == 0 else { return 0 }
        return Int64(usage.xsu_used)
    }
}
