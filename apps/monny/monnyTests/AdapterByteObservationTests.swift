import Foundation
import Synchronization
import Testing
@testable import monny

@MainActor
struct AdapterByteObservationTests {
    private let requirement = "identifier \"blinks44.monny\""
    private nonisolated static func backend(_ fixture: AdapterVerificationFixture) -> ChargeCommandExecutor.AdapterVerificationBackend {
        AdapterBytePulseIPCTests.backend(fixture)
    }

    @Test func authenticatedXPCObservesBatteryAndRestoresWithoutClaimingPhysicalSupport() async throws {
        let fixture = AdapterVerificationFixture()
        let executor = ChargeCommandExecutor(adapterVerificationBackend: Self.backend(fixture))
        try await executor.start()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement)
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let endpoint = listener.endpoint
        let result = try await AdapterByteObservationCommand.collect(requirement: requirement,
            status: { try await HelperConnection(endpoint: endpoint).request(requirement: $0) },
            verify: { try await HelperConnection(endpoint: endpoint).observeAdapterByte(requirement: $0) })
        let report = try #require(result.adapterByteObservation)
        #expect(report.isSuccessful)
        #expect(report.sampleCount == 1)
        #expect(report.byteEvidence.during?.nativeLimit == nil)
        #expect(report.byteEvidence.controlSupport == .unverified)
        #expect(result.adapterVerificationAvailable == false)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
        let encoded = try JSONEncoder().encode(result)
        #expect(encoded.count < 4096)
        #expect(try HelperStatus.decode(encoded) == result)
    }

    @Test func sampleBoundRestoresWithoutSourceTransitionAndCannotCountAsSuccess() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.simulateSourceTransition = false }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: Self.backend(fixture))
        try await executor.start()
        let token = try await executor.beginSession()
        let result = try await executor.observeAdapterByte(for: token, pause: {})
        let report = try #require(result.adapterByteObservation)
        #expect(report.sampleCount == 8)
        #expect(!report.batterySourceObserved)
        #expect(!report.isSuccessful)
        #expect(report.byteEvidence.outcome == .byteRoundTripRestored)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func wallTimeBoundRestoresBeforeFurtherReadingEvenWhenPauseRunsLate() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.simulateSourceTransition = false }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: Self.backend(fixture))
        try await executor.start()
        let token = try await executor.beginSession()
        let result = try await executor.observeAdapterByte(for: token, pause: {
            try await Task.sleep(for: .milliseconds(2100), clock: .suspending)
        })
        let report = try #require(result.adapterByteObservation)
        #expect(report.sampleCount == 1)
        #expect(!report.batterySourceObserved)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: ["sleep", "removal", "disconnect", "shutdown", "expiry", "cancel", "sleepWake"])
    func interruptionRestoresAndReservedRequestRejectsCompetitors(event: String) async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.simulateSourceTransition = false }
        let native = VerificationFixture()
        let executor = ChargeCommandExecutor(nativeBackend: native.backend, adapterVerificationBackend: Self.backend(fixture))
        try await executor.start()
        let token = try await executor.beginSession()
        let foreign = try await executor.beginSession()
        let gate = AdapterObservationPause()
        let request = Task { try await executor.observeAdapterByte(for: token, pause: { await gate.wait() }) }
        await gate.waitUntilPaused()
        #expect(fixture.storage.withLock { $0.byte } == 8)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.observeAdapterByte(for: foreign) }
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.applyNativeLimit(80, owner: token, leaseFor: .seconds(30)) }
        switch event {
        case "sleep", "sleepWake": try await executor.willSleep()
        case "removal": _ = try await executor.status(for: foreign, removing: true)
        case "disconnect": try await executor.disconnect(owner: token)
        case "shutdown": try await executor.shutdown()
        case "cancel": request.cancel()
        default:
            let deadline = try #require(await executor.leaseDeadline)
            try await executor.checkLease(at: deadline)
        }
        if event == "sleepWake" {
            try await executor.didWake()
            let new = try await executor.beginSession()
            await #expect(throws: ChargeCommandExecutor.Failure.notReady) {
                try await executor.applyNativeLimit(80, owner: new, leaseFor: .seconds(30))
            }
        }
        await gate.finish()
        let response = try await request.value
        #expect(response.adapterByteObservation?.batterySourceObserved == false)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(native.storage.withLock { $0.writes } == 0)
    }

    @Test(arguments: ["unknownLid", "lowBattery", "missingReading", "nativeChanged", "unknownSource"])
    func unsafeOrMissingDuringObservationRestoresImmediately(condition: String) async throws {
        let fixture = AdapterVerificationFixture()
        var backend = Self.backend(fixture)
        let original = try #require(backend.pulseRead)
        backend.pulseRead = { phase in
            var sample = try original(phase)
            if phase == .during {
                if condition == "unknownLid" { sample.reading.isLidClosed = nil }
                if condition == "lowBattery" { sample.reading.level = 0.29 }
                if condition == "missingReading" { throw AdapterTransaction.Failure.unavailable }
                if condition == "nativeChanged" {
                    sample.reading.nativeLimit = sample.reading.nativeLimit ?? fixture.storage.withLock { $0.environment.nativeLimit }
                    sample.reading.nativeLimit?.configuredLimit = 90
                }
                if condition == "unknownSource" { sample.reading.source = .unknown }
            }
            return sample
        }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: backend)
        try await executor.start()
        let token = try await executor.beginSession()
        let response = try await executor.observeAdapterByte(for: token, pause: {})
        let report = try #require(response.adapterByteObservation)
        #expect(!report.batterySourceObserved)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        if condition != "unknownSource" { #expect(report.sampleCount == 0) }
    }

    @Test func restorationFailureRetainsJournalAndRecoveryWatchdogWithoutRepeatingIsolation() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.effects[2] = .failBefore }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: Self.backend(fixture))
        try await executor.start()
        let token = try await executor.beginSession()
        let response = try await executor.observeAdapterByte(for: token, pause: {})
        #expect(response.adapterByteObservation?.byteEvidence.outcome == .restorationRequired)
        #expect(fixture.storage.withLock { $0.journal } != nil)
        let deadline = try #require(await executor.leaseDeadline)
        try await executor.checkLease(at: deadline)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(fixture.storage.withLock { $0.writes.filter { $0 }.count } == 1)
    }

    @Test(arguments: [Optional<Bool>.none, false, true])
    func incompatibleHandshakeNeverSendsSelector(available: Bool?) async {
        var status = HelperStatus.current
        status.adapterByteObservationAvailable = available
        status.adapterByteObservationVersion = 999
        let handshake = status
        await #expect(throws: available == false ? AdapterByteObservationCommand.Failure.verificationNotEnabled : .helperUpdateRequired) {
            try await AdapterByteObservationCommand.collect(requirement: "fixture", status: { _ in handshake }, verify: { _ in
                Issue.record("Unadvertised selector sent")
                return .current
            })
        }
    }

    @Test(arguments: [false, true])
    func clientTimeoutDisconnectRestoresAndDoesNotReplay(settling: Bool) async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.simulateSourceTransition = settling }
        var backend = Self.backend(fixture)
        let original = try #require(backend.pulseRead)
        backend.pulseRead = { phase in
            var sample = try original(phase)
            if settling && phase == .after { sample.reading.source = .battery }
            return sample
        }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: backend)
        try await executor.start()
        let (events, continuation) = AsyncStream<Void>.makeStream()
        let service = try LocalHelperService(executor: executor, clientRequirement: requirement,
            onDisconnect: { continuation.yield(()); continuation.finish() })
        let listener = NSXPCListener.anonymous()
        listener.delegate = service
        listener.activate()
        defer { withExtendedLifetime(service) { listener.invalidate() } }
        let client = HelperConnection(endpoint: listener.endpoint, timeout: .milliseconds(300))
        await #expect(throws: HelperConnectionError.timedOut) { try await client.observeAdapterByte(requirement: requirement) }
        for await _ in events { break }
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
    }

    @Test func restoredByteWithoutAdapterSourceReturnDoesNotSucceed() async throws {
        let fixture = AdapterVerificationFixture()
        var backend = Self.backend(fixture)
        let original = try #require(backend.pulseRead)
        backend.pulseRead = { phase in
            var sample = try original(phase)
            if phase == .after { sample.reading.source = .battery }
            return sample
        }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: backend)
        try await executor.start()
        let token = try await executor.beginSession()
        let response = try await executor.observeAdapterByte(for: token, pause: {})
        let report = try #require(response.adapterByteObservation)
        #expect(report.batterySourceObserved)
        #expect(report.byteEvidence.restoredByte == 0)
        #expect(!report.isSuccessful)
        #expect(fixture.storage.withLock { $0.byte } == 0)
    }

    @Test func delayedAdapterReturnWaitsOnlyAfterZeroAndWithoutMoreSetters() async throws {
        let fixture = AdapterVerificationFixture()
        var backend = Self.backend(fixture)
        let original = try #require(backend.pulseRead)
        let afterReads = Mutex(0)
        backend.pulseRead = { phase in
            var sample = try original(phase)
            if phase == .after {
                #expect(fixture.storage.withLock { $0.byte } == 0)
                #expect(fixture.storage.withLock { $0.journal } == nil)
                let count = afterReads.withLock { $0 += 1; return $0 }
                if count < 3 { sample.reading.source = .battery }
            }
            return sample
        }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: backend)
        try await executor.start()
        let token = try await executor.beginSession()
        let result = try await executor.observeAdapterByte(for: token, pause: {})
        let report = try #require(result.adapterByteObservation)
        #expect(report.isSuccessful)
        #expect(report.returnObservation == .adapterObserved)
        #expect(report.returnSampleCount == 3)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(try HelperStatus.decode(JSONEncoder().encode(result)) == result)
    }

    @Test(arguments: ["sleep", "sleepWake", "removal", "disconnect", "shutdown", "cancel"])
    func settlingInterruptionKeepsRollbackAndReservesRequest(event: String) async throws {
        let fixture = AdapterVerificationFixture()
        let native = VerificationFixture()
        var backend = Self.backend(fixture)
        let original = try #require(backend.pulseRead)
        backend.pulseRead = { phase in
            var sample = try original(phase)
            if phase == .after { sample.reading.source = .battery }
            return sample
        }
        let executor = ChargeCommandExecutor(nativeBackend: native.backend, adapterVerificationBackend: backend)
        try await executor.start()
        let token = try await executor.beginSession()
        let foreign = try await executor.beginSession()
        let gate = AdapterObservationPause()
        let request = Task { try await executor.observeAdapterByte(for: token, pause: { await gate.wait() }) }
        await gate.waitUntilPaused()
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(await executor.leaseDeadline == nil)
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.observeAdapterByte(for: foreign) }
        await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.applyNativeLimit(80, owner: foreign, leaseFor: .seconds(30)) }
        switch event {
        case "sleep", "sleepWake": try await executor.willSleep()
        case "removal": _ = try await executor.status(for: foreign, removing: true)
        case "disconnect": try await executor.disconnect(owner: token)
        case "shutdown": try await executor.shutdown()
        default: request.cancel()
        }
        if event == "sleepWake" {
            try await executor.didWake()
            let new = try await executor.beginSession()
            await #expect(throws: ChargeCommandExecutor.Failure.notReady) { try await executor.applyNativeLimit(80, owner: new, leaseFor: .seconds(30)) }
        }
        await gate.finish()
        let result = try await request.value
        #expect(result.adapterByteObservation?.returnObservation == .interrupted)
        #expect(result.adapterByteObservation?.isSuccessful == false)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(native.storage.withLock { $0.writes } == 0)
    }

    @Test(arguments: ["stale", "missing", "nativeChanged", "byteChanged", "neverReturns"])
    func settlingUnavailableOrUnreturnedSourceCannotSucceedOrWriteAgain(condition: String) async throws {
        let fixture = AdapterVerificationFixture()
        var backend = Self.backend(fixture)
        let original = try #require(backend.pulseRead)
        backend.pulseRead = { phase in
            var sample = try original(phase)
            if phase == .after {
                switch condition {
                case "stale": sample.age = .seconds(3)
                case "missing": throw AdapterTransaction.Failure.unavailable
                case "nativeChanged": sample.reading.nativeLimit?.configuredLimit = 90
                case "byteChanged": fixture.storage.withLock { $0.byte = 8 }; sample.reading.source = .battery
                default: sample.reading.source = .battery
                }
            }
            return sample
        }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: backend)
        try await executor.start()
        let token = try await executor.beginSession()
        let result = try await executor.observeAdapterByte(for: token, pause: {})
        let report = try #require(result.adapterByteObservation)
        #expect(!report.isSuccessful)
        #expect(report.returnObservation == (condition == "neverReturns" ? .boundReached : .unavailable))
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
        if condition == "neverReturns" { #expect(report.returnSampleCount == 8) }
    }

    @Test func settlingTimeBoundExitsAfterLatePauseWithoutAnotherRead() async throws {
        let fixture = AdapterVerificationFixture()
        var backend = Self.backend(fixture)
        let original = try #require(backend.pulseRead)
        backend.pulseRead = { phase in
            var sample = try original(phase)
            if phase == .after { sample.reading.source = .battery }
            return sample
        }
        let executor = ChargeCommandExecutor(adapterVerificationBackend: backend)
        try await executor.start()
        let token = try await executor.beginSession()
        let response = try await executor.observeAdapterByte(for: token, pause: {
            try await Task.sleep(for: .milliseconds(2100), clock: .suspending)
        })
        #expect(response.adapterByteObservation?.returnSampleCount == 1)
        #expect(response.adapterByteObservation?.returnObservation == .boundReached)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
    }

    @Test func revisionOneHelperRefusesBeforeAnyHardwareSelector() async {
        var status = HelperStatus.current
        status.adapterByteObservationAvailable = true
        status.adapterByteObservationVersion = 1
        let handshake = status
        await #expect(throws: AdapterByteObservationCommand.Failure.helperUpdateRequired) {
            try await AdapterByteObservationCommand.collect(requirement: "fixture", status: { _ in handshake }, verify: { _ in
                Issue.record("Revision 1 helper must not receive a revision 2 request")
                return .current
            })
        }
    }

    @Test func wireValidationRejectsInventedSourceSuccessAndMixedReports() throws {
        var response = HelperStatus.current
        response.adapterByteObservationAvailable = true
        response.adapterByteObservationVersion = HelperContract.adapterByteObservationVersion
        response.adapterByteObservation = .init(byteEvidence: .init(outcome: .unavailable))
        #expect(try response.validated() == response)
        response.adapterByteObservation?.batterySourceObserved = true
        #expect(throws: HelperConnectionError.invalidReply) { try response.validated() }
        response.adapterByteObservation?.batterySourceObserved = false
        response.adapterByteObservation?.sampleCount = 999
        #expect(throws: HelperConnectionError.invalidReply) { try response.validated() }
        response.adapterByteObservation?.sampleCount = 0
        response.adapterBytePulse = .init(outcome: .unavailable)
        #expect(throws: HelperConnectionError.invalidReply) { try response.validated() }
        try AdapterByteObservationCommand.validate(arguments: ["Monny", AdapterByteObservationCommand.flag])
        #expect(throws: AdapterByteObservationCommand.Failure.invalidArguments) {
            try AdapterByteObservationCommand.validate(arguments: ["Monny", AdapterByteObservationCommand.flag, "30"])
        }
    }
}
