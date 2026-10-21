import Darwin

nonisolated struct ProcessUsage: Sendable, Equatable, Identifiable {
    var id: pid_t
    var name: String
    /// Share of one core over the interval: 1.0 = 100 %, as in Activity Monitor.
    var cpu: Double
    var memory: Int64
    /// Average power over the interval, in watts, from the kernel's per-process energy estimate.
    var power: Double
    /// `nil` when the task info cannot be read.
    var threads: Int?
    /// Bytes per second read from and written to storage over the interval.
    var diskRead: Double = 0
    var diskWrite: Double = 0
}

/// Per-process CPU time, memory footprint and energy (`ri_energy_nj`, nanojoules) from libproc. Processes of other
/// users cannot be read by an unprivileged app and are skipped.
nonisolated struct ProcessReader {
    private var previous: [pid_t: (cpu: UInt64, energy: UInt64, read: UInt64, written: UInt64)] = [:]
    private var lastTime: ContinuousClock.Instant?
    private let timebase: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    mutating func read() -> [ProcessUsage] {
        let now = ContinuousClock.now
        let elapsed = lastTime.map { now - $0 }
        lastTime = now
        let seconds = elapsed.map { Double($0.components.seconds) + Double($0.components.attoseconds) / 1e18 } ?? 0

        var current: [pid_t: (cpu: UInt64, energy: UInt64, read: UInt64, written: UInt64)] = [:]
        var usages: [ProcessUsage] = []
        for pid in Self.allPIDs() where pid > 0 {
            var info = rusage_info_v6()
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { proc_pid_rusage(pid, RUSAGE_INFO_V6, $0) }
            }
            guard result == 0 else { continue }
            // rusage times are Mach absolute time units, not nanoseconds, on Apple silicon.
            let cpu = (info.ri_user_time + info.ri_system_time) * UInt64(timebase.numer) / UInt64(timebase.denom)
            current[pid] = (cpu, info.ri_energy_nj, info.ri_diskio_bytesread, info.ri_diskio_byteswritten)
            guard seconds > 0, let old = previous[pid],
                  cpu >= old.cpu, info.ri_energy_nj >= old.energy,
                  info.ri_diskio_bytesread >= old.read, info.ri_diskio_byteswritten >= old.written else { continue }
            // A recycled PID/reset counter establishes a new baseline rather than a huge wrapped rate.
            let cpuShare = Double(cpu - old.cpu) / 1e9 / seconds
            let power = Double(info.ri_energy_nj - old.energy) / 1e9 / seconds
            usages.append(ProcessUsage(id: pid, name: Self.name(of: pid), cpu: max(cpuShare, 0),
                                       memory: Int64(clamping: info.ri_phys_footprint), power: max(power, 0),
                                       threads: Self.threadCount(of: pid),
                                       diskRead: Double(info.ri_diskio_bytesread - old.read) / seconds,
                                       diskWrite: Double(info.ri_diskio_byteswritten - old.written) / seconds))
        }
        previous = current
        return usages
    }

    private static func allPIDs() -> [pid_t] {
        let estimate = proc_listallpids(nil, 0)
        guard estimate > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(estimate) + 64)
        let count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        return Array(pids.prefix(Int(max(count, 0))))
    }

    private static func threadCount(of pid: pid_t) -> Int? {
        var info = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size) == size else { return nil }
        return Int(info.pti_threadnum)
    }

    private static func name(of pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return "\(pid)" }
        return String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
