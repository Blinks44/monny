import Foundation
import Testing
import Synchronization
import Observation
@testable import monny

/// An unprivileged anonymous service exercises Foundation IPC, never SMAppService.
nonisolated final class LocalHelperService: NSObject, NSXPCListenerDelegate, BatteryHelperProtocol {
    let nativeCalls = Mutex(0)
    private let response: Data
    private let onDisconnect: (@Sendable () -> Void)?
    private let replies: Bool
    private let executor: ChargeCommandExecutor?
    private let clientRequirement: String?

    init(replies: Bool = true, executor: ChargeCommandExecutor? = nil, clientRequirement: String? = nil,
         onDisconnect: (@Sendable () -> Void)? = nil, status: HelperStatus = .current) throws {
        self.onDisconnect = onDisconnect
        self.clientRequirement = clientRequirement
        self.executor = executor
        self.response = try JSONEncoder().encode(status)
        self.replies = replies
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        if let clientRequirement { connection.setCodeSigningRequirement(clientRequirement) }
        connection.exportedInterface = NSXPCInterface(with: BatteryHelperProtocol.self)
        if let executor {
            let session = HelperSession(executor: executor)
            connection.exportedObject = session
            let onDisconnect = self.onDisconnect
            connection.invalidationHandler = { Task { await session.disconnect(); onDisconnect?() } }
            connection.interruptionHandler = { Task { await session.disconnect(); onDisconnect?() } }
        } else {
            connection.exportedObject = self
        }
        connection.activate()
        return true
    }

    func readStatus(withReply reply: @escaping @Sendable (Data) -> Void) {
        if replies { reply(response) }
    }

    func prepareAdapterRemoval(withReply reply: @escaping @Sendable (Data) -> Void) { if replies { reply(response) } }
    func prepareAdapterSleep(withReply reply: @escaping @Sendable (Data) -> Void) { if replies { reply(response) } }
    func cancelAdapterSleep(withReply reply: @escaping @Sendable (Data) -> Void) { if replies { reply(response) } }
    func verifyAdapterRestart(withReply reply: @escaping @Sendable (Data) -> Void) { if replies { reply(response) } }
    func observeAdapterByte(withReply reply: @escaping @Sendable (Data) -> Void) { if replies { reply(response) } }
    func verifyAdapterBytePulse(withReply reply: @escaping @Sendable (Data) -> Void) { if replies { reply(response) } }
    func verifyAdapterIsolation(withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }
    func verifyNativeChargeLimit(_ limit: Int, withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }
    func readChargeDiagnostics(withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }
    func readAdapterDiagnostics(withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }

    func applyNativeChargeLimit(_ limit: Int, withReply reply: @escaping @Sendable (Data) -> Void) { nativeCalls.withLock { $0 += 1 }; reply(response) }
    func restoreNativeChargeLimit(withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }

    func prepareForRemoval(withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }
}

@MainActor
struct HelperIPCTests {
    @Test func adapterDiagnosticsUseAuthenticatedAnonymousIPCWithoutChargingWrites() async throws {
        let executor = ChargeCommandExecutor(adapterDiagnosticRead: {
            AdapterCapabilityProbe.inspect { _ in .unavailable(.smc(0x84)) }
        })
        try await executor.start()
        let server = try LocalHelperService(executor: executor)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let response = try await BatteryDiagnosticCommand.collectAdapter(
            requirement: "identifier \"blinks44.monny\"",
            status: { try await HelperConnection(endpoint: endpoint).request(requirement: $0) },
            diagnostics: { try await HelperConnection(endpoint: endpoint).diagnoseAdapter(requirement: $0) })
        #expect(response.adapterDiagnostics?.entries.map(\.key) == ["CHIE", "CH0I", "CH0J"])
        #expect(response.adapterDiagnostics?.controlSupport == .unverified)
        #expect(response.chargeDiagnostics == nil)
        #expect(response.controlState == .notControlling)
    }

