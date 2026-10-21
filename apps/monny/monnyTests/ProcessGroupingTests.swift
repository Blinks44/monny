import Testing
@testable import monny

/// Helpers and web content roll up into their app; system processes stay single rows.
struct ProcessGroupingTests {
    private let chrome = AppOwner(pid: 10, name: "Google Chrome")

    @Test func helpersSumIntoTheirApp() throws {
        let processes = [
            ProcessUsage(id: 10, name: "Google Chrome", app: chrome, cpu: 0.2, memory: 300, power: 1),
            ProcessUsage(id: 11, name: "Google Chrome Helper (Renderer)", app: chrome, cpu: 0.5, memory: 700, power: 2),
            ProcessUsage(id: 20, name: "WindowServer", app: nil, cpu: 0.1, memory: 50, power: 0.5),
        ]
        let groups = ProcessUsage.groupedByApp(processes)
        #expect(groups.count == 2)
        let app = try #require(groups.first { $0.id == 10 })
        #expect(app.name == "Google Chrome")
        #expect(app.count == 2)
        #expect(abs(app.cpu - 0.7) < 1e-9)
        #expect(app.memory == 1_000)
        #expect(app.power == 3)
        let system = try #require(groups.first { $0.id == 20 })
        #expect(system.count == 1)
        #expect(system.app == nil)
    }

    /// The owner can be unreadable (or not sampled yet); its helpers still form one row under its PID.
    @Test func groupWithoutItsMainProcessUsesTheOwner() throws {
        let processes = [
            ProcessUsage(id: 11, name: "Helper", app: chrome, cpu: 0.1, memory: 10, power: 0),
            ProcessUsage(id: 12, name: "Helper", app: chrome, cpu: 0.1, memory: 10, power: 0),
        ]
        let group = try #require(ProcessUsage.groupedByApp(processes).first)
        #expect(group.id == 10)
        #expect(group.name == "Google Chrome")
        #expect(group.count == 2)
    }

    @Test func appBundleIsTheOutermostApp() {
        let helper = "/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Helpers/Google Chrome Helper.app/Contents/MacOS/Google Chrome Helper"
        #expect(ProcessReader.appBundle(in: helper) == "/Applications/Google Chrome.app")
        #expect(ProcessReader.appBundle(in: "/usr/libexec/trustd") == nil)
    }
}
