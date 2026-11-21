import Foundation
import Synchronization
import Testing

@testable import monny

struct AntigravityUsageTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func readsEachReportedPoolAndKeepsItsResetAndCadence() throws {
        let reading = try AntigravityUsage.usage(
            summary(
                """
                {"bucketId":"gemini-weekly","remainingFraction":0.75,"resetTime":"2027-01-18T08:00:00Z"},
                {"bucketId":"gemini-5h","remainingFraction":0.5,"resetTime":"2027-01-15T10:30:00.500Z"},
                {"bucketId":"3p-weekly","remainingFraction":0},
                {"bucketId":"3p-5h","remainingFraction":1},
                {"bucketId":"gemini-argon-wtu-weekly","remainingFraction":0.25}
                """), now: now)
        #expect(reading.windows.map(\.left) == [0.75, 0.5, 0, 1, 0.25])
        #expect(reading.windows.map(\.kind) == [.weekly, .session, .weekly, .session, .weekly])
        #expect(reading.windows.map(\.duration) == [604_800, 18_000, 604_800, 18_000, 604_800])
        #expect(reading.windows[0].resetsAt == (try Date("2027-01-18T08:00:00Z", strategy: .iso8601)))
        #expect(reading.windows[1].resetsAt?.timeIntervalSince1970 == 1_800_009_000.5)
        #expect(Set(reading.windows.map(\.id)).count == 5)
        #expect(reading.plan == nil)
    }

    @Test func skipsUnknownDisabledAndMalformedBuckets() throws {
        let reading = try AntigravityUsage.usage(
            summary(
                """
                {"bucketId":"gemini-weekly","remainingFraction":1},
                {"bucketId":"gemini-5h","remainingFraction":true},
                {"bucketId":"3p-weekly","remainingFraction":0,"disabled":true},
                {"bucketId":"3p-5h","remainingFraction":1.5},
                {"bucketId":"gemini-argon-wtu-weekly","resetTime":"2027-01-18T08:00:00Z"},
                {"bucketId":"unknown-weekly","remainingFraction":0.2}
                """), now: now)
        #expect(reading.windows.count == 1)
        #expect(reading.windows.first?.left == 1)
        #expect(reading.windows.first?.kind == .weekly)
        #expect(reading.windows.first?.resetsAt == nil)
        #expect(throws: AIUsageProblem.unavailable(retryAfter: nil)) { try AntigravityUsage.usage(summary(""), now: now) }
        #expect(throws: AIUsageProblem.unavailable(retryAfter: nil)) {
            try AntigravityUsage.usage(Data(#"{"status":"SUCCESS"}"#.utf8), now: now)
        }
    }

    @Test func decodesKeychainCredentialWithBase64PrefixAndPlainJSON() throws {
        let futureUTC = #"{"auth_method":"consumer","token":{"access_token":"tok-utc","expiry":"2027-01-15T08:10:00.876776Z"}}"#
        let wrapped = Data(("go-keyring-base64:" + Data(futureUTC.utf8).base64EncodedString() + "\n").utf8)
        #expect(try AntigravityUsage.token(wrapped, now: now) == "tok-utc")

        let futureOffset = #"{"token":{"access_token":"tok-offset","expiry":"2027-01-15T11:10:00.123456+03:00"}}"#
        #expect(try AntigravityUsage.token(Data(futureOffset.utf8), now: now) == "tok-offset")
    }

    @Test func rejectsMissingAndExpiredCredentials() {
        #expect(throws: AIUsageProblem.signedOut) { try AntigravityUsage.token(Data(), now: now) }
        #expect(throws: AIUsageProblem.signedOut) {
            try AntigravityUsage.token(Data("go-keyring-base64:%%%".utf8), now: now)
        }
        #expect(throws: AIUsageProblem.signedOut) {
            try AntigravityUsage.token(Data(#"{"token":{"access_token":"   "}}"#.utf8), now: now)
        }
        // Within the 60-second safety margin, zero Go time, and unparseable expiry all report expired.
        for expiry in ["2027-01-15T08:00:30Z", "0001-01-01T00:00:00Z", "not-a-date"] {
            let payload = Data(#"{"token":{"access_token":"tok-1","expiry":"\#(expiry)"}}"#.utf8)
            #expect(throws: AIUsageProblem.expired) { try AntigravityUsage.token(payload, now: now) }
        }
    }

    @Test func fetchesQuotaSummaryDirectlyWithExpectedHeadersAndHandlesErrors() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AntigravityFixtureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let reader = AIUsageReader(session: session)
        let refreshes = Mutex(0)
        let countRefresh: @Sendable () async -> Void = { refreshes.withLock { $0 += 1 } }

        let validData = credential("valid-token")
        let valid = try await reader.readAntigravity(
            readCredential: { validData }, refreshCredential: countRefresh, now: now
        ).get()
        #expect(valid.windows.map(\.left) == [0.75, 0.5])
        #expect(valid.recoveryContext != nil)
        #expect(refreshes.withLock { $0 } == 0)

        let rejectedData = credential("rejected")
        let rejected = await reader.readAntigravity(
            readCredential: { rejectedData }, refreshCredential: countRefresh, now: now)
        #expect(rejected == .failure(.signedOut))

        let limitedData = credential("rate-limit")
        let limited = await reader.readAntigravity(
            readCredential: { limitedData }, refreshCredential: countRefresh, now: now)
        if case .failure(.unavailable(let retryAfter)) = limited {
            #expect((retryAfter?.timeIntervalSince(now) ?? 0) >= 300)
        } else {
            Issue.record("Expected 429 cooldown")
        }
        #expect(refreshes.withLock { $0 } == 0)
    }

    @Test func refreshesExpiredTokenViaCLIOnlyWhenExpiredAndHonorsCooldown() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AntigravityFixtureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let reader = AIUsageReader(session: session)

        let expiredData = credential("stale-token", expiry: "2027-01-15T08:00:30Z")
        let freshData = credential("valid-token", expiry: "2027-01-15T09:00:00Z")

        // Signed-out or missing Keychain credentials never invoke the CLI refresh.
        let refreshes = Mutex(0)
        let signedOut = await reader.readAntigravity(
            readCredential: { nil },
            refreshCredential: { refreshes.withLock { $0 += 1 } },
            now: now)
        #expect(signedOut == .failure(.signedOut))
        #expect(refreshes.withLock { $0 } == 0)

        // When the token is expired, one CLI refresh updates the Keychain entry and succeeds.
        let stored = Mutex<Data?>(expiredData)
        let refreshed = try await reader.readAntigravity(
            readCredential: { stored.withLock { $0 } },
            refreshCredential: {
                refreshes.withLock { $0 += 1 }
                stored.withLock { $0 = freshData }
            },
            now: now
        ).get()
        #expect(refreshed.windows.map(\.left) == [0.75, 0.5])
        #expect(refreshes.withLock { $0 } == 1)

        // If a subsequent token is still expired inside the 15-minute cooldown, the CLI is not respawned.
        stored.withLock { $0 = expiredData }
        let throttled = await reader.readAntigravity(
            readCredential: { stored.withLock { $0 } },
            refreshCredential: { refreshes.withLock { $0 += 1 } },
            now: now.addingTimeInterval(5 * 60))
        #expect(throttled == .failure(.expired))
        #expect(refreshes.withLock { $0 } == 1)

        // After the cooldown elapses, the CLI refresh is allowed again.
        let afterCooldown = await reader.readAntigravity(
            readCredential: { stored.withLock { $0 } },
            refreshCredential: { refreshes.withLock { $0 += 1 } },
            now: now.addingTimeInterval(AIUsageReader.antigravityRefreshCooldown))
        #expect(afterCooldown == .failure(.expired))
        #expect(refreshes.withLock { $0 } == 2)
    }

    @Test func agyCommandEnvironmentDisablesAutoUpdateAndInteractiveBrowser() {
        let env = AIUsageCommand.environment(for: URL(filePath: "/opt/homebrew/bin/agy"))
        #expect(env["AGY_CLI_DISABLE_AUTO_UPDATE"] == "true")
        #expect(env["AGY_CLI_NONINTERACTIVE_HEADLESS"] == "1")
        #expect(env["BROWSER"] == "/usr/bin/false")
        #expect(env["CI"] == "1")
        #expect(env["TERM"] == "dumb")
    }

    @Test @MainActor func historiesAndAlertsKeepTheModelPoolsDistinct() throws {
        let reading = try AntigravityUsage.usage(
            summary(
                """
                {"bucketId":"gemini-weekly","remainingFraction":0.75},
                {"bucketId":"gemini-5h","remainingFraction":0.5},
                {"bucketId":"3p-weekly","remainingFraction":0},
                {"bucketId":"gemini-argon-wtu-weekly","remainingFraction":0}
                """), now: now)
        let monitor = AIUsageMonitor(installed: [.antigravity], states: [.antigravity: .init(usage: reading)])
        #expect(monitor.historyValues(at: now) == [.antigravityWeekly: 0.75, .antigravitySession: 0.5])
        var alerts = AILowWindows()
        #expect(alerts.update(.antigravity, usage: reading, now: now).count == 2)
        #expect(alerts.update(.antigravity, usage: reading, now: now).isEmpty)
    }

    private func credential(_ token: String, expiry: String = "2027-01-15T09:00:00Z") -> Data {
        let json = #"{"auth_method":"consumer","token":{"access_token":"\#(token)","expiry":"\#(expiry)"}}"#
        return Data(("go-keyring-base64:" + Data(json.utf8).base64EncodedString()).utf8)
    }

    private func summary(_ buckets: String) -> Data {
        Data(#"{"groups":[{"displayName":"Gemini Models","buckets":[\#(buckets)]}]}"#.utf8)
    }
}

/// Stateless fixture transport; it never contacts Google or reads real Keychain credentials.
nonisolated private final class AntigravityFixtureProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        #expect(request.url?.absoluteString == "https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Cookie") == nil)
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == AntigravityUsage.userAgent)
        let body = requestBody(of: request)
        #expect(body == Data("{}".utf8))

        let auth = request.value(forHTTPHeaderField: "Authorization")
        let status = auth == "Bearer rejected" ? 403 : auth == "Bearer rate-limit" ? 429 : 200
        let payload =
            #"{"groups":[{"buckets":[{"bucketId":"gemini-weekly","remainingFraction":0.75},{"bucketId":"3p-5h","remainingFraction":0.5}]}]}"#
        guard let url = request.url,
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: ["Retry-After": "0"])
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(payload.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private func requestBody(of request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
