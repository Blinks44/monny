import Darwin
import Foundation

nonisolated struct ProcessUsage: Sendable, Equatable, Identifiable {
    var id: pid_t
    var name: String
    /// The app the process works for, if any; `nil` for system processes.
    var app: AppOwner?
    /// Processes summed into this value: more than 1 only after `groupedByApp`.
    var count = 1
    /// Share of one core over the interval: 1.0 = 100 %, as in Activity Monitor.
    var cpu: Double
    var memory: Int64
    /// Average power over the interval, in watts, from the kernel's per-process energy estimate.
    var power: Double
    /// Bytes per second read from and written to storage over the interval.
    var diskRead: Double = 0
    var diskWrite: Double = 0

    /// One value per app, as Activity Monitor groups them: helpers, web content and tools an app
    /// launched are summed into it, with its PID as the id. System processes stay single rows.
    static func groupedByApp(_ processes: [ProcessUsage]) -> [ProcessUsage] {
        var groups: [pid_t: ProcessUsage] = [:]
        var single: [ProcessUsage] = []
        for process in processes {
            guard let app = process.app else {
                single.append(process)
                continue
            }
            if var group = groups[app.pid] {
                group.cpu += process.cpu
                group.memory += process.memory
                group.power += process.power
                group.diskRead += process.diskRead
                group.diskWrite += process.diskWrite
                group.count += 1
                groups[app.pid] = group
            } else {
                var group = process
                group.id = app.pid
                group.name = app.name
                groups[app.pid] = group
            }
        }
        return single + groups.values
    }
}

/// The app bundle a process belongs to: its responsible process (the app that launched it, or
/// the process itself) when that runs from inside an `.app`.
nonisolated struct AppOwner: Sendable, Equatable {
    var pid: pid_t
    /// The bundle's display name, for an app that `NSRunningApplication` does not list.
    var name: String
}

/// Per-process CPU time, memory footprint and energy (`ri_energy_nj`, nanojoules) from libproc. Processes of other
/// users cannot be read by an unprivileged app and are skipped.
nonisolated struct ProcessReader {
    private var previous: [pid_t: (cpu: UInt64, energy: UInt64, read: UInt64, written: UInt64)] = [:]
    /// Owners never change during a process's life, so each is looked up once per PID.
    private var owners: [pid_t: AppOwner?] = [:]
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
        var currentOwners: [pid_t: AppOwner?] = [:]
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
            // A PID seen in the previous pass is the same process, so its cached owner still holds.
            let owner = previous[pid] != nil ? owners[pid] ?? nil : Self.owner(of: pid)
            currentOwners[pid] = owner
            guard seconds > 0, let old = previous[pid],
                  cpu >= old.cpu, info.ri_energy_nj >= old.energy,
                  info.ri_diskio_bytesread >= old.read, info.ri_diskio_byteswritten >= old.written else { continue }
            // A recycled PID/reset counter establishes a new baseline rather than a huge wrapped rate.
            let cpuShare = Double(cpu - old.cpu) / 1e9 / seconds
            let power = Double(info.ri_energy_nj - old.energy) / 1e9 / seconds
            usages.append(ProcessUsage(id: pid, name: Self.name(of: pid), app: owner, cpu: max(cpuShare, 0),
                                       memory: Int64(clamping: info.ri_phys_footprint), power: max(power, 0),
                                       diskRead: Double(info.ri_diskio_bytesread - old.read) / seconds,
                                       diskWrite: Double(info.ri_diskio_byteswritten - old.written) / seconds))
        }
        previous = current
        owners = currentOwners
        return usages
    }

    private static func allPIDs() -> [pid_t] {
        let estimate = proc_listallpids(nil, 0)
        guard estimate > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(estimate) + 64)
        let count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        return Array(pids.prefix(Int(max(count, 0))))
    }

    /// `responsibility_get_pid_responsible_for_pid` is the libsystem call behind Activity Monitor's
    /// grouping and has no public header. Without it each process is its own responsible process,
    /// which still groups the helpers that live inside an app's bundle.
    private static let responsiblePID: (@convention(c) (pid_t) -> pid_t)? = {
        // `RTLD_DEFAULT`, a C macro Swift does not import; looked up once.
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "responsibility_get_pid_responsible_for_pid") else { return nil }
        return unsafeBitCast(symbol, to: (@convention(c) (pid_t) -> pid_t).self)
    }()

    private static func owner(of pid: pid_t) -> AppOwner? {
        let responsible = responsiblePID.map { $0(pid) }.flatMap { $0 > 0 ? $0 : nil } ?? pid
        guard let bundle = path(of: responsible).flatMap(appBundle(in:)) else { return nil }
        return AppOwner(pid: responsible, name: FileManager.default.displayName(atPath: bundle))
    }

    /// The outermost `.app` in an executable path: an app's helper apps live inside its bundle.
    static func appBundle(in path: String) -> String? {
        guard let range = path.range(of: ".app/") else { return nil }
        return String(path[..<range.lowerBound]) + ".app"
    }

    private static func path(of pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        return String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    private static func name(of pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return "\(pid)" }
        return String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}
