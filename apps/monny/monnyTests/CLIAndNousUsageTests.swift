import Foundation
import Darwin
import Testing
@testable import monny

struct CLIAndNousUsageTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func ampTierKeepsAgentOrbAndCashSeparate() throws {
        let text = """
        Signed in as ignored@example.test
        Amp Test Tier: agent usage $15 of $20 remaining (75%), orb usage 240h of 300h a1.small orb hours remaining (80%) - period 2027-01-01 to 2027-02-01, resets upon renewal in 10 days
        Individual credits: $9.25 remaining
        Workspace ignored: $123 remaining
        """
        let value = try AmpUsage.usage(text, now: now)
        #expect(value.plan == "Test")
        #expect(value.windows.map(\.ampQuota) == [.agent, .orb])
        #expect(value.windows[0].left == 0.75)
        #expect(value.windows[1].left == 0.8)
        #expect(value.windows[0].dollarsLimit == 20)
        #expect(value.windows[1].dollarsLimit == nil)
        #expect(value.windows[0].duration == 31 * 86_400)
        #expect(value.windows[0].resetsAt == AICommandText.isoDay("2027-02-01"))
        #expect(value.windows[0].isPlanLimit)
        #expect(value.windows[1].isPlanLimit == false)
        #expect(value.windows[0].id != value.windows[1].id)
        #expect(value.balanceUSD == Decimal(string: "9.25"))
        #expect(value.credits == nil)
    }

    @Test func ampFreeAndLegacyDoNotInventDeadlines() throws {
        let value = try AmpUsage.usage("Amp Free: $4/$10 remaining (replenishes +$0.5/hour)\nIndividual credits: $0 remaining", now: now)
        #expect(value.windows.first?.ampQuota == .free)
        #expect(value.windows.first?.left == 0.4)
        #expect(value.windows.first?.resetsAt == nil)
        #expect(value.windows.first?.timeLeft(at: now) == nil)
        #expect(value.balanceUSD == 0)
        let percent = try AmpUsage.usage("\u{1b}[32m**Amp Free:** 35% remaining today (resets daily)\u{1b}[0m", now: now)
        #expect(abs(try #require(percent.windows.first).left - 0.35) < 0.00001)
        #expect(percent.windows.first?.resetsAt == nil)
        let old = try AmpUsage.usage("Subscription Example: 40% other usage and 60% orb usage remaining - resets upon renewal in 2 months", now: now)
        #expect(old.windows.map(\.ampQuota) == [.other, .orb])
        #expect(old.windows.allSatisfy { $0.resetsAt == nil && $0.duration == 0 })
    }

    @Test func ampMissingOrbAndDatesKeepReportedAgentUsage() throws {
        let value = try AmpUsage.usage("Amp Test Tier: agent usage $0 of $25 remaining, orb usage unavailable - period 2027-02-30 to 2027-03-30, resets upon renewal in 1 month", now: now)
        #expect(value.windows.count == 1)
        #expect(value.windows[0].isExhausted)
        #expect(value.windows[0].resetsAt == nil)
        let cash = try AmpUsage.usage("Individual credits: $15 remaining", now: now)
        #expect(cash.windows.isEmpty)
        #expect(cash.balanceUSD == 15)
    }

    @Test(arguments: ["Amp Free: -1% remaining", "Amp Free: 101% remaining", "Amp Free: $0/$0 remaining", "unrecognized report", "Individual credits: $NaN remaining"])
    func invalidAmpDoesNotBecomeZero(text: String) {
        #expect(throws: (any Error).self) { try AmpUsage.usage(text, now: now) }
    }

    @Test func augmentCurrentAndLegacyUseTheirReportedDenominator() throws {
        let current = try AugmentUsage.usage("│ 1,500 credits remaining        Test Plan │\n│ 2,000 credits / month │\n7 days remaining in this billing cycle (ends 2/1/2027)", now: now)
        #expect(current.windows.first?.left == 0.75)
        #expect(current.windows.first?.resetsAt == AICommandText.isoDay("2027-02-01"))
        #expect(current.windows.first?.duration == 0)
        let legacy = try AugmentUsage.usage("Test Plan 500 credits / month\n100 remaining · 900 / 1,000 credits used\nends 2/30/2027", now: now)
        #expect(abs(try #require(legacy.windows.first).left - 0.1) < 0.00001)
        #expect(legacy.windows.first?.resetsAt == nil)
    }

    @Test(arguments: ["5 credits remaining", "1,000 credits / month", "-1 credits remaining\n100 credits / month", "1e99 credits remaining\n100 credits / month", "1,,000 credits remaining\n2000 credits / month", "0 credits remaining\n0 credits / month"])
    func invalidAugmentDoesNotBorrowMissingValues(text: String) {
        #expect(throws: (any Error).self) { try AugmentUsage.usage(text, now: now) }
    }

    @Test func nousMonthlyAndTopUpAmountsStaySeparate() throws {
        let json = #"{"subscription":{"plan":"Pro","monthly_credits":"100","credits_remaining":25,"current_period_end":"2027-02-01T00:00:00Z","rollover_credits":5},"purchased_credits_remaining":"12.5","paid_service_access":{"total_usable_credits":37.5}}"#
        let value = try NousUsage.usage(Data(json.utf8), now: now)
        #expect(value.plan == "Pro")
        #expect(value.windows.count == 1)
        #expect(value.windows[0].left == 0.25)
        #expect(value.windows[0].timeLeft(at: now) == nil)
        #expect(value.windows[0].resetsAt == AICommandText.isoDay("2027-02-01"))
        #expect(value.balanceUSD == Decimal(string: "37.5"))
        #expect(value.topUpUSD == Decimal(string: "12.5"))
        #expect(value.credits == nil)
        let free = try NousUsage.usage(Data(#"{"subscription":{"monthly_credits":0},"purchased_credits_remaining":0}"#.utf8), now: now)
        #expect(free.windows.isEmpty)
        #expect(free.topUpUSD == 0)
        let fallback = try NousUsage.usage(Data(#"{"subscription":{"monthly_credits":100,"credits_remaining":null},"purchased_credits_remaining":null,"paid_service_access":{"subscription_credits_remaining":30,"purchased_credits_remaining":5}}"#.utf8), now: now)
        #expect(abs(try #require(fallback.windows.first).left - 0.3) < 0.00001)
        #expect(fallback.topUpUSD == 5)
    }

    @Test(arguments: [#"{}"#, #"{"subscription":{"monthly_credits":100}}"#, #"{"subscription":{"monthly_credits":true,"credits_remaining":25}}"#,
                     #"{"subscription":{"monthly_credits":100,"credits_remaining":"NaN"}}"#, #"{"purchased_credits_remaining":-1}"#,
                     #"{"purchased_credits_remaining":"1e200"}"#, #"{"error":"failure","purchased_credits_remaining":25}"#])
    func unknownNousRemainsUnavailable(json: String) {
        #expect(throws: (any Error).self) { try NousUsage.usage(Data(json.utf8), now: now) }
    }

    @Test func hermesCredentialSelectionAndExpiry() throws {
        let credential = #"{"providers":{"nous":{"access_token":"selected","expires_at":"2027-02-01T00:00:00Z","portal_base_url":"https://portal.nousresearch.com"}},"access_token":"ignored"}"#
        #expect(try NousUsage.credential(Data(credential.utf8), now: now) == "selected")
        #expect(try NousUsage.credential(Data(#"{"credential_pool":{"nous":[{"access_token":"only"}]}}"#.utf8), now: now) == "only")
        #expect(try NousUsage.credential(Data(#"{"access_token":"shared"}"#.utf8), now: now) == "shared")
        for json in [#"{"providers":{"nous":{}},"access_token":"ignored"}"#,
                     #"{"credential_pool":{"nous":[{"access_token":"one"},{"access_token":"two"}]}}"#,
                     #"{"access_token":"wrong-host","portal_base_url":"https://example.com"}"#,
                     #"{"access_token":"no","expires_at":"not-a-date"}"#,
                     #"{"agent_key":"inference-only","refresh_token":"never-used"}"#] {
            #expect(throws: (any Error).self) { try NousUsage.credential(Data(json.utf8), now: now) }
        }
        #expect(throws: AIUsageProblem.expired) {
            try NousUsage.credential(Data(#"{"access_token":"old","expires_at":"2000-01-01T00:00:00Z"}"#.utf8), now: now)
        }
    }

    @Test @MainActor func historyAlertsAndBackwardCache() throws {
        let amp = try AmpUsage.usage("Amp Free: 5% remaining\nAmp Test Tier: agent usage $1 of $20 remaining, orb usage 0h of 100h a1.small orb hours remaining", now: now)
        let monitor = AIUsageMonitor(installed: [.amp], states: [.amp: .init(usage: amp)])
        let values = monitor.historyValues(at: now)
        #expect(abs(try #require(values[.ampFree]) - 0.05) < 0.00001)
        #expect(abs(try #require(values[.ampMonthly]) - 0.05) < 0.00001)
        #expect(values.count == 2)
        var episodes = AILowWindows()
        #expect(episodes.update(.amp, usage: amp, now: now).count == 3)
        #expect(episodes.update(.amp, usage: amp, now: now.addingTimeInterval(120)).isEmpty)
        #expect(monitor.historyValues(at: now.addingTimeInterval(901)).isEmpty)
        let restored = try JSONDecoder().decode(AIUsage.self, from: JSONEncoder().encode(amp))
        #expect(restored == amp)
        let old = try JSONDecoder().decode(AIUsage.self, from: Data(#"{"windows":[{"kind":"monthly","used":0.5,"duration":0}],"date":0}"#.utf8))
        #expect(old.windows[0].ampQuota == nil)
        #expect(old.balanceUSD == nil)
    }

    @Test func commandEnvironmentExcludesKeysAndProfileOverrides() {
        let environment = AIUsageCommand.environment(for: URL(filePath: "/opt/homebrew/bin/amp"))
        let allowed: Set<String> = ["HOME", "USER", "LOGNAME", "TMPDIR", "HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "NO_PROXY", "https_proxy", "http_proxy", "all_proxy", "no_proxy", "PATH", "LANG", "LC_ALL", "TZ", "TERM", "NO_COLOR", "CI"]
        #expect(Set(environment.keys).isSubset(of: allowed))
        #expect(environment["LANG"] == "en_US.UTF-8")
        #expect(environment["TZ"] == "UTC")
        #expect(environment["NO_COLOR"] == "1")
    }

    @Test func commandDrainsBothPipesAndBoundsOutput() async throws {
        let executable = URL(filePath: "/bin/sh")
        // These are test-owned fixture processes, never provider commands or user processes.
        let result = try #require(await AIUsageCommand.run(executable, arguments: ["-c", "printf report; printf warning >&2; exit 7"]))
        #expect(result.stdout == "report")
        #expect(result.stderr == "warning")
        #expect(result.status == 7)
        let large = await AIUsageCommand.run(URL(filePath: "/usr/bin/yes"), arguments: [], timeout: .seconds(2))
        #expect(large == nil)
        #expect(await AIUsageCommand.run(URL(filePath: "/does/not/exist"), arguments: []) == nil)
    }

    @Test func commandTimeoutAndCancellationEndOnlyTheirChild() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "pid")
        let executable = URL(filePath: "/bin/sh")
        let args = ["-c", "echo $$ > \"$1\"; exec /bin/sleep 30", "fixture", file.path]
        let result = await AIUsageCommand.run(executable, arguments: args, timeout: .milliseconds(200))
        #expect(result == nil)
        let pid = try #require(Int32(String(contentsOf: file, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)))
        for _ in 0..<40 where kill(pid, 0) == 0 { try await Task.sleep(for: .milliseconds(25)) }
        #expect(kill(pid, 0) == -1)
        try FileManager.default.removeItem(at: file)
        let task = Task { await AIUsageCommand.run(executable, arguments: args) }
        for _ in 0..<40 where !FileManager.default.fileExists(atPath: file.path) { try await Task.sleep(for: .milliseconds(25)) }
        let cancelledPID = try #require(Int32(String(contentsOf: file, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)))
        task.cancel()
        #expect(await task.value == nil)
        for _ in 0..<40 where kill(cancelledPID, 0) == 0 { try await Task.sleep(for: .milliseconds(25)) }
        #expect(kill(cancelledPID, 0) == -1)
    }
}
