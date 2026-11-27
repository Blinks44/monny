import Foundation
import SQLite3
import Synchronization
import Testing

@testable import monny

/// Decoding the services' answers and the pace math behind the bars, chips and alerts.
struct AIUsageTests {
    private let now = Date(timeIntervalSince1970: 1_792_660_000)

    @MainActor
    @Test func aiCardOrderKeepsExistingDefaultsAndAddsNewTools() {
        #expect(AIToolOrder(saved: []).tools == AITool.allCases)

        let order = AIToolOrder(saved: ["antigravity", "copilot", "retired-tool", "antigravity"])
        #expect(Array(order.tools.prefix(3)) == [.antigravity, .copilot, .claude])
        #expect(order.tools.count == AITool.allCases.count)
    }

    @MainActor
    @Test func aiCardOrderMovesToTheTargetSlotAndSurvivesReload() {
        let detected: Set<AITool> = [.codex, .copilot, .antigravity]
        var order = AIToolOrder(saved: [])
        order.move(.antigravity, to: .copilot)
        #expect(order.tools.filter { detected.contains($0) } == [.codex, .antigravity, .copilot])
        order.move(.antigravity, to: .codex)
        #expect(order.tools.filter { detected.contains($0) } == [.antigravity, .codex, .copilot])
        order.move(.antigravity, to: .copilot)
        order.move(.codex, to: .codex)

        let reloaded = AIToolOrder(saved: order.tools.map(\.rawValue))
        #expect(reloaded.tools == order.tools)
        #expect(reloaded.tools.filter { detected.contains($0) } == [.codex, .copilot, .antigravity])
    }

    @Test func decodesClaudeUsage() throws {
        let json = """
            {"five_hour": {"utilization": 34.0, "resets_at": "2026-10-22T14:30:00.274954+00:00", "used_dollars": null},
             "seven_day": {"utilization": 61.0, "resets_at": "2026-10-27T22:00:00+00:00"},
             "seven_day_opus": null, "extra_usage": {"is_enabled": false}}
            """
        let windows = try JSONDecoder().decode(ClaudeUsageResponse.self, from: Data(json.utf8)).windows()
        #expect(windows.map(\.kind) == [.session, .weekly])
        #expect(abs(windows[0].left - 0.66) < 0.0001)
        #expect(windows[0].duration == 5 * 3_600)
        // Microseconds parse to about a millisecond.
        #expect(abs(try #require(windows[0].resetsAt).timeIntervalSince1970 - 1_792_679_400.275) < 0.01)
        #expect(windows[1].resetsAt == Date(timeIntervalSince1970: 1_793_138_400))
    }