    @Test(.timeLimit(.minutes(1)))
    func expiredOwnerRenewalReadsFreshStateWithoutReapplyingOrCancellingTheRead() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let server = try LocalHelperService(executor: executor)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let helper = BatteryHelper(operations: .init(
            signingIdentity: { .appleTeam("ABCDEFGHIJ") }, registration: { .enabled },
            register: { Issue.record("Lease recovery must not register a helper") },
            unregister: { Issue.record("Lease recovery must not unregister a helper") },
            request: { _, removing in
                try await HelperConnection(endpoint: endpoint).request(
                    requirement: "identifier \"blinks44.monny\"", forRemoval: removing)
            }), connectNativeSession: { _ in
                let session = NativeLimitSession(endpoint: endpoint)
                _ = try await session.open(requirement: "identifier \"blinks44.monny\"")
                return session
            })
        await helper.refresh()
        await helper.setNativeLimit(80)
        #expect(helper.nativeLimit == 80)
        let deadline = try #require(await executor.leaseDeadline)
        try await executor.checkLease(at: deadline)
        let writes = fixture.storage.withLock { $0.writes }
        let (events, continuation) = AsyncStream<Void>.makeStream()
        observeNativeRecovery(helper, continuation: continuation)
        // Wait for the real ten-second renewal and published result, without polling
        // or an arbitrary test sleep. A cancelled read can never reach this state.
        for await _ in events { break }
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(fixture.storage.withLock { $0.writes } == writes)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    private func observeNativeRecovery(_ helper: BatteryHelper, continuation: AsyncStream<Void>.Continuation) {
        let recovered = withObservationTracking {
            helper.nativeLimit == nil && helper.state == .connected && !helper.nativeFailed
                && !helper.nativeBusy && !helper.isBusy
        } onChange: {
            Task { @MainActor in observeNativeRecovery(helper, continuation: continuation) }
        }
        if recovered { continuation.yield(()); continuation.finish() }
    }

    @Test(arguments: ["stop", "sleep", "expiry", "removal", "external"])
    func appCoordinatorReleasesNativeControlWithoutReplayingIt(event: String) async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let server = try LocalHelperService(executor: executor)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let registered = Mutex(true)
        let registerCalls = Mutex(0)
        let connections = Mutex(0)
        let helper = BatteryHelper(operations: .init(
            signingIdentity: { .appleTeam("ABCDEFGHIJ") },
            registration: { registered.withLock { $0 ? .enabled : .notRegistered } },
            register: { registerCalls.withLock { $0 += 1 } },
            unregister: {
                #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
                #expect(fixture.storage.withLock { $0.journal } == nil)
                registered.withLock { $0 = false }
            },
            request: { _, removing in
                try await HelperConnection(endpoint: endpoint).request(
                    requirement: "identifier \"blinks44.monny\"", forRemoval: removing)
            }), connectNativeSession: { _ in
                connections.withLock { $0 += 1 }
                let session = NativeLimitSession(endpoint: endpoint)
                _ = try await session.open(requirement: "identifier \"blinks44.monny\"")
                return session
            })
        await helper.refresh()
        #expect(helper.nativeLimit == nil)
        #expect(fixture.storage.withLock { $0.writes } == 0)
        await helper.setNativeLimit(80)
        #expect(helper.nativeLimit == 80)
        #expect(helper.state == .connected)

