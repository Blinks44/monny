import Foundation
import Testing

@testable import monny

struct KimiUsageTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func newPlanKeepsMonthlyExhaustionWithoutInventingWeeklyQuota() throws {
        let usage = try KimiUsage.usage(Data(Self.newPlan.utf8), now: now)
        #expect(usage.windows.map(\.kind) == [.session, .monthly])
        #expect(usage.windows[0].left == 0.75)
        #expect(usage.windows[1].isExhausted)
        #expect(usage.windows[1].timeLeft(at: now) == nil)
        #expect(usage.windows[1].runsOut(at: now) == nil)
        #expect(usage.credits == nil)
        #expect(usage.plan == nil)
    }

    @Test func legacyCountsAndRatioConflictsKeepTheMoreExhaustedSamePeriod() throws {
        let json =
            #"{"usage":{"limit":"100","remaining":"40","resetTime":"2027-02-01T00:00:00Z"},"limits":[{"window":{"duration":5,"timeUnit":"TIME_UNIT_HOUR"},"detail":{"limit":200,"used":190,"resetTime":"2027-01-15T13:00:01Z"}}],"usages":{"limit_5h":{"used_ratio":0.2,"reset_time":"2027-01-15T13:00:00Z"}}}"#
        let usage = try KimiUsage.usage(Data(json.utf8), now: now)
        #expect(usage.windows.map(\.kind) == [.session, .weekly])
        #expect(usage.windows[0].used == 0.95)
        #expect(usage.windows[1].used == 0.6)
        let differentPeriod = json.replacingOccurrences(of: "13:00:01Z", with: "14:00:00Z")
        #expect(try KimiUsage.usage(Data(differentPeriod.utf8), now: now).windows[0].used == 0.2)
    }

    @Test(arguments: [
        #"{}"#, #"{"usages":{"limit_month_code":{"used_ratio":0.2}}}"#,
        #"{"usages":{"limit_5h":{"used_ratio":0.2},"limit_month_total":false}}"#,
        #"{"usage":{"limit":100,"used":50},"usages":[]}"#,
        #"{"usages":{"limit_5h":{"used_ratio":true}}}"#,
        #"{"usages":{"limit_month_total":{"used_ratio":-1}}}"#,
        #"{"usages":{"limit_month_total":{"used_ratio":"NaN"}}}"#,
        #"{"usages":{"limit_5h":{"used_ratio":0.5,"reset_time":"invalid"}}}"#,
        #"{"usage":{"limit":100}}"#, #"{"usage":{"limit":0,"used":0}}"#,
        #"{"usage":{"limit":100,"used":false,"remaining":40}}"#,
    ])
    func malformedQuotaNeverBecomesZeroUsage(json: String) {
        #expect(throws: (any Error).self) { try KimiUsage.usage(Data(json.utf8), now: now) }
    }

    @Test func ratiosAllowNumericStringsOverageAndUnknownReset() throws {
        let usage = try KimiUsage.usage(Data(#"{"usages":{"limit_5h":{"used_ratio":"1.2"},"limit_7d":{"used_ratio":0.5}}}"#.utf8), now: now)
        #expect(usage.windows[0].isExhausted)
        #expect(usage.windows[0].resetsAt == nil)
        #expect(usage.windows[1].duration == 604_800)
    }

    @Test func credentialsRequireFreshAccessAndIgnoreRefreshAndAPIKeys() throws {
        #expect(
            try KimiUsage.credential(
                Data(#"{"access_token":"saved-session","expires_at":"1800000900","refresh_token":"unused"}"#.utf8), now: now)
                == "saved-session")
        for json in [
            #"{"refresh_token":"unused","expires_at":1800000900}"#,
            #"{"api_key":"not-a-session","expires_at":1800000900}"#,
            #"{"access_token":"bad\r\nHeader: value","expires_at":1800000900}"#,
        ] {
            #expect(throws: AIUsageProblem.signedOut) { try KimiUsage.credential(Data(json.utf8), now: now) }
        }
        for expiry in ["1800000060", "1800000000", "true", "null", "\"NaN\""] {
            let json = "{\"access_token\":\"saved-session\",\"expires_at\":\(expiry)}"
            #expect(throws: AIUsageProblem.expired) { try KimiUsage.credential(Data(json.utf8), now: now) }
        }
        let claims = Data(#"{"iss":"https://auth.kimi.ai","exp":1800000900}"#.utf8).base64EncodedString()
        let otherRegion = try JSONSerialization.data(withJSONObject: [
            "access_token": "header.\(claims).signature", "expires_at": 1_800_000_900,
        ])
        #expect(throws: AIUsageProblem.signedOut) { try KimiUsage.credential(otherRegion, now: now) }
    }

    @Test @MainActor func monthlyHistoryAndAlertSurviveTheShortWindowReset() throws {
        let usage = try KimiUsage.usage(Data(Self.newPlan.utf8), now: now)
        let monitor = AIUsageMonitor(installed: [.kimi], states: [.kimi: .init(usage: usage)])
        #expect(monitor.historyValues(at: now)[.kimiMonthly] == 0)
        #expect(monitor.historyValues(at: now)[.kimiWeekly] == nil)
        #expect(monitor.historyValues(at: now.addingTimeInterval(901)).isEmpty)
        var episodes = AILowWindows()
        #expect(episodes.update(.kimi, usage: usage, now: now).count == 1)
        #expect(episodes.update(.kimi, usage: usage, now: now.addingTimeInterval(120)).isEmpty)
        var reset = usage
        reset.windows[0].resetsAt = now.addingTimeInterval(-1)
        let afterReset = AIUsageMonitor(installed: [.kimi], states: [.kimi: .init(usage: reset)])
        #expect(afterReset.historyValues(at: now)[.kimiSession] == nil)
        #expect(afterReset.historyValues(at: now)[.kimiMonthly] == 0)
    }

    @Test(arguments: ["kimi-auth", "https://auth.kimi.com"])
    func acceptsDefaultKimiIssuerWithoutTreatingEveryIssuerAsAURL(issuer: String) throws {
        let claims = try JSONSerialization.data(withJSONObject: ["iss": issuer, "exp": 1_800_000_900])
        let token = "header." + claims.base64EncodedString() + ".signature"
        let data = try JSONSerialization.data(withJSONObject: ["access_token": token, "expires_at": 1_800_000_900])
        #expect(try KimiUsage.credential(data, now: now) == token)
    }

    @Test func readerRereadsSessionWithoutWritesOrFallbackAndHandlesErrors() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let modern = root.appending(path: ".kimi-code")
        let legacy = root.appending(path: ".kimi")
        for home in [modern, legacy] {
            try FileManager.default.createDirectory(at: home.appending(path: "credentials"), withIntermediateDirectories: true)
        }
        let file = modern.appending(path: "credentials/kimi-code.json")
        let oldFile = legacy.appending(path: "credentials/kimi-code.json")
        let original = Data(#"{"access_token":"saved-session","expires_at":1800000900,"refresh_token":"unused"}"#.utf8)
        try original.write(to: oldFile)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [KimiFixtureProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let reader = AIUsageReader(session: session)
        #expect(await reader.readKimi(homes: [modern, legacy], now: now) == .failure(.signedOut))
        try original.write(to: file)
        #expect(try await reader.readKimi(homes: [modern, legacy], now: now).get().windows.count == 2)
        #expect(try Data(contentsOf: file) == original)
        #expect(FileManager.default.fileExists(atPath: modern.appending(path: "device_id").path) == false)
        for (token, problem) in [
            ("rejected", AIUsageProblem.signedOut),
            ("rate-limit", .unavailable(retryAfter: now.addingTimeInterval(300))),
            ("malformed", .unavailable(retryAfter: nil)),
        ] {
            try JSONSerialization.data(withJSONObject: ["access_token": token, "expires_at": 1_800_000_900]).write(to: file)
            #expect(await reader.readKimi(homes: [modern, legacy], now: now) == .failure(problem))
        }
        try Data(#"{"access_token":"never-send-expired","expires_at":1}"#.utf8).write(to: file)
        #expect(await reader.readKimi(homes: [modern, legacy], now: now) == .failure(.expired))
        try FileManager.default.removeItem(at: modern)
        #expect(try await reader.readKimi(homes: [modern, legacy], now: now).get().windows.count == 2)
    }

    @Test func standardRegionalSlotsAreRecognizedWithoutPickingAnAmbiguousAccount() throws {
        #expect(KimiSession.Region.china.credentialName == "kimi-code.json")
        #expect(KimiSession.Region.international.credentialName == "kimi-code-env-0e4f99c69cc27850.json")
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appending(path: "credentials")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let international = directory.appending(path: KimiSession.Region.international.credentialName)
        // Selection reads metadata only; invalid/empty contents cannot change the chosen region.
        try Data().write(to: international)
        #expect(KimiSession.locate(in: root)?.region == .international)
        let china = directory.appending(path: KimiSession.Region.china.credentialName)
        try Data().write(to: china)
        #expect(KimiSession.locate(in: root) == nil)
        try FileManager.default.removeItem(at: china)
        let custom = directory.appending(path: "kimi-code-env-ffffffffffffffff.json")
        try Data().write(to: custom)
        #expect(KimiSession.locate(in: root) == nil)
        try FileManager.default.removeItem(at: international)
        #expect(KimiSession.locate(in: root) == nil)
        try FileManager.default.removeItem(at: custom)
        try FileManager.default.createSymbolicLink(at: international, withDestinationURL: directory.appending(path: "missing.json"))
        #expect(KimiSession.locate(in: root) == nil)
    }

    @Test func internationalSessionUsesOnlyItsOwnAPIAndDoesNotFallBackToChina() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appending(path: "credentials")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appending(path: KimiSession.Region.international.credentialName)
        let original = Data(#"{"access_token":"international-session","expires_at":1800000900}"#.utf8)
        try original.write(to: file)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [KimiFixtureProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let reader = AIUsageReader(session: session)
        #expect(try await reader.readKimi(homes: [root], now: now).get().windows.count == 2)
        #expect(try Data(contentsOf: file) == original)
        try Data(#"{"access_token":"international-rejected","expires_at":1800000900}"#.utf8).write(to: file)
        #expect(await reader.readKimi(homes: [root], now: now) == .failure(.signedOut))
        try original.write(to: directory.appending(path: "kimi-code.json"))
        #expect(await reader.readKimi(homes: [root], now: now) == .failure(.signedOut))
    }

    @Test func urlIssuerMustMatchTheSelectedRegionalSlot() throws {
        let claims = Data(#"{"iss":"https://auth.kimi.ai","exp":1800000900}"#.utf8).base64EncodedString()
        let token = "header.\(claims).signature"
        let data = try JSONSerialization.data(withJSONObject: ["access_token": token, "expires_at": 1_800_000_900])
        #expect(try KimiUsage.credential(data, now: now, region: .international) == token)
        #expect(throws: AIUsageProblem.signedOut) { try KimiUsage.credential(data, now: now, region: .china) }
    }

    nonisolated static let newPlan =
        #"{"user":{"membership":{"level":"LEVEL_BASIC"}},"usages":{"limit_5h":{"used_ratio":0.25,"reset_time":"2027-01-15T13:00:00Z"},"limit_month_total":{"used_ratio":1,"reset_time":"2027-02-01T00:00:00Z"},"limit_month_code":{"used_ratio":0.8}}}"#
}

/// Stateless fixture transport; request/client state is owned by URLProtocol.
nonisolated private final class KimiFixtureProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let auth = request.value(forHTTPHeaderField: "Authorization")
        let international = auth?.hasPrefix("Bearer international-") == true
        #expect(
            request.url?.absoluteString
                == (international ? "https://api.kimi.ai/coding/v1/usages" : "https://api.kimi.com/coding/v1/usages"))
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "Monny")
        #expect(request.value(forHTTPHeaderField: "Cookie") == nil)
        #expect(request.allHTTPHeaderFields?.keys.contains { $0.lowercased().hasPrefix("x-msh-") } == false)
        #expect(auth != "Bearer never-send-expired")
        let status = auth == "Bearer rejected" || auth == "Bearer international-rejected" ? 401 : auth == "Bearer rate-limit" ? 429 : 200
        let body = auth == "Bearer malformed" ? "{}" : KimiUsageTests.newPlan
        guard let url = request.url,
            let response = HTTPURLResponse(
                url: url, statusCode: status,
                httpVersion: nil, headerFields: ["Retry-After": "0"])
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
