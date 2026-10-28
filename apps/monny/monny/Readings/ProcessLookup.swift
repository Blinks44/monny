import Darwin
import Foundation

/// What the Processes search field asks for. A bare number is both a PID and a port; `:3002`,
/// `localhost:3002` and loopback http(s) URLs are ports. Parsing never makes a network request.
nonisolated enum ProcessQuery: Equatable {
    case name(String)
    case number(Int32)
    case port(UInt16)

    init(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty, text.allSatisfy(\.isASCIIDigit), let value = Int32(text), value > 0 {
            self = .number(value)
        } else if text.hasPrefix(":"), let port = Self.port(String(text.dropFirst())) {
            self = .port(port)
        } else if let port = Self.loopbackPort(text) {
            self = .port(port)
        } else {
            self = .name(text)
        }
    }

    /// The port a listener must have to match, if this query names one.
    var port: UInt16? {
        switch self {
        case .name: nil
        case .number(let value): value <= Int32(UInt16.max) ? UInt16(value) : nil
        case .port(let port): port
        }
    }

    var pid: pid_t? {
        if case .number(let value) = self { value } else { nil }
    }

    private static func port(_ text: String) -> UInt16? {
        guard !text.isEmpty, text.allSatisfy(\.isASCIIDigit), let port = UInt16(text), port > 0 else { return nil }
        return port
    }

    private static func loopbackPort(_ text: String) -> UInt16? {
        let link = text.contains("://") ? text : "http://" + text
        guard let components = URLComponents(string: link), ["http", "https"].contains(components.scheme?.lowercased()),
              let host = components.host?.lowercased(), let port = components.port, (1...65_535).contains(port),
              ["localhost", "127.0.0.1", "::1", "[::1]", "0.0.0.0"].contains(host) else { return nil }
        return UInt16(port)
    }
}

nonisolated private extension Character {
    var isASCIIDigit: Bool { isASCII && isWholeNumber }
}

/// One listening TCP socket of a process; `address` is `*` for all interfaces.
nonisolated struct PortListener: Sendable, Hashable {
    let pid: pid_t
    let port: UInt16
    let address: String

    var isLocalOnly: Bool { address == "127.0.0.1" || address == "::1" }
}

/// Listening TCP sockets from libproc's per-process file descriptors, the source `lsof` uses.
/// Only the current user's processes are readable without privileges; others are skipped.
nonisolated enum PortListenerReader {
    static func read(pids: [pid_t]) -> [PortListener] {
        var listeners: [PortListener] = []
        for pid in pids where pid > 0 {
            let bytes = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
            guard bytes > 0 else { continue }
            let stride = MemoryLayout<proc_fdinfo>.stride
            var descriptors = [proc_fdinfo](repeating: proc_fdinfo(), count: Int(bytes) / stride + 8)
            let filled = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, &descriptors, Int32(descriptors.count * stride))
            guard filled > 0 else { continue }
            var seen = Set<PortListener>()
            for descriptor in descriptors.prefix(Int(filled) / stride) where descriptor.proc_fdtype == UInt32(PROX_FDTYPE_SOCKET) {
                guard let listener = listener(pid: pid, descriptor: descriptor.proc_fd), seen.insert(listener).inserted else { continue }
                listeners.append(listener)
            }
        }
        return listeners
    }

    private static func listener(pid: pid_t, descriptor: Int32) -> PortListener? {
        var info = socket_fdinfo()
        let size = Int32(MemoryLayout<socket_fdinfo>.size)
        guard proc_pidfdinfo(pid, descriptor, PROC_PIDFDSOCKETINFO, &info, size) == size,
              info.psi.soi_kind == SOCKINFO_TCP else { return nil }
        let tcp = info.psi.soi_proto.pri_tcp
        guard tcp.tcpsi_state == TSI_S_LISTEN else { return nil }
        let internet = tcp.tcpsi_ini
        // `insi_lport` holds the port in network byte order in its low 16 bits.
        let port = UInt16(bigEndian: UInt16(truncatingIfNeeded: internet.insi_lport))
        guard port > 0 else { return nil }
        return PortListener(pid: pid, port: port, address: address(of: internet))
    }

    private static func address(of internet: in_sockinfo) -> String {
        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        if internet.insi_vflag & UInt8(INI_IPV6) != 0 {
            var address = internet.insi_laddr.ina_6
            guard withUnsafeBytes(of: &address, { $0.contains { $0 != 0 } }) else { return "*" }
            inet_ntop(AF_INET6, &address, &buffer, socklen_t(buffer.count))
        } else {
            var address = internet.insi_laddr.ina_46.i46a_addr4
            guard address.s_addr != 0 else { return "*" }
            inet_ntop(AF_INET, &address, &buffer, socklen_t(buffer.count))
        }
        return String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }
}

