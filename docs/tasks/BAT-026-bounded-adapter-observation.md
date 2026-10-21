# BAT-026: Bounded adapter-source observation

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: awaiting_verification (build-18 bounded source/settling acceptance passes; adapter lifecycle open)
- Owner: app engineering; software ready for user verification
- Baseline: main cb9abff plus preserved uncommitted work; BAT-025 build-16 single pulse consumed
- Scope: upstream review, bounded observation and read-only settling, tests/candidate; real build-17 evidence retained below

## Outcome

Prepare one fixed CHIE 0→8→0 attempt with at most two seconds of source observation inside the existing three-second checkpoint/lease budget. Restore immediately on battery/no-charge evidence, missing/unsafe readings, lifecycle interruption or the observation bound. Never toggle repeatedly, extend ownership, change native settings or enable product Discharge. Keep the old no-dwell command unchanged and full physical-provider verification disabled.

OpenDente issue #3 and open/unmerged PR #4 report CHIE 8/0 on M1/macOS 14.8.9 with USB-C monitor power; these do not validate the user's macOS 27 setup. AlDente reports include dock failures and AC/battery oscillation/display flicker. Review source/status/licensing in the owning research record before implementation; GPL implementation is reference-only, never copied. Modern AlDente is closed source; legacy code is not evidence of its current mechanism.

## Acceptance

- [x] Fixed two-second/8-sample bound, at most one isolation write, immediate recovery and no private native getter while isolated.
- [x] Same authenticated single owner, revisioned handshake, journal/startup recovery and post-await lifecycle revalidation.
- [x] Report source observations separately from byte rollback and physical support; bounded valid wire data.
- [x] Behavioral/XPC/negative/lifecycle tests; package checks recorded below.
- [x] One separately authorized build-17 hardware observation/user-visible return recorded below.
- [x] One build-18 bounded source/settling observation passes on the installed helper.
- [x] Bounded adapter helper-exit recovery passes separately in BAT-027.
- [ ] Adapter sleep/removal, broader crash boundaries and sustained behavior remain open.

## Implementation and verification

Build **17** adds `--observe-adapter-byte`, with exactly zero extra arguments and the separate adapterByteObservationAvailable=true / adapterByteObservationVersion=1 authenticated handshake. No old helper selector, registration, fallback or automatic retry is used. The existing no-dwell command retains its contract; full adapterVerificationAvailable stays false.

A shared byte-research begin operation performs known-zero/signature/fresh native/source/raw/lid/battery admission, then checkpoints before one isolation attempt. Existing strict physical begin/observe admission is unchanged. The new executor request reserves its authenticated owner across awaits; foreign/new native commands cannot steal the interval, even after sleep/wake rollback while an old request is suspended. At most eight candidate readings, normally 250 ms apart, fit inside a two-second observation window starting before admission. The existing non-renewable three-second lease/checkpoint budget remains the outer limit. Synchronous system calls cannot be interrupted by that software deadline.

Source battery plus no charging ends observation immediately. Unknown raw/source readings remain observations, not a physical-cable provider. Missing/unsafe samples, cancellation, disconnect, sleep, removal, shutdown, expiry or the observation bound restore independently of telemetry. No getter of native settings runs while isolated. The adapter journal is recovered before native startup/listener activation. Failed final recovery retains intent and arms one recovery-only watchdog attempt; it never repeats isolation. Further failure remains blocked for explicit recovery/startup, not an unbounded retry loop.

The report separates byte evidence, sample count and battery-source observation. Zero exit requires valid byte read-back/restoration, matching native endpoints, a battery/no-charge sample and actual adapter-source observation after restoration. Byte zero with missing/battery post-restoration source returns nonzero. All control support remains unverified. No physical cable presence, exact electrical flow, sustained isolation or adapter-specific crash guarantee follows from these observations.

Agent-observed **dev.sh test: 250 tests in 30 suites pass**, compiling app/helper with the existing Xcode 27.1/Swift 6.4/Apple-silicon/macOS 27.0.1 toolchain and strict Swift 6 settings. Ten new test functions (parameterized interruptions/failures) cover authenticated anonymous XPC, one-write early success, sample/time bounds, source-return failure, unsafe/missing/unknown observations, owner reservation/competitors, cancellation/disconnect/sleep/wake/removal/shutdown/expiry, client timeout, retryable restoration plus recovery watchdog, absent/disabled/wrong-version handshake, exact arguments and malformed/mixed wire evidence. All charging/SMC effects are injected. Existing no-dwell/native/journal/signing suites pass. Final full rerun includes the stricter source-return success rule.

