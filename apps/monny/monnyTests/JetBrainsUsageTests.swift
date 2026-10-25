import Foundation
import Testing
@testable import monny

struct JetBrainsUsageTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let prefix = "2026-10-20 10:00:00,000 [123] INFO - "
    private let monthly = "QuotaDetails(current=250000, maximum=1000000, available=750000)"

    private func xml(current: Any = "250000", maximum: Any = "1000000", refill: Bool = true) throws -> Data {
        let quota: [String: Any] = ["type": "Available", "current": "250000", "maximum": "1500000",
                                  "until": "2030-01-01T00:00:00Z",
                                  "tariffQuota": ["current": current, "maximum": maximum, "available": "750000"],
                                  "topUpQuota": ["current": "0", "maximum": "500000", "available": "375000"]]
        func escaped(_ value: [String: Any]) throws -> String {
            String(decoding: try JSONSerialization.data(withJSONObject: value), as: UTF8.self)
                .replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;")
        }
        let reset = refill ? try "<option name=\"nextRefill\" value=\"\(escaped(["type": "Known", "next": "2026-11-20T10:00:00Z", "tariff": ["duration": "PT720H"]]))\"/>" : ""
        return Data(try "<application><component name=\"AIAssistantQuotaManager2\"><option name=\"quotaInfo\" value=\"\(escaped(quota))\"/>\(reset)</component></application>".utf8)
    }

    private var flat: String {
        prefix + JetBrainsQuotaLog.quotaMarker + "Available(current=250000, maximum=1500000, until=2030-01-01T00:00:00Z, tariffQuota=\(monthly), topUpQuota=QuotaDetails(current=0, maximum=500000, available=375000))"
    }

    private var refill: String {
        prefix + JetBrainsQuotaLog.refillMarker + "Known(next=2026-11-20T10:00:00Z, tariff=QuotaRefillInfoTariff(amount=1000000, duration=30d))"
    }

    @Test func xmlKeepsMonthlyAndTopUpsSeparateAndUsesRefillRatherThanExpiry() throws {
        let quota = try #require(JetBrainsQuota.xml(xml(), date: now))
        #expect(quota.used == 0.25)
        #expect(quota.topUpCredits == 3.75)
        #expect(quota.duration == 30 * 86_400.0)
        #expect(quota.reset == ClaudeUsageResponse.date(from: "2026-11-20T10:00:00Z"))
        #expect(quota.date == now)
        #expect(quota.usage(source: "PhpStorm 2026.2").plan == nil)
    }

    @Test(arguments: ["bad", "NaN", "Infinity", "-1"])
    func invalidAmountsNeverBecomeZeroOrBorrowTheTotal(value: String) throws {
        #expect(try JetBrainsQuota.xml(xml(current: value), date: now) == nil)
        #expect(try JetBrainsQuota.xml(xml(maximum: value), date: now) == nil)
        #expect(try JetBrainsQuota.xml(xml(maximum: "0"), date: now) == nil)
    }

    @Test func missingRefillDisablesResetPaceAndForecast() throws {
        let quota = try #require(JetBrainsQuota.xml(xml(refill: false), date: now))
        let window = try #require(quota.usage(source: "IDE").windows.first)
        #expect(window.resetsAt == nil)
        #expect(window.timeLeft(at: now) == nil)
        #expect(window.runsOut(at: now) == nil)
    }

    @Test func numbersNestedAmountsAndInvalidTopUps() throws {
        let valid: [String: Any] = ["tariffQuota": ["current": ["amount": 25], "maximum": ["amount": "100"]]]
        #expect(JetBrainsQuota.decode(valid, date: now)?.used == 0.25)
        #expect(JetBrainsQuota.number(true) == nil)
        #expect(JetBrainsQuota.decode(["current": "25", "maximum": "100"], date: now) == nil)
        #expect(JetBrainsQuota.decode(["current": "25", "maximum": "100"], date: now, allowsLegacy: true)?.used == 0.25)
        let mixed: [String: Any] = ["current": "25", "maximum": "100", "topUpQuota": ["maximum": "50"]]
        #expect(JetBrainsQuota.decode(mixed, date: now, allowsLegacy: true) == nil)
        var extra = valid
        extra["topUpQuota"] = ["current": "25", "maximum": "100"]
        #expect(JetBrainsQuota.decode(extra, date: now)?.topUpCredits == nil)
    }

    @Test func xmlRejectsExternalDocumentsAndMissingState() {
        let dtd = Data("<!DOCTYPE application SYSTEM 'file:///not-read'><application/>".utf8)
        #expect(JetBrainsQuota.xml(dtd, date: now) == nil)
        #expect(JetBrainsQuota.xml(Data("<application/>".utf8), date: now) == nil)
        #expect(JetBrainsQuota.xml(Data(repeating: 32, count: JetBrainsUsageReader.xmlByteLimit + 1), date: now) == nil)
    }

    @Test func flatAndWrappedLogsWithTheirOwnRefill() throws {
        let flatQuota = try #require(JetBrainsQuotaLog.latest(in: refill + "\n" + flat))
        #expect(flatQuota.used == 0.25)
        #expect(flatQuota.topUpCredits == 3.75)
        #expect(flatQuota.duration == 30 * 86_400.0)
        let wrapped = prefix + JetBrainsQuotaLog.quotaMarker + "Available(quota=JbaiQuota(license=TEST, quotaID=JbaiQuotaId(quotaId=TEST, userId=null), tariffQuota=Details(current=250000, maximum=1000000, available=750000)))"
        let wrappedRefill = prefix + JetBrainsQuotaLog.refillMarker + "Known(refill=JbaiQuotaRefill(tariff=JbaiQuotaTariff(amount=1000000, period=30d), next=2026-11-20T10:00:00Z, last=2026-10-21T10:00:00Z))"
        let quota = try #require(JetBrainsQuotaLog.latest(in: wrapped + "\n" + wrappedRefill))
        #expect(quota.used == flatQuota.used)
        #expect(quota.reset == flatQuota.reset)
        #expect(quota.duration == flatQuota.duration)
    }

    @Test func junieHasNoInventedResetAndDisabledAssistantErrorsAreIgnored() throws {
        let json = #"{"license":"TEST","until":1893456000000,"tariffQuota":{"current":{"amount":"500000"},"maximum":{"amount":1000000},"available":{"amount":"500000"}}}"#
        let junie = prefix + JetBrainsQuotaLog.junieMarker + json
        let disabled = prefix + JetBrainsQuotaLog.quotaMarker + JetBrainsQuotaLog.disabledState + ": AirMigration)"
        let quota = try #require(JetBrainsQuotaLog.latest(in: flat + "\n" + junie + "\n" + disabled))
        #expect(quota.used == 0.5)
        #expect(quota.reset == nil)
        #expect(quota.duration == 0)
        #expect(String(describing: quota).contains("TEST") == false)
    }

    @Test(arguments: ["Unknown", "Error(exception=network)", "Available(", "Available(tariffQuota=Unknown())"])
    func latestUnknownQuotaNeverRevivesAnOlderAccount(state: String) {
        #expect(JetBrainsQuotaLog.latest(in: flat + "\n" + prefix + JetBrainsQuotaLog.quotaMarker + state) == nil)
    }

    @Test func timestampUsesTheSourceTimeZoneAndKnownPeriodsOnly() throws {
        let date = try #require(JetBrainsQuotaLog.timestamp("2026-10-20 10:00:00,123", timeZone: TimeZone(secondsFromGMT: 0) ?? .current))
        let expected = try #require(ClaudeUsageResponse.date(from: "2026-10-20T10:00:00.123Z"))
        #expect(abs(date.timeIntervalSince(expected)) < 0.001)
        #expect(JetBrainsQuotaLog.timestamp("not a timestamp") == nil)
        #expect(JetBrainsQuota.seconds("30d") == 30 * 86_400.0)
        #expect(JetBrainsQuota.seconds("PT720H") == 30 * 86_400.0)
        #expect(JetBrainsQuota.seconds("P30D") == 30 * 86_400.0)
        #expect(JetBrainsQuota.seconds("P1M") == nil)
        #expect(JetBrainsQuota.seconds("-1d") == nil)
    }

    @Test func boundedTailDropsPartialLinesAndRejectsUnfinishedRecords() throws {
        let fixture = try SourceFixture()
        let record = flat + "\n"
        try Data((String(repeating: "x", count: 100) + "\n" + record).utf8).write(to: fixture.log)
        let tail = try #require(JetBrainsUsageReader.logTail(fixture.log, limit: record.utf8.count + 2))
        #expect(tail == record)
        try Data(flat.utf8).write(to: fixture.log)
        #expect(JetBrainsUsageReader.logTail(fixture.log) == nil)
    }

    @Test func selectsSameIDEOnlyAndKeepsTheOriginalReadingDate() throws {
        let fixture = try SourceFixture()
        let otherFixture = try SourceFixture()
        let logDate = try #require(JetBrainsQuotaLog.timestamp("2026-10-20 10:00:00,000"))
        let xmlDate = logDate.addingTimeInterval(-120)
        try xml().write(to: fixture.xml)
        try Data((flat + "\n").utf8).write(to: fixture.log)
        try Data((flat.replacingOccurrences(of: "current=250000", with: "current=500000") + "\n").utf8).write(to: otherFixture.log)
        let selected = fixture.source(xmlDate: xmlDate, logDate: logDate)
        let other = JetBrainsUsageReader.Source(name: "Other IDE", xml: otherFixture.xml,
                                               log: otherFixture.log, xmlDate: nil, logDate: now)
        let usage = try JetBrainsUsageReader.read(sources: [selected, other], now: now).get()
        #expect(usage.date == logDate)
        #expect(usage.source == selected.name)
        #expect(usage.windows.first?.used == 0.25)
        #expect(usage.isStale(at: now))
        #expect(usage.windows.first?.resetsAt == nil)
        #expect(try JetBrainsUsageReader.read(sources: [fixture.source(xmlDate: now, logDate: logDate)], now: now).get().date == now)
    }

    @Test func discoveryIsBoundedAndDoesNotNeedQuotaOrAnAccount() throws {
        let fixture = try SourceFixture()
        let sources = JetBrainsUsageReader.sources(home: fixture.home)
        #expect(sources.count == 1)
        #expect(sources.first?.name == "PhpStorm 2026.2")
        #expect(sources.first?.xmlDate == nil)
        #expect(JetBrainsUsageReader.read(sources: sources, now: now) == .failure(.localDataMissing))
    }

    @Test func aLogWithoutQuotaIsSetupNeededRatherThanSignedOut() throws {
        let fixture = try SourceFixture()
        try Data((refill + "\n").utf8).write(to: fixture.log)
        #expect(JetBrainsUsageReader.read(sources: [fixture.source(xmlDate: nil, logDate: now)], now: now)
            == .failure(.localDataMissing))
    }

    @Test func aFutureDatedCacheCannotStayFreshForever() throws {
        let fixture = try SourceFixture()
        try xml().write(to: fixture.xml)
        #expect(JetBrainsUsageReader.read(sources: [fixture.source(xmlDate: now.addingTimeInterval(3_600), logDate: nil)], now: now)
            == .failure(.unavailable(retryAfter: nil)))
    }

    @Test func readFallsBackToXMLForMalformedOrIncompleteLatestLog() throws {
        let fixture = try SourceFixture()
        try xml().write(to: fixture.xml)
        try Data((flat + "\n" + prefix + JetBrainsQuotaLog.junieMarker + "bad\n").utf8).write(to: fixture.log)
        let usage = try JetBrainsUsageReader.read(sources: [fixture.source(xmlDate: now, logDate: now)], now: now).get()
        #expect(usage.date == now)
        #expect(usage.windows.first?.duration == 30 * 86_400.0)
        #expect(usage.windows.first?.resetsAt != nil)
    }

    @MainActor @Test func staleAndResetLocalQuotaStayOutOfHistoryAndResetAlerts() {
        let window = AIQuotaWindow(kind: .monthly, used: 0.95, resetsAt: now.addingTimeInterval(-1), duration: 30 * 86_400)
        let usage = AIUsage(windows: [window], date: now)
        let monitor = AIUsageMonitor(installed: [.jetBrains], states: [.jetBrains: .init(usage: usage)])
        #expect(monitor.historyValues(at: now).isEmpty)
        var alerts = AILowWindows()
        #expect(alerts.update(.jetBrains, usage: usage, now: now).isEmpty)
        let fresh = AIUsage(windows: [AIQuotaWindow(kind: .monthly, used: 0.3, duration: 0)], date: now)
        let active = AIUsageMonitor(installed: [.jetBrains], states: [.jetBrains: .init(usage: fresh)])
        #expect(active.historyValues(at: now) == [.jetBrainsMonthly: 0.7])
        #expect(active.historyValues(at: now.addingTimeInterval(3_600)).isEmpty)
        let missing = AIUsageMonitor(installed: [.jetBrains], states: [.jetBrains: .init(usage: fresh, problem: .localDataMissing)])
        #expect(missing.historyValues(at: now).isEmpty)
    }

    @Test func cacheRetainsTheLocalDateAndRemainsCompatibleWithOlderReadings() throws {
        let usage = AIUsage(windows: [], date: now, topUpCredits: 3.75, source: "PhpStorm 2026.2")
        #expect(try JSONDecoder().decode(AIUsage.self, from: JSONEncoder().encode(usage)) == usage)
        let old = Data(#"{"windows":[],"date":0}"#.utf8)
        let decoded = try JSONDecoder().decode(AIUsage.self, from: old)
        #expect(decoded.topUpCredits == nil)
        #expect(decoded.source == nil)
    }

    @Test func aNewMonthlyResetStartsANewLowQuotaEpisode() {
        var alerts = AILowWindows()
        let first = AIUsage(windows: [AIQuotaWindow(kind: .monthly, used: 0.95, resetsAt: now.addingTimeInterval(60), duration: 2_592_000)], date: now)
        var next = first
        next.windows[0].resetsAt = now.addingTimeInterval(2_592_060)
        #expect(alerts.update(.jetBrains, usage: first, now: now).count == 1)
        #expect(alerts.update(.jetBrains, usage: first, now: now).isEmpty)
        #expect(alerts.update(.jetBrains, usage: next, now: now).count == 1)
    }
}

private final class SourceFixture {
    let home = FileManager.default.temporaryDirectory.appending(path: "monny-jetbrains-\(UUID().uuidString)")
    var xml: URL { home.appending(path: "Library/Application Support/JetBrains/PhpStorm2026.2/options/AIAssistantQuotaManager2.xml") }
    var log: URL { home.appending(path: "Library/Logs/JetBrains/PhpStorm2026.2/idea.log") }

    init() throws {
        try FileManager.default.createDirectory(at: xml.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: log.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    deinit { try? FileManager.default.removeItem(at: home) }

    func source(xmlDate: Date?, logDate: Date?) -> JetBrainsUsageReader.Source {
        .init(name: "PhpStorm 2026.2", xml: xml, log: log, xmlDate: xmlDate, logDate: logDate)
    }
}
