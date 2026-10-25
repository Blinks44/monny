import Darwin
import Foundation
import Synchronization
import Testing
@testable import monny

struct ProcessTerminationTests {
    private func process(_ pid: Int32 = 10, name: String = "Editor", app: AppOwner? = nil,
                         start: UInt64? = 100) -> ProcessUsage {
        ProcessUsage(id: pid, name: name, app: app, cpu: 0, memory: 0, power: 0, startTime: start)
    }

    @Test func protectedAndUnknownTargetsHaveNoActions() {
        for row in [process(0), process(-1), process(1), process(99), process(name: "loginwindow"),
                    process(name: "Monny"), process(start: nil)] {
            #expect(ProcessTerminationRequest(row: row, processes: [], currentPID: 99) == nil)
        }
        let child = process(99, app: AppOwner(pid: 10, name: "Editor"))
        #expect(ProcessTerminationRequest(row: process(app: child.app), processes: [child], currentPID: 99) == nil)
    }

    @Test func gracefulAppQuitDoesNotSignalHelpers() async throws {
        let fixture = Fixture()
        let request = try #require(ProcessTerminationRequest(row: process(), processes: []))
        try await fixture.terminator().terminate(request, force: false)
        #expect(fixture.events.withLock { $0 } == ["app:10:false"])
    }

    @Test(arguments: [false, true])
    func standaloneUsesOnlyTheSelectedSignal(force: Bool) async throws {
        let fixture = Fixture(isApp: false)
        let request = try #require(ProcessTerminationRequest(row: process(), processes: []))
        try await fixture.terminator().terminate(request, force: force)
        #expect(fixture.events.withLock { $0 } == ["app:10:\(force)", "signal:10:\(force ? SIGKILL : SIGTERM)"])
    }

    @Test func forceQuitEndsTheSampledGroupAndSkipsExitedHelpers() async throws {
        let fixture = Fixture()
        let owner = AppOwner(pid: 10, name: "Editor", startTime: 100)
        let request = try #require(ProcessTerminationRequest(row: process(app: owner),
                                      processes: [process(11, app: owner), process(12, app: owner)]))
        try await fixture.terminator().terminate(request, force: true)
        #expect(fixture.events.withLock { $0 } == ["app:10:true", "signal:11:\(SIGKILL)"])
    }

    @Test func refusedAppRequestNeverFallsBackToASignal() async throws {
        let fixture = Fixture(accepts: false)
        let request = try #require(ProcessTerminationRequest(row: process(), processes: []))
        await #expect(throws: ProcessTerminationFailure.rejected) {
            try await fixture.terminator().terminate(request, force: false)
        }
        #expect(fixture.events.withLock { $0 } == ["app:10:false"])
    }

    @Test func recycledPIDAndOtherUsersAreRejectedBeforeAnyAction() async throws {
        let fixture = Fixture()
        let stale = try #require(ProcessTerminationRequest(row: process(start: 99), processes: []))
        await #expect(throws: ProcessTerminationFailure.changed) {
            try await fixture.terminator().terminate(stale, force: true)
        }
        let otherUser = try #require(ProcessTerminationRequest(row: process(13), processes: []))
        await #expect(throws: ProcessTerminationFailure.denied) {
            try await fixture.terminator().terminate(otherUser, force: true)
        }
        #expect(fixture.events.withLock { $0.isEmpty })
    }

    @Test func staleHelperIsNotSignalledAndReportsPartialFailure() async throws {
        let fixture = Fixture()
        let owner = AppOwner(pid: 10, name: "Editor", startTime: 100)
        let request = try #require(ProcessTerminationRequest(row: process(app: owner),
                                                            processes: [process(11, app: owner, start: 99)]))
        await #expect(throws: ProcessTerminationFailure.partial) {
            try await fixture.terminator().terminate(request, force: true)
        }
        #expect(fixture.events.withLock { $0 } == ["app:10:true"])
    }

    @Test func groupedRowsKeepTheOwnersLaunchIdentity() throws {
        let owner = AppOwner(pid: 10, name: "Editor", startTime: 50)
        let row = try #require(ProcessUsage.groupedByApp([process(11, app: owner)]).first)
        #expect(row.id == 10)
        #expect(row.startTime == 50)
    }

    @Test func membersOfAnOlderOwnerWithARecycledPIDAreExcluded() throws {
        let owner = AppOwner(pid: 10, name: "Editor", startTime: 100)
        let olderOwner = AppOwner(pid: 10, name: "Editor", startTime: 50)
        let request = try #require(ProcessTerminationRequest(row: process(app: owner),
                                                            processes: [process(11, app: olderOwner)]))
        #expect(request.helpers.isEmpty)
    }

    @Test(arguments: [false, true])
    func realSignalsEndOnlyATestOwnedChild(force: Bool) async throws {
        let child = Process()
        child.executableURL = URL(filePath: "/bin/sleep")
        child.arguments = ["60"]
        try child.run()
        defer { if child.isRunning { child.terminate() } }
        let start = try #require(ProcessIdentity.readStartTime(of: child.processIdentifier))
        let row = process(child.processIdentifier, name: "sleep", start: start)
        let request = try #require(ProcessTerminationRequest(row: row, processes: []))
        try await ProcessTerminator().terminate(request, force: force)
        child.waitUntilExit()
        #expect(child.terminationReason == .uncaughtSignal)
        #expect(child.terminationStatus == (force ? SIGKILL : SIGTERM))
    }
}

private final class Fixture: Sendable {
    let events = Mutex<[String]>([])
    let isApp: Bool
    let accepts: Bool

    init(isApp: Bool = true, accepts: Bool = true) {
        self.isApp = isApp
        self.accepts = accepts
    }

    func terminator() -> ProcessTerminator {
        ProcessTerminator(client: ProcessTerminationClient(identity: { pid in
            if pid == 12 { throw ProcessTerminationFailure.gone }
            return ProcessIdentity(startTime: 100, userID: pid == 13 ? 501 : 500, name: "Editor")
        }, quitApplication: { [self] pid, force in
            events.withLock { $0.append("app:\(pid):\(force)") }
            return isApp ? accepts : nil
        }, signal: { [self] pid, signal in
            events.withLock { $0.append("signal:\(pid):\(signal)") }
        }), currentPID: 99, userID: 500)
    }
}
