import Foundation
import Testing
@testable import monny

struct BusyProcessesTests {
    private let start = Date(timeIntervalSinceReferenceDate: 0)

    private func process(_ pid: Int32, cpu: Double, launch: UInt64 = 100, name: String = "node") -> ProcessUsage {
        ProcessUsage(id: pid, name: name, cpu: cpu, memory: 0, power: 0, startTime: launch)
    }

    @Test func aProcessAppearsAfterAMinuteOfSustainedLoadWithTheObservedDuration() throws {
        var busy = BusyProcesses()
        busy.update([process(10, cpu: 0.99)], now: start)
        #expect(busy.attention(in: [process(10, cpu: 0.99)], now: start.addingTimeInterval(59), currentPID: 1).isEmpty)
        busy.update([process(10, cpu: 0.95)], now: start.addingTimeInterval(840))
        let item = try #require(busy.attention(in: [process(10, cpu: 0.95)], now: start.addingTimeInterval(840), currentPID: 1).first)
        #expect(item.process.id == 10)
        #expect(item.duration == 840)
    }

    @Test func dippingBelowTheThresholdOrAnUnreadPassEndsTheEpisode() {
        var busy = BusyProcesses()
        busy.update([process(10, cpu: 0.9)], now: start)
        busy.update([process(10, cpu: 0.2)], now: start.addingTimeInterval(30))
        busy.update([process(10, cpu: 0.9)], now: start.addingTimeInterval(60))
        #expect(busy.attention(in: [process(10, cpu: 0.9)], now: start.addingTimeInterval(100), currentPID: 1).isEmpty)
        busy.update([], now: start.addingTimeInterval(200))
        busy.update([process(10, cpu: 0.9)], now: start.addingTimeInterval(210))
        #expect(busy.attention(in: [process(10, cpu: 0.9)], now: start.addingTimeInterval(260), currentPID: 1).isEmpty)
    }

    @Test func aRecycledPIDStartsAgainAndProtectedProcessesNeverShow() {
        var busy = BusyProcesses()
        busy.update([process(10, cpu: 0.9), process(99, cpu: 0.9), process(20, cpu: 0.9, name: "loginwindow")], now: start)
        busy.update([process(10, cpu: 0.9, launch: 200), process(99, cpu: 0.9), process(20, cpu: 0.9, name: "loginwindow")],
                    now: start.addingTimeInterval(120))
        let now = start.addingTimeInterval(170)
        #expect(busy.attention(in: [process(10, cpu: 0.9, launch: 200), process(99, cpu: 0.9),
                                    process(20, cpu: 0.9, name: "loginwindow")], now: now, currentPID: 99).isEmpty)
    }

    @Test func atMostThreeLongestBusyProcessesAreShown() {
        var busy = BusyProcesses()
        let all = (1...5).map { process(Int32($0 + 10), cpu: 0.9) }
        for index in all.indices { busy.update(Array(all.prefix(index + 1)), now: start.addingTimeInterval(Double(index) * 10)) }
        let shown = busy.attention(in: all, now: start.addingTimeInterval(500), currentPID: 1)
        #expect(shown.map(\.process.id) == [11, 12, 13])
    }
}
