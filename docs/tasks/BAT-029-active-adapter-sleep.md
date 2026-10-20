# BAT-029: Active adapter sleep recovery

- Updated: 2026-10-21
- Stage: done (one authorized installed build-22 active sleep/wake report and independent endpoints pass)
- Owner: app engineering; bounded acceptance recorded, ownership released
- Baseline: main cb9abff plus preserved uncommitted work; BAT-028 idle callback delivery and BAT-027 helper-exit recovery accepted
- Scope: explicit one-shot active-adapter sleep preparation, retained authenticated client session, console-user sleep request and read-only post-wake verification; one authorized actual preparation/sleep trial, no install/removal

## Outcome

Prepare one fixed CHIE 0→8 attempt with the existing three-second non-renewable lease. Retain its authenticated connection while the app requests ordinary system sleep once through the public console-user API. Helper must acknowledge adapter restoration before permitting sleep. After the user wakes the Mac, require the same instance, paired real lifecycle counters, adapterRestored at sleep, no failed wake, unchanged native settings and adapter source. Timer expiry before the sleep callback is inconclusive, never a pass. No increased isolation budget, sleep assertion, root shortcut, automatic wake schedule or repeated setter.

## Acceptance

- [x] Separate positively advertised revision and zero-argument selector, known-eight typed preparation reply rather than non-controlling status.
- [x] Persistent session is retained through the sleep request; failure/cancellation/disconnect restore or retain retryable intent, no mutation retry.
- [x] Actual system sleep is requested only by the ordinary app/console user and only after valid admission; helper remains charge-only.
- [x] Software/XPC/lifecycle tests and explicit new hardware authorization handoff.
- [x] Signed package/read-only mount review passes.
- [x] One separately authorized actual active-adapter sleep trial executed; restoration receipts and endpoints observed.
- [x] Correct the CLI wake collector and cover delayed transition, buffered callbacks, timeout and cancellation in software.
- [x] Obtain a passing actual final-artifact report: one authorized installed build-22 trial exits 0; independent read-only endpoints pass. Historical build-21 failure remains recorded.

## Implementation

Build **21** adds `--verify-adapter-sleep`, exact zero extra arguments. A retained AdapterSleepSession first authenticates normal status and requires adapterSleepVerificationAvailable=true/revision 1, helperInstance/lifecycle evidence, idle control and available native settings. No registration/retry occurs. Its separate prepareAdapterSleep selector accepts only a live ready owner with no native/adapter transaction/reserved request; it reuses the fixed checkpoint/signature/source/native/raw/lid/battery admission and three-second watchdog. A separate typed, bounded AdapterSleepPreparation reply says appliedByte=8, fresh native snapshot, helper instance and lifecycle baseline. It never claims notControlling while the byte is eight.

