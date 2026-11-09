import Foundation
import Testing

@testable import monny

struct AIRecoveryTests {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    private func usage(_ used: Double, at date: Date, context: String? = "session-a", reset: Date? = nil) -> AIUsage {
        AIUsage(windows: [.init(kind: .session, used: used, resetsAt: reset, duration: 18000)], date: date, recoveryContext: context)
    }

    @Test func firstReadingNeverNotifiesAndRecoveryFiresOnce() {
        var monitor = AIRecoveredWindows()
        #expect(monitor.update(.codex, usage: usage(0, at: now), now: now).isEmpty)
        #expect(monitor.update(.codex, usage: usage(1, at: now), now: now).isEmpty)
        let later = now.addingTimeInterval(300)
        #expect(monitor.update(.codex, usage: usage(0.2, at: later), now: later).count == 1)
        #expect(monitor.update(.codex, usage: usage(0.2, at: later), now: later).isEmpty)
    }

    @Test func resetTimerStaleReadingAndAccountSwitchDoNotConfirmRecovery() {
        var monitor = AIRecoveredWindows()
        _ = monitor.update(.claude, usage: usage(1, at: now), now: now)
        let later = now.addingTimeInterval(1800)
        #expect(monitor.update(.claude, usage: usage(0, at: now), now: later).isEmpty)
        #expect(monitor.update(.claude, usage: usage(0, at: later, reset: now), now: later).isEmpty)
        #expect(monitor.update(.claude, usage: usage(0, at: later, context: "session-b"), now: later).isEmpty)
    }

    @Test func optOutAndUnknownIdentityCancelPendingEpisodes() {
        var monitor = AIRecoveredWindows()
        _ = monitor.update(.codex, usage: usage(1, at: now), now: now)
        monitor.retain([])
        let later = now.addingTimeInterval(300)
        #expect(monitor.update(.codex, usage: usage(0, at: later), now: later).isEmpty)
        _ = monitor.update(.codex, usage: usage(1, at: later), now: later)
        #expect(monitor.update(.codex, usage: usage(0, at: later, context: nil), now: later).isEmpty)
    }

    @Test func sessionContextIsNeverSaved() throws {
        let data = try JSONEncoder().encode(usage(1, at: now))
        #expect(try JSONDecoder().decode(AIUsage.self, from: data).recoveryContext == nil)
    }
}
