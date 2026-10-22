import Synchronization
import Testing
@testable import monny

/// Order and read-back of charge-limit writes against an injected system setting.
struct ChargeLimitTests {
    private final class FakeSystem: Sendable {
        struct State: Sendable {
            var setting = ChargeLimit(available: [80, 85, 90, 95, 100], limit: 85, isEnabled: false, isOptimized: true)
            var events: [String] = []
            var available = true
            var failsSetLimit = false
        }

        let state = Mutex(State())

        var operations: ChargeLimitStore.Operations {
            .init(
                read: { self.state.withLock { $0.available ? $0.setting : nil } },
                setLimit: { limit in
                    self.state.withLock { state in
                        state.events.append("limit")
                        guard !state.failsSetLimit else { return false }
                        state.setting.limit = limit
                        return true
                    }
                },
                setEnabled: { enabled in
                    // Like macOS 27: turning the limit on resets its target, turning it off shows 100%.
                    self.state.withLock { state in
                        state.events.append("enabled")
                        state.setting.isEnabled = enabled
                        state.setting.limit = enabled ? 80 : 100
                        return true
                    }
                },
                setOptimized: { isOn in
                    self.state.withLock { state in
                        state.events.append("optimized")
                        state.setting.isOptimized = isOn
                        return true
                    }
                })
        }

        var events: [String] { state.withLock { $0.events } }
    }

    @Test func enablesBeforeSettingTheTargetBecauseEnablingResetsIt() async throws {
        let system = FakeSystem()
        let store = ChargeLimitStore(operations: system.operations)
        let result = try await store.set(target: 90)
        #expect(result.isEnabled && result.limit == 90)
        #expect(system.events == ["enabled", "limit"])
        // Already in that state: nothing is written again.
        _ = try await store.set(target: 90)
        _ = await store.read()
        #expect(system.events == ["enabled", "limit"])
    }

    @Test func fullTargetTurnsTheLimitOffWithoutWritingATarget() async throws {
        let system = FakeSystem()
        system.state.withLock { $0.setting.isEnabled = true }
        let store = ChargeLimitStore(operations: system.operations)
        let result = try await store.set(target: 100)
        #expect(!result.isEnabled && result.target == 100)
        #expect(system.events == ["enabled"])
    }

    /// The reported bug: after turning the limit off, macOS shows 100%; choosing a target turns it on again.
    @Test func choosingATargetAfterTurningOffTurnsTheLimitOn() async throws {
        let system = FakeSystem()
        system.state.withLock { $0.setting.isEnabled = true }
        let store = ChargeLimitStore(operations: system.operations)
        _ = try await store.set(target: 100)
        let result = try await store.set(target: 85)
        #expect(result.isEnabled && result.target == 85)
    }

    @Test func switchesOptimizedChargingAndReadsItBack() async throws {
        let system = FakeSystem()
        let store = ChargeLimitStore(operations: system.operations)
        #expect(try await store.setOptimized(false).isOptimized == false)
        _ = try await store.setOptimized(false)
        #expect(system.events == ["optimized"])
    }

    @Test func doesNotSwitchUnreadableOptimizedCharging() async throws {
        let system = FakeSystem()
        system.state.withLock { $0.setting.isOptimized = nil }
        let store = ChargeLimitStore(operations: system.operations)
        await #expect(throws: ChargeLimitStore.Failure.unavailable) { try await store.setOptimized(true) }
        #expect(system.events.isEmpty)
    }

    @Test(arguments: ["unavailable", "unsupportedTarget", "failedWrite"])
    func neverClaimsAnUnconfirmedChange(condition: String) async throws {
        let system = FakeSystem()
        system.state.withLock { state in
            state.setting.isEnabled = true
            state.available = condition != "unavailable"
            state.failsSetLimit = condition == "failedWrite"
        }
        let store = ChargeLimitStore(operations: system.operations)
        await #expect(throws: ChargeLimitStore.Failure.self) {
            try await store.set(target: condition == "unsupportedTarget" ? 60 : 90)
        }
        #expect(system.events.count == (condition == "failedWrite" ? 1 : 0))
    }

    @Test func rejectsRepliesUnlikeTheVerifiedInterface() {
        #expect(ChargeLimit(available: [80, 85, 90, 95, 100], limit: 80, isEnabled: true).isValid)
        #expect(!ChargeLimit(available: [], limit: 80, isEnabled: true).isValid)
        #expect(!ChargeLimit(available: [80, 90], limit: 85, isEnabled: true).isValid)
        #expect(!ChargeLimit(available: [100, 80], limit: 80, isEnabled: true).isValid)
        #expect(!ChargeLimit(available: [0, 80], limit: 80, isEnabled: true).isValid)
        #expect(!ChargeLimit(available: [80, 85, 90], limit: 80, isEnabled: true).isValid)
    }
}
