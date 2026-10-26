import Foundation
import Testing
@testable import monny

struct AdditionalAIUsageTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let cline = #"{"success":true,"data":{"limits":[{"type":"monthly","percentUsed":25,"resetsAt":"2027-02-01T00:00:00Z"},{"type":"five_hour","percentUsed":95},{"type":"weekly","percentUsed":50}]}}"#

    @Test func clineWindowsKeepKindsAndDoNotInventMonthlyPace() throws {
        let reading = try ClineUsage.usage(Data(cline.utf8), now: now)
        #expect(reading.windows.map(\.kind) == [.session, .weekly, .monthly])
        #expect(abs(reading.windows[0].left - 0.05) < 0.00001)
        #expect(reading.windows[1].left == 0.5)
        #expect(reading.windows[2].left == 0.75)
        #expect(reading.windows[0].duration == 18_000)
        #expect(reading.windows[1].duration == 604_800)
        #expect(reading.windows[2].timeLeft(at: now) == nil)
        #expect(reading.windows[2].runsOut(at: now) == nil)
        #expect(reading.credits == nil)
    }

    @Test(arguments: [#"{"success":1,"data":{"limits":[{"type":"weekly","percentUsed":1}]}}"#, #"{}"#, #"{"success":false,"data":{"limits":[]}}"#,
                     #"{"success":true,"data":{"limits":[{"type":"unknown","percentUsed":10}]}}"#,
                     #"{"success":true,"data":{"limits":[{"type":"weekly","percentUsed":true}]}}"#,
                     #"{"success":true,"data":{"limits":[{"type":"weekly"}]}}"#,
                     #"{"success":true,"data":{"limits":[{"type":"weekly","percentUsed":-1}]}}"#,
                     #"{"success":true,"data":{"limits":[{"type":"weekly","percentUsed":10,"resetsAt":"bad"}]}}"#,
                     #"{"success":true,"data":{"limits":[{"type":"weekly","percentUsed":10},{"type":"weekly","percentUsed":20}]}}"#])
    func invalidClineDoesNotInventQuota(json: String) {
        #expect(throws: (any Error).self) { try ClineUsage.usage(Data(json.utf8), now: now) }
    }

    @Test func clineUnknownWindowsAndOverage() throws {
        let json = #"{"success":true,"data":{"limits":[{"type":"weekly","percentUsed":110,"resetsAt":null},{"type":"future","percentUsed":80}]}}"#
        let reading = try ClineUsage.usage(Data(json.utf8), now: now)
        #expect(reading.windows.count == 1)
        #expect(reading.windows[0].isExhausted)
        #expect(reading.windows[0].resetsAt == nil)
    }

    @Test func savedSessionsIgnoreAPIKeysAndOtherProfiles() {
        let data = Data(#"{"providers":{"cline":{"settings":{"auth":{"accessToken":"session","apiKey":"ignored"},"apiKey":"ignored"}},"other":{"settings":{"auth":{"accessToken":"other"}}}}}"#.utf8)
        #expect(SavedAISession.cline(data) == "workos:session")
        #expect(SavedAISession.cline(Data(#"{"providers":{"cline":{"settings":{"auth":{"accessToken":"workos:session"}}}}}"#.utf8)) == "workos:session")
        #expect(SavedAISession.cline(Data(#"{"providers":{"cline":{"settings":{"apiKey":"ignored"}}}}"#.utf8)) == nil)
        #expect(SavedAISession.codebuff(Data(#"{"default":{"authToken":"selected"},"authToken":"legacy"}"#.utf8)) == "selected")
        #expect(SavedAISession.codebuff(Data(#"{"default":{},"authToken":"legacy"}"#.utf8)) == nil)
        #expect(SavedAISession.codebuff(Data(#"{"authToken":"legacy"}"#.utf8)) == "legacy")
        #expect(SavedAISession.token("token\r\nInjected: true") == nil)
        #expect(SavedAISession.cline(Data(#"{"providers":{"cline":{"settings":{"auth":{"accessToken":"workos:"}}}}}"#.utf8)) == nil)
    }

    @Test func codebuffKeepsWeeklySubscriptionSeparateFromCredits() throws {
        let reading = try CodebuffUsage.usage(Data(#"{"usage":100,"quota":1000,"remainingBalance":"25.5"}"#.utf8),
            subscription: Data(#"{"subscription":{"displayName":"Pro"},"rateLimit":{"weeklyUsed":"25","weeklyLimit":100,"weeklyResetsAt":1800500000000}}"#.utf8), now: now)
        #expect(reading.plan == "Pro")
        #expect(reading.credits == 25.5)
        #expect(reading.windows.count == 1)
        #expect(reading.windows[0].kind == .weekly)
        #expect(reading.windows[0].left == 0.75)
        #expect(reading.windows[0].resetsAt == Date(timeIntervalSince1970: 1_800_500_000))
    }

    @Test func codebuffBalanceAloneIsNotAnExhaustedQuota() throws {
        let reading = try CodebuffUsage.usage(Data(#"{"remainingBalance":0}"#.utf8), subscription: Data("{}".utf8), now: now)
        #expect(reading.credits == 0)
        #expect(reading.windows.isEmpty)
        var episodes = AILowWindows()
        #expect(episodes.update(.codebuff, usage: reading, now: now).isEmpty)
        let noUsage = try CodebuffUsage.usage(Data(#"{"remainingBalance":10}"#.utf8),
            subscription: Data(#"{"rateLimit":{"weeklyLimit":100}}"#.utf8), now: now)
        #expect(noUsage.windows.isEmpty)
    }

    @Test(arguments: [#"{}"#, #"{"remainingBalance":true}"#, #"{"remainingBalance":"NaN"}"#, #"{"remainingBalance":-1}"#])
    func unknownCodebuffIsUnavailable(json: String) {
        #expect(throws: (any Error).self) {
            try CodebuffUsage.usage(Data(json.utf8), subscription: Data(#"{"rateLimit":{"weeklyLimit":0,"weeklyUsed":0}}"#.utf8), now: now)
        }
    }

    @Test @MainActor func historiesExpiryAndAlerts() throws {
        let reading = try ClineUsage.usage(Data(cline.utf8), now: now)
        let monitor = AIUsageMonitor(installed: [.cline], states: [.cline: .init(usage: reading)])
        let values = monitor.historyValues(at: now)
        #expect(abs(try #require(values[.clineSession]) - 0.05) < 0.00001)
        #expect(values[.clineWeekly] == 0.5)
        #expect(values[.clineMonthly] == 0.75)
        #expect(monitor.historyValues(at: now.addingTimeInterval(901)).isEmpty)
        var episodes = AILowWindows()
        #expect(episodes.update(.cline, usage: reading, now: now).count == 1)
        #expect(episodes.update(.cline, usage: reading, now: now.addingTimeInterval(120)).isEmpty)
        let balance = try CodebuffUsage.usage(Data(#"{"remaining":40}"#.utf8), subscription: Data("{}".utf8), now: now)
        let other = AIUsageMonitor(installed: [.codebuff], states: [.codebuff: .init(usage: balance)])
        #expect(other.historyValues(at: now).isEmpty)
        #expect(monitor.historyValues(at: now)[.codebuffWeekly] == nil)
    }

    @Test func boundedCredentialsAndJWTExpiry() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "auth.json")
        #expect(SavedAISession.data(at: file) == nil)
        try Data(repeating: 32, count: 256 * 1_024 + 1).write(to: file)
        #expect(SavedAISession.data(at: file) == nil)
        let claims = Data(#"{"exp":1}"#.utf8).base64EncodedString()
        #expect(SavedAISession.isExpired("workos:header.\(claims).signature", now: now))
        #expect(SavedAISession.isExpired("opaque", now: now) == false)
    }

    @Test func readersUseFixedHostsAndOwnSessionRequests() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "auth.json")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AdditionalAIUsageProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let reader = AIUsageReader(session: session)
        let expired = "header." + Data(#"{"exp":1}"#.utf8).base64EncodedString() + ".signature"
        try JSONSerialization.data(withJSONObject: ["default": ["authToken": expired]]).write(to: file)
        #expect(await reader.readCodebuff(at: file, now: now) == .failure(.expired))
        try Data(#"{"providers":{"cline":{"settings":{"apiKey":"not-a-session"}}}}"#.utf8).write(to: file)
        #expect(await reader.readCline(at: file, now: now) == .failure(.signedOut))
        try Data(#"{"providers":{"cline":{"settings":{"auth":{"accessToken":"session"}}}}}"#.utf8).write(to: file)
        let hermes = directory.appending(path: "hermes.json")
        let fallback = directory.appending(path: "shared.json")
        try Data(#"{"access_token":"hermes-session"}"#.utf8).write(to: fallback)
        try Data(#"{"providers":{"nous":{}}}"#.utf8).write(to: hermes)
        #expect(await reader.readNous(files: [hermes, fallback], now: now) == .failure(.signedOut))
        try Data(#"{"providers":{"nous":{"access_token":"hermes-session"}}}"#.utf8).write(to: hermes)
        let nous = try await reader.readNous(files: [hermes, fallback], now: now).get()
        #expect(nous.windows.first?.left == 0.4)
        #expect(nous.topUpUSD == 5)
        let clineReading = try await reader.readCline(at: file, now: now).get()
        #expect(clineReading.windows.first?.left == 0.75)
        try Data(#"{"default":{"authToken":"session"}}"#.utf8).write(to: file)
        let buff = try await reader.readCodebuff(at: file, now: now).get()
        #expect(buff.credits == 25)
        #expect(buff.windows.first?.left == 0.5)
        // A 429 from the second endpoint cannot freshen a partial balance.
        try Data(#"{"default":{"authToken":"rate-limit"}}"#.utf8).write(to: file)
        let limited = await reader.readCodebuff(at: file, now: now)
        #expect(limited == .failure(.unavailable(retryAfter: now.addingTimeInterval(300))))
        try Data(#"{"providers":{"cline":{"settings":{"auth":{"accessToken":"rejected"}}}}}"#.utf8).write(to: file)
        #expect(await reader.readCline(at: file, now: now) == .failure(.signedOut))
    }
}

/// Stateless fixture transport; URLProtocol owns its thread-safe request/client state.
nonisolated private final class AdditionalAIUsageProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let auth = request.value(forHTTPHeaderField: "Authorization")
        var status = 500
        var body = "{}"
        switch (request.url?.host(), request.url?.path, request.httpMethod) {
        case ("portal.nousresearch.com", "/api/oauth/account", "GET"):
            status = auth == "Bearer hermes-session" ? 200 : 401
            body = #"{"subscription":{"monthly_credits":100,"credits_remaining":40},"purchased_credits_remaining":5}"#
        case ("api.cline.bot", "/api/v1/users/me/plan/usage-limits", "GET"):
            status = auth == "Bearer workos:session" ? 200 : 401
            body = #"{"success":true,"data":{"limits":[{"type":"weekly","percentUsed":25}]}}"#
        case ("www.codebuff.com", "/api/v1/usage", "POST"):
            // URLSession can expose the body as a stream to URLProtocol.
            var data = request.httpBody
            if let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var buffer = [UInt8](repeating: 0, count: 128)
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count > 0 { data = Data(buffer.prefix(count)) }
            }
            if data == Data(#"{"fingerprintId":"monny-usage"}"#.utf8),
               ["Bearer session", "Bearer rate-limit"].contains(auth) { status = 200 }
            body = #"{"remainingBalance":25}"#
        case ("www.codebuff.com", "/api/user/subscription", "GET"):
            status = auth == "Bearer rate-limit" ? 429 : auth == "Bearer session" ? 200 : 401
            body = #"{"rateLimit":{"weeklyUsed":50,"weeklyLimit":100}}"#
        default: break
        }
        guard let url = request.url, let response = HTTPURLResponse(url: url, statusCode: status,
            httpVersion: nil, headerFields: ["Retry-After": "0"]) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
