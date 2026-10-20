import Foundation
import Testing
@testable import monny

/// An unprivileged anonymous service exercises Foundation IPC, never SMAppService.
nonisolated private final class LocalHelperService: NSObject, NSXPCListenerDelegate, BatteryHelperProtocol {
    private let response: Data
    private let replies: Bool
    private let executor: ChargeCommandExecutor?
    private let clientRequirement: String?

    init(replies: Bool = true, executor: ChargeCommandExecutor? = nil, clientRequirement: String? = nil) throws {
        self.clientRequirement = clientRequirement
        self.executor = executor
        self.response = try JSONEncoder().encode(HelperStatus.current)
        self.replies = replies
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        if let clientRequirement { connection.setCodeSigningRequirement(clientRequirement) }
        connection.exportedInterface = NSXPCInterface(with: BatteryHelperProtocol.self)
        if let executor {
            let session = HelperSession(executor: executor)
            connection.exportedObject = session
            connection.invalidationHandler = { Task { await session.disconnect() } }
            connection.interruptionHandler = { Task { await session.disconnect() } }
        } else {
            connection.exportedObject = self
        }
        connection.activate()
        return true
    }

    func readStatus(withReply reply: @escaping @Sendable (Data) -> Void) {
        if replies { reply(response) }
    }

    func verifyNativeChargeLimit(_ limit: Int, withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }
    func readChargeDiagnostics(withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }

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

    @Test func productionSessionStatusAndRestorationAcknowledgementRoundTripOverXPC() async throws {
        let executor = ChargeCommandExecutor()
        try await executor.start()
        let server = try LocalHelperService(executor: executor)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        for removing in [false, true] {
            let connection = HelperConnection(endpoint: listener.endpoint)
            #expect(try await connection.request(requirement: "identifier \"blinks44.monny\"", forRemoval: removing) == .current)
        }
        #expect(await executor.phase == .removing)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) {
            try await executor.apply(.hold, owner: executor.beginSession(), leaseFor: .seconds(30))
        }
    }

    @Test func productionDiagnosticRoundTripRemainsReadOnly() async throws {
        let expected = ChargeCapabilityProbe.inspect { _ in .unavailable(.kernel(-1)) }
        let native = NativeChargeLimit.available(.init(availableLimits: [80, 100], configuredLimit: 80, enabled: true))
        let executor = ChargeCommandExecutor(diagnosticRead: { expected }, nativeDiagnosticRead: { native })
        try await executor.start()
        let server = try LocalHelperService(executor: executor)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let response = try await HelperConnection(endpoint: listener.endpoint).diagnose(requirement: "identifier \"blinks44.monny\"")
        #expect(response.chargeDiagnostics == expected)
        #expect(response.nativeChargeLimit == native)
        #expect(response.chargingSupport == .notImplemented)
        #expect(await executor.state == .macOS)
    }

    @Test func diagnosticRejectsMissingPayloadAndWrongPeer() async throws {
        let server = try LocalHelperService()
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        await #expect(throws: HelperConnectionError.invalidReply) {
            try await HelperConnection(endpoint: listener.endpoint).diagnose(requirement: "identifier \"blinks44.monny\"")
        }
        await #expect(throws: HelperConnectionError.connectionFailed) {
            try await HelperConnection(endpoint: listener.endpoint).diagnose(requirement: "identifier \"blinks44.monny.untrusted\"")
        }
    }

    @Test func manualVerificationRoundTripsThroughAuthenticatedProductionSession() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let server = try LocalHelperService(executor: executor)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let requirement = "identifier \"blinks44.monny\""
        let response = try await NativeLimitVerificationCommand.collect(target: 80, requirement: requirement,
            status: { try await HelperConnection(endpoint: endpoint).request(requirement: $0) },
            verify: { try await HelperConnection(endpoint: endpoint).verifyNativeLimit($0, requirement: $1) })
        #expect(response.nativeVerification?.outcome == .restored)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        let writes = fixture.storage.withLock { $0.writes }
        // Enforce rejection on the server before dispatch; a client rejecting a reply is too late.
        let denied = try LocalHelperService(executor: executor, clientRequirement: "identifier \"blinks44.monny.untrusted\"")
        let deniedListener = NSXPCListener.anonymous()
        deniedListener.delegate = denied
        deniedListener.setConnectionCodeSigningRequirement("identifier \"blinks44.monny.untrusted\"")
        deniedListener.activate()
        defer { withExtendedLifetime(denied) { deniedListener.invalidate() } }
        await #expect(throws: HelperConnectionError.connectionFailed) {
            try await HelperConnection(endpoint: deniedListener.endpoint).verifyNativeLimit(80, requirement: requirement)
        }
        #expect(fixture.storage.withLock { $0.writes } == writes)
    }

}
