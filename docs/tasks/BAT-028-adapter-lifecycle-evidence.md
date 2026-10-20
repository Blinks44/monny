# BAT-028: Observable sleep/wake and removal recovery

- Updated: 2026-10-20
- Stage: done (build-20 idle OS sleep/wake callback delivery accepted)
- Owner: app engineering; software ownership released for user verification
- Baseline: main cb9abff plus preserved uncommitted work; bounded build-18 observation and build-19 adapter restart recovery accepted
- Scope: additive authenticated lifecycle receipts, recovery-failure tests, signed candidate and a read-only sleep integration handoff; no hardware mutation/sleep/removal

## Outcome

Make actual helper sleep/wake/removal preparation observable without adding another isolation writer, arbitrary OS sleep command or longer lease. Record per-instance event counts and last event outcomes, distinguishing adapter checkpoint recovery, preserved native sessions, no pending recovery and failures. Existing power callbacks and explicit removal are the only event sources; clients cannot forge events or choose an outcome.

## Acceptance

- [x] Additive validated receipts preserve existing status/removal contracts and do not expose paths/PIDs/private machine data.
- [x] Receipt reflects the real executor callback path; failure never reports successful recovery or acknowledges removal.
- [x] Tests cover pending adapter recovery, unavailable telemetry, failed rollback, sleep/wake retry, native preservation and repeated removal.
- [x] Signed build/package checks and a concrete user-owned read-only sleep/wake test.
- [x] Actual idle OS sleep/wake callback delivery accepted below; no active-CHIE sleep/removal acceptance inferred.

## Implementation and fixes

Build **20** adds lifecycleDiagnostics/version 1 to authenticated status, adapter/charge diagnostics and removal acknowledgements. The receipt is tied to helperInstance and reports bounded per-process sleepCount, wakeCount, removalPreparationCount and last outcomes: noAdapterRecoveryNeeded, adapterRestored, nativeLimitPreserved or failed. Counters saturate at one million; outcomes/counts/version are validated on decode. Default/injected status-only executors remain unchanged; live instance diagnostics reset with a new helper process, and no runtime IDs go into repository evidence. No event timestamps, private paths or machine identities are exposed.

Only actual executor willSleep/didWake and existing prepareForRemoval calls update the receipt; there is no IPC event-simulation selector. HelperPowerMonitor still serializes IORegisterForSystemPower callbacks, prepares recovery before IOAllowPowerChange and never prevents sleep. The receipt proves callback execution/outcome, not that the OS slept, physical power flow or a guaranteed hardware recovery deadline. A paired unchanged-instance sleep/wake comparison is needed for integration acceptance.

Review found two recoverability gaps. A lease-rollback failure before the sleeping phase was set could leave didWake ineligible to retry. The phase now becomes sleeping before lease validation, keeping wake recovery available. Also, didWake previously ignored a failed removing state: it now retries restoration while retaining phase=removing, so no new control is admitted after removal preparation. Failure remains explicit, the adapter journal is retained and no telemetry is needed for recovery. Ordinary native-limit preservation/rearm semantics are unchanged; idle callbacks issue no adapter setter.

## Verification

Agent-observed final **dev.sh test: 272 tests in 32 suites pass**, app/helper built with the existing Xcode 27.1/Swift 6.4/Swift 6 strict-concurrency/macOS 27.0.1 environment. Seven new test functions cover idle event pairing/no writes, anonymous-XPC receipt delivery and wire round trips, adapter recovery despite missing environment data, failed sleep rollback/retry on wake, prior lease failure, failed removal plus wake retry without reopening commands, native preservation without extra setters, counter saturation and malformed receipts.

The first regression run exposed a pre-existing negative-XPC test race: a client-side requirement for the server does not authorize/reject that client's outgoing request at the service. Under load the test's intentionally mismatched server requirement could still allow the correctly signed caller's outgoing mutation before reply validation. The negative test now rejects the wrong caller requirement at the listener, as production caller authentication does. This is a correction of the test's security model, not a bypass of peer checking. Production engineering commands already require an authenticated read-only handshake before new mutating selectors. Final full suite passes; no sleeps/repeated test runs are used to hide the race.

All new power/SMC/lifecycle effects are injected. No real OS sleep/wake, helper removal, crash, SMC write, native-setting change, Sketch edit or valid engineering command was executed during preparation. Current build-19 actual restart evidence remains scoped separately in BAT-027.

