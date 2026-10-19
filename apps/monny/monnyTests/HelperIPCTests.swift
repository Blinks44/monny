import Foundation
import Testing
@testable import monny

/// An unprivileged anonymous service exercises Foundation IPC, never SMAppService.
nonisolated private final class LocalHelperService: NSObject, NSXPCListenerDelegate, BatteryHelperProtocol {
    private let response: Data
    private let replies: Bool

    init(replies: Bool = true) throws {
        self.response = try JSONEncoder().encode(HelperStatus.current)
        self.replies = replies
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: BatteryHelperProtocol.self)
        connection.exportedObject = self
        connection.activate()
        return true
    }

    func readStatus(withReply reply: @escaping @Sendable (Data) -> Void) {
        if replies { reply(response) }
    }

    func prepareForRemoval(withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }
}

@MainActor
struct HelperIPCTests {
    @Test func anonymousStatusAndRemovalRoundTrips() async throws {
        let server = try LocalHelperService()
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        // This test-only requirement accepts this app as an anonymous peer. Production uses
        // the helper identifier, Apple anchor, matching team and debugging exclusion.
        let requirement = "identifier \"blinks44.monny\""
        for removing in [false, true] {
            let connection = HelperConnection(endpoint: listener.endpoint)
            #expect(try await connection.request(requirement: requirement, forRemoval: removing) == .current)
        }
    }

    @Test(arguments: [false, true])
    func actualXPCRejectsWrongPeerIdentifier(serverRejects: Bool) async throws {
        let server = try LocalHelperService()
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        if serverRejects { listener.setConnectionCodeSigningRequirement("identifier \"blinks44.monny.untrusted\"") }
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let connection = HelperConnection(endpoint: listener.endpoint)
        await #expect(throws: HelperConnectionError.connectionFailed) {
            try await connection.request(requirement: serverRejects ? "identifier \"blinks44.monny\""
                                         : "identifier \"blinks44.monny.untrusted\"")
        }
    }

    @Test func unansweredRequestTimesOut() async throws {
        let server = try LocalHelperService(replies: false)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let connection = HelperConnection(endpoint: listener.endpoint, timeout: .milliseconds(150))
        await #expect(throws: HelperConnectionError.timedOut) {
            try await connection.request(requirement: "identifier \"blinks44.monny\"")
        }
    }

    @Test func cancelledRequestFinishesWithoutWaitingForTheDeadline() async throws {
        let connection = HelperConnection()
        let task = Task { try await connection.request(requirement: "identifier \"blinks44.monny\"") }
        task.cancel()
        await #expect(throws: HelperConnectionError.cancelled) { try await task.value }
    }
}
