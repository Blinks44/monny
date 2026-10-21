# BAT-024: Guarded adapter verification IPC

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: awaiting_verification (software/package ready; native runtime prerequisite and adapter physical gates open)
- Owner: unassigned; scoped implementation/package ownership released
- Baseline: main cb9abff plus preserved uncommitted app/helper/design work; no Git commit
- Owned surfaces: adapter report, executor request ownership, additive status/protocol/session/client, explicit CLI, tests, signing fixture source list and scoped records
- Requirements: SPEC §5 fail-safe; BAT-022 software core; BAT-023 accepted baseline

## Outcome and acceptance

Prepare a fixed three-second authenticated adapter verification request using injected backends, validated before/during/after observations and explicit rollback uncertainty. Production supplies no adapter backend and advertises adapterVerificationAvailable=false: physical semantics under isolation and real crash/restart recovery remain gates. No helper installation or hardware write is authorized/performed by this preparation.

- [x] Positive revisioned handshake precedes the zero-argument selector; old helpers stay readable/removable.
- [x] One request owns the asynchronous observation/report interval; foreign/expired sessions cannot revive it or write over it.
- [x] Every exit restores or retains restorationRequired; byte acknowledgement is separate from return to adapter source.
- [x] Typed bounded reports reject inconsistent success/restoration/ownership evidence.
- [x] Anonymous-XPC, cancellation/timeout/lifecycle, negative handshake and failure tests pass; build/package checks recorded.
- [x] Concrete next user hardware prerequisite is recorded; no production adapter backend is enabled.
- [ ] User validates build-15 native helper crash/restart restoration. Adapter physical-provider/recovery acceptance remains separate even if this passes.

## Implementation and verification

`AdapterVerificationReport` records the exact admitted before/during environments and optional fresh after reading. restoredAfterObservation requires initial adapter/connected/adequate-battery evidence, battery-source/no-charge evidence with unchanged native settings, and acknowledged CHIE=0 rollback. That outcome alone does not imply return to wall power: the command's success exit additionally requires fresh connected adapter-source evidence and unchanged native settings after rollback. Missing post-read, external native change or disconnected evidence cannot produce exit 0. failedRestored requires a before observation and byte acknowledgement; restorationRequired cannot carry a confirmed-restored byte or after reading. Invalid values, incompatible flags/revision, conflicting native/adapter reports and mismatched control state fail closed; client payload stays bounded to 4 KiB.

Additive protocol-1 selector verifyAdapterIsolation has no key, target, duration or path parameters. The explicit --verify-adapter-isolation CLI accepts no extra arguments, performs one authenticated status handshake and one attempt, and never retries. Version 1 is independent of native session revision 3. Older helpers lacking the flag report helperUpdateRequired; a disabled new helper reports verificationNotEnabled without sending the selector. Normal launch/status/diagnostics never start verification.

The actor wrapper reserves the request across every observation suspension, including the interval after lifecycle recovery already returned state to macOS. Native/adapter competitors remain blocked until the original request revalidates and exits. Existing three-second non-renewable watchdog, expiry-token revocation, checkpoint/startup/disconnect/sleep/removal/shutdown restoration remain the authority. Cancellation restores without trusting missing telemetry. Failed recovery blocks removal; explicit retry can acknowledge later recovery. Private/synchronous I/O is not forcibly interruptible. The hardware constructor remains uncalled and its separate production journal is unopened.

Agent-observed on the existing Xcode 27.1/Swift 6.4, Apple-silicon/macOS 27.0.1 environment:

- Final dev.sh test: **227 tests in 27 suites pass**. Twelve new test functions cover default nil backend, absent/disabled/wrong-revision handshake, real authenticated anonymous-XPC success, wrong peer, client timeout/disconnect, byte-vs-source evidence, external native change, malformed/mixed reports, fixed arguments/no retry, competing requests, sleep/wake admission during a deliberately suspended report, cancellation/sleep/disconnect/removal/shutdown/expiry recovery, non-transition watchdog expiry and retryable restoration failure. All hardware/charging effects are injected. Prior adapter/native/signing/IPC regressions pass. The last full rerun includes the tightened missing-before and mixed-report rejection checks.
- Release build/signing/package checks use the existing identity; no dependency/tool/key installation, helper registration or charge operation. The standalone signing fixture compiler list includes the new shared report/core dependencies. Final artifact checksum and mount/runtime checks are recorded below.
- Source ownership/call-site review confirms no production adapter backend or physical-provider fallback. The app routes the new diagnostic command before creating its model/SMC reader. Shell syntax, new-path Git visibility, scoped local links and git diff --check pass. Existing unused-result/AppIntents/Release Text-concatenation warnings remain outside this slice.

