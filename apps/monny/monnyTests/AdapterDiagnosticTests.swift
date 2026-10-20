import Foundation
import Synchronization
import Testing
@testable import monny

private actor SuspendedAdapterProbe {
    var calls = 0
    private var entered: CheckedContinuation<Void, Never>?
    private var pending: CheckedContinuation<Void, Never>?

    func read() async -> AdapterCapabilityProbe {
        calls += 1
        entered?.resume()
        entered = nil
        await withCheckedContinuation { pending = $0 }
        return AdapterCapabilityProbe.inspect { _ in .unavailable(.smc(0x84)) }
    }

    func waitUntilReading() async {
        if calls == 0 { await withCheckedContinuation { entered = $0 } }
    }

    func finish() { pending?.resume(); pending = nil }
}

struct AdapterDiagnosticTests {
    @Test func allowlistPreservesPartialFailuresWithoutInferringWriteSupport() throws {
        var requested: [String] = []
        let report = AdapterCapabilityProbe.inspect { key in
            requested.append(key)
            if key == "CHIE" {
                return .readable(metadata: .init(type: "hex_", size: 1, attributes: 255),
                                 value: .init(type: "hex_", bytes: [0]))
            }
            return .unavailable(.smc(0x84))
        }
        #expect(requested == ["CHIE", "CH0I", "CH0J"])
        #expect(report.isValid)
        #expect(report.controlSupport == .unverified)
        #expect(report.entries[1].inspection == .unavailable(.smc(0x84)))
        var status = HelperStatus.current
        status.adapterDiagnostics = report
        let encoded = try JSONEncoder().encode(status)
        #expect(encoded.count < 4_096)
        #expect(try HelperStatus.decode(encoded) == status)
        #expect(status.chargeDiagnostics == nil)
        #expect(ChargeCapabilityProbe.candidateKeys == ["CH0B", "CH0C", "CHTE", "bfF0", "bfD0", "bfE0"])
    }

    @Test func malformedAdapterReportsAndMissingAdvertisementAreRejected() throws {
        let good = AdapterCapabilityProbe.inspect { _ in
            .readable(metadata: .init(type: "hex_", size: 1, attributes: 0),
                      value: .init(type: "hex_", bytes: [0]))
        }
        var reports = [good, good, good, good]
        reports[0].entries.reverse()
        reports[1].entries.append(good.entries[0])
        reports[2].entries[0].inspection = .readable(metadata: .init(type: "hex_", size: 1, attributes: 0),
                                                   value: .init(type: "hex_", bytes: []))
        reports[3].entries[0].inspection = .readable(metadata: .init(type: "hex_", size: 0, attributes: 0),
                                                   value: .init(type: "hex_", bytes: []))
        for report in reports {
            var status = HelperStatus.current
            status.adapterDiagnostics = report
            #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        }
        var status = HelperStatus.current
        status.adapterDiagnostics = good
        status.adapterDiagnosticsAvailable = nil
        #expect(throws: HelperConnectionError.invalidReply) { try status.validated() }
        status.adapterDiagnosticsAvailable = true
        let encoded = try JSONEncoder().encode(status)
        let invented = Data(String(decoding: encoded, as: UTF8.self)
            .replacingOccurrences(of: "unverified", with: "supported").utf8)
        #expect(throws: HelperConnectionError.invalidReply) { try HelperStatus.decode(invented) }
    }

    @Test func explicitProbeCoalescesWithoutWritesOrImplicitStatusWork() async throws {
        let fixture = SuspendedAdapterProbe()
        let writes = Mutex(0)
        let executor = ChargeCommandExecutor(operations: .init(
            setAdapterEnabled: { _ in writes.withLock { $0 += 1 } },
            setChargingAllowed: { _ in writes.withLock { $0 += 1 } }),
            diagnosticRead: { ChargeCapabilityProbe.inspect { _ in .unavailable(.connectionUnavailable) } },
            adapterDiagnosticRead: { await fixture.read() })
        try await executor.start()
        let startupWrites = writes.withLock { $0 }
        let first = try await executor.beginSession()
        let second = try await executor.beginSession()
        #expect(try await executor.status(for: first).adapterDiagnostics == nil)
        #expect(try await executor.diagnose(for: first).adapterDiagnostics == nil)
        #expect(await fixture.calls == 0)
        async let left = executor.diagnoseAdapter(for: first)
        async let right = executor.diagnoseAdapter(for: second)
        await fixture.waitUntilReading()
        await fixture.finish()
        let (a, b) = try await (left, right)
        #expect(a == b)
        #expect(a.adapterDiagnostics?.isValid == true)
        #expect(a.adapterDiagnostics?.controlSupport == .unverified)
        #expect(a.controlState == .notControlling)
        #expect(a.chargeDiagnostics == nil)
        #expect(try await executor.diagnoseAdapter(for: first) == a)
        #expect(await fixture.calls == 1)
        #expect(writes.withLock { $0 } == startupWrites)
    }

    @Test(arguments: ["disconnect", "sleep", "removal", "shutdown"])
    func suspendedAdapterReadRechecksSessionAndLifecycle(event: String) async throws {
        let fixture = SuspendedAdapterProbe()
        let executor = ChargeCommandExecutor(adapterDiagnosticRead: { await fixture.read() })
        try await executor.start()
        let token = try await executor.beginSession()
        let request = Task { try await executor.diagnoseAdapter(for: token) }
        await fixture.waitUntilReading()
        switch event {
        case "disconnect": try await executor.disconnect(owner: token)
        case "sleep": try await executor.willSleep()
        case "shutdown": try await executor.shutdown()
        default: _ = try await executor.status(for: token, removing: true)
        }
        await fixture.finish()
        await #expect(throws: event == "removal" ? ChargeCommandExecutor.Failure.notReady : .invalidSession) {
            try await request.value
        }
    }

    @Test(arguments: [Optional<Bool>.none, false])
    func oldHelperCannotReceiveAdapterSelector(advertised: Bool?) async {
        var old = HelperStatus.current
        old.adapterDiagnosticsAvailable = advertised
        let handshake = old
        await #expect(throws: BatteryDiagnosticCommand.Failure.helperUpdateRequired) {
            try await BatteryDiagnosticCommand.collectAdapter(requirement: "unused", status: { _ in handshake },
                diagnostics: { _ in Issue.record("Old helper must not receive adapter selector"); return .current })
        }
    }

    @Test func advertisedSelectorMustReturnAdapterPayload() async {
        await #expect(throws: HelperConnectionError.invalidReply) {
            try await BatteryDiagnosticCommand.collectAdapter(requirement: "unused", status: { _ in .current },
                                                              diagnostics: { _ in .current })
        }
    }
}