[Upstream review](../research/opendente-aldente-chie.md) covers all currently listed OpenDente issues/PRs including pinned PR #4 diff/reviews and AlDente's current public source limits, vendor behavior and relevant maintainer issue responses. No dependencies, upstream implementation, Swift mode changes, sleep assertions or automatic adapter cycling added.

## Signed candidate

`apps/monny/build/release/Monny-1.0-17.dmg` is ready, signed with the existing Apple Development identity and not notarized. Release build and artifact tests pass: app/helper signer match; wrong identifier/pin, ad-hoc, debugger and tampered negative fixtures. Image integrity and read-only mount review pass: build 17, Applications link, exact app/helper bytes matching signed staging and strict deep signature. The signed app refuses an extra observation argument with invalidArguments/exit 1 before helper access. SHA-256: `3585befba7c57f3c917f6198d9042f1a52870b4e2ad1bc2b346407e1840b0226`.

Candidate preparation performed no valid hardware invocation or helper installation. The later authorized runtime check is recorded below; no native-setting mutation or Sketch change was performed. All new effects in tests are injected. New files remain visible to Git; affected local links, shell syntax and git diff --check pass. No Git commit. BAT-025 build-16 evidence and build-17 runtime evidence below retain their original scope.

## Authorized direct-adapter observation — 2026-10-20

The user explicitly authorized the new bounded experiment, reported installing build 17/updating the helper, and connected a separate third-party charger rated approximately 60 W. Actual negotiated wattage and exact adapter model were not collected; do not attribute the result to a specific rating/protocol. Installed app metadata independently reports build 17; authenticated diagnostics advertise observation revision 1, full physical verification false and notControlling. Initial read-only source is adapter with affirmative raw/external flags. The helper reports known-open lid and sufficient battery during the attempt. The user was instructed to disconnect the USB-C monitor; its absence was not independently inspected.

The agent quit the ordinary app and executed --observe-adapter-byte **exactly once** as the ordinary user. Command elapsed time is approximately 1.64 seconds (whole process, not isolation duration). The response has five candidate samples and batterySourceObserved=true. Before source/flags are adapter/true/true; the final during reading is battery/false/false, with no charging and no native getter during isolation. The report acknowledges attempted/applied CHIE=8 and restored CHIE=0. Measured native before/after snapshots match; no Monny native session was active.

The command returns **exit 1**, correctly under its strict contract: the immediate after snapshot still says battery with raw/external flags false despite CHIE=0. This does not mean a reported byte-restoration failure. A subsequent separate read-only power diagnostic reports adapter source and raw/external/charge-capable flags true, with adapter details populated. Subsequent read-only helper adapter diagnostics report CHIE=0 with the expected signature, unchanged native snapshot and notControlling. The later return time is not precisely measured and must not be described as immediate or within a guaranteed interval. Raw bounded JSON remains temporary/local outside the repository.

The user additionally confirms a noticeable charging/power disconnection for approximately one second followed by reconnection. This duration is a user estimate, not a measured firmware/telemetry latency. This accepts one observed source-selection transition and user-visible return to adapter on this setup, plus byte rollback and matching native endpoints. It does not measure electrical power flow, establish sustained isolation, certify physical cable predicates or close adapter-specific crash/sleep/removal recovery. Both raw and ordinary external flags drop during isolation despite the connected charger: **neither can serve as an independent physical-cable provider during this state**. They cannot distinguish isolation from physical unplugging.

No second isolation attempt, longer dwell, native write, helper kill, sleep test or retry was performed. Existing 250-test/package evidence above was not rerun for this evidence-only update.

## Build 18: read-only source-return settling

