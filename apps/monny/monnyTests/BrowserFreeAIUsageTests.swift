import Foundation
import SQLite3
import Testing

@testable import monny

struct BrowserFreeAIUsageTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func openCodeWindowsHaveReportedUnitsAndNoInventedMonthlyDuration() throws {
        let usage = try OpenCodeGoUsage.usage(
            Data(#"{"usage":{"rolling":{"percent":25,"resetsAt":1800010000},"weekly":{"percent":0},"monthly":{"percent":100}}}"#.utf8),
            now: now)
        #expect(usage.windows.map(\.used) == [0.25, 0, 1])
        #expect(usage.windows.map(\.duration) == [18_000, 604_800, 0])
        #expect(usage.windows[0].resetsAt == Date(timeIntervalSince1970: 1_800_010_000))
    }

    @Test(arguments: [
        "{}", #"{"usage":{"rolling":{}}}"#, #"{"usage":{"rolling":{"percent":true}}}"#, #"{"usage":{"rolling":{"percent":-1}}}"#,
    ])
    func invalidOpenCodeDoesNotBecomeZero(json: String) {
        #expect(throws: AIUsageProblem.self) { try OpenCodeGoUsage.usage(Data(json.utf8), now: now) }
    }

    @Test func bailianUsesRatiosAndKeepsMissingWindowsAbsent() throws {
        let token = try BailianUsage.usage(
            Data(#"{"per5HourPercentage":0.25,"per1MonthPercentage":0.9,"per1MonthResetTime":1800010000000,"hasQuotaData":true}"#.utf8),
            codingPlan: false, now: now)
        #expect(token.windows.map(\.used) == [0.25, 0.9])
        #expect(token.windows.map(\.kind) == [.session, .monthly])
        #expect(token.windows[1].duration == 0)
        #expect(token.windows[1].resetsAt == Date(timeIntervalSince1970: 1_800_010_000))
        let coding = try BailianUsage.usage(
            Data(
                #"{"instanceType":"pro","per5Hour":{"usedQuota":20,"totalQuota":100},"perWeek":{},"perBillMonth":{"percentage":0.5}}"#.utf8),
            codingPlan: true, now: now)
        #expect(coding.windows.map(\.used) == [0.2, 0.5])
        #expect(coding.plan == "pro")
        #expect(throws: AIUsageProblem.localDataMissing) {
            try BailianUsage.usage(Data(#"{"hasQuotaData":false}"#.utf8), codingPlan: false, now: now)
        }
        #expect(throws: AIUsageProblem.self) {
            try BailianUsage.usage(Data(#"{"per5Hour":{"usedQuota":-1,"totalQuota":100,"percentage":0}}"#.utf8), codingPlan: true, now: now)
        }
    }

    @Test func kiroSubtractsOverageAndKeepsItOutOfPlanHistory() throws {
        let usage = try KiroUsage.usage(Data(Self.kiro.utf8), now: now)
        #expect(usage.windows.map(\.used) == [1, 0.25])
        #expect(usage.windows.map(\.isPlanLimit) == [true, false])
        #expect(usage.windows[1].label == .overage)
        #expect(usage.windows.allSatisfy { $0.duration == 0 })
        let bonus = Self.kiro.replacingOccurrences(of: #""resourceType":"CREDIT""#, with: #""resourceType":"CREDIT","bonuses":[{}]"#)
        #expect(throws: AIUsageProblem.self) { try KiroUsage.usage(Data(bonus.utf8), now: now) }
    }

    @Test func malformedOptionalCountersNeverBecomeZero() {
        let invalidOverage = Self.kiro.replacingOccurrences(
            of: #""currentOveragesWithPrecision":10"#, with: #""currentOveragesWithPrecision":true"#)
        #expect(throws: AIUsageProblem.self) { try KiroUsage.usage(Data(invalidOverage.utf8), now: now) }
        let invalidBonus = Self.kilo.replacingOccurrences(
            of: #""currentPeriodBonusCreditsUsd":5"#, with: #""currentPeriodBonusCreditsUsd":"bad""#)
        #expect(throws: AIUsageProblem.self) { try KiloUsage.usage(Data(invalidBonus.utf8), now: now) }
    }

    @Test func kiroRegionIsBoundToTheProfile() throws {
        #expect(
            try KiroUsage.endpoint(profile: "arn:aws:codewhisperer:eu-central-1:123:profile/demo").host() == "q.eu-central-1.amazonaws.com")
        #expect(
            try KiroUsage.endpoint(profile: "arn:aws:codewhisperer:us-east-1:123:profile/demo").host()
                == "codewhisperer.us-east-1.amazonaws.com")
        for arn in [
            "https://example.org", "arn:aws:codewhisperer:eu-west-1:123:profile/demo", "arn:aws:codewhisperer:us-east-1:123:profile/",
            "arn:aws:codewhisperer:us-east-1:123:profile/a\nb",
        ] {
            #expect(throws: AIUsageProblem.self) { try KiroUsage.endpoint(profile: arn) }
        }
    }

    @Test @MainActor func windsurfCacheNeverBecomesFreshFromPolling() throws {
        let usage = try WindsurfUsage.usage(
            Data(#"{"planName":"Pro","quotaUsage":{"dailyRemainingPercent":10,"weeklyRemainingPercent":50}}"#.utf8), now: now)
        #expect(usage.sourceDateUnknown == true)
        #expect(usage.isStale(at: now))
        #expect(usage.windows[0].label == .daily)
        let monitor = AIUsageMonitor(installed: [.windsurf], states: [.windsurf: .init(usage: usage)])
        #expect(monitor.historyValues(at: now).isEmpty)
        let later = try WindsurfUsage.usage(Data(#"{"usage":{"messages":100,"usedMessages":20}}"#.utf8), now: now.addingTimeInterval(120))
        #expect(later.isStale(at: now.addingTimeInterval(120)))
        #expect(later.windows[0].label == .messages)
    }

    @Test func geminiGroupsModelsWithoutInventingAPeriod() throws {
        let usage = try GeminiUsage.usage(
            Data(
                #"{"buckets":[{"modelId":"gemini-pro","remainingFraction":0.8},{"modelId":"gemini-pro","remainingFraction":0.2},{"modelId":"gemini-flash-lite","remainingFraction":0.5},{"modelId":"gemini-flash","remainingFraction":0.1}]}"#
                    .utf8), now: now)
        #expect(usage.windows.map(\.label) == [.pro, .flash, .flashLite])
        #expect(abs(usage.windows[0].left - 0.2) < 0.000001)
        #expect(usage.windows.allSatisfy { $0.duration == 0 })
        #expect(usage.windows.filter(\.isPlanLimit).count == 1)
        #expect(throws: AIUsageProblem.localDataMissing) {
            try GeminiUsage.project(Data(#"{"ineligibleTiers":[{"reasonCode":"UNSUPPORTED_CLIENT"}]}"#.utf8))
        }
        #expect(try GeminiUsage.project(Data(#"{"cloudaicompanionProject":"project-demo"}"#.utf8)) == "project-demo")
    }

    @Test func huggingFaceReportsOnlyActualGPUAllowance() throws {
        let usage = try HuggingFaceUsage.usage(Data(#"{"base":2400,"current":600,"resetsAt":1800010000000}"#.utf8), now: now)
        #expect(usage.windows[0].left == 0.25)
        #expect(usage.windows[0].label == .zeroGPU)
        #expect(usage.windows[0].duration == 0)
        #expect(usage.balanceUSD == nil)
        #expect(throws: AIUsageProblem.self) { try HuggingFaceUsage.usage(Data(#"{"base":0,"current":0}"#.utf8), now: now) }
        #expect(throws: AIUsageProblem.self) { try HuggingFaceUsage.usage(Data(#"{"base":100,"current":101}"#.utf8), now: now) }
    }

    @Test func kiloSeparatesPassAndMoneyAndNeverReadsPaymentMetadata() throws {
        let usage = try KiloUsage.usage(Data(Self.kilo.utf8), now: now)
        #expect(usage.windows[0].used == 0.25)
        #expect(usage.windows[0].dollarsLimit == 20)
        #expect(usage.balanceUSD == 2)
        let request = try KiloUsage.request(token: "test")
        #expect(request.url?.host() == "app.kilo.ai")
        #expect(request.url?.path().contains("PaymentMethod") == false)
        #expect(request.value(forHTTPHeaderField: "Cookie") == nil)
    }

    @Test func codeRabbitCountNeverCreatesAQuota() throws {
        let usage = try CodeRabbitUsage.usage("Organization: Demo\nYour reviews : 25\nPeriod resets : 2027-02-01", now: now)
        #expect(usage.reviewCount == 25)
        #expect(usage.windows.isEmpty)
        #expect(usage.credits == nil)
        #expect(throws: AIUsageProblem.self) { try CodeRabbitUsage.usage("Your reviews: unavailable", now: now) }
        #expect(throws: AIUsageProblem.self) { try CodeRabbitUsage.usage("Your reviews: 1\nYour reviews: 2", now: now) }
        #expect(AIUsageCommand.environment(for: URL(filePath: "/usr/local/bin/coderabbit"))["CODERABBIT_CLI_DISABLE_AUTO_UPDATE"] == "true")
    }

    @Test func expiredOAuthIsNeverSentOrRenewed() throws {
        #expect(throws: AIUsageProblem.expired) {
            try OpenCodeGoUsage.token(Data(#"{"type":"oauth","access":"test","expires":1}"#.utf8), now: now)
        }
        #expect(throws: AIUsageProblem.expired) { try GeminiUsage.token(Data(#"{"access_token":"test","expiry_date":1}"#.utf8), now: now) }
    }

    @Test func openCodeSQLiteLogoutDoesNotReviveLegacyLogin() throws {
        let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        let directory = home.appending(path: ".local/share/opencode")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(#"{"opencode-go":{"type":"api","key":"old-account"}}"#.utf8).write(to: directory.appending(path: "auth.json"))
        #expect(try OpenCodeGoUsage.credential(home: home, now: now) == "old-account")
        let database = directory.appending(path: "opencode.db")
        try Self.sql(database, "CREATE TABLE credential (integration_id TEXT, value TEXT, active INTEGER)")
        #expect(throws: AIUsageProblem.signedOut) { try OpenCodeGoUsage.credential(home: home, now: now) }
        try Self.sql(database, #"INSERT INTO credential VALUES ('opencode-go','{"type":"key","key":"current-account"}',1)"#)
        #expect(try OpenCodeGoUsage.credential(home: home, now: now) == "current-account")
        try Self.sql(database, #"INSERT INTO credential VALUES ('opencode-go','{"type":"key","key":"ambiguous-account"}',1)"#)
        #expect(throws: AIUsageProblem.signedOut) { try OpenCodeGoUsage.credential(home: home, now: now) }
        #expect(!FileManager.default.fileExists(atPath: database.path + "-wal"))
    }

    @Test(arguments: [AITool.openCodeGo, .kilo, .kiro, .gemini, .huggingFace])
    func readerUsesOnlyFixedServiceAndPreservesCredentials(tool: AITool) async throws {
        let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [AdditionalAIFixtureProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let reader = AIUsageReader(session: session)
        let file: URL
        let data: Data
        if tool == .kiro {
            file = try #require(AdditionalAISources.path(tool, home: home))
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Self.sql(file, "CREATE TABLE auth_kv (key TEXT,value TEXT); CREATE TABLE state (key TEXT,value TEXT)")
            try Self.sql(
                file,
                #"INSERT INTO auth_kv VALUES ('kirocli:odic:token','{"access_token":"accepted"}'); INSERT INTO state VALUES ('api.codewhisperer.profile','{"arn":"arn:aws:codewhisperer:us-east-1:123:profile/demo"}')"#
            )
            data = try Data(contentsOf: file)
        } else {
            file =
                tool == .openCodeGo
                ? home.appending(path: ".local/share/opencode/auth.json") : try #require(AdditionalAISources.path(tool, home: home))
            let value: String
            switch tool {
            case .openCodeGo: value = #"{"opencode-go":{"type":"api","key":"accepted"}}"#
            case .kilo: value = #"{"kilo":{"access":"accepted"}}"#
            case .gemini: value = #"{"access_token":"accepted","expiry_date":1800010000000}"#
            default: value = "accepted"
            }
            data = Data(value.utf8)
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: file)
        }
        let usage = try await reader.readAdditional(tool, home: home, now: now).get()
        #expect(!usage.windows.isEmpty || usage.balanceUSD != nil)
        #expect(try Data(contentsOf: file) == data)
        if tool == .huggingFace {
            try Data("rejected".utf8).write(to: file)
            #expect(await reader.readAdditional(tool, home: home, now: now) == .failure(.signedOut))
            try Data("rate-limit".utf8).write(to: file)
            #expect(
                await reader.readAdditional(tool, home: home, now: now) == .failure(.unavailable(retryAfter: now.addingTimeInterval(300))))
        }
    }

    nonisolated static func sql(_ file: URL, _ sql: String) throws {
        var db: OpaquePointer?
        guard sqlite3_open(file.path, &db) == SQLITE_OK else { throw AIUsageProblem.localDataMissing }
        defer { sqlite3_close(db) }
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw AIUsageProblem.localDataMissing }
    }

    nonisolated static let kiro =
        #"{"usageBreakdownList":[{"resourceType":"CREDIT","currentUsageWithPrecision":110,"usageLimitWithPrecision":100,"currentOveragesWithPrecision":10,"overageCapWithPrecision":40}],"nextDateReset":1800010000,"overageConfiguration":{"overageStatus":"ENABLED"}}"#
    nonisolated static let kilo =
        #"[{"result":{"data":{"json":{"totalBalance_mUsd":2000000}}}},{"result":{"data":{"json":{"subscription":{"currentPeriodUsageUsd":5,"currentPeriodBaseCreditsUsd":15,"currentPeriodBonusCreditsUsd":5}}}}}]"#
}

/// Stateless transport; it never contacts providers or reads real credentials.
nonisolated private final class AdditionalAIFixtureProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let auth = request.value(forHTTPHeaderField: "Authorization")
        #expect(request.value(forHTTPHeaderField: "Cookie") == nil)
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "Monny")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        let body: String
        switch request.url?.host() {
        case "opencode.ai":
            #expect(request.url?.path() == "/inference/go/v1/usage")
            body = #"{"usage":{"rolling":{"percent":20}}}"#
        case "app.kilo.ai": body = BrowserFreeAIUsageTests.kilo
        case "codewhisperer.us-east-1.amazonaws.com":
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "X-Amz-Target") == "AmazonCodeWhispererService.GetUsageLimits")
            body = BrowserFreeAIUsageTests.kiro
        case "cloudcode-pa.googleapis.com":
            #expect(request.httpMethod == "POST")
            body =
                request.url?.path().contains("loadCodeAssist") == true
                ? #"{"currentTier":{"id":"standard-tier"},"cloudaicompanionProject":"fixture"}"#
                : #"{"buckets":[{"modelId":"gemini-pro","remainingFraction":0.5}]}"#
        case "huggingface.co":
            #expect(request.url?.path() == "/api/spaces/zero-gpu/quota")
            body = #"{"base":100,"current":40}"#
        default:
            Issue.record("Unexpected provider host")
            body = "{}"
        }
        let status = auth == "Bearer rejected" ? 403 : auth == "Bearer rate-limit" ? 429 : 200
        guard let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: ["Retry-After": "0"])
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