/// A process found by PID or port, with what explains where it came from. Like the process
/// list, only the current user's processes are readable without privileges.
nonisolated struct ProcessMatch: Sendable, Equatable, Identifiable {
    let id: pid_t
    let name: String
    let startTime: UInt64
    var executable: String?
    var folder: String?
    var parent: Parent?
    var ports: [PortListener]

    nonisolated struct Parent: Sendable, Equatable {
        let id: pid_t
        let name: String
    }
}

/// Everything a number or port query found, read in one pass off the main actor.
nonisolated struct ProcessLookupResult: Sendable, Equatable {
    var listeners: [ProcessMatch] = []
    var process: ProcessMatch?

    var isEmpty: Bool { listeners.isEmpty && process == nil }
}

nonisolated enum ProcessLookup {
    @concurrent static func find(_ query: ProcessQuery) async -> ProcessLookupResult {
        let sockets = query.port == nil ? [] : PortListenerReader.read(pids: allPIDs())
        let port = query.port
        var result = ProcessLookupResult()
        let owners = Set(sockets.filter { $0.port == port }.map(\.pid)).sorted()
        result.listeners = owners.compactMap { match($0, sockets: sockets) }
        if let pid = query.pid, !owners.contains(pid) {
            result.process = match(pid, sockets: query.port == nil ? PortListenerReader.read(pids: [pid]) : sockets)
        }
        return result
    }

    /// Whether the exact process (PID and launch identity) still runs.
    static func isRunning(_ pid: pid_t, startTime: UInt64) -> Bool {
        ProcessIdentity.readStartTime(of: pid) == startTime
    }

    /// Waits a few seconds for an ended process to disappear; `false` means it still runs, for
    /// example because it ignored SIGTERM or an app is asking to save.
    @concurrent static func waitForExit(_ pid: pid_t, startTime: UInt64, timeout: Duration = .seconds(3)) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while isRunning(pid, startTime: startTime) {
            guard ContinuousClock.now < deadline, !Task.isCancelled else { return false }
            try? await Task.sleep(for: .milliseconds(200))
        }
        return true
    }

    private static func match(_ pid: pid_t, sockets: [PortListener]) -> ProcessMatch? {
        guard pid > 0, let identity = try? ProcessIdentity.read(pid) else { return nil }
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        let parentID = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size ? pid_t(info.pbi_ppid) : 0
        let parent = parentID > 1 ? (try? ProcessIdentity.read(parentID)).map { ProcessMatch.Parent(id: parentID, name: $0.name) } : nil
        return ProcessMatch(id: pid, name: identity.name, startTime: identity.startTime,
                            executable: executable(of: pid), folder: folder(of: pid), parent: parent,
                            ports: sockets.filter { $0.pid == pid }.sorted { ($0.port, $0.address) < ($1.port, $1.address) })
    }

    private static func executable(of pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN) * 4)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        return String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    private static func folder(of pid: pid_t) -> String? {
        var info = proc_vnodepathinfo()
        let size = Int32(MemoryLayout<proc_vnodepathinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, size) == size else { return nil }
        let path = withUnsafeBytes(of: &info.pvi_cdir.vip_path) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
        // The root folder says nothing about where a process came from.
        return path.isEmpty || path == "/" ? nil : path
    }

    private static func allPIDs() -> [pid_t] {
        let estimate = proc_listallpids(nil, 0)
        guard estimate > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(estimate) + 64)
        let count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        return Array(pids.prefix(Int(max(count, 0))))
    }
}
