# BAT-027: Adapter-specific helper restart recovery

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: done (bounded build-19 helper-only unclean-exit recovery accepted)
- Owner: app engineering; bounded ownership released
- Baseline: main cb9abff plus preserved uncommitted work; build-18 bounded source/return evidence accepted in BAT-026
- Scope: authenticated startup recovery receipt, one-shot engineering restart verification, behavioral tests and signed candidate; no real crash/write/install

## Outcome

Prepare one separately authorized CHIE checkpoint/write/read-back followed by deliberate helper-only process termination, then verify a different helper instance restored the pending adapter record before serving requests. Do not use a longer timed isolation window, kill an arbitrary process, modify native settings, retry the mutation or enable Discharge. Existing KeepAlive is a runtime dependency, not a guaranteed recovery deadline.

## Acceptance

- [x] New helper instance and validated initial/recovered byte are observable through authenticated read-only status; no paths/PIDs/serials exposed.
- [x] Explicit revisioned zero-argument test admission retains all existing byte/source/lid/native-owner safeguards and durable intent.
- [x] Only the helper terminates itself after known CHIE=8; any failed admission/write/read-back restores normally and does not terminate.
- [x] Client sends mutation once and polls only read-only status afterward, with bounded waiting and no native/source assumptions.
- [x] Behavioral/process-fixture tests and concrete fallback/authorization handoff prepared.
- [x] Signed build-19 package and read-only mount review pass.
- [x] One separately authorized real helper-only unclean-exit recovery passes; broader lifecycle gates remain outside this bounded acceptance.

## Implementation

Build **19** adds `--verify-adapter-restart`, with exactly zero extra arguments and a separate authenticated adapterRestartVerificationAvailable/revision-1 handshake. No product UI invokes it. Production startup creates a process-local random helperInstance and reports adapterStartupRecovery after adapter recovery, before native construction/listener activation. A pending checkpoint receipt records the freshly validated initial CHIE byte (0 or 8) and acknowledged restored byte 0; no checkpoint has an explicit false receipt. No path, PID, hardware identity or raw journal crosses IPC. Startup failure refuses service. These fields are additive to protocol 1 and old status/removal clients remain compatible.

The explicit selector accepts only a live authenticated session in ready/macOS state, without native/adapter owner or reserved request. It reuses known-zero/signature/native/source/raw/lid/battery admission and durable checkpoint-before-write. Only after the single fixed setter and CHIE=8 read-back does the live helper invoke _exit(75) on itself. No external PID, signal, shell command or arbitrary termination API is accepted. No cleanup/termination handler runs; this deliberately tests persisted startup recovery. A failed admission/setter/read-back never invokes termination. A returning/throwing test callback restores normally; failed rollback retains recovery intent and a recovery-only watchdog attempt. Other constructors have no terminating callback and cannot advertise or execute this selector.

The client sends the mutation exactly once. An ordinary reply or invalid reply is failure; only expected transport interruption/timeout proceeds to read-only status polling. It requires a different helperInstance with checkpointFound=true, initialByte=8 and restoredByte=0, matching freshly measured native settings, notControlling and an actual adapter-source observation. A restarted process without a checkpoint, initial zero, changed settings, unknown source or unchanged instance cannot count as success. Read-only polling has both a 15-second monotonic budget and 24-attempt limit (500 ms pauses, one-second request timeouts). Synchronous firmware calls can exceed software budgets. Cancellation never retries the mutation. Success stays unverified for product control.

No observation dwell or automatic crash loop is added. After deliberate termination the three-second in-process watchdog no longer exists: actual outage/recovery time depends on launchd, startup and firmware. The local launchd.plist manual documents default throttling of repeated quick exits; neither a two-second nor a fixed restart-time guarantee applies. Existing KeepAlive=true is unchanged, with no throttle override, extra watchdog daemon or sleep assertion. See Apple's [launchd guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html) and [launchd.plist source](https://github.com/apple-oss-distributions/launchd/blob/main/man/launchd.plist.5). Native restart recovery was observed previously, but that is a prerequisite, not acceptance of this adapter experiment.

## Software evidence

A separate-process fixture, `apps/monny/scripts/verify-adapter-recovery.sh`, compiles the existing transaction/storage with file-backed injected SMC operations. The first ordinary-user subprocess persists the real private adapter journal and injected byte 8, then exits via _exit(75) without cleanup. A second process loads/restores injected zero, clears the record and preserves a native sentinel. A third process confirms no pending checkpoint and idempotent zero state. Agent-observed all stages pass. It never opens AppleSMC or registers/terminates an installed helper; this proves process/disk reconstruction only, not root directory permissions, actual launchd availability or hardware rollback.

Swift Testing covers real private-file reopening before native construction, authenticated anonymous-XPC receipt delivery, initial-zero distinction, failure before/after setter, ignored writes/save failures, callback return/throw, active-native/foreign/invalid/removing admission, unsupported/wrong-version handshake, missing/false recovery and source evidence, one-mutation polling, unexpected replies, startup fail-closed and malformed receipts. Added final checks cover anonymous selector refusal, cancelled/invalid-reply collector admission and rollback retry after a refused termination. All SMC/process effects are injected; no live callback or real _exit was used by hosted tests.

## Proposed hardware test and fallback

