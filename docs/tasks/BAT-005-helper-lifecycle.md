# BAT-005: Wire helper lifecycle without enabling charge writes

- Updated: 2026-10-19
- Stage: awaiting_verification (new native observer runtime)
- Owner: unassigned; released
- Baseline: main 1dc16bd plus preserved uncommitted battery/UI/packaging work
- Ownership: helper main/power observer, shared executor/session, executor tests, helper build settings and scoped records
- Requirements: SPEC/ENGINEERING battery fail-safe; phase 4

## Outcome

Connect the tested executor to per-connection native XPC session ownership, startup/removal/disconnect, real IOKit sleep/wake and SIGTERM/SIGINT. Keep the versioned IPC status/removal-only and the production hardware backend absent. A queued request from an expired/disconnected/pre-sleep owner must never reactivate control. Tests use acknowledged injected writes only. No helper installation, process termination, system sleep, charging modification or permission change on the user's Mac.

## Acceptance

- [x] One executor and independent server-issued bounded sessions; stale-session requests rejected.
- [x] Startup/awake/removal/termination gates preserve conservative restoration and block replay.
- [x] Native daemon observes sleep/wake without AppKit, sleep veto or polling; cleanup owns its C handles.
- [x] Status-only wire compatibility and signed app/helper checks preserved; injected lifecycle and real anonymous IPC checks pass.
- [x] Runtime/hardware/crash recovery limitations and next action explicitly recorded.

## Research

Apple IORegisterForSystemPower documentation and the installed SDK specify: acknowledge CanSystemSleep/WillSleep with IOAllowPowerChange; do not acknowledge early/complete power-on. Sleep proceeds after 30 seconds regardless; notification is not a hardware safety guarantee. IORegisterForSystemPower does not provide shutdown/restart messages. Use dispatch signal sources for graceful SIGTERM/SIGINT; SIGKILL/crash cannot execute cleanup. No suitable added dependency is required.

## Implementation and verification — 2026-10-19

One ChargeCommandExecutor owns phase, lease, session admission and the synchronous acknowledged-operation boundary. HelperSession creates a token on the server per XPC connection; the two existing protocol methods remain unchanged, with no writable method and no owner token in message data. Invalidation/interruption closes ownership. Live sessions are capped at 16 and reclaimed, pre-sleep sessions are revoked, and removal/shutdown prevent late command reactivation. Removal failure produces an invalid reply rather than a success acknowledgement and supports a subsequent restoration retry.

HelperPowerMonitor registers IORegisterForSystemPower on the main dispatch queue and sequences will-sleep/complete-wake events. It never vetoes sleep, acknowledges only required events, and owns registration/port/root handles in deinit. A six-line C bridging header exposes SDK message constants unavailable through Swift's importer; both helper configurations use it. SIGTERM/SIGINT dispatch sources attempt restore and exit success/failure accordingly. Native observer code is compiled but not executed/registered by the test harness. No keep-alive, polling, power assertion, persistent policy, shell execution or dependency was introduced.

The default executor has no Operations backend. It always refuses apply as unsupported and reports unchanged status-only capability. The optional branch denotes absence of hardware control, not a fabricated successful hardware write. Existing app protocol/helper versions remain compatible; prior installed helper processes can therefore report Connected without having loaded the newly built executable. New-binary runtime checks require explicit user-owned installation/restart, not merely observing an old daemon's compatible reply.

Final dev.sh test: **85 tests in 12 suites passed**. Coverage includes all prior 75, invalidated session replay, startup/stop gates, sleep revocation/fresh wake session, wake recovery failure, retryable removal failure, terminal shutdown, bounded session reclamation, real exported-object negative/positive replies, and anonymous Foundation XPC through the production HelperSession. Hardware operations are injected and do not touch IOKit. Existing anonymous wrong-peer tests still pass. Local final test log is outside the repository; macOS 27.0.1 / Xcode 27.1 / Apple silicon development environment, no macOS 26 runtime claim.

Final release.sh: arm64 Release, runtime/strict signed app/helper positive/negative fixtures, strict app/DMG signatures and hdiutil integrity all pass. Artifact: apps/monny/build/release/Monny-1.0-1.dmg; SHA-256 **83132ebc42edab380c5338bee22bbf8eab803632e20f20ad57a42336930f5c65**. Stable Monny certificate retained. Project plist, shell syntax, document links, ignore policy and git diff --check pass. No agent install/uninstall, helper execution/termination, system sleep, charging write, permission change or publication.

## Limits and next action

User's confirmed installation/app+Mac restart/removal/reinstall applies to the previous status-only binary (BAT-003), not these new native event handlers. The new observer's actual sleep/wake and graceful termination behavior needs user-owned runtime acceptance. Sleep acknowledgement after an attempted restore is not proof of successful physical restoration; IOKit proceeds after 30 seconds even if a process stalls. SIGKILL/crash cannot run cleanup; current launchd is on-demand without KeepAlive. Native-event/hardware/runtime negative-peer and clean-Mac gates remain open.

Read-only SMC/helper diagnostics are complete in BAT-006/007, and native getter-only installed diagnostics in BAT-011. Journal-backed native settings now use this executor's lifecycle with injected operations ([BAT-014](BAT-014-native-executor-lifecycle.md)); this does not verify real native events or charging. Next review the guarded setter/storage/capability contract before supplying any real backend. Runtime observer, restart availability and physical restoration remain open; real charging tests require explicit target/rollback authorization.