The app retains the same connection while requesting sleep. A preparation taking two or more awake seconds is rejected/cancelled rather than requesting late sleep. SystemSleepRequest calls public IOPMFindPowerManagement/IOPMSleepSystem once, off the main actor from the diagnostic command, as the ordinary console user; failure codes propagate. No privileged helper OS-sleep API, shell/pmset invocation, AppleEvents permission, assertion or scheduled wake is added. The public SDK documents root or console-user admission; [Apple pmset source](https://github.com/apple-oss-distributions/PowerManagement/blob/main/pmset/pmset.m) supplies the reference error-handling semantics. Its privilege-error branch is not a reason to request root access: if the native API refuses, cancel the experiment.

On a rejected sleep call/cancellation/transport error, cancellation restores only this authenticated owner's adapter experiment; connection invalidation and the unchanged watchdog also recover. No native setter, renewed lease or repeated prepare/sleep request. If admission partially takes effect and recovery fails, intent and one recovery-only timer remain; no successful preparation is returned. After real sleep the helper's existing willSleep restores before IOAllowPowerChange, revokes the adapter session and didWake does not replay. Native-limit sleep preservation remains separate.

After the workspace wake barrier in build 22, read-only polling requires the same helper instance, both counters increased from the actual preparation baseline, lastSleep=adapterRestored, lastWake=noAdapterRecoveryNeeded, idle control, unchanged measured native settings and adapter source. A watchdog-restored-before-sleep/no-checkpoint event, changed helper/native setting, failed callback or absent source cannot pass. Polling uses SuspendingClock (sleep time excluded), a 15-awake-second budget and 30-attempt limit. The owner connection is retained until success/error. Missing/failed evidence never retries isolation. All synchronous firmware/system-call deadline limits remain explicit.

## Verification

Agent-observed final **dev.sh test: 280 tests in 33 suites pass**, compiling app/helper with the existing Xcode 27.1/Swift 6.4/strict Swift 6/macOS 27.0.1 toolchain. Eight new test functions with parameterized exits exercise actual authenticated anonymous XPC, retained-byte-eight owner at injected sleep, restoration before injected wake, unavailable/old-helper refusal, malformed typed replies, exact arguments, rejected system call, cancellation, disconnect signaling, expiry, removal, competing owners, native changes/new instances/failed callbacks/no source and admission partial failure/recovery timer. Disconnect assertions wait on the fixture's actual restoration event rather than a fixed delay. All SMC values and OS-sleep calls are injected; the real SystemSleepRequest API is never invoked by tests. Existing lifecycle/native/byte/restart suites pass.

No real sleep/wake, CHIE write, helper installation/removal/crash, native-setting change or Sketch edit was performed in preparation. The already accepted build-20 idle sleep and build-19 helper-exit evidence remain unchanged. New shared/app/test files are tracked inputs, not generated outputs; no dependency or toolchain migration.

## Proposed user test and fallback

**Historical build-21 procedure; its single authorization is consumed.** The user installed build 21 and updated its helper before authorizing the trial below. Same dedicated adapter, USB-C monitor disconnected, lid open and battery ≥30%; Monny native control and competing charge controllers off. Save/finish current work because the command intentionally requests ordinary system sleep. Do not start another charging command, close the lid, unplug, uninstall or kill the helper during the trial.

With explicit authorization for **one** fixed CHIE preparation and **one** ordinary system sleep request, capture read-only before diagnostics and run as the ordinary user:

```sh
/Applications/Monny.app/Contents/MacOS/Monny --verify-adapter-sleep
```

Keep the connection/command alive. When the Mac sleeps, wait briefly and wake it manually, then read the result. Do not use an external wall-clock timeout that kills the command while the user is asleep; the command's awake-time budget excludes system sleep. Expected result is exit zero and paired same-instance callback evidence with adapterRestoredBeforeSleep=true, native preservation and adapter source. Separate read-only diagnostics must confirm CHIE=0 and no control. Actual OS transition timing may mean the three-second watchdog wins first; that is an inconclusive nonzero result, not permission to extend isolation or retry.

If the OS refuses sleep or no active-sleep evidence appears, retain the report and stop; the cancellation/watchdog path restores without a new write attempt. If adapter power remains unavailable or recovery is uncertain, keep the lid open, reconnect dedicated power and report the result before any further control. Connection reset is not guaranteed to reset CHIE; existing journal/startup recovery remains the fallback, and no root/SIP/BTM/journal-deletion shortcut is allowed. The user controls any further restart action. No longer isolation budget is proposed.

A passing active sleep trial would close that observed sleep callback/rollback case only. Actual removal while isolated, wider failure timing, sustained Discharge, other hardware/adapters and macOS 26 remain separate; product Discharge/full physical verification stay disabled.


## Signed candidate and next handoff

`apps/monny/build/release/Monny-1.0-21.dmg`, SHA-256 `15d13d67fb2186949bba9bd988b3f0f4e1c6c88d7f4fa7d190c1844687ea7979`. Existing Apple Development signing identity; signed, not notarized. Release build/signing fixtures and wrong-ID/pin/ad-hoc/debugger/tampered negatives pass. Image integrity and read-only mount review confirm build 21, Applications link, exact app/helper binaries matching signed staging and strict deep signature. The signed app rejects extra --verify-adapter-sleep arguments with invalidArguments/exit 1 before helper/OS access. Local links, shell syntax, Git visibility/ignore checks and git diff --check pass. No Git commit.

Build 22 implements the app-only wake correction below, accepted in the single authorized trial recorded at the end. Any further active trial needs new scoped authorization. The original software/package checks above were performed before the actual trial; they are not a new rerun.

## Authorized build-21 trial — 2026-10-20

After the user confirmed installation/helper update and authorized proceeding, engineering captured read-only baseline, quit the ordinary app and invoked the valid command exactly once, as the console user. No external wall-clock termination, second preparation, helper crash, removal or native-setting write. The command exited 1 with wakeNotObserved; this is a failed end-to-end diagnostic result, not a successful CLI acceptance.

Subsequent independent read-only battery/adapter/power diagnostics show the same authenticated helper instance, sleepCount 0→1 and wakeCount 0→1, lastSleep=adapterRestored and lastWake=noAdapterRecoveryNeeded. CHIE is directly readable as zero, controlState=notControlling, native enabled/value endpoints match the baseline, and public adapter source plus external/raw/charge-capable flags are present. These receipts accept the observed active adapter restoration before sleep and wake recovery on this setup only. They do not retroactively change the command's exit status or prove sustained physical behavior.

Read-only system power history records software-requested sleep, then DarkWake, then full wake. Helper logs show refused status requests throughout the transition; the CLI starts its 15-awake-second/30-attempt observation budget as soon as the sleep request returns, before full wake. A console-user sleep request is not a synchronous completed-sleep/wake barrier; transition and DarkWake consume observation attempts/time. The after-the-fact paired receipt explains why wakeNotObserved must not be described as failed hardware restoration. Exact status failure reasons remain private, and no root cause beyond this premature observation window is claimed.

The build-22 correction below arms real wake observation before the one-shot request and starts bounded status/source collection after wake, covering delayed transition/DarkWake with injected regression tests. Do not increase the three-second hardware lease or repeat the real test while debugging. Raw reports, instance identifiers, machine settings and system logs stay in temporary local storage. Previous 280-test/package checks are retained historical evidence; this runtime/doc update does not rerun them.

## Build-22 wake collection correction — 2026-10-20

App-only SystemWakeObserver registers synchronously with NSWorkspace.shared.notificationCenter before helper preparation or the one-shot sleep request. [Apple willSleep](https://developer.apple.com/documentation/appkit/nsworkspace/willsleepnotification) and [didWake](https://developer.apple.com/documentation/appkit/nsworkspace/didwakenotification) document the workspace notification center requirement. The main-queue callbacks only record sleep and buffer one subsequent wake; they never wait, request sleep, add an assertion or acknowledge/delay the helper's IOKit callback. A wake without a preceding observed sleep cannot release the barrier. An event delivered before the sleep API returns remains buffered.

A structured race waits for the paired workspace event or a separate 60-awake-second transition bound (SuspendingClock), cancelling/draining the losing child. Actual suspension time is excluded; long transition/DarkWake can still produce an explicitly bounded inconclusive result. Only after this barrier does the unchanged 15-awake-second/30-attempt authenticated helper/native/source collection begin. The workspace event is a scheduling barrier, never proof of adapter restoration: same-instance helper counters and adapterRestored/noAdapterRecoveryNeeded remain required. Failure/cancellation closes/cancels the owner without repeating preparation or sleep. Both observer tokens are removed before returning/exiting; isolated deinitialization also cleans them up. The three-second hardware lease, helper implementation, protocol and sleep-preparation revision 1 are unchanged. A compatible running build-21 helper is sufficient.

Final software check: **dev.sh test: 284 tests in 33 suites pass**, app/helper compile under existing Swift 6 strict-concurrency settings. Four added test functions cover a virtual 20-awake-second transition without consuming the post-wake budget or polling while sleeping; unrelated wake rejection and buffered sleep/wake delivery; cancelled/stopped observation; and timeout/cancellation restoring one preparation without polling/replay. The notification center, clock and OS/SMC effects are injected; no actual sleep, CHIE write, helper install/removal or native write occurs. Two initial compilation checks caught explicit-self and non-Sendable listener captures; both are corrected and the final full run passes. No new dependency or UI/Sketch change.

The user installed build 22 and separately authorized the single repeat below. A compatible build-21 revision-1 helper is sufficient; no replacement is required for this app-only fix. The authorization is consumed; no further valid command is authorized.

### Signed build-22 candidate review

Artifact: `apps/monny/build/release/Monny-1.0-22.dmg`; SHA-256 `245424e05016b66f66c07fa4830b5ebcecc305c4f924a4572a0e78b9eae19bdd`. Existing Apple Development identity retained; signed, not notarized. Release/signing positive and wrong-ID/pin/ad-hoc/debugger/tampered fixtures pass. Image checksum and separate read-only mount review pass: build 22, Applications link, exact signed staging app/helper binaries and strict deep signature. The mounted app rejects an extra sleep-command argument with invalidArguments/exit 1 before observer/helper/OS access. Source is visible to Git; generated DMG remains ignored. Local links and git diff --check pass. No actual valid sleep command, helper installation, charging change, Sketch edit or Git commit during this correction/review.

## Authorized build-22 acceptance — 2026-10-21

After the user confirmed readiness for the proposed single repeat, engineering verified installed build 22, positively advertised sleep revision 1, no active control and adapter source, then captured read-only baseline. The ordinary app was quit and the valid command invoked exactly once as the console user. No external wall-clock timeout, repeated preparation/sleep, helper kill/removal or native-setting write. The command exited **0**, reporting sameHelperInstance, sleepObserved, wakeObserved, adapterRestoredBeforeSleep, nativeSettingsPreserved and adapterSourceObserved all true; controlSupport remains unverified.

Independent post-wake battery/adapter/power diagnostics confirm the same authenticated helper instance, exactly one added sleep and wake, lastSleep=adapterRestored and lastWake=noAdapterRecoveryNeeded. Direct CHIE read-back is zero, controlState=notControlling, native enabled/value endpoints match baseline and public source is adapter. This accepts the observed active-sleep restoration and corrected wake collector on the current Apple silicon/macOS 27.0.1 setup with the dedicated adapter. It does not establish a universal physical-isolation duration, sustained Discharge, actual removal while isolated, other failure boundaries, other hardware or macOS 26. Full physical verification/Discharge stay disabled.

Raw before/after reports, instance identifiers and settings stay local in temporary storage. No code changed or software/package test rerun for this evidence update; the prior build-22 284-test/33-suite and signed candidate checks remain the artifact evidence. Documentation links and git diff --check pass. No Git commit.

Next: [BAT-030](BAT-030-active-adapter-removal.md) now owns the prepared bounded active-adapter removal candidate, reusing existing restoration acknowledgement and lifecycle evidence. Do not uninstall, request another sleep or alter charging without new scoped authorization.