**Not authorized or executed yet.** Install/approve the signed build-19 app/helper through Monny. Use the dedicated adapter, USB-C monitor disconnected, lid open, battery comfortably above 30%, ordinary Monny/native control and competing controllers off. Do not sleep, unplug or manually kill/restart a process during the command. Record the read-only before feature/instance/native snapshot. With explicit authorization for one fixed CHIE write/read-back and one helper-only unclean exit, run exactly once as the ordinary user:

```sh
/Applications/Monny.app/Contents/MacOS/Monny --verify-adapter-restart
```

The new helper must autonomously recover adapter input from its journal before serving requests. Keep the Mac visible while waiting; connection failure during the deliberate exit is expected but not success. The CLI waits read-only and never replays. Confirm the final receipt/source/native settings and CHIE=0 using separate read-only diagnostics. Retain any nonzero report; do not repeat the test or begin another control session.

If adapter power does not return or helper startup fails, stop all tests, keep the lid open and preserve battery charge. Reconnect the dedicated power cable and report whether power returns; reconnection is a troubleshooting observation, not a guaranteed reset of CHIE. A Mac restart may be required to let the registered helper try startup recovery again, under separate user control. Do not use a root shell, private entitlement, foreign SMC utility, SIP/BTM changes or manual journal deletion to bypass recovery. There is no independent hardware watchdog in this design; this failure-mode test explicitly depends on OS restart availability and carries a longer possible outage than previous bounded observations. Present this limitation with the authorization request.

One passing test establishes the observed helper-exit/checkpoint/restart rollback case only. It does not validate kernel failure, loss of storage, every crash instruction boundary, sleep/removal, sustained Discharge or other models/OS versions. Keep product Discharge and full physical verification disabled.


Final agent-observed dev.sh test: **265 tests in 31 suites pass**, compiling app/helper under the existing Swift 6 strict-concurrency/Xcode 27.1/Swift 6.4/macOS 27.0.1 environment. The first test compile exposed throwing-expression inference inside an assertion; corrected by reading the throwing value before asserting. The final full rerun includes recovery-only retry and cancellation/XPC refusal checks. The separate subprocess fixture also passes. No real process identity, machine data or raw logs are retained in versioned evidence.


## Signed candidate and current handoff

Signed **Monny 1.0 build 19**: `apps/monny/build/release/Monny-1.0-19.dmg`; SHA-256 `8afdbc854f4ab8917ec5f340ef62422e1abf7ff51eaaa5c28be4495dd78c84c7`. Existing Apple Development identity, signed/not notarized. Release build and signing fixtures pass: matching app/helper signer and negative wrong-ID/pin/ad-hoc/debugger/tampered artifacts. Image integrity/read-only mount review confirms build 19, Applications link, exact app/helper binaries matching signed staging and strict deep signature. Signed CLI refuses extra restart arguments with invalidArguments/exit 1 before helper access. During candidate preparation no valid restart command or ordinary diagnostic was used against the installed helper; the later authorized runtime result is below.

Affected local link targets, shell syntax, Git visibility/ignore checks and git diff --check pass. Candidate preparation performed no helper install, real SMC access/write, installed process termination, native-setting change, Sketch edit or Git commit. Temporary compiler/test/package outputs remain local. Software ownership released for user verification; next user action is installation/approval and explicit consent to the single longer-outage helper-restart experiment above. Do not treat ordinary readiness for the earlier two-second observation as authorization for this new failure mode.


## Authorized installed helper recovery — 2026-10-20

The user explicitly authorizes the scoped failure experiment after the build-19 handoff. Installed app metadata independently identifies build 19; authenticated before diagnostics advertise restart verification revision 1, a helper instance and no pending startup checkpoint. Control is notControlling and source adapter. The dedicated-adapter/open-lid/no-monitor setup is requested as in the prior check; exact adapter and monitor connections were not independently recaptured. Runtime admission enforces open lid, sufficient battery and initial source/raw/native state.

The agent quits the ordinary app and executes --verify-adapter-restart **exactly once** as the ordinary user. **Exit 0**: helperRestarted=true, startupRecovery.checkpointFound=true, initialByte=8, restoredByte=0, nativeSettingsPreserved=true and adapterSourceObserved=true. Authenticated subsequent diagnostics identify a different helper instance and repeat the pending-eight-to-zero startup receipt; direct adapter diagnostics read CHIE=0 with the expected metadata. Native settings match the before snapshot, control remains notControlling and public power diagnostics report adapter with affirmative connection flags.

Whole CLI execution is approximately 0.405 seconds in this observation. This is not a measured physical isolation interval or a guaranteed launchd restart latency; source telemetry may not publish every intermediate transition. The verified evidence is known-eight durable intent, loss of the former helper process, different-instance startup recovery and actual zero/adapter/native endpoints. No user-visible duration or electrical power-flow claim is made. Exact process UUIDs/raw JSON remain local outside the repository.

No repeated isolation, manual process kill, native write, sleep/removal test or automatic mutation retry was performed. Existing 265-test/package/process-fixture evidence remains historical; this evidence-only update does not rerun it. The single authorized experiment is consumed.

## Completion and remaining work

The bounded BAT-027 acceptance is complete on the observed setup: the helper-only unclean-exit/journal/restart path restores the adapter before serving requests. This does not guarantee other crash instruction boundaries, firmware/kernel/storage failure, sleep/removal, sustained control, other adapters/hardware or macOS 26. Product Discharge/full physical verification stay disabled. [BAT-028](BAT-028-adapter-lifecycle-evidence.md) now owns observable sleep/wake/removal preparation and a first idle callback-delivery check; no further hardware action has been performed. No further approval for another crash or longer isolation follows from this result.
