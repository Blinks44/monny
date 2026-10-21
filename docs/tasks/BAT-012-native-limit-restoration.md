# BAT-012: Native charge-limit ownership and restoration

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: done
- Owner: unassigned; implementation and software checks complete
- Ownership checked: main 1dc16bd; existing uncommitted work preserved
- Owned surfaces: new native transaction value type, injected behavioral tests, scoped documentation
- Requirements: SPEC §5 fail-safe; phase 4; BAT-011 getter-only report

## Outcome and scope

Prepare a serialized, fresh-read transaction for a future native backend. Preserve the original enabled/configured-limit pair across target changes, verify every acknowledged change and restore the original pair on release or command failure. Detect external changes rather than overwriting user settings. Continue local self-signing as explicitly chosen by the user; Developer ID is not a development prerequisite.

No production setter, writable IPC, live setting change, installation or UI change in this slice. Do not enable controls or claim crash recovery from an in-memory transaction. Existing executor/session lifecycle will own serialization when this is integrated; no second worker/service or retry loop.

## Acceptance

- [x] Reject invalid/unsupported snapshots and targets before writes; read fresh rather than use diagnostic cache.
- [x] Preserve original setting across repeated targets and disabled/enabled starting states.
- [x] Verify write read-back; recover known partial effects, retain failed recovery for an explicit retry and block new targets until recovered.
- [x] Stop on external setting changes without overwriting them; cancellation cannot skip recovery.
- [x] Behavioral tests and app/helper build pass; current records describe limits and next action.

## Implementation

NativeChargeLimitTransaction is a Sendable value type with explicitly injected synchronous operations and no production/default writer. A future helper executor must own it off-main and serialize its entire mutating operation; it introduces no suspension, additional actor, timer or global state. The original setting survives target updates. Each setter records both its prior and intended pair before invocation, because a throwing setter may already have taken effect. Fresh read-back must equal one of those attributable pairs; any other valid pair latches externalChange and drops ownership without writing. Explicit recovery ignores task cancellation, retains uncertain ownership on read/recovery failure and blocks new targets until recovery succeeds. Restoring a disabled original disables before changing the limit; all targets are validated before the first recovery write.

A matching external change is indistinguishable from our own value, and a separate process may still change settings between read and write: no atomic system compare-and-set is claimed. A new transaction must not automatically be constructed after externalChange. The original slice used in-memory ownership. [BAT-013](BAT-013-native-recovery-journal.md) now requires checkpoints and verifies process-restart recovery; production lifecycle and physical fail-safe acceptance remain open.

## Verification

Final apps/monny/scripts/dev.sh test passed **121 tests in 16 suites**, including 14 new transaction tests (parameterized disabled/enabled originals and before/after-effect failures). The final run compiled both app and helper targets with Swift 6 strict concurrency. Covered repeated targets/no-op, invalid/unavailable input, ignored writes, both partial setter steps, failed/retryable rollback, external changes before command/release and during read-back, capability changes before restoration, cancellation before/after writes, and invalid renewal releasing the original. Local log: /tmp/monny-native-transaction-final-test.log. Initial sandboxed invocation could not write Xcode/SPM caches; normal Xcode access allowed compilation/tests. No helper/service or real charging settings changed. Affected source/diff and relative documentation links reviewed; git diff --check passes. No commit or publication. No new DMG is needed for this unconnected logic; the installed build-3 artifact remains unchanged.

## Open checks / next handoff

Checkpoint/reconstructed-process recovery is verified in BAT-013. Runtime setters, restart availability, lease/lifecycle integration, private API races and physical restoration remain prerequisites before control. Next integrate the journal-backed transaction with executor lifecycle using injected operations; actual charging checks require explicit target/rollback authorization. Existing helper launch instability remains in BAT-003, not a reason to migrate signing or change OS trust.