        switch event {
        case "sleep":
            try await executor.willSleep()
            await helper.refresh()
            #expect(helper.nativeLimit == 80)
            #expect(helper.state == .connected)
            try await executor.didWake()
            await helper.refresh()
            #expect(helper.nativeLimit == 80)
            #expect(helper.state == .connected)
            await helper.stopNativeLimit()
        case "expiry":
            let deadline = try #require(await executor.leaseDeadline)
            try await executor.checkLease(at: deadline)
            await helper.refresh()
        case "removal": await helper.remove()
        case "external":
            fixture.storage.withLock { $0.snapshot.configuredLimit = 95 }
            await helper.refresh()
            #expect(helper.nativeLimit == nil)
            #expect(helper.nativeFailed)
            await helper.refresh()
        default: await helper.stopNativeLimit()
        }
        #expect(helper.nativeLimit == nil)
        #expect(!helper.nativeFailed)
        #expect(helper.state == (event == "removal" ? .notInstalled : .connected))
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == (event == "external" ? 95 : 85))
        #expect(fixture.storage.withLock { $0.journal } == nil)
        let writes = fixture.storage.withLock { $0.writes }
        await helper.refresh()
        #expect(fixture.storage.withLock { $0.writes } == writes)
        #expect(connections.withLock { $0 } == 1)
        #expect(registerCalls.withLock { $0 } == 0)
    }

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


    @Test func persistentNativeOwnerRenewsAndRestoresOverRealAnonymousXPC() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let server = try LocalHelperService(executor: executor)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let client = NativeLimitSession(endpoint: listener.endpoint)
        let requirement = "identifier \"blinks44.monny\""
        #expect(try await client.open(requirement: requirement).nativeLimitSessionAvailable == true)
        #expect(try await client.apply(80).activeNativeLimit == 80)
        let writes = fixture.storage.withLock { $0.writes }
        #expect(try await client.apply(80).activeNativeLimit == 80)
        #expect(fixture.storage.withLock { $0.writes } == writes)
        let observer = try await HelperConnection(endpoint: listener.endpoint).request(requirement: requirement)
        #expect(observer.controlState == .nativeLimit)
        #expect(try await client.apply(90).activeNativeLimit == 90)
        #expect(try await client.stop().controlState == .notControlling)
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: [0, 1, 2])
    func persistentClientRejectsLegacyHelperBeforeAnyWriteSelector(legacyRevision: Int) async throws {
        var status = HelperStatus.current
        if legacyRevision > 0 {
            status.nativeLimitSessionAvailable = true
            if legacyRevision == 2 { status.nativeLimitSessionVersion = 2 }
            status.nativeChargeLimit = .available(.init(availableLimits: [80, 85, 100], configuredLimit: 85, enabled: true))
        }
        let server = try LocalHelperService(status: status)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let client = NativeLimitSession(endpoint: listener.endpoint)
        await #expect(throws: BatteryDiagnosticCommand.Failure.helperUpdateRequired) {
            try await client.open(requirement: "identifier \"blinks44.monny\"")
        }
        #expect(server.nativeCalls.withLock { $0 } == 0)
        #expect(try await HelperConnection(endpoint: listener.endpoint).request(
            requirement: "identifier \"blinks44.monny\"", forRemoval: true) == status)
    }

    @Test func persistentClientTimeoutClosesInsteadOfRetrying() async throws {
        let server = try LocalHelperService(replies: false)
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let client = NativeLimitSession(endpoint: listener.endpoint, timeout: .milliseconds(100))
        await #expect(throws: HelperConnectionError.timedOut) {
            try await client.open(requirement: "identifier \"blinks44.monny\"")
        }
        await #expect(throws: HelperConnectionError.invalidReply) { try await client.apply(80) }
        #expect(server.nativeCalls.withLock { $0 } == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func closingNativeOwnerConnectionRestoresWithoutAnExplicitStop() async throws {
        let fixture = VerificationFixture()
        let executor = fixture.executor()
        try await executor.start()
        let (events, continuation) = AsyncStream<Void>.makeStream()
        let server = try LocalHelperService(executor: executor, onDisconnect: {
            continuation.yield(()); continuation.finish()
        })
        let listener = NSXPCListener.anonymous()
        listener.delegate = server
        listener.activate()
        defer { withExtendedLifetime(server) { listener.invalidate() } }
        let client = NativeLimitSession(endpoint: listener.endpoint)
        _ = try await client.open(requirement: "identifier \"blinks44.monny\"")
        _ = try await client.apply(80)
        await client.close()
        for await _ in events { break }
        #expect(fixture.storage.withLock { $0.snapshot.configuredLimit } == 85)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

}