## Artifact

Artifact: `apps/monny/build/release/Monny-1.0-15.dmg`. SHA-256: **ad4409955694903c83c72f2482475cb219252217aa68dc46f4fc39ea5309c68a**.

Final release.sh passes signed runtime/app/helper identity and negative-peer/ad-hoc/debuggable/tampering fixtures, strict signatures and DMG integrity. Read-only mounting verifies build 15, Applications link and exact signed app/helper executable hashes against staging; the image is detached. The final staging executable rejects an extra adapter-verification argument with exit 1/invalidArguments before any helper access, and its unprivileged power command exits 0 with valid build-15 JSON. No valid hardware verification command was run. Complete local power output stays temporary; no machine output is committed. The earlier preliminary package was replaced after final validation tightening; only the checksum above identifies this candidate. It is signed with the existing Apple Development identity, not notarized. No macOS 26 or clean-Mac runtime claim follows from local tests.

## User-reported helper restart — 2026-10-20

The user confirms that a distinct temporary native target was visibly active before force-quitting the helper, the helper reappeared in approximately 4–5 seconds, and the original enabled/value pair returned with controlState=notControlling. The supplied before/after reports match that original pair. This accepts the bounded native helper restart/journal rollback observation on the user's build-15 setup; intermediate activation is confirmed by the user's follow-up, not independently sampled by the agent. No repeat crash is needed. Exact process identities and package hashes were not independently recaptured. App crash, sustained physical enforcement, CHIE recovery and other platforms remain open. No raw machine output is retained.

## User check: native helper recovery

This is the next runtime prerequisite; it exercises the existing native setting backend, **not CHIE**. It temporarily changes a system charge limit and deliberately terminates Monny's helper. The agent has not performed either action. The user controls every step. Keep the lid open and power connected, and do not alter the system charge setting during the observation.

1. In the currently installed Monny, switch control off and explicitly uninstall the responding helper through Settings, then quit Monny. Replace the app in Applications from the build-15 DMG; launch it and explicitly install/approve its helper. A copied app alone does not replace a running daemon. If safe removal/installation fails, stop and report that failure rather than bypassing the restoration acknowledgement.
2. With Monny control off, record the original macOS charge-limit enabled/value pair using this read-only command:

   ```sh
   /Applications/Monny.app/Contents/MacOS/Monny --battery-diagnostics
   ```

   Keep this **before** report. Confirm the app is build 15 and the response contains adapterVerificationAvailable=false, identifying the new prepared-but-disabled helper contract; missing that field means the expected helper update has not been established. Native readings must be available. Do not continue with an unknown original pair.
3. In Monny, explicitly enable 80%; if the original value was already 80%, choose 90% instead. Confirm the different value appears in macOS Battery Settings. Leave the Monny app running. No --verify-adapter-isolation command is part of this test.
4. In Activity Monitor, show All Processes, find exactly MonnyBatteryHelper and note its PID locally. Select it and use Stop → Force Quit; macOS may ask for administrator authentication ([Apple instructions](https://support.apple.com/en-lamr/guide/activity-monitor/actmntr1002/mac)). Do not force-quit unrelated processes or repeat the kill.
5. Wait about 15 seconds, then capture the same --battery-diagnostics command as **after**. Check that a new MonnyBatteryHelper process appeared, the original enabled/value pair returned, controlState is notControlling and Monny did not automatically re-enable the temporary target. A read may need to reconnect; this is observation, not permission to replay a control request. Keep any error as evidence.
6. Return the before/after reports and whether the helper reappeared, the original setting returned and Monny control stopped. Exact PIDs, terminal identity, serials and unrelated machine data are not needed in repository evidence. If restoration is not confirmed, do not re-enable control or repeat the crash: restore the original setting explicitly in macOS Battery Settings and report what failed. No BTM reset/security change/root shortcut is part of this check.

## Limits and next handoff

A passing native crash test establishes this daemon's restart/native-journal recovery availability in the observed scenario, not physical charge enforcement, sustained operation, app-crash/removal acceptance, CHIE access or adapter-journal recovery. Existing BAT-005/BAT-018/BAT-022 gates remain scoped separately.

The native restart/rollback prerequisite is user-confirmed above. [BAT-025](BAT-025-adapter-byte-pulse.md) owns the separate pulse-only hardware reader/transport and signed build-16 candidate. Full physical-isolation verification still lacks an independent provider and remains unavailable. Byte evidence must not enable Discharge; actual CHIE execution requires explicit authorization for the fixed attempt and rollback.
