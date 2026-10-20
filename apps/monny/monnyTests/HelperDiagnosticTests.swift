import Foundation
import Testing
@testable import monny

private actor SuspendedProbe {
    var calls = 0
    private var entered: CheckedContinuation<Void, Never>?
    private var pending: CheckedContinuation<Void, Never>?

    func read() async -> ChargeCapabilityProbe {
        calls += 1
        entered?.resume()
        entered = nil
        await withCheckedContinuation { pending = $0 }
        return ChargeCapabilityProbe.inspect { _ in .unavailable(.smc(0x84)) }
    }

    func waitUntilReading() async {
        if calls == 0 { await withCheckedContinuation { entered = $0 } }
    }

    func finish() { pending?.resume(); pending = nil }
}

struct HelperDiagnosticTests {
    @Test func statusDoesNotProbeAndConcurrentDiagnosticsShareOneSnapshot() async throws {
        let fixture = SuspendedProbe()
        let executor = ChargeCommandExecutor(diagnosticRead: { await fixture.read() })
        try await executor.start()
        let first = try await executor.beginSession()
        let second = try await executor.beginSession()
        #expect(try await executor.status(for: first).chargeDiagnostics == nil)
        #expect(await fixture.calls == 0)
        async let left = executor.diagnose(for: first)
        async let right = executor.diagnose(for: second)
        await fixture.waitUntilReading()
        await fixture.finish()
        let (a, b) = try await (left, right)
        #expect(a == b)
        #expect(a.chargeDiagnostics?.isValid == true)
        #expect(a.chargingSupport == .notImplemented)
        #expect(a.chargeDiagnostics?.controlSupport == .unverified)
        #expect(try await executor.diagnose(for: first) == a)
        #expect(await fixture.calls == 1)
    }

    @Test(arguments: ["disconnect", "sleep", "removal"])
    func suspendedDiagnosticCannotOutliveSessionOrLifecycle(event: String) async throws {
        let fixture = SuspendedProbe()
        let executor = ChargeCommandExecutor(diagnosticRead: { await fixture.read() })
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

    @Test func legacyHandshakeStopsBeforeSendingANewSelector() async throws {
        let data = Data(#"{"protocolVersion":1,"helperVersion":"1.0","controlState":"notControlling","chargingSupport":"notImplemented"}"#.utf8)
        let legacy = try HelperStatus.decode(data)
        #expect(legacy.chargeDiagnosticsAvailable == nil)
        #expect(legacy.chargeDiagnostics == nil)
        await #expect(throws: BatteryDiagnosticCommand.Failure.helperUpdateRequired) {
            try await BatteryDiagnosticCommand.collect(requirement: "unused", status: { _ in legacy }, diagnostics: { _ in
                Issue.record("Legacy helper must never receive a diagnostic selector")
                return .current
            })
        }
    }

    @Test func wireReportRejectsWrongKeysSizesAndInventedControlSupport() throws {
        let report = ChargeCapabilityProbe.inspect { _ in
            .readable(metadata: SMCKeyMetadata(type: "hex_", size: 32, attributes: 255),
                      value: SMCValue(type: "hex_", bytes: Array(repeating: 255, count: 32)))
        }
        var status = HelperStatus.current
        status.chargeDiagnostics = report
        let encoded = try JSONEncoder().encode(status)
        #expect(encoded.count < 4_096)
        #expect(try HelperStatus.decode(encoded) == status)
        status.chargeDiagnostics?.entries[0].key = "PATH"
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.chargeDiagnostics = report
        status.chargeDiagnostics?.entries[0].inspection = .readable(
            metadata: SMCKeyMetadata(type: "ui8 ", size: 1, attributes: 255), value: SMCValue(type: "ui8 ", bytes: []))
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        let invented = Data(String(decoding: encoded, as: UTF8.self).replacingOccurrences(of: "unverified", with: "supported").utf8)
        #expect(throws: HelperConnectionError.invalidReply) { try HelperStatus.decode(invented) }
    }
}