Observation revision **2** preserves the same single-write/two-second isolation observation and three-second recovery watchdog. Only after the transaction acknowledges CHIE=0 and clears its journal does an independent read-only settling window begin: at most two seconds/eight fresh readings, normally 250 ms apart. Every reading first validates CHIE is still zero, then obtains actual native/source data. No setter or renewed hardware lease runs in this window. Source publication delays never extend isolation. The original request reservation remains until the response; native/pulse/observation competitors cannot take ownership while it awaits. Session/phase/state/cancellation are rechecked after suspension; sleep/wake/removal/disconnect/shutdown terminate observation without replay.

`returnObservation` distinguishes adapterObserved, boundReached, interrupted, unavailable and notAttempted, with a separate returnSampleCount. The latest valid actual after snapshot is retained; no pre-pulse data is substituted. Missing/stale data or observed native changes stop settling and prevent success. Zero exit still requires battery/no-charge evidence, confirmed byte restoration, unchanged native endpoints and an observed return to adapter. A deadline reached before an adapter reading is accepted remains inconclusive/nonzero. Synchronous calls can outlast software budgets; no hard deadline is claimed.

The CLI requires revision 2 and uses a seven-second response timeout for the two independent observation windows and recovery overhead. Revision-1 helpers refuse before the selector; helper installation remains explicit. Older no-dwell/native/full-isolation contracts remain unchanged. Full physical verification and product Discharge remain disabled.

Agent-observed build-18 **dev.sh test: 255 tests in 30 suites pass**, including app/helper compilation. Five added test functions and expanded timeout parameters cover delayed adapter publication with CHIE=0/journal already cleared, no additional setters, settling sample/time bounds, missing/stale/native-change/unexpected-byte data, reservation across cancellation/sleep/wake/removal/disconnect/shutdown, real anonymous-XPC timeout during either isolation or settling, revision-1 helper refusal and wire round trips. All effects are injected. Final full rerun includes late-reading deadline checks and revision compatibility. No new hardware operation was used to validate the change.

Signed build-18 candidate: `apps/monny/build/release/Monny-1.0-18.dmg`, SHA-256 `03942cd1fcd189585e970e7d34811c866cbd90cd5a84620a6cf53cbe929c5805`. Existing Apple Development signing identity, not notarized. Release build, signer/negative fixture checks, image integrity and read-only mount verification pass: build 18, Applications link, exact app/helper binaries matching signed staging and strict deep signature. Invalid extra observation arguments refuse before helper access. Affected local links, shell syntax and git diff --check pass; no Git commit or hardware invocation.

## Build-18 installed source/settling acceptance — 2026-10-20

Following the scoped test/update handoff, the user reports readiness. Installed metadata independently identifies build 18; authenticated diagnostics advertise observation revision 2, notControlling and no full physical verification. Initial read-only source is adapter. The existing dedicated-adapter test setup was requested; exact adapter/connection details were not independently recaptured. The helper confirms open lid and sufficient battery. The agent quit the ordinary app and invoked --observe-adapter-byte exactly once as the ordinary user.

**Exit 0**: batterySourceObserved=true after five during samples; returnObservation=adapterObserved after two post-rollback samples. CHIE attempted/applied 8 and restored 0, before/during/after source adapter→battery→adapter, raw/external flags true→false→true, no active native session and matching actual native endpoints. During-native remains absent. Whole command elapsed approximately 2.04 seconds, not a measured isolation or firmware publication interval. No setter extends/repeats isolation while waiting for source return.

Subsequent separate read-only adapter/power diagnostics confirm CHIE=0 with expected signature, adapter source/affirmative connection flags, unchanged native settings and notControlling. Raw JSON remains temporary/local outside the repository. No second attempt, native-setting write, helper install, sleep/crash experiment or automatic retry performed. Existing 255-test/package checks above are historical and not rerun for this evidence-only update.

This accepts the bounded revision-2 source-return report on this setup, including delayed source publication. It does not establish electrical flow, sustained control, an independent physical-cable provider or real adapter recovery after crash/sleep/removal. Product Discharge/full physical verification remain disabled. The one build-18 test authorization is consumed.

## Next action

[BAT-027](BAT-027-adapter-restart-recovery.md) now owns the separate adapter-specific helper-exit/recovery experiment, authenticated startup evidence and acceptance/safety conditions. Any helper crash, sleep/removal or longer isolation trial needs separate reviewed scope and user authorization; no further hardware action follows automatically from this passing test. Native helper restart/journal rollback remains accepted separately and does not substitute for adapter-specific recovery.
