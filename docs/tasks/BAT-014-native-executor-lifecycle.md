# BAT-014: Native transaction lifecycle in the helper executor

- Updated: 2026-10-20
- Stage: done
- Owner: unassigned; bounded software integration and checks complete
- Baseline: main 1dc16bd; existing uncommitted work preserved
- Owned surfaces: ChargeCommandExecutor, native lifecycle fixtures and scoped records
- Requirements: SPEC §5 fail-safe, BAT-005 lifecycle, BAT-013 checkpoint recovery

## Scope and acceptance

- [x] Injected native backend is distinct from adapter/charging modes; production remains non-writing.
- [x] Startup recovers a checkpoint before sessions; failures block ready state and remain retryable.
- [x] Server-owned session and bounded lease govern native limit requests; stale/foreign owners cannot change or revoke control.
- [x] Sleep/disconnect/shutdown/removal/lease expiry restore the original setting; no replay after wake.
- [x] Recovery failures block acknowledgement; external settings stay intact without trapping explicit removal.
- [x] App/helper build, behavioral tests and affected records checked.

No new writable IPC, real setter, root storage location, launchd changes, installation or charging changes. Hardware lifecycle and restart availability remain release gates. Continue existing self-signing.


## Implementation and verification

ChargeCommandExecutor owns one journal-backed transaction on its existing actor. A distinct NativeBackend initializer takes injected operations/journal, deferring construction/read I/O until startup recovery. It cannot also select adapter/charging operations. applyNativeLimit is an internal method only; no selector, owner token, path, target or setter was added to IPC. The shipped helper still supplies no backend and rejects both command families as unsupported.

Native requests reuse authenticated server session tokens, single-owner checks, ContinuousClock maximum-30-second leases, cancellation/deadline checks and the existing expiry task. Startup restores before admitting sessions. Sleep revokes sessions; wake restores without replay. Owner disconnect, shutdown, explicit removal and expiry restore the first original setting. A transaction error revokes any previous lease; failed restoration stays blocked rather than reporting idle. A successfully observed external change relinquishes ownership and permits a non-controlling removal acknowledgement without claiming the original was restored. The transaction remains latched against automatic reapplication; future explicit re-enable semantics require review.

Final apps/monny/scripts/dev.sh test passed **145 tests in 18 suites** on M1 Max/macOS 27.0.1/Xcode 27.1; app/helper compile with Swift 6 strict concurrency. Local log: /tmp/monny-native-lifecycle-final-test.log. New injected tests cover checkpoint recovery before sessions, unreadable/corrupt/failed startup and repair, all five restore boundaries including retryable failure, foreign/stale sessions, renewal/old deadline, native-vs-adapter separation, active status refusing a false notControlling reply, external ownership/removal, invalid lease/target and cancellation before/during writes. An AsyncStream-driven automatic-expiry test drops the external executor reference and still observes both original setting writes, without polling or a fixed sleep assertion. Existing adapter, journal, XPC/signing and diagnostics tests remain green.

No actual sleep/termination notification, PowerUI writer, real checkpoint location, installed service or hardware control changed. Native write I/O remains synchronous in one off-main actor turn; it cannot be forcibly interrupted if a future private API stalls, so these leases do not establish a physical timing guarantee. Existing status/removal IPC/capability stays unchanged. Source/diff, documentation links and git diff --check reviewed; no commit, DMG or publication.

## Next engineering slice / release gates

Guarded native setter and fixed storage preparation is now verified in [BAT-015](BAT-015-native-writer-preparation.md), without exposing writes. Next prepare bounded manual verification IPC before authorized physical tests. Review actual setter ABI, boundedness/entitlements, read-back, restart availability and app capability/charging-aware removal contract before any real backend is supplied. The present non-writing offline-unregister exception must not apply to a charging-capable release. Physical target/rollback, native sleep/wake, crash/termination and clean-Mac/self-signed launch checks remain open and require the appropriate user-owned runtime checks. No new installation is needed for this injected-only slice.
