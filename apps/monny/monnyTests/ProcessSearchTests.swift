import Testing
@testable import monny

struct ProcessSearchTests {
    private let owner = AppOwner(pid: 10, name: "Studio")

    private var processes: [ProcessUsage] {
        [ProcessUsage(id: 10, name: "Studio", app: owner, cpu: 0.2, memory: 300, power: 1),
         ProcessUsage(id: 11, name: "Render Worker", app: owner, cpu: 0.5, memory: 700, power: 2),
         ProcessUsage(id: 20, name: "Café Agent", app: nil, cpu: 0.1, memory: 50, power: 0.5)]
    }

    @Test(arguments: ["studio", " STUDIO\n", "Render Worker", "worker"])
    func appOrHelperMatchPreservesTheWholeGroup(query: String) throws {
        let rows = ProcessSort.cpu.rows(in: processes, matching: query, limit: 8)
        #expect(rows.count == 1)
        let app = try #require(rows.first)
        #expect(app.id == 10)
        #expect(app.name == "Studio")
        #expect(app.count == 2)
        #expect(abs(app.cpu - 0.7) < 1e-9)
        #expect(app.memory == 1_000)
        #expect(app.power == 3)
    }

    @Test func ungroupedNamesMatchWithoutCaseOrAccentAndUnmatchedQueriesAreEmpty() {
        #expect(ProcessSort.cpu.rows(in: processes, matching: "CAFE", limit: 8).map(\.id) == [20])
        #expect(ProcessSort.cpu.rows(in: processes, matching: "unknown app", limit: 8).isEmpty)
        #expect(ProcessSort.cpu.rows(in: processes, matching: " \n ", limit: 8).count == 2)
    }

    @Test func searchIncludesProcessesBelowTheUnfilteredVisibleRows() throws {
        let all: [ProcessUsage] = (1...20).map { index in
            let name = index == 1 ? "Low-load target" : "Worker \(index)"
            return ProcessUsage(id: Int32(index), name: name, app: nil,
                                cpu: Double(index), memory: Int64(index), power: Double(index))
        }
        #expect(ProcessSort.cpu.rows(in: all, matching: "", limit: 8).contains { $0.id == 1 } == false)
        let result = try #require(ProcessSort.cpu.rows(in: all, matching: "target", limit: 8).first)
        #expect(result.id == 1)
        #expect(result.name == "Low-load target")
    }

    @Test func appNameMatchesEvenWhenOnlyItsHelpersWereSampled() throws {
        let helpers = [ProcessUsage(id: 11, name: "Render Worker", app: owner, cpu: 0.5, memory: 700, power: 2)]
        let result = try #require(ProcessSort.cpu.rows(in: helpers, matching: "studio", limit: 8).first)
        #expect(result.id == owner.pid)
        #expect(result.memory == 700)
    }

    @Test func eachSortKeepsItsOrderWhenSearchingAndLimiting() {
        let all = [ProcessUsage(id: 1, name: "Agent A", app: nil, cpu: 3, memory: 1, power: 2),
                   ProcessUsage(id: 2, name: "Agent B", app: nil, cpu: 2, memory: 3, power: 1),
                   ProcessUsage(id: 3, name: "Agent C", app: nil, cpu: 1, memory: 2, power: 3)]
        #expect(ProcessSort.cpu.rows(in: all, matching: "agent", limit: 2).map(\.id) == [1, 2])
        #expect(ProcessSort.memory.rows(in: all, matching: "agent", limit: 2).map(\.id) == [2, 3])
        #expect(ProcessSort.energy.rows(in: all, matching: "agent", limit: 2).map(\.id) == [3, 1])
        #expect(ProcessSort.cpu.rows(in: all, matching: "agent", limit: 0).isEmpty)
    }

    @Test func aNewSnapshotUpdatesMatchesAndEqualValuesHaveStableOrder() {
        var all = [ProcessUsage(id: 2, name: "Agent", app: nil, cpu: 1, memory: 1, power: 1),
                   ProcessUsage(id: 1, name: "Agent", app: nil, cpu: 1, memory: 1, power: 1)]
        #expect(ProcessSort.cpu.rows(in: all, matching: "agent", limit: 8).map(\.id) == [1, 2])
        all.removeLast()
        #expect(ProcessSort.cpu.rows(in: all, matching: "agent", limit: 8).map(\.id) == [2])
    }
}
