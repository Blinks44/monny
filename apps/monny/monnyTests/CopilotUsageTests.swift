import Foundation
import Testing
@testable import monny

struct CopilotUsageTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func usage(_ json: String) throws -> AIUsage {
        try JSONDecoder().decode(CopilotUsageResponse.self, from: Data(json.utf8)).usage(now: now)
    }

    @Test func separateMonthlyQuotasAndNoInventedPace() throws {
        let reading = try usage(#"{"copilot_plan":"pro","quota_reset_date":"2027-02-01","quota_snapshots":{"premium_interactions":{"percent_remaining":72,"entitlement":300,"remaining":216},"chat":{"unlimited":true},"completions":{"unlimited":true}}}"#)
        let window = try #require(reading.windows.first)
        #expect(reading.plan == "pro")
        #expect(window.copilotQuota == .premium)
        #expect(abs(window.left - 0.72) < 0.00001)
        #expect(window.resetsAt == CopilotUsageResponse.resetDate("2027-02-01T00:00:00Z"))
        #expect(window.timeLeft(at: now) == nil)
        #expect(window.runsOut(at: now) == nil)
        #expect(reading.unlimitedCopilotQuotas == [.chat, .completions])
    }

    @Test func numericStringsAndNegativeRemainingPreserveExhaustion() throws {
        let reading = try usage(#"{"quota_snapshots":{"premium_interactions":{"percent_remaining":"-4","entitlement":"300","remaining":"-12"},"chat":{"entitlement":"2000","remaining":"1500"}}}"#)
        #expect(reading.windows.count == 2)
        #expect(reading.windows[0].isExhausted)
        #expect(reading.windows[1].left == 0.75)
        #expect(reading.windows[0].id != reading.windows[1].id)
        #expect(reading.windows.allSatisfy { $0.resetsAt == nil && $0.timeLeft(at: now) == nil })
    }

    @Test func placeholdersAndCreditsAreNotRemainingQuota() throws {
        let reading = try usage(#"{"copilot_plan":"business","token_based_billing":true,"quota_snapshots":{"premium_interactions":{"entitlement":0,"remaining":0,"percent_remaining":100,"credits_used":"12.5"},"chat":{"credits_used":12.5},"completions":{"credits_used":12.5}}}"#)
        #expect(reading.windows.isEmpty)
        #expect(reading.creditsUsed == 12.5)
        #expect(reading.credits == nil)
        #expect(reading.unlimitedCopilotQuotas?.isEmpty == true)
        let unmetered = try usage(#"{"token_based_billing":true}"#)
        #expect(unmetered.windows.isEmpty)
    }

    @Test func unknownMissingMalformedAndNonfiniteQuotasFailClosed() {
        for json in [#"{}"#, #"{"quota_snapshots":{"new_product":{"percent_remaining":75}}}"#,
                     #"{"quota_snapshots":{"premium_interactions":{"entitlement":0,"remaining":0,"percent_remaining":100}}}"#,
                     #"{"quota_snapshots":{"premium_interactions":{"percent_remaining":"NaN","credits_used":"Infinity"}}}"#] {
            #expect(throws: AIUsageProblem.self) { try usage(json) }
        }
    }

    @Test func oneMalformedCategoryDoesNotHideOthers() throws {
        let reading = try usage(#"{"quota_snapshots":{"premium_interactions":"unknown","chat":{"percent_remaining":40},"completions":{"percent_remaining":10}}}"#)
        #expect(reading.windows.map(\.copilotQuota) == [.chat, .completions])
        #expect(abs(reading.windows[0].left - 0.4) < 0.00001)
        #expect(abs(reading.windows[1].left - 0.1) < 0.00001)
    }

    @Test func legacyChatAndCompletionsKeepTheirIdentity() throws {
        let reading = try usage(#"{"monthly_quotas":{"chat":50,"completions":2000},"limited_user_quotas":{"chat":25,"completions":1800},"quota_snapshots":{"chat":{"unlimited":true}}}"#)
        #expect(reading.windows.map(\.copilotQuota) == [.chat, .completions])
        #expect(reading.windows.map(\.left) == [0.5, 0.9])
        #expect(reading.unlimitedCopilotQuotas?.isEmpty == true)
    }

    @Test func resetParsing() {
        #expect(CopilotUsageResponse.resetDate(" 2027-02-01 ") == CopilotUsageResponse.resetDate("2027-02-01T00:00:00Z"))
        #expect(CopilotUsageResponse.resetDate("unknown") == nil)
        #expect(CopilotUsageResponse.resetDate("") == nil)
    }

    @Test @MainActor func historyAndAlertEpisodesKeepQuotasSeparate() throws {
        let reading = try usage(#"{"quota_snapshots":{"premium_interactions":{"percent_remaining":5},"chat":{"percent_remaining":2},"completions":{"percent_remaining":0}}}"#)
        let monitor = AIUsageMonitor(installed: [.copilot], states: [.copilot: .init(usage: reading)])
        #expect(abs(try #require(monitor.historyValues(at: now)[.copilotPremium]) - 0.05) < 0.00001)
        #expect(monitor.historyValues(at: now.addingTimeInterval(901)).isEmpty)
        var episodes = AILowWindows()
        #expect(episodes.update(.copilot, usage: reading, now: now).count == 3)
        #expect(episodes.update(.copilot, usage: reading, now: now.addingTimeInterval(120)).isEmpty)
        let chatOnly = try usage(#"{"quota_snapshots":{"chat":{"percent_remaining":25}}}"#)
        let chatMonitor = AIUsageMonitor(installed: [.copilot], states: [.copilot: .init(usage: chatOnly)])
        #expect(chatMonitor.historyValues(at: now).isEmpty)
    }

    @Test func environmentUsesSavedGithubAccount() async {
        let environment = await AIUsageReader.githubEnvironment
        for key in ["GH_TOKEN", "GITHUB_TOKEN", "GH_HOST", "GH_CONFIG_DIR", "XDG_CONFIG_HOME"] {
            #expect(environment[key] == nil)
        }
        #expect(environment["GH_PROMPT_DISABLED"] == "1")
    }

    @Test func zeroCreditsOnAMeteredPlanDoNotAddAnEmptyCounter() throws {
        let reading = try usage(#"{"quota_snapshots":{"premium_interactions":{"percent_remaining":75,"credits_used":0}}}"#)
        #expect(reading.windows.count == 1)
        #expect(reading.creditsUsed == nil)
    }

    @Test func oldCachedReadingsRemainDecodable() throws {
        let reading = try JSONDecoder().decode(AIUsage.self, from: Data(#"{"windows":[{"kind":"weekly","used":0.5,"duration":604800}],"date":0}"#.utf8))
        #expect(reading.windows.first?.copilotQuota == nil)
        #expect(reading.windows.first?.id == "weekly.")
        #expect(reading.creditsUsed == nil)
        #expect(reading.unlimitedCopilotQuotas == nil)
    }

    @Test func refusesTokenBearingRedirects() async throws {
        let source = try #require(URL(string: "https://api.github.com/copilot_internal/user"))
        let target = try #require(URL(string: "https://example.com/redirect"))
        let response = try #require(HTTPURLResponse(url: source, statusCode: 302, httpVersion: nil, headerFields: nil))
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: source)
        let redirected: URLRequest? = await withCheckedContinuation { continuation in
            CopilotRedirectPolicy().urlSession(session, task: task, willPerformHTTPRedirection: response,
                                               newRequest: URLRequest(url: target)) { request in
                continuation.resume(returning: request)
            }
        }
        #expect(redirected == nil)
    }

}
