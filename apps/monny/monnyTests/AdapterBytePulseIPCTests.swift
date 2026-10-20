import Foundation
import Synchronization
import Testing
@testable import monny

@MainActor
struct AdapterBytePulseIPCTests {
    private let requirement = "identifier \"blinks44.monny\""

    nonisolated static func backend(_ fixture: AdapterVerificationFixture) -> ChargeCommandExecutor.AdapterVerificationBackend {
        var backend = fixture.backend
        backend.allowsIsolationVerification = false
        backend.pulseRead = { phase in
            fixture.storage.withLock { state in
                .init(reading: .init(nativeLimit: phase == .during ? nil : state.environment.nativeLimit,
                    nativeSessionActive: false, source: state.environment.source,
                    isCharging: state.environment.isCharging, level: state.environment.level,
                    rawExternalConnected: phase == .during ? nil : true,
                    externalConnected: state.byte == 0, isLidClosed: false))
            }
        }
        return backend
    }

    @Test func pulseOnlyBackendUsesAuthenticatedIPCAndNeverEnablesIsolation() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = ChargeCommandExecutor(adapterVerificationBackend: Self.backend(fixture))
        try await executor.start()
        let token = try await executor.beginSession()
        let status = try await executor.status(for: token)
        #expect(status.adapterBytePulseAvailable == true)
        #expect(status.adapterVerificationAvailable == false)
        await #expect(throws: ChargeCommandExecutor.Failure.unsupported) { try await executor.startAdapterVerification(for: token) }
        await #expect(throws: ChargeCommandExecutor.Failure.unsupported) { try await executor.verifyAdapterIsolation(for: token) }
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let response = try await AdapterBytePulseCommand.collect(requirement: requirement,
            status: { try await HelperConnection(endpoint: endpoint).request(requirement: $0) },
            verify: { try await HelperConnection(endpoint: endpoint).verifyAdapterBytePulse(requirement: $0) })
        let report = try #require(response.adapterBytePulse)
        #expect(report.outcome == .byteRoundTripRestored)
        #expect(report.controlSupport == .unverified)
        #expect(report.during?.nativeLimit == nil)
        #expect(report.during?.rawExternalConnected == nil)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(try HelperStatus.decode(JSONEncoder().encode(response)) == response)
        #expect(await executor.state == .macOS)
    }

    @Test(arguments: [Optional<Bool>.none, false, true])
    func handshakeRefusesAbsentDisabledOrWrongRevision(available: Bool?) async {
        var status = HelperStatus.current
        status.adapterBytePulseAvailable = available
        status.adapterBytePulseVersion = 999
        let handshake = status
        await #expect(throws: available == false ? AdapterBytePulseCommand.Failure.verificationNotEnabled : .helperUpdateRequired) {
            try await AdapterBytePulseCommand.collect(requirement: "fixture", status: { _ in handshake }, verify: { _ in
                Issue.record("No selector may be sent without a positive revisioned handshake")
                return .current
            })
        }
    }

    @Test func recoveryPrecedesNativeFactoryAndBlocksReadsUntilRestored() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.effects[1] = .loseReadAccess }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: Self.backend(fixture))
        try await executor.start()
        let token = try await executor.beginSession()
        let report = try await executor.verifyAdapterBytePulse(for: token)
        #expect(report.adapterBytePulse?.outcome == .restorationRequired)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.status(for: token) }
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.verifyAdapterBytePulse(for: token) }
        fixture.storage.withLock { $0.failReads = false }
        let backend = Self.backend(fixture)
        let restarted = ChargeCommandExecutor(nativeBackendFactory: {
            #expect(fixture.storage.withLock { $0.byte } == 0)
            #expect(fixture.storage.withLock { $0.journal } == nil)
            throw ChargeCommandExecutor.Failure.unsupported
        }, adapterBackendFactory: { backend })
        await #expect(throws: ChargeCommandExecutor.Failure.restorationFailed) { try await restarted.start() }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func nativeOwnerAndInvalidSessionRefuseBeforePulse() async throws {
        let fixture = AdapterVerificationFixture()
        let native = VerificationFixture()
        let executor = ChargeCommandExecutor(nativeBackend: native.backend, adapterVerificationBackend: Self.backend(fixture))
        try await executor.start()
        let owner = try await executor.beginSession()
        let other = try await executor.beginSession()
        try await executor.applyNativeLimit(80, owner: owner, leaseFor: .seconds(30))
        for token in [owner, other] {
            await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.verifyAdapterBytePulse(for: token) }
        }
        await #expect(throws: ChargeCommandExecutor.Failure.invalidSession) { try await executor.verifyAdapterBytePulse(for: UUID()) }
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
        _ = try await executor.releaseNativeLimit(for: owner)
    }

    @Test func malformedOrMixedEvidenceFailsClosed() throws {
        var status = HelperStatus.current
        status.adapterBytePulseAvailable = true
        status.adapterBytePulseVersion = HelperContract.adapterBytePulseVersion
        status.adapterBytePulse = .init(outcome: .byteRoundTripRestored)
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.adapterBytePulse = .init(outcome: .unavailable)
        #expect(try status.validated() == status)
        status.nativeVerification = .init(target: 80, outcome: .unavailable)
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        try AdapterBytePulseCommand.validate(arguments: ["Monny", AdapterBytePulseCommand.flag])
        #expect(throws: AdapterBytePulseCommand.Failure.invalidArguments) {
            try AdapterBytePulseCommand.validate(arguments: ["Monny", AdapterBytePulseCommand.flag, "CHIE"])
        }
    }

    @Test(arguments: ["timeout", "wrongPeer", "missingReport"])
    func failedPulseTransportDoesNotRetryOrAcceptStatusOnlyReply(condition: String) async throws {
        let service = try LocalHelperService(replies: condition != "timeout")
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let connection = HelperConnection(endpoint: listener.endpoint, timeout: .milliseconds(150))
        let expected: HelperConnectionError = condition == "timeout" ? .timedOut : condition == "wrongPeer" ? .connectionFailed : .invalidReply
        await #expect(throws: expected) {
            try await connection.verifyAdapterBytePulse(requirement: condition == "wrongPeer" ? "identifier \"blinks44.monny.untrusted\"" : requirement)
        }
    }

    @Test func lidRequiresRealBooleanAndNativeGetterIsSkippedDuringPulse() throws {
        for invalid: Any in [NSNumber(value: 0), NSNumber(value: 1), "false", NSNull()] {
            #expect(AdapterBytePulseReader.boolean(invalid) == nil)
        }
        #expect(AdapterBytePulseReader.boolean(kCFBooleanFalse) == false)
        #expect(AdapterBytePulseReader.boolean(kCFBooleanTrue) == true)
        #expect(AdapterBytePulseReader.boolean(nil) == nil)
        let result = try AdapterBytePulseReader.nativeSnapshot(for: .during) {
            Issue.record("The private getter must not run during isolation")
            throw ChargeCommandExecutor.Failure.unsupported
        }
        #expect(result == nil)
    }
}
