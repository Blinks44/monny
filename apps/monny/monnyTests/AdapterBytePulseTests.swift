import Foundation
import Testing
@testable import monny

struct AdapterBytePulseTests {
    private nonisolated static func sample(_ fixture: AdapterVerificationFixture) -> AdapterBytePulseReport.Sample {
        fixture.storage.withLock { state in
            .init(reading: .init(nativeLimit: state.environment.nativeLimit,
                                 nativeSessionActive: state.environment.nativeSessionActive,
                                 source: state.environment.source, isCharging: state.environment.isCharging,
                                 level: state.environment.level, rawExternalConnected: true,
                                 externalConnected: state.byte == 0, isLidClosed: false), age: state.environment.age)
        }
    }

    @Test(arguments: [Optional<Bool>.none, false, true])
    func bytePulseCapturesUnverifiedFlagsWithoutClaimingPhysicalIsolation(rawDuring: Bool?) throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock {
            $0.simulateSourceTransition = false
            $0.environment.isAdapterConnected = false // Normal verification must refuse this unknown physical condition.
        }
        var normal = try fixture.transaction()
        #expect(throws: AdapterTransaction.Failure.adapterDisconnected) { try normal.begin() }
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
        var pulse = try fixture.transaction()
        let report = try pulse.pulse { _ in
            var sample = Self.sample(fixture)
            if fixture.storage.withLock({ $0.byte }) == 8 {
                sample.reading.rawExternalConnected = rawDuring
                sample.reading.source = .unknown
                sample.reading.nativeLimit = nil // Do not invent a native read while input is isolated.
            }
            return sample
        }
        #expect(report.isValid)
        #expect(report.outcome == .byteRoundTripRestored)
        #expect(report.controlSupport == .unverified)
        #expect(report.appliedByte == 8)
        #expect(report.restoredByte == 0)
        #expect(report.during?.source == .unknown)
        #expect(report.during?.nativeLimit == nil)
        #expect(report.during?.rawExternalConnected == rawDuring)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(pulse.state == .idle)
        let events = fixture.storage.withLock { $0.events }
        #expect(try #require(events.firstIndex(of: "save")) < #require(events.firstIndex(of: "isolate")))
        let data = try JSONEncoder().encode(report)
        #expect(data.count < 4096)
        #expect(try JSONDecoder().decode(AdapterBytePulseReport.self, from: data) == report)
    }

    @Test(arguments: ["lowBattery", "lidClosed", "unknownLid", "rawFalse", "rawUnknown", "nativeOwner", "batterySource", "unknownSource", "stale", "negativeAge"])
    func unsafeAdmissionCannotCheckpointOrWrite(condition: String) throws {
        let fixture = AdapterVerificationFixture()
        var sample = Self.sample(fixture)
        switch condition {
        case "lowBattery": sample.reading.level = 0.29
        case "lidClosed": sample.reading.isLidClosed = true
        case "unknownLid": sample.reading.isLidClosed = nil
        case "rawFalse": sample.reading.rawExternalConnected = false
        case "rawUnknown": sample.reading.rawExternalConnected = nil
        case "nativeOwner": sample.reading.nativeSessionActive = true
        case "batterySource": sample.reading.source = .battery
        case "unknownSource": sample.reading.source = .unknown
        case "stale": sample.age = .seconds(3)
        default: sample.age = .milliseconds(-1)
        }
        let reading = sample
        var transaction = try fixture.transaction()
        let report = try transaction.pulse { _ in reading }
        #expect(report.outcome == .unavailable)
        #expect(report.isValid)
        #expect(fixture.storage.withLock { $0.writes.isEmpty })
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test(arguments: ["ignored", "throwAfterEffect", "missingDuring", "expiredSetter", "expiredSave", "unknownAfter"])
    func partialFailureOrMissingTelemetryAlwaysRestores(condition: String) throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock {
            if condition == "ignored" { $0.effects[1] = .ignore }
            if condition == "throwAfterEffect" { $0.effects[1] = .failAfter }
            if condition == "expiredSetter" { $0.advanceOnIsolate = .seconds(4) }
            if condition == "expiredSave" { $0.advanceOnSave = .seconds(4) }
        }
        var transaction = try fixture.transaction()
        let report = try transaction.pulse { _ in
            let isIsolated = fixture.storage.withLock { $0.byte == 8 }
            let wasAttempted = fixture.storage.withLock { $0.writes.isEmpty == false }
            if condition == "missingDuring" && isIsolated { throw AdapterTransaction.Failure.unavailable }
            if condition == "unknownAfter" && wasAttempted && !isIsolated { throw AdapterTransaction.Failure.unavailable }
            return Self.sample(fixture)
        }
        #expect(report.outcome == .failedRestored)
        #expect(report.isValid)
        #expect(report.restoredByte == 0)
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
        #expect(transaction.state == .idle)
        if condition == "expiredSave" { #expect(fixture.storage.withLock { $0.writes.isEmpty }) }
    }

    @Test func recoveryIgnoresObservationLossAndRemainsRestartable() throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.effects[1] = .loseReadAccess }
        var transaction = try fixture.transaction()
        let report = try transaction.pulse { _ in Self.sample(fixture) }
        #expect(report.outcome == .restorationRequired)
        #expect(report.isValid)
        #expect(report.restoredByte == nil)
        #expect(fixture.storage.withLock { $0.journal != nil })
        #expect(throws: AdapterTransaction.Failure.restorationRequired) {
            try transaction.pulse { _ in Self.sample(fixture) }
        }
        fixture.storage.withLock { $0.failReads = false; $0.failEnvironment = true }
        var restarted = try fixture.transaction()
        try restarted.restore()
        #expect(fixture.storage.withLock { $0.byte } == 0)
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func cancellationStillRestoresWithoutPostRead() async throws {
        let fixture = AdapterVerificationFixture()
        fixture.storage.withLock { $0.cancelOnIsolate = true }
        let result = try await Task {
            var transaction = try fixture.transaction()
            return try transaction.pulse { _ in Self.sample(fixture) }
        }.value
        #expect(result.outcome == .failedRestored)
        #expect(result.after == nil)
        #expect(fixture.storage.withLock { $0.writes } == [true, false])
        #expect(fixture.storage.withLock { $0.journal } == nil)
    }

    @Test func changedNativeSettingIsPreservedAndPreventsByteRoundTripSuccess() throws {
        let fixture = AdapterVerificationFixture()
        var transaction = try fixture.transaction()
        let report = try transaction.pulse { _ in
            fixture.storage.withLock { if $0.byte == 8 { $0.environment.nativeLimit.configuredLimit = 90 } }
            return Self.sample(fixture)
        }
        #expect(report.outcome == .failedRestored)
        #expect(report.isValid)
        #expect(report.before?.nativeLimit?.configuredLimit == 85)
        #expect(report.after?.nativeLimit?.configuredLimit == 90)
        #expect(fixture.storage.withLock { $0.environment.nativeLimit.configuredLimit } == 90)
        #expect(fixture.storage.withLock { $0.byte } == 0)
    }
}
