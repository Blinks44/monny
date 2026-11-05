import Foundation
import Testing

@testable import monny

struct ProcessNetworkTests {
    @Test func localCommandIsBoundedAndCancellable() async {
        let started = ContinuousClock.now
        let timedOut = await LocalCommand.run(URL(filePath: "/bin/sleep"), arguments: ["5"], timeout: .milliseconds(100))
        #expect(timedOut == nil)
        #expect(ContinuousClock.now - started < .seconds(2))
        let command = Task { await LocalCommand.run(URL(filePath: "/bin/sleep"), arguments: ["5"]) }
        command.cancel()
        #expect(await command.value == nil)
    }

    @Test func usesDeltaSampleAndLastDotForPID() throws {
        let values = try #require(
            ProcessNetworkReader.parse(
                """
                ,bytes_in,bytes_out,
                app.helper.42,999999,888888,
                kernel_task.0,10,20,
                ,bytes_in,bytes_out,
                app.helper.42,5000000,100000,
                kernel_task.0,0,0,
                """))
        #expect(values[42] == NetworkRates(download: 5_000_000, upload: 100_000))
        #expect(values[0] == nil)
    }

    @Test func columnsCanMoveAndFirstSampleIsNeverARate() {
        #expect(
            ProcessNetworkReader.parse(",bytes_out,bytes_in,\napp.42,12,30,\n,bytes_out,bytes_in,\napp.42,2,5,\n")?[42]
                == NetworkRates(download: 5, upload: 2))
        #expect(ProcessNetworkReader.parse(",bytes_in,bytes_out,\napp.42,123,456,\n") == nil)
        #expect(ProcessNetworkReader.parse("nettop: NStatManagerCreate failed") == nil)
        #expect(ProcessNetworkReader.parse(",bytes_in,bytes_out,\n,bytes_in,bytes_out,\n") == [:])
    }

    @Test func commasInProcessNamesKeepTheirColumns() {
        #expect(
            ProcessNetworkReader.parse(",bytes_in,bytes_out,\n,bytes_in,bytes_out,\nFoo, Inc.42,7,3,\n")?[42]
                == NetworkRates(download: 7, upload: 3))
    }

    @Test(arguments: ["-1,20", "1 KiB,20", "bad,20", "20", "18446744073709551616,20"])
    func malformedDataStaysUnavailable(_ fields: String) {
        #expect(ProcessNetworkReader.parse(",bytes_in,bytes_out,\n,bytes_in,bytes_out,\napp.42,\(fields),\n") == nil)
    }

    @Test func groupsHelpersAndSortsByBothDirections() throws {
        let owner = AppOwner(pid: 10, name: "Browser")
        let rows = [
            ProcessUsage(
                id: 10, name: "Browser", app: owner, cpu: 0, memory: 1, power: 0,
                network: NetworkRates(download: 100, upload: 200)),
            ProcessUsage(
                id: 11, name: "Worker", app: owner, cpu: 0, memory: 1, power: 0,
                network: NetworkRates(download: 500, upload: 0)),
            ProcessUsage(
                id: 20, name: "Uploader", app: nil, cpu: 0, memory: 1, power: 0,
                network: NetworkRates(download: 0, upload: 900)),
            ProcessUsage(id: 30, name: "Unknown", app: nil, cpu: 0, memory: 1, power: 0),
        ]
        #expect(ProcessSort.network.rows(in: rows, matching: "", limit: 9).map(\.id) == [20, 10, 30])
        let grouped = try #require(ProcessSort.network.rows(in: rows, matching: "Worker", limit: 9).first)
        #expect(grouped.count == 2)
        #expect(grouped.network == NetworkRates(download: 600, upload: 200))
        // A helper without a reading yet leaves the app's known traffic visible.
        var missing = rows
        missing[1].network = nil
        #expect(ProcessUsage.groupedByApp(missing).first { $0.id == 10 }?.network == NetworkRates(download: 100, upload: 200))
        missing[0].network = nil
        #expect(ProcessUsage.groupedByApp(missing).first { $0.id == 10 }?.network == nil)
    }

    @Test func dailyValuesKeepMissingDaysSeparateFromZero() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let today = calendar.startOfDay(for: now)
        var tier = HistoryTier(span: 7 * 86400, step: 600)
        tier.add([.download: 10, .upload: 2], at: today.addingTimeInterval(-86400 + 3600))
        tier.add([.download: 0, .upload: 0], at: today.addingTimeInterval(3600))
        let days = DailyTraffic.days(in: tier, now: now, calendar: calendar)
        #expect(days.count == 7)
        #expect(days[0].total == nil)
        #expect(days[5].download == 6000)
        #expect(days[5].upload == 1200)
        #expect(days[5].total == 7200)
        #expect(days[6].total == 0)
    }
}