## Read-only sleep integration handoff

After the candidate is reviewed, the user installs build 20 and explicitly replaces/approves its helper. Leave native Monny control off, use the dedicated adapter and disconnect the USB-C monitor. Do not invoke any CHIE engineering command. Obtain --battery-diagnostics and --adapter-diagnostics as a before baseline: build 20, helperInstance present, lifecycleDiagnostics.version=1, notControlling, CHIE=0, original native pair and adapter source. Keep the bounded output local.

The user then chooses ordinary Sleep in the Apple menu, waits briefly and wakes the Mac. Do not uninstall, force quit or enable charging control during the cycle. Obtain the same read-only diagnostics afterward. Success requires the same helperInstance, increased sleepCount and wakeCount, lastSleep/lastWake=noAdapterRecoveryNeeded, CHIE=0, adapter source, unchanged native settings and no active control. If helperInstance changed, counts/outcomes are missing/failed, or source/settings differ, retain the result and investigate; do not repeat automatically or infer delivery from the battery icon alone.

This first hardware step deliberately tests OS notification wiring **without pending adapter isolation**. It cannot establish that an active CHIE checkpoint was restored before actual sleep, or that uninstall restores while isolated. Those physical cases remain open even if it passes. Preparing an active sleep test later may use the public IOPMSleepSystem API from the console user with a dedicated authenticated session; it is not added or invoked here. The installed SDK documents console-user/root admission, while Apple's pmset implementation demonstrates error handling. No root workaround, helper-issued system sleep, AppleEvents permission or longer isolation window is justified for this read-only step.

## Next action

Signed package review is complete. Installed build-20 idle sleep/wake acceptance is recorded below. Engineering next prepares a separate active-adapter lifecycle scope; no further hardware action is authorized. Further active-CHIE sleep/removal experiments require their own concrete scope and authorization. Product Discharge and full physical verification remain disabled.


## Signed candidate

`apps/monny/build/release/Monny-1.0-20.dmg`, SHA-256 `89add6c83a524fc447963335dc9f06db095ab5cee5fc3a439bd90e9d36246006`. Existing Apple Development signing identity; signed, not notarized. Release/signing fixtures, app/helper matching signer and wrong-ID/pin/ad-hoc/debugger/tampered negatives pass. Image integrity and read-only mount review confirm build 20, Applications link, exact app/helper binaries matching signed staging and strict deep signature. Invalid extra engineering arguments refuse before helper access. Local links, shell syntax, Git visibility/ignore review and git diff --check pass. No Git commit or installed-helper action; all runtime acceptance limits above remain.


## Installed idle baseline — 2026-10-20

After the user installation/readiness handoff, installed metadata independently reports build 20. Authenticated read-only diagnostics show lifecycle receipt version 1, zero sleep/wake/removal-preparation counts, notControlling and CHIE=0 with expected metadata. Source is adapter and native settings are available. Bounded before output/helper instance/native snapshot are saved locally outside the repository for same-instance comparison; no UUID/raw settings are versioned. No OS sleep, removal or hardware mutation has been performed by the agent. Next the user performs one ordinary idle sleep/wake cycle, then returns for read-only comparison.


## User-owned idle sleep/wake accepted — 2026-10-20

The user performs ordinary sleep/wake after the saved baseline and reports waking the Mac. Subsequent authenticated read-only diagnostics identify the **same helperInstance**, sleepCount 0→1 and wakeCount 0→1, lastSleep/lastWake=noAdapterRecoveryNeeded and removalPreparationCount=0. CHIE remains zero with expected metadata, source remains adapter, native settings match the before snapshot and controlState remains notControlling. Bounded before/after JSON is local outside the repository; runtime UUIDs/raw machine settings are not versioned.

This accepts one actual paired IORegisterForSystemPower-to-executor idle sleep/wake cycle on the observed setup, without helper replacement/restart and without adapter/native setters. It does not accept active-CHIE sleep restoration, uninstall while isolated, every failure path or sustained Discharge. No additional sleep, mutation, removal or retry was performed by the agent. Existing 272-test/package evidence was not rerun for this evidence-only update.

The bounded observable-lifecycle/idle integration task is complete. [BAT-029](BAT-029-active-adapter-sleep.md) now owns the separate active-adapter sleep experiment; removal remains separate and each requires explicit hardware authorization; product Discharge and full physical verification remain disabled.
