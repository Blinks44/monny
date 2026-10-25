import Darwin
import Foundation

/// A kernel launch identity and current owner, read only when validating an explicit action.
nonisolated struct ProcessIdentity: Sendable {
    let startTime: UInt64
    let userID: uid_t
    let name: String

    static func readStartTime(of pid: pid_t) -> UInt64? {
        var usage = rusage_info_v6()
        let result = withUnsafeMutablePointer(to: &usage) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { proc_pid_rusage(pid, RUSAGE_INFO_V6, $0) }
        }
        return result == 0 && usage.ri_proc_start_abstime > 0 ? usage.ri_proc_start_abstime : nil
    }

    static func read(_ pid: pid_t) throws -> Self {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size,
              let start = readStartTime(of: pid) else { throw ProcessTerminationFailure.gone }
        var buffer = [CChar](repeating: 0, count: 256)
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { throw ProcessTerminationFailure.gone }
        let name = String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
        return Self(startTime: start, userID: info.pbi_uid, name: name)
    }
}
