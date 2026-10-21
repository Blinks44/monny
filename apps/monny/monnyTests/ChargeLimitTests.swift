import Synchronization
import Testing
@testable import monny

struct ChargeLimitTests {
    private final class Fixture: Sendable {
        struct State: Sendable {
            var snapshot = NativeChargeLimit.Snapshot(availableLimits: [80,85,90,95,100], configuredLimit: 85, enabled: false)
            var events: [String] = []
            var available = true
            var failSetter = false
        }
        let state = Mutex(State())
        var operations: NativeChargeLimitStore.Operations {
            .init(read: { self.state.withLock { $0.available ? $0.snapshot : nil } }, setLimit: { limit in
                self.state.withLock { s in s.events.append("limit"); if s.failSetter { return false }; s.snapshot.configuredLimit = limit; return true }
            }, setEnabled: { enabled in
                self.state.withLock { s in s.events.append("enabled"); s.snapshot.enabled = enabled; s.snapshot.configuredLimit = 80; return true }
            })
        }
    }

    @Test func enablingPrecedesTargetBecauseSystemEnableResetsTheLimit() async throws {
        let f = Fixture(); let store = NativeChargeLimitStore(operations: f.operations)
        let result = try await store.set(limit: 90, enabled: true)
        #expect(result.enabled && result.configuredLimit == 90)
        #expect(f.state.withLock { $0.events } == ["enabled", "limit"])
        _ = try await store.set(limit: 90, enabled: true)
        #expect(f.state.withLock { $0.events } == ["enabled", "limit"])
        _ = await store.read()
        #expect(f.state.withLock { $0.events } == ["enabled", "limit"])
    }

    @Test func disablingDoesNotWriteAnIrrelevantTarget() async throws {
        let f = Fixture(); f.state.withLock { $0.snapshot.enabled = true }
        let store = NativeChargeLimitStore(operations: f.operations)
        #expect(try await !store.set(limit: 85, enabled: false).enabled)
        #expect(f.state.withLock { $0.events } == ["enabled"])
    }

    @Test(arguments: ["unavailable", "invalidTarget", "failedWrite"])
    func unknownOrFailedOperationsNeverClaimSuccess(condition: String) async throws {
        let f = Fixture()
        f.state.withLock { s in
            s.snapshot.enabled = true
            s.available = condition != "unavailable"
            s.failSetter = condition == "failedWrite"
        }
        let store = NativeChargeLimitStore(operations: f.operations)
        await #expect(throws: (any Error).self) { try await store.set(limit: condition == "invalidTarget" ? 60 : 90, enabled: true) }
        #expect(f.state.withLock { $0.events.count } == (condition == "failedWrite" ? 1 : 0))
    }
}