    @Test func claudeWithoutWindowsHasNone() throws {
        let response = try JSONDecoder().decode(ClaudeUsageResponse.self, from: Data(#"{"five_hour": null}"#.utf8))
        #expect(response.windows().isEmpty)
    }

    @Test func decodesCodexUsage() throws {
        let json = """
            {"plan_type": "plus", "rate_limit": {"allowed": true,
              "primary_window": {"used_percent": 12, "limit_window_seconds": 18000, "reset_after_seconds": 9100, "reset_at": 1792670777},
              "secondary_window": {"used_percent": 86, "limit_window_seconds": 604800, "reset_at": 1793126525}},
             "credits": {"has_credits": false}}
            """
        let response = try JSONDecoder().decode(CodexUsageResponse.self, from: Data(json.utf8))
        let windows = response.windows()
        #expect(response.planType == "plus")
        #expect(windows.map(\.kind) == [.session, .weekly])
        #expect(windows[1].duration == 604_800)
        #expect(abs(windows[1].left - 0.14) < 0.0001)
        #expect(windows[0].resetsAt == Date(timeIntervalSince1970: 1_792_670_777))
    }

    @Test func decodesCursorIncludedUsage() throws {
        let json = """
            {"billingCycleStart": "2026-10-03T00:00:00.000Z", "billingCycleEnd": "2026-11-03T00:00:00.000Z",
             "membershipType": "pro", "isUnlimited": false,
             "individualUsage": {"plan": {"enabled": true, "used": 760, "limit": 2000, "remaining": 1240,
                                          "autoPercentUsed": 20, "apiPercentUsed": 56, "totalPercentUsed": 38},
                                 "onDemand": {"enabled": false, "used": 0, "limit": null}}}
            """
        let response = try JSONDecoder().decode(CursorUsageResponse.self, from: Data(json.utf8))
        let window = try #require(response.windows().first)
        #expect(window.kind == .monthly)
        #expect(abs(window.left - 0.62) < 0.0001)
        #expect(window.duration == 31 * 86_400)
        #expect(window.dollarsUsed == 7.6)
        #expect(window.dollarsLimit == 20)
        #expect(response.membershipType == "pro")
    }

    @Test func cursorFallsBackToAmountsAndTheTeamCap() throws {
        let json = #"{"individualUsage": {"overall": {"used": 4500, "limit": 5000}}}"#
        let window = try #require(try JSONDecoder().decode(CursorUsageResponse.self, from: Data(json.utf8)).windows().first)
        #expect(abs(window.used - 0.9) < 0.0001)
        #expect(window.resetsAt == nil)
        #expect(try JSONDecoder().decode(CursorUsageResponse.self, from: Data("{}".utf8)).windows().isEmpty)
    }

    @Test func decodesGrokCredits() throws {
        let json = """
            {"config": {"creditUsagePercent": 12.5, "subscriptionTier": "SuperGrok",
              "currentPeriod": {"type": "USAGE_PERIOD_TYPE_WEEKLY", "start": "2026-08-06T00:00:00Z", "end": "2026-08-13T00:00:00Z"},
              "billingPeriodEnd": "2026-09-01T00:00:00Z", "onDemandCap": {"val": 1000}, "onDemandUsed": {"val": 250}}}
            """
        let response = try JSONDecoder().decode(GrokBillingResponse.self, from: Data(json.utf8))
        let window = try #require(response.windows().first)
        #expect(window.kind == .weekly)
        #expect(window.left == 0.875)
        #expect(window.duration == 7 * 86_400)
        #expect(window.resetsAt == Date(timeIntervalSince1970: 1_786_579_200))
        #expect(response.plan == "SuperGrok")
        // Without a percentage the on-demand amounts give it; a period without either is unknown.
        let amounts = #"{"config": {"onDemandCap": {"val": 1000}, "onDemandUsed": {"val": 250}}}"#
        #expect(try JSONDecoder().decode(GrokBillingResponse.self, from: Data(amounts.utf8)).windows().first?.used == 0.25)
        let unknown = #"{"config": {"currentPeriod": {"start": "2026-08-06T00:00:00Z", "end": "2026-08-13T00:00:00Z"}}}"#
        #expect(try JSONDecoder().decode(GrokBillingResponse.self, from: Data(unknown.utf8)).windows().isEmpty)
    }

    @Test func picksTheSuperGrokSignIn() throws {
        let json =
            #"{"https://accounts.x.ai/sign-in": {"key": "legacy"}, "https://auth.x.ai::client": {"key": "oidc", "expires_at": "2026-10-22T10:00:00Z"}}"#
        let credentials = try #require(GrokCredentials.token(from: Data(json.utf8)))
        #expect(credentials.token == "oidc")
        #expect(credentials.expiresAt == Date(timeIntervalSince1970: 1_792_663_200))
        #expect(GrokCredentials.token(from: Data(#"{"https://auth.x.ai::client": {"key": ""}}"#.utf8)) == nil)
    }

    @Test func readsCursorsTokenFromItsStateDatabase() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "monny-cursor-\(UUID().uuidString).vscdb")
        defer { try? FileManager.default.removeItem(at: url) }
        var db: OpaquePointer?
        #expect(sqlite3_open(url.path(percentEncoded: false), &db) == SQLITE_OK)
        sqlite3_exec(db, "CREATE TABLE ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB)", nil, nil, nil)
        sqlite3_exec(db, "INSERT INTO ItemTable VALUES ('cursorAuth/accessToken', 'header.payload.signature')", nil, nil, nil)
        sqlite3_close(db)
        #expect(AIUsageReader.cursorToken(at: url) == "header.payload.signature")
        #expect(AIUsageReader.cursorToken(at: url.appending(path: "missing")) == nil)
    }

