import Darwin
import Foundation
import Testing
@testable import monny

struct ProcessLookupTests {
    @Test(arguments: [
        ("3002", ProcessQuery.number(3002)), (" 48216\n", .number(48_216)), ("70000", .number(70_000)),
        (":3002", .port(3002)), ("localhost:3002", .port(3002)), ("127.0.0.1:5173", .port(5173)),
        ("[::1]:8080", .port(8080)), ("http://localhost:3002/api?token=x", .port(3002)),
        ("HTTPS://127.0.0.1:8443", .port(8443)),
    ])
    func numbersAndLocalAddressesAreLookups(text: String, expected: ProcessQuery) {
        #expect(ProcessQuery(text) == expected)
    }

    @Test(arguments: ["", "node", "0", ":0", ":70000", "localhost", "example.com:3002",
                      "http://example.com:3002", "ftp://localhost:21", "3002a", "١٢٣"])
    func everythingElseIsANameSearch(text: String) {
        #expect(ProcessQuery(text) == .name(text.trimmingCharacters(in: .whitespacesAndNewlines)))
    }

    @Test func aNumberIsAPortOnlyWithinThePortRange() {
        #expect(ProcessQuery("3002").port == 3002)
        #expect(ProcessQuery("3002").pid == 3002)
        #expect(ProcessQuery("70000").port == nil)
        #expect(ProcessQuery(":3002").pid == nil)
    }

    /// The listener is a socket this test opens in its own process, never another app's.
    @Test func findsTheTestsOwnListenerByPortAndPID() async throws {
        let socket = try ListeningSocket()
        defer { socket.close() }
        let listeners = PortListenerReader.read(pids: [getpid()])
        #expect(listeners.contains(PortListener(pid: getpid(), port: socket.port, address: "127.0.0.1")))

        let byPort = await ProcessLookup.find(.port(socket.port))
        let match = try #require(byPort.listeners.first { $0.id == getpid() })
        #expect(match.ports.contains { $0.port == socket.port && $0.isLocalOnly })
        #expect(match.executable != nil)
        #expect(byPort.process == nil)

        let byPID = await ProcessLookup.find(.number(getpid()))
        #expect(byPID.process?.id == getpid() || byPID.listeners.contains { $0.id == getpid() })
    }

    @Test func aMissingPIDOrUnusedPortFindsNothing() async throws {
        let socket = try ListeningSocket()
        let port = socket.port
        socket.close()
        #expect(await ProcessLookup.find(.port(port)).listeners.allSatisfy { $0.id != getpid() })
        #expect(await ProcessLookup.find(.number(Int32.max)).process == nil)
    }

    /// End to end with a disposable child this test starts: found by PID, quit, seen gone.
    @Test func aQuitProcessFoundByPIDIsReportedGone() async throws {
        let child = Process()
        child.executableURL = URL(filePath: "/bin/sleep")
        child.arguments = ["60"]
        try child.run()
        defer { if child.isRunning { child.terminate() } }
        let found = await ProcessLookup.find(.number(child.processIdentifier))
        let match = try #require(found.process ?? found.listeners.first { $0.id == child.processIdentifier })
        #expect(match.name == "sleep")
        #expect(match.executable == "/bin/sleep")
        #expect(match.parent?.id == getpid())
        let row = ProcessUsage(id: match.id, name: match.name, cpu: 0, memory: 0, power: 0, startTime: match.startTime)
        let request = try #require(ProcessTerminationRequest(row: row, processes: []))
        try await ProcessTerminator().terminate(request, force: false)
        #expect(await ProcessLookup.waitForExit(match.id, startTime: match.startTime))
        let after = await ProcessLookup.find(.number(child.processIdentifier))
        #expect(after.process == nil)
    }

    @Test func waitingEndsAsSoonAsTheProcessIsGone() async {
        #expect(await ProcessLookup.waitForExit(Int32.max, startTime: 1, timeout: .seconds(1)))
        let start = ProcessIdentity.readStartTime(of: getpid()) ?? 0
        #expect(await ProcessLookup.waitForExit(getpid(), startTime: start, timeout: .milliseconds(300)) == false)
    }
}

/// A TCP listener on an ephemeral loopback port owned by the test process.
private struct ListeningSocket {
    let descriptor: Int32
    let port: UInt16

    init() throws {
        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw POSIXError(.EBADF) }
        self.descriptor = descriptor
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        address.sin_port = 0
        let size = socklen_t(MemoryLayout<sockaddr_in>.size)
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(descriptor, $0, size) }
        }
        guard bound == 0, listen(descriptor, 1) == 0 else { throw POSIXError(.EADDRINUSE) }
        var length = size
        _ = withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(descriptor, $0, &length) }
        }
        port = UInt16(bigEndian: address.sin_port)
    }

    func close() { _ = Darwin.close(descriptor) }
}
