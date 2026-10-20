# BAT-004: Bounded commands and restoration before hardware control

- Updated: 2026-10-19
- Stage: done (bounded executor/software foundation)
- Owner: unassigned; released
- Baseline: started at main fd8ba18; prior battery/UI/signing work was committed externally as 1dc16bd during this task, preserved. This executor/tests and maintenance remain uncommitted.
- Ownership: new shared executor and tests; scoped review/cleanup, task/STATE/PLAN/research records
- Requirements: SPEC battery fail-safe; ENGINEERING helper security; phase 4

## Outcome

Add a small serialized command executor with a short renewable monotonic lease, connection ownership and conservative restoration. A synchronous injected hardware boundary permits partial-failure tests. No production writer, XPC charge method, helper installation or charging change is introduced; the shipped daemon remains status-only. This is an independently testable prerequisite for hardware control, not proof of hardware fail-safe behavior.

## Acceptance

- [x] Startup requires restoration; commands serialize without suspension during writes.
- [x] Lease expiry/disconnect/release restores adapter power and allows charging; old timers/connections cannot cancel another lease.
- [x] Partial writes attempt both restoration steps; failed restoration stays unknown and blocks commands until recovered.
- [x] Deterministic state/failure tests and a real expiry callback test pass with the full suite; signed release remains status-only.
- [x] Review/cleanup removes only verified redundant generated files, preserves original key/backup and current source work, and updates links/current records.

## Review and verification — 2026-10-19

Reviewed changed battery/helper/signing code, sampler ownership, Xcode target settings, scripts, tracked/ignored paths and documentation links. No unrelated refactor, new dependency, generic clock framework or design change was needed. Corrected stale current-development/capability statements; preserved shared skills, website placeholder, active IDE state and original private keychain pending an off-device backup.

Baseline full suite: 63 tests/11 suites. Final dev.sh test: 75 tests/12 suites pass, including startup/restart restoration, safe mode ordering, renewal without redundant writes, invalid leases, foreign/late disconnects, expiry, all partial command-write failures, both restoration failures, cancellation, automatic expiry and lost external ownership. Failures use injected synchronous operations only; no IOKit is called. Local test log remains outside the repository.

Final release.sh passes arm64 Release, native signed fixtures, strict app/DMG signatures and hdiutil verification. Current artifact: apps/monny/build/release/Monny-1.0-1.dmg; SHA-256 8cd4699dce3ec56f9a94f5820ae21daa2e109f47404db40bed68081877aa013d. Scheme/identifiers, status-only protocol and disabled control UI remain unchanged. The executor's bounded timer retains it through expiry and never acknowledges a failed restore. Writes contain no await, so recovery cannot interleave with another command. Expiry errors remain visible as restorationRequired.

Removed 789.7 MiB of superseded SelfSigned/DesignReview/SigningReview packages and reproducible DerivedData after verification; package checkout was clean and no application was running from those folders. Removed four .DS_Store metadata files. Latest release and original keychain/private backups retained. Historical checks/hashes remain in their owning records; only their obsolete local generated artifacts were removed. Shell/Python syntax, document links, ignore-policy inspection and git diff --check pass. No commit, helper installation, charging change or publication performed by the agent.

## Open checks and next action

User-confirmed local status-only installation/status, app/Mac restart and removal/reinstallation are recorded under BAT-003; clean-Mac and runtime negative-peer checks remain open. Per-connection identity and native sleep/wake/graceful-termination/removal integration is now implemented in [BAT-005](BAT-005-helper-lifecycle.md), which owns its new runtime acceptance and the hardware/capability/crash-recovery handoff. Clock expiry alone cannot restore during sleep or after process death; crash/restart recovery and real hardware remain release gates. Preserve the status-only daemon until these prerequisites are resolved. User also retains signing backups off-device.