    @Test func codexAPIKeyLoginHasNoPlan() throws {
        let key = try JSONDecoder().decode(
            CodexCredentials.self, from: Data(#"{"auth_mode": "apikey", "OPENAI_API_KEY": "sk-test", "tokens": null}"#.utf8))
        #expect(key.usesAPIKey)
        let chatGPT = try JSONDecoder().decode(
            CodexCredentials.self,
            from: Data(#"{"auth_mode": "chatgpt", "OPENAI_API_KEY": null, "tokens": {"access_token": "a.b.c", "account_id": "x"}}"#.utf8))
        #expect(!chatGPT.usesAPIKey)
        #expect(chatGPT.tokens?.accountID == "x")
    }

    @Test func claudeModelWeeklyLimits() throws {
        let json = """
            {"five_hour": {"utilization": 10, "resets_at": "2026-10-22T14:30:00+00:00"},
             "seven_day": {"utilization": 40, "resets_at": "2026-10-27T22:00:00+00:00"},
             "seven_day_sonnet": {"utilization": 12, "resets_at": "2026-10-27T22:00:00+00:00"},
             "limits": [
               {"kind": "weekly_all", "group": "weekly", "percent": 40, "scope": null},
               {"kind": "weekly_scoped", "group": "weekly", "percent": 29, "resets_at": 1793138400,
                "scope": {"model": {"id": null, "display_name": "Opus"}, "surface": null}},
               {"kind": "weekly_scoped", "group": "weekly", "percent": 5, "scope": {"model": null}},
               "garbage"
             ]}
            """
        let windows = try JSONDecoder().decode(ClaudeUsageResponse.self, from: Data(json.utf8)).windows()
        #expect(windows.map(\.id) == ["session.", "weekly.", "weekly.Opus", "weekly.Sonnet"])
        let opus = try #require(windows.first { $0.model == "Opus" })
        #expect(abs(opus.left - 0.71) < 0.0001)
        #expect(opus.resetsAt == Date(timeIntervalSince1970: 1_793_138_400))
    }

    @Test func codexModelLimitsAndCredits() throws {
        let json = """
            {"plan_type": "pro", "rate_limit": {"primary_window": {"used_percent": 12, "limit_window_seconds": 18000, "reset_at": 1792670777}},
             "additional_rate_limits": ["garbage", {"limit_name": "GPT-5.3-Codex-Spark", "metered_feature": "gpt_5_3_codex_spark",
               "rate_limit": {"primary_window": {"used_percent": 46, "limit_window_seconds": 18000, "reset_at": 1792670777},
                              "secondary_window": {"used_percent": 20, "limit_window_seconds": 604800, "reset_at": 1793126525}}}],
             "credits": {"has_credits": true, "unlimited": false, "balance": "1250"}}
            """
        let response = try JSONDecoder().decode(CodexUsageResponse.self, from: Data(json.utf8))
        #expect(response.windows().map(\.id) == ["session.", "session.Spark", "weekly.Spark"])
        #expect(response.creditsLeft == 1_250)
        let none = try JSONDecoder().decode(
            CodexUsageResponse.self, from: Data(#"{"credits": {"has_credits": false, "unlimited": false, "balance": "0"}}"#.utf8))
        #expect(none.creditsLeft == nil)
        #expect(CodexUsageResponse.shortName("Codex Max") == "Codex Max")
    }

    @Test func readsTheJWTExpiry() {
        // Header and payload {"exp": 1792700000} in base64url, unsigned.
        let token = "eyJhbGciOiJub25lIn0.eyJleHAiOjE3OTI3MDAwMDB9."
        #expect(CodexCredentials.expiry(ofJWT: token) == Date(timeIntervalSince1970: 1_792_700_000))
        #expect(CodexCredentials.expiry(ofJWT: "not-a-token") == nil)
    }

    @Test func paceMarkIsTheShareOfTimeLeft() throws {
        let window = AIQuotaWindow(kind: .weekly, used: 0.5, resetsAt: now.addingTimeInterval(3.5 * 86_400), duration: 7 * 86_400)
        #expect(try #require(window.timeLeft(at: now)) == 0.5)
        // Exactly on pace: runs out at the reset, not before.
        #expect(window.runsOut(at: now) == nil)
    }

    @Test func runningLowOnlyBelowTenPercentWhateverThePace() throws {
        // 38 % left with 90 % of the window to go is ahead of pace, but not running low.
        let early = AIQuotaWindow(kind: .session, used: 0.62, resetsAt: now.addingTimeInterval(4.5 * 3_600), duration: 5 * 3_600)
        #expect(!early.isRunningLow)
        let runsOut = try #require(early.runsOut(at: now))
        #expect(abs(runsOut.timeIntervalSince(now) - 0.38 / (0.62 / (0.5 * 3_600))) < 1)
        let low = AIQuotaWindow(kind: .weekly, used: 0.92, resetsAt: now.addingTimeInterval(86_400), duration: 7 * 86_400)
        #expect(low.isRunningLow)
        #expect(!AIQuotaWindow(kind: .weekly, used: 0.89, resetsAt: nil, duration: 7 * 86_400).isRunningLow)
    }

    @Test func usedUpIsNotRunningLowButReachesTheLimit() {
        let window = AIQuotaWindow(kind: .session, used: 1.02, resetsAt: now.addingTimeInterval(3_600), duration: 5 * 3_600)
        #expect(window.isExhausted)
        #expect(window.left == 0)
        #expect(!window.isRunningLow)
        #expect(window.runsOut(at: now) == nil)
    }

    @Test func lowWindowAlertsOncePerEpisode() {
        var low = AILowWindows()
        func usage(_ used: Double) -> AIUsage {
            AIUsage(
                plan: "pro",
                windows: [
                    AIQuotaWindow(
                        kind: .weekly, used: used, resetsAt: now.addingTimeInterval(3.5 * 86_400),
                        duration: 7 * 86_400)
                ], date: now)
        }
        #expect(low.update(.codex, usage: usage(0.4), now: now).isEmpty)
        #expect(low.update(.codex, usage: usage(0.86), now: now).isEmpty)
        #expect(low.update(.codex, usage: usage(0.92), now: now).count == 1)
        #expect(low.update(.codex, usage: usage(0.95), now: now).isEmpty)
        // Used up continues the same episode.
        #expect(low.update(.codex, usage: usage(1), now: now).isEmpty)
        // After the reset the window recovers and can alert again.
        #expect(low.update(.codex, usage: usage(0.1), now: now).isEmpty)
        #expect(low.update(.codex, usage: usage(0.95), now: now).count == 1)
        // Claude's windows are separate.
        #expect(low.update(.claude, usage: usage(0.95), now: now).count == 1)
    }

    @Test func exhaustedWindowDoesNotAlertAgainWhenResetTimeChanges() {
        var alerts = AILowWindows()
        let reset = now.addingTimeInterval(22 * 60)
        func usage(reset: Date?) -> AIUsage {
            AIUsage(windows: [AIQuotaWindow(kind: .session, used: 1, resetsAt: reset, duration: 18_000)], date: now)
        }
        #expect(alerts.update(.claude, usage: usage(reset: reset), now: now).count == 1)
        // Successive checks can refine the reset, including across a whole-second boundary.
        for (index, shift) in [0.274954, -0.5, 1.2, 30.0].enumerated() {
            #expect(
                alerts.update(
                    .claude, usage: usage(reset: reset.addingTimeInterval(shift)),
                    now: now.addingTimeInterval(Double(index + 1) * 120)
                ).isEmpty)
        }
        // An omitted reset and its return also belong to the same exhausted episode.
        #expect(alerts.update(.claude, usage: usage(reset: nil), now: now.addingTimeInterval(600)).isEmpty)
        #expect(alerts.update(.claude, usage: usage(reset: reset), now: now.addingTimeInterval(720)).isEmpty)
        // A new period can already be low even if no recovered reading was observed.
        #expect(
            alerts.update(
                .claude, usage: usage(reset: reset.addingTimeInterval(18_000)),
                now: reset.addingTimeInterval(120)
            ).count == 1)
    }

    @Test func learningAnUnknownResetDoesNotRepeatALowAlert() {
        var alerts = AILowWindows()
        var usage = AIUsage(windows: [AIQuotaWindow(kind: .session, used: 0.95, duration: 18_000)], date: now)
        #expect(alerts.update(.claude, usage: usage, now: now).count == 1)
        usage.windows[0].resetsAt = now.addingTimeInterval(600)
        #expect(alerts.update(.claude, usage: usage, now: now.addingTimeInterval(120)).isEmpty)
        usage.windows[0].resetsAt = now.addingTimeInterval(18_600)
        #expect(alerts.update(.claude, usage: usage, now: now.addingTimeInterval(720)).count == 1)
    }

    @MainActor @Test func historyGetsOnlyFreshWindowsThatHaveNotReset() {
        let fresh = AIUsage(
            plan: nil,
            windows: [
                AIQuotaWindow(kind: .session, used: 0.2, resetsAt: now.addingTimeInterval(-60), duration: 5 * 3_600),
                AIQuotaWindow(kind: .weekly, used: 0.3, resetsAt: now.addingTimeInterval(86_400), duration: 7 * 86_400),
            ], date: now.addingTimeInterval(-120))
        let stale = AIUsage(
            plan: nil,
            windows: [
                AIQuotaWindow(kind: .weekly, used: 0.3, resetsAt: now.addingTimeInterval(86_400), duration: 7 * 86_400)
            ], date: now.addingTimeInterval(-3_600))
        let monitor = AIUsageMonitor(installed: [.claude, .codex], states: [.claude: .init(usage: fresh), .codex: .init(usage: stale)])
        #expect(monitor.historyValues(at: now) == [.claudeWeekly: 0.7])
    }

    @Test func normalizesWindowsToSessionBeforeWeeklyAndPlanBeforeModel() {
        let windows = [
            AIQuotaWindow(kind: .weekly, used: 0.2, duration: 7 * 86_400, model: "Opus"),
            AIQuotaWindow(kind: .monthly, used: 0.5, duration: 30 * 86_400),
            AIQuotaWindow(kind: .weekly, used: 0.3, duration: 7 * 86_400),
            AIQuotaWindow(kind: .session, used: 0.1, duration: 5 * 3_600, model: "Opus"),
            AIQuotaWindow(kind: .session, used: 0.4, duration: 5 * 3_600),
        ]
        let sorted = AIQuotaWindow.normalized(windows)
        #expect(sorted.map(\.model) == [nil, nil, nil, "Opus", "Opus"])
        #expect(sorted.map(\.kind) == [.session, .weekly, .monthly, .session, .weekly])
    }

    @Test func adaptiveScheduleHandlesCacheIdleExhaustedMissingAndRateLimit() {
        var schedule = AIPollSchedule()
        let baseUsage = AIUsage(
            windows: [AIQuotaWindow(kind: .session, used: 0.25, resetsAt: now.addingTimeInterval(3_600), duration: 18_000)],
            date: now.addingTimeInterval(-30))

        // Fresh persisted cache (< 2 min) skips an immediate startup check.
        schedule.seed([.claude: baseUsage], now: now)
        #expect(schedule.isDue(.claude, problem: nil, visible: false, notificationsOn: true, now: now) == false)
        #expect(schedule.isDue(.claude, problem: nil, visible: true, notificationsOn: false, now: now.addingTimeInterval(100)))

        // With notifications on: 5 min while active, then 14 min after 2 unchanged readings.
        let t1 = now.addingTimeInterval(200)
        let changed = AIUsage(
            windows: [AIQuotaWindow(kind: .session, used: 0.4, resetsAt: t1.addingTimeInterval(3_600), duration: 18_000)],
            date: t1)
        schedule.record(.claude, result: .success(changed), notificationsOn: true, now: t1)
        #expect(schedule.isDue(.claude, problem: nil, visible: false, notificationsOn: true, now: t1.addingTimeInterval(4 * 60)) == false)
        #expect(schedule.isDue(.claude, problem: nil, visible: false, notificationsOn: true, now: t1.addingTimeInterval(5 * 60)))

        schedule.record(.claude, result: .success(changed), notificationsOn: true, now: t1.addingTimeInterval(5 * 60))
        let t3 = t1.addingTimeInterval(10 * 60)
        schedule.record(.claude, result: .success(changed), notificationsOn: true, now: t3)
        #expect(schedule.isDue(.claude, problem: nil, visible: false, notificationsOn: true, now: t3.addingTimeInterval(10 * 60)) == false)
        #expect(schedule.isDue(.claude, problem: nil, visible: false, notificationsOn: true, now: t3.addingTimeInterval(14 * 60)))

        // With notifications off: slow 14-minute history cadence.
        schedule.record(.codex, result: .success(changed), notificationsOn: false, now: t1)
        #expect(schedule.isDue(.codex, problem: nil, visible: false, notificationsOn: false, now: t1.addingTimeInterval(10 * 60)) == false)
        #expect(schedule.isDue(.codex, problem: nil, visible: false, notificationsOn: false, now: t1.addingTimeInterval(14 * 60)))

        // Exhausted tool sleeps until resetsAt + 15s (clamped to 2m..6h).
        let reset = t1.addingTimeInterval(3_600)
        let exhausted = AIUsage(windows: [AIQuotaWindow(kind: .session, used: 1.0, resetsAt: reset, duration: 18_000)], date: t1)
        schedule.record(.cursor, result: .success(exhausted), notificationsOn: true, now: t1)
        #expect(schedule.isDue(.cursor, problem: nil, visible: false, notificationsOn: true, now: reset) == false)
        #expect(schedule.isDue(.cursor, problem: nil, visible: false, notificationsOn: true, now: reset.addingTimeInterval(15)))

        // Signed-out/missing tools back off to 30 minutes.
        schedule.record(.grok, result: .failure(.signedOut), notificationsOn: true, now: t1)
        #expect(
            schedule.isDue(.grok, problem: .signedOut, visible: false, notificationsOn: true, now: t1.addingTimeInterval(20 * 60)) == false)
        #expect(schedule.isDue(.grok, problem: .signedOut, visible: false, notificationsOn: true, now: t1.addingTimeInterval(30 * 60)))

        // HTTP 429 Retry-After overrides even visible UI.
        let retryAfter = t1.addingTimeInterval(600)
        #expect(
            schedule.isDue(
                .claude, problem: .unavailable(retryAfter: retryAfter),
                visible: true, notificationsOn: true, now: t1.addingTimeInterval(300)) == false)
    }

    @MainActor @Test func pollsToolsConcurrentlyAndNormalizesResults() async {
        let inFlight = Mutex(0)
        let maxConcurrent = Mutex(0)
        let tools: [AITool] = [.claude, .codex, .cursor, .antigravity]
        let testNow = now
        let monitor = AIUsageMonitor(installed: tools, states: [:]) { tool, _ in
            let current = inFlight.withLock { value -> Int in
                value += 1
                return value
            }
            maxConcurrent.withLock { peak in peak = max(peak, current) }
            try? await Task.sleep(for: .milliseconds(tool == .antigravity ? 10 : 60))
            inFlight.withLock { $0 -= 1 }
            let windows = [
                AIQuotaWindow(kind: .weekly, used: 0.4, duration: 7 * 86_400),
                AIQuotaWindow(kind: .session, used: 0.2, duration: 5 * 3_600),
            ]
            return .success(AIUsage(windows: windows, date: testNow))
        }

        await monitor.pollTools(tools, notificationsOn: false, now: testNow)
        #expect(maxConcurrent.withLock { $0 } >= 2)
        for tool in tools {
            #expect(monitor.states[tool]?.usage?.windows.map(\.kind) == [.session, .weekly])
        }
    }
}
