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

User's confirmed installation/app+Mac restart/removal/reinstall applies to the previous status-only binary (BAT-003), not these new native event handlers. The new observer's actual sleep/wake and graceful termination behavior needs user-owned runtime acceptance. Sleep acknowledgement after an attempted restore is not proof of successful physical restoration; IOKit proceeds after 30 seconds even if a process stalls. SIGKILL/crash cannot run cleanup. The original observer build used on-demand launchd; build 10 adds KeepAlive to request restart and journal recovery ([BAT-018](BAT-018-native-limit-interface.md)), whose real crash timing remains unverified. Native-event/hardware/runtime negative-peer and clean-Mac gates remain open.

Read-only SMC/helper diagnostics are complete in BAT-006/007, and native getter-only installed diagnostics in BAT-011. Journal-backed native settings now use this executor's lifecycle with injected operations ([BAT-014](BAT-014-native-executor-lifecycle.md)); this does not verify real native events or charging. The guarded native backend is now connected in build 10 (BAT-018); setting/read-back/restoration is user-confirmed, while real lifecycle acceptance remains open. Runtime observer, restart availability and physical restoration remain open; real charging tests require explicit target/rollback authorization.


## Native sleep contract superseded — 2026-10-20

Build 12 in [BAT-018](BAT-018-native-limit-interface.md) preserves an already-active native macOS limit and original checkpoint through ordinary sleep. Wake validates read-back and rearms the awake lease without setters; older injected SMC modes retain pre-sleep restoration. Earlier sleep-restoration checks in this record describe the historical observer contract, not current native product acceptance. Real power notifications, connection survival, later explicit restoration and physical enforcement still require hardware verification.

## Build-15 restart evidence — 2026-10-20

The user confirms a distinct temporary native target was active before force-quit, helper reappearance in approximately 4–5 seconds, and restoration of the original enabled/value pair with no active control. This accepts bounded native restart/journal rollback on that setup. [BAT-024](BAT-024-adapter-verification-ipc.md#user-reported-helper-restart--2026-10-20) owns the evidence. App-crash, full physical enforcement, adapter-specific recovery and other-platform gates remain open. No repeat crash is requested.


## Bounded adapter helper-exit recovery accepted — 2026-10-20

[BAT-027](BAT-027-adapter-restart-recovery.md) records one authorized installed build-19 unclean helper exit after durable CHIE-eight read-back. A different authenticated instance recovers the pending record from eight to zero before serving; native settings and adapter source are preserved/confirmed. This closes that bounded adapter restart case only, not all crash boundaries, sleep/removal or sustained behavior. No repeat is requested.


## Wake retry eligibility fixes — 2026-10-20

BAT-028 makes lifecycle outcomes observable and fixes retry eligibility after pre-sleep lease rollback failure and while removal remains pending. Injected regressions pass; removal stays gated. The next idle OS callback-delivery check does not close active adapter sleep/removal acceptance.


## Idle OS callback delivery accepted — 2026-10-20

BAT-028 records one user-owned build-20 sleep/wake cycle with the same authenticated helper instance, paired counter increments, noAdapterRecoveryNeeded outcomes, CHIE=0, adapter source and unchanged native settings. This accepts actual idle callback delivery only; active adapter sleep/removal remains open.


## Active adapter sleep observed; collector correction open — 2026-10-20

[BAT-029](BAT-029-active-adapter-sleep.md#authorized-build-21-trial--2026-10-20) records one authorized build-21 sleep request. Same-instance paired callbacks report adapterRestored before sleep and noAdapterRecoveryNeeded at wake; later read-only CHIE=0/native/source endpoints confirm restoration. The command itself exits wakeNotObserved during its premature collection window, so end-to-end acceptance remains open pending a software correction and reviewed candidate. No repeat trial is authorized; removal/sustained/other-platform gates remain.


## Bounded active sleep accepted — 2026-10-21

[BAT-029](BAT-029-active-adapter-sleep.md#authorized-build-22-acceptance--2026-10-21) accepts one authorized installed build-22 active sleep/wake report, exit 0. Independent diagnostics confirm same-instance paired counters, adapterRestored/noAdapterRecoveryNeeded, CHIE=0, no control, matching native endpoints and adapter source. This closes the observed active sleep and collector timing case; actual active removal, other timing/platform boundaries and sustained behavior remain open. No additional hardware action is authorized.


## Active removal candidate ready — 2026-10-21

[BAT-030](BAT-030-active-adapter-removal.md) prepares separately advertised bounded removal preparation, same-instance restoration acknowledgement before one native unregister, and direct post-removal byte/source checks without XPC/reinstall. Build-23 software/package review passes; actual active removal is still open and separately authorized. No new hardware action performed.


## Bounded active removal accepted — 2026-10-21

[BAT-030](BAT-030-active-adapter-removal.md#authorized-installed-build-23-removal-accepted--2026-10-21) accepts one authorized installed build-23 active removal report, exit 0, with restoration/native acknowledgement before unregister, direct byte-zero/source after it and independent service/process absence. No post-removal native getter or automatic reinstall is claimed. Helper remains unregistered; client-exit/sustained/other-platform gates remain open. No further hardware action authorized.
