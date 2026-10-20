import Foundation
import Testing
@testable import monny

private actor NativeProbeFixture {
    var calls = 0
    private var pending: CheckedContinuation<Void, Never>?
    private var entered: CheckedContinuation<Void, Never>?

    func read() async -> NativeChargeLimit {
        calls += 1
        entered?.resume()
        entered = nil
        await withCheckedContinuation { pending = $0 }
        return .available(.init(availableLimits: [80, 85, 90, 95, 100], configuredLimit: 85, enabled: true))
    }
    func waitUntilReading() async {
        if calls == 0 { await withCheckedContinuation { entered = $0 } }
    }
    func finish() { pending?.resume(); pending = nil }
}

struct NativeChargeLimitTests {
    @Test func reportIsOptionalForLegacyStatusAndAlwaysReadOnly() throws {
        let legacy = Data(#"{"protocolVersion":1,"helperVersion":"1.0","controlState":"notControlling","chargingSupport":"notImplemented","chargeDiagnosticsAvailable":true}"#.utf8)
        #expect(try HelperStatus.decode(legacy).nativeChargeLimit == nil)
        var status = HelperStatus.current
        status.nativeChargeLimit = .available(.init(availableLimits: [80, 85, 90, 95, 100], configuredLimit: 85, enabled: false))
        #expect(try HelperStatus.decode(JSONEncoder().encode(status)) == status)
        #expect(status.chargingSupport == .notImplemented)
        status.nativeLimitDiagnosticsAvailable = nil
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
    }

    @Test(arguments: [[Int](), [79, 80, 100], [80, 80, 100], [100, 80], [80, 101], Array(0...100)])
    func malformedNativeRangesNeverBecomeCapability(limits: [Int]) throws {
        var status = HelperStatus.current
        status.nativeChargeLimit = .available(.init(availableLimits: limits, configuredLimit: 80, enabled: true))
        #expect(throws: HelperConnectionError.invalidReply) { try HelperStatus.decode(JSONEncoder().encode(status)) }
    }

    @Test func configuredLimitMustBeAdvertisedAndFailuresCarryNoInventedSettings() throws {
        var status = HelperStatus.current
        status.nativeChargeLimit = .available(.init(availableLimits: [80, 100], configuredLimit: 90, enabled: true))
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.nativeChargeLimit = .unavailable(.queryFailed)
        #expect(try HelperStatus.decode(JSONEncoder().encode(status)) == status)
    }

    @Test func nativeReadIsExplicitCoalescedAndDoesNotEnableControl() async throws {
        let fixture = NativeProbeFixture()
        let executor = ChargeCommandExecutor(
            diagnosticRead: { .inspect { _ in .unavailable(.smc(132)) } },
            nativeDiagnosticRead: { await fixture.read() })
        try await executor.start()
        let first = try await executor.beginSession()
        let second = try await executor.beginSession()
        _ = try await executor.status(for: first)
        #expect(await fixture.calls == 0)
        async let a = executor.diagnose(for: first)
        async let b = executor.diagnose(for: second)
        await fixture.waitUntilReading()
        await fixture.finish()
        let (left, right) = try await (a, b)
        #expect(left == right)
        #expect(left.nativeChargeLimit?.isValid == true)
        #expect(left.chargingSupport == .notImplemented)
        #expect(try await executor.diagnose(for: first) == left)
        #expect(await fixture.calls == 1)
    }

    @Test(arguments: ["disconnect", "sleep", "removal"])
    func nativeReplyCannotOutliveSessionOrLifecycle(event: String) async throws {
        let fixture = NativeProbeFixture()
        let executor = ChargeCommandExecutor(
            diagnosticRead: { .inspect { _ in .unavailable(.smc(132)) } },
            nativeDiagnosticRead: { await fixture.read() })
        try await executor.start()
        let token = try await executor.beginSession()
        let request = Task { try await executor.diagnose(for: token) }
        await fixture.waitUntilReading()
        switch event {
        case "disconnect": try await executor.disconnect(owner: token)
        case "sleep": try await executor.willSleep()
        default: _ = try await executor.status(for: token, removing: true)
        }
        await fixture.finish()
        await #expect(throws: event == "removal" ? ChargeCommandExecutor.Failure.notReady : .invalidSession) {
            try await request.value
        }
    }

    @Test func smcOnlyHelperStopsBeforeNewDiagnosticIsAssumed() async {
        var old = HelperStatus.current
        old.nativeLimitDiagnosticsAvailable = nil
        let legacy = old
        await #expect(throws: BatteryDiagnosticCommand.Failure.helperUpdateRequired) {
            try await BatteryDiagnosticCommand.collect(requirement: "unused", status: { _ in legacy }, diagnostics: { _ in
                Issue.record("Native report requires the updated helper")
                return .current
            })
        }
    }
}
