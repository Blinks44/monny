# SMC control below 80%, Hold and Discharge

> Battery helper and Discharge task/verification records referenced here (BAT-*, APP-005/006, helper verification) were retired from main on 2026-10-21; they are preserved on the `experiments/discharge` branch.

Reviewed **2026-10-20** for BAT-019. Decision: keep the existing native-limit backend; no reviewed mechanism currently establishes the remaining SPEC behaviors on the development Mac. CHIE is a candidate for separately verified adapter isolation, not permission to enable a charging mode.

Product scope update (2026-10-20): charge-limit targets below 80% and separate Hold-at-current-level are removed in [SPEC §5](../SPEC.md#5-battery-control). The comparison below retains the researched inhibition distinction; automatic holding at the selected limit and after Discharge is still required. This removal does not make CHIE-only adapter isolation sufficient for those behaviors.

## Mechanisms and product fit

| Mechanism | Below-80% limit | Hold on adapter | Plugged-in Discharge | Local evidence / decision |
| --- | --- | --- | --- | --- |
| Native PowerUI / system Charge Limit | No advertised value below 80 | No arbitrary immediate Hold | No explicit adapter isolation | Existing 80/85/90/95/100 setting round trip and ordinary sleep preservation accepted; retain BAT-018 |
| Legacy CH0B/CH0C or CHTE inhibition | Possible with a live policy on compatible firmware | Candidate dedicated charging inhibition | Requires an independent adapter key | All three reject metadata locally, including prior authenticated helper diagnostics; do not enable |
| Firmware bfF0/bfD0/bfE0 range | Reported on earlier compatible firmware | Cannot assume: firmware may discharge above its range | Not independently established by a range setting | All three reject metadata locally and through the prior helper; do not enable |
| Adapter isolation CHIE, alternatives CH0I/CH0J | Cycling between thresholds is possible in third-party reports, but violates Monny's run-on-adapter limit contract | No: removing wall input consumes battery | Candidate for the discharge phase only; endpoint Hold still needs a separate mechanism | CHIE reads one-byte hex_ metadata; CH0I/CH0J unavailable. BAT-025 confirms one byte round trip/rollback only; physical effect remains inconclusive |

These are separate capabilities. A readable key or successful setter/read-back is insufficient evidence of physical charging inhibition or adapter isolation. Firmware version and model names are context, never capability grants.

Apple's [Charge Limit documentation](https://support.apple.com/en-gb/102338) describes 80–100%, approximate thresholds and occasional full charging for estimation. It does not provide an arbitrary below-80% public control API. [batt issue 152](https://github.com/charlie0129/batt/issues/152) reports a private entitlement gate on the legacy/firmware keys and the powerd SOC-limit path. That is third-party evidence, consistent with Monny's access failures, not independent proof of the kernel's exact check here. Neither root escalation nor skipping metadata is an established solution. Do not request private entitlements or change SIP.

## Existing solutions reviewed

- **batt** (GPL-2.0): [adapter-mode PR 154](https://github.com/charlie0129/batt/pull/154), merged 2026-09-24 as `aa9b6ff`, reports explicit adapter cycling on gated firmware. Its mechanism needs awake policy execution and has clamshell/sleep constraints; it cannot provide Monny's Hold contract. GPL documentation/reference only; no source adopted. Native fallback already exists in Monny. Do not adopt another daemon/installer or its sleep assertions.
- **OpenDente** (GPL-3.0), `06c5a8199f5c0657374e667073b3aa6a75f50df8`: GitHub API confirms unchanged main/push date 2026-05-04. Main CHTE/CH0B detection does not overcome the observed rejection. The newer open issue #3/PR #4 adds CHIE fallback and a state-machine fix outside main; [the updated issue/PR review](opendente-aldente-chie.md) records its pinned head and hardware limits. No GPL implementation adopted.
- **Battery Toolkit macOS 27 fork** (BSD-3-Clause), `5c8587d4239831b413425fbc1c00e69559b6c689`, API last push 2026-09-21, not archived: reviewed pinned [SMCComm+Power.swift](https://github.com/diegonoceli/Battery-Toolkit-MacOs-27/blob/5c8587d4239831b413425fbc1c00e69559b6c689/Libraries/SMCComm%2BPower.swift). It accepts an adapter key without a charge key, but `disableCharging()` returns true without writing when no charge key exists; `isChargingDisabled()` returns false. Therefore its broader supported-machine result does not prove Hold or charge stopping on CHIE-only hardware. Adapter enable/disable remains separate. No code adopted; do not reproduce the successful no-op as control support.
- **BatteryControl** (MIT), `9ab2eecc1b104c27ebd7a3cb69df070e9d52eaee`, API last push 2026-09-25, not archived: [README](https://github.com/Ednk-1312/BatteryControl) explicitly stops active development and limits physical validation to one M3/macOS 15.8. Reviewed pinned [SMCLayer.swift](https://github.com/Ednk-1312/BatteryControl/blob/9ab2eecc1b104c27ebd7a3cb69df070e9d52eaee/Helper/SMCLayer.swift), [Backends.swift](https://github.com/Ednk-1312/BatteryControl/blob/9ab2eecc1b104c27ebd7a3cb69df070e9d52eaee/Helper/Backends.swift) and [Package.swift](https://github.com/Ednk-1312/BatteryControl/blob/9ab2eecc1b104c27ebd7a3cb69df070e9d52eaee/Package.swift). SMC families use the same unavailable keys. Its package exports core models/client and CLI, not the Helper hardware backends, and uses Swift 5 language mode. It is not a ready maintained Swift 6 charging package for Monny.

BatteryControl's other named candidates do not establish another usable backend: its CHWA probe is an unsupported stub, not verified hardware discovery. Its power-assertion backend explicitly records ChargeInhibit acceptance without physical enforcement on its tested Mac and advertises control as unverified. No assertion created here; do not mistake an accepted IOPM assertion for stopped charging. These source observations are narrower than the projects' advertised feature lists.

Swift Package Index search was attempted but returned a fetch error. No registry-wide completeness claim. Earlier SMCKit and original Battery Toolkit maintenance/licensing decisions remain in BAT-009. No dependency installed, foreign code copied, foreign binary compiled or executed.

## Local read-only evidence

Agent-observed 2026-10-20 on the development Apple-silicon Mac (previously identified as M1 Max/macOS 27.0.1; no new serial/firmware inventory collected). A temporary Swift 6 executable compiled only the unchanged Monny `BatteryHelperShared/SMC.swift` and a fixed nine-key harness calling `SMCConnection.inspect`. The harness never prints raw values, enumerates keys, invokes XPC/helper, registers services or implements writes.

| Keys | Result |
| --- | --- |
| CH0B, CH0C, CHTE, CH0I | SMC result 132 (0x84), no metadata |
| bfF0, bfD0, bfE0, CH0J | IOKit -536870207 (0xe00002c1), no metadata |
| CHIE | Readable, type hex_, size 1; value omitted; write support unverified |

The first sandboxed invocation could not open AppleSMC; a separately approved run outside the sandbox as the ordinary user obtained the table above. Sandbox connection failure is not unsupported hardware evidence. The six charge-key results reproduce earlier unprivileged and authenticated helper observations; CH0J adds a previously unrecorded local rejection. This run does not establish current privileged CHIE/CH0J access or write permission. The shipped diagnostic's fixed six-key response remains unchanged.

Reproduction: compile a temporary `@main` Swift harness with `SMC.swift` using `xcrun swiftc -swift-version 6 -parse-as-library -module-cache-path <temporary-cache> ... -o <temporary-probe>`. Open one SMC connection; inspect exactly `CH0B, CH0C, CHTE, bfF0, bfD0, bfE0, CHIE, CH0I, CH0J`; print only success type/size or failure. Run unprivileged with AppleSMC access. Do not substitute a foreign SMC executable or a root write test.

## Implementation decision and next step

1. Preserve native 80–100% UI and all open BAT-018/BAT-005 crash/helper-restart, sustained physical and broader platform acceptance. No artifact, lifecycle or charging change follows from this research.
2. Targets below 80% and separate manual Hold are removed from product scope. Keep Discharge disabled pending an independently verified mechanism. CHIE alone supplies no at-limit ceiling. Engineering hypothesis for the revised scope: one owner could coordinate a supported native 80–100% limit with adapter isolation, then restore adapter input at the target and leave holding to the native limit. This combination has not been implemented or physically verified; native approximation, coexistence and partial-failure restoration need their own acceptance. The earlier 60% endpoint example belongs to the superseded below-80% scope.
3. The separate **read-only adapter diagnostic** through the authenticated helper for CHIE/CH0I/CH0J is implemented and accepted on the installed path in BAT-021. User-supplied 2026-10-20 output confirms CHIE readable (hex_, one byte), CH0I SMC 132 and CH0J IOKit -536870207, with control unverified/notControlling. Exact installed build/hash and physical power state were not independently recaptured. No raw output retained. Do not infer write permission or enable a mode from this report.
4. BAT-022 now prepares an injected CHIE 0→8 transaction with a separate secure recovery namespace, a three-second observation budget and native-setting preservation. Its exact hex_/one-byte/0xD4 admission and 0/8 constants come from the previously reviewed pinned BSD Power source above; the stored reviewed source was consulted again, with no implementation copied. A direct fresh web fetch of that pinned page failed, so no new upstream-maintenance claim is made. No ready package removes the already-recorded compatibility/lifecycle limits. The value core is driven by an injected executor owner/watchdog/startup/lifecycle path in software tests. No full physical-isolation backend is provided; its revisioned selector/CLI is prepared in BAT-024 but advertised false. Build 16 adds the separate pulse-only construction described below. Helper-only unbound operation preparation is recorded below, with no executed SMC write. The later live adapter verification writer still needs reviewed original-state checkpoint/recovery wiring, single ownership coordinating any native limit and adapter state without competing controllers, exact type/size validation, read-back and observed adapter/charging behavior, pre-sleep/default restoration, monotonic lease and startup recovery tests. Physical adapter connection must be distinguished from source selection. Unknown state, external ownership, missing readings or restoration failure must refuse control. Close crash/helper-restart safety gates and obtain explicit target/rollback authorization before any real writes. No automatic native-limit or optimization setting changes, sleep prevention or silent adapter fallback.

The bounded research is complete; hardware control remains unsupported/unverified. No app build/test rerun is required for documentation and a temporary read-only probe. Historical 180-test/build-12 results remain historical evidence.

## Unbound helper operations — 2026-10-20

BAT-022 now compiles a fixed Bool-only CHIE setter exclusively in the helper target, with no production constructor/call site or writable IPC. Rechecked [MIT SMCKit](https://raw.githubusercontent.com/beltex/SMCKit/master/SMCKit/SMC.swift) for command 6 and existing call layout, and [BSD-3-Clause original Battery Toolkit Power source](https://raw.githubusercontent.com/mhaeuser/Battery-Toolkit/master/Libraries/SMCComm%2BPower.swift) for CHIE hex_/one-byte/0xD4 and allowed/isolated 0/8. The earlier pinned fork fetch failed again; no new maintenance/compatibility claim follows. Existing ready-solution/licensing decisions above remain; no implementation copied or package installed.

Apple's [IOPowerSources header](https://raw.githubusercontent.com/apple-oss-distributions/IOKitUser/main/ps.subproj/IOPowerSources.h) and [IOPSKeys](https://raw.githubusercontent.com/apple-oss-distributions/IOKitUser/main/ps.subproj/IOPSKeys.h), also checked in the installed SDK, distinguish active source selection from adapter descriptions; the adapter-details call can return nil for either no adapter or error. They do not establish the behavior/freshness of independent physical cable evidence during CHIE isolation. Do not turn missing data into unplugged/plugged proof, or latch initial presence through the probe. Prepared source decoding therefore requires an explicit independent physical-presence provider and refuses nil. That provider remains an engineering dependency before production construction.

Every unbound environment call acquires native settings and source data anew and bounds its acquisition interval with ContinuousClock. This is not proof of firmware publication freshness, physical isolation, or restoration of wall power. Injected operation/decoding and existing recovery regressions pass in the 209-test run. No physical reading/write check or installed-helper update was performed. Next evidence collection is now prepared in BAT-023 below, before guarded verification IPC and separately authorized bounded hardware acceptance.

## Physical-adapter evidence collection — 2026-10-20

Apple's [IOPMPowerSource contract](https://raw.githubusercontent.com/apple-oss-distributions/xnu/main/iokit/IOKit/pwr_mgt/IOPMPowerSource.h) defines ExternalConnected in terms of external power draw. It does not establish physical cable presence while input is isolated. The reviewed [IOPM keys](https://raw.githubusercontent.com/apple-oss-distributions/xnu/main/iokit/IOKit/pwr_mgt/IOPM.h) supply no AppleRawExternalConnected isolation guarantee. Therefore neither source selection nor ExternalConnected can fill the independent physical-provider gate. RawExternalConnected and registry AdapterDetails remain candidates, not grants; no fallback is wired.

A third-party [battery-limiter README](https://github.com/MlayKlayer/battery-limiter/blob/main/README.md) reports AdapterDetails surviving CH0I isolation on its tested setup. This is a hardware-specific lead, not CHIE evidence for Monny. Its raw source/API fetch was unavailable, no new maintenance/license/package-adoption conclusion is made and no implementation was copied. The existing native APIs suffice to collect observations; no new dependency can substitute for validating this firmware behavior.

A narrowly approved, unprivileged AppleSmartBattery read on the development Mac found the selected five Boolean properties and a populated AdapterDetails dictionary. Only allowlisted type/presence summaries were emitted; no serials, IDs or raw registry output were retained. Physical connection was not independently manipulated/verified by the agent. The first sandboxed ioreg call failed; that was access failure, not absent-hardware evidence.

BAT-023 implements `--adapter-power-diagnostics` in signed build 14 and now has a complete user-supplied USB-C-monitor unplug/replug comparison. Source selection changes adapter→battery→adapter; ExternalConnected, AppleRawExternalConnected and ExternalChargeCapable change yes→no→yes. Registry AdapterDetails stays populated throughout, including unplugged: reject it as an attachment predicate on this setup. Public adapter details change populated→unavailable→populated; unavailable still is not generally a proven absence rather than error.

This establishes baseline correlation only, not independent physical-presence semantics while CHIE is isolated. Short acquisition duration measures query time, not firmware freshness. No CHIE write or physical recovery observation follows, and no repeat baseline is required. Bounded authenticated verification reporting/IPC is now prepared in BAT-024 with injected negative/lifecycle tests, retaining unknown physical support and production-backend gating; an eventual explicitly authorized one-shot experiment must report candidate flags before/during/after isolation. No raw user/machine output retained.

## Guarded verification transport — 2026-10-20

BAT-024 reuses the existing authenticated session, fixed checkpoint/lease executor and native XPC transport without a new mechanism/dependency. Its before/during/after report differentiates byte restoration, power-source return and unchanged native settings; success in fixtures grants no physical capability. The live daemon still constructs no adapter backend and advertises the selector unavailable. Raw/source correlation from BAT-023 is not promoted into a physical provider.

The next hardware prerequisite is a user-owned native helper restart/recovery check on build 15, not CHIE isolation. Apple's [Activity Monitor process-termination instructions](https://support.apple.com/en-lamr/guide/activity-monitor/actmntr1002/mac) and [process visibility instructions](https://support.apple.com/en-ie/guide/activity-monitor/actmntr1001/mac) were checked for the proposed manual step: show all processes, select MonnyBatteryHelper and Force Quit; administrator authentication may be required. This is a planned controlled failure, not an operation performed by the agent. KeepAlive and native-journal reconstruction are implemented/software-tested, but the user subsequently confirms bounded native restart/rollback in BAT-024; adapter-specific recovery remains open. No private entitlement, BTM reset, root shell, sleep assertion, extra watchdog daemon or automatic helper install is added. A passing native check would not establish CHIE physical restoration or justify treating raw flags as verified during isolation.

## Byte evidence without physical inference — 2026-10-20

The strict isolation transaction cannot legitimately use unverified raw connection semantics to prove those same semantics. BAT-025 therefore prepares a separate injected, no-dwell byte-research operation using the already reviewed CHIE constants/transport and existing recovery schema. No new hardware API, dependency or source implementation is adopted. Normal begin/observe retains independent physical-adapter admission.

The pulse report captures unknown raw/source observations as data and calls success only a byte round trip with matching measured native settings. It does not advertise physical isolation, adapter connection or product control support. A native getter is not needed during isolation: that report field may remain absent, with actual fresh before/after native snapshots instead. Build 16 adds the guarded pulse-only reader/transport and fixed adapter startup recovery, while full physical verification stays disabled. No new dependency or third-party implementation is used. A concrete user-authorized experiment and real adapter recovery are still required.

For lid admission, the installed SDK and Apple's [IOPM.h](https://github.com/apple-oss-distributions/xnu/blob/main/iokit/IOKit/pwr_mgt/IOPM.h) define kAppleClamshellStateKey on IOPMrootDomain as a Boolean closed/open state. The reader accepts only an actual CFBoolean false; absent, integer or ambiguous services refuse initial admission. It projects only fixed battery/lid properties, not identities. This is a precondition, not atomic protection against a later lid close. Getter acquisition duration is not firmware publication age.

The user now confirms the distinct temporary native target was active before helper force-quit and the original pair returned after reappearance in roughly 4–5 seconds. BAT-024 accepts bounded native restart/journal rollback. It does not establish CHIE recovery, native app-crash safety or physical control. No hardware operation is performed by the agent.


## First authorized real byte pulse — 2026-10-20

Installed build 16 completes one fixed CHIE 0→8→0 pulse with read-back, matching native endpoints and no active control; subsequent read-only diagnostics confirm CHIE=0. Source remains adapter and raw/external flags remain true in all no-dwell samples. This proves byte acceptance/restoration only: no firmware update-age guarantee exists, and the sample cannot establish physical isolation or independent cable semantics. The user tentatively noticed no monitor/link change; physical effect remains inconclusive in BAT-025. No repeat, dwell extension or adapter crash experiment is authorized by this result.


## Bounded observation decision — 2026-10-20

The requested [OpenDente issues/PR and AlDente review](opendente-aldente-chie.md) supports a separate fixed, bounded source-observation experiment, not automatic adapter cycling or a new physical provider. BAT-026 prepares at most two seconds/eight samples with one isolation attempt and existing rollback, reserved ownership and startup recovery. Direct adapter comparison is preferred to USB-C monitor/dock power. Real execution remains separately authorized; current native settings and product capabilities are unchanged.


## First bounded source observation — 2026-10-20

BAT-026 observes battery/no-charge source and raw/external flags false during one authorized CHIE attempt on a separate charger. Byte-zero rollback/native preservation pass; immediate after-source lags, while later read-only diagnostics confirm adapter/affirmative flags and CHIE=0. Both flags therefore fail as independent physical-presence evidence during isolation. Prepare read-only post-restore settling evidence; no setter retry or extended isolation follows from this result.


## Adapter restart verification preparation — 2026-10-20

BAT-027 reuses the fixed helper/journal mechanism and existing KeepAlive for one explicit helper-only unclean exit after known-eight read-back, with additive authenticated instance/recovery evidence. Apple launchd documentation and the local launchd.plist manual confirm restart/throttling semantics; there is no hard recovery-time guarantee. No new dependency, arbitrary process control, sleep assertion, private entitlement or root shortcut is justified. The command stays separate from normal bounded observation; real execution needs new explicit authorization. Ordinary-user file-backed subprocess recovery passes but does not establish physical or privileged restart recovery.


## First authorized adapter helper-exit recovery — 2026-10-20

BAT-027 now accepts one real installed build-19 checkpoint/known-eight/helper-only unclean-exit experiment. A different authenticated process reports pending-eight-to-zero recovery before service, matching native endpoints and adapter source; subsequent read-only diagnostics confirm CHIE=0/notControlling. This validates the bounded observed restart path, not every failure boundary, physical transition timing, sleep/removal or sustained Discharge. No retry or further hardware action is authorized.


## Observable lifecycle preparation — 2026-10-20

BAT-028 adds authenticated per-instance event/outcome receipts to the existing IORegisterForSystemPower/executor path, without a new writer or OS-sleep selector. Failures before sleep phase and during removal now remain eligible for wake recovery. The installed public IOPMLib header permits IOPMSleepSystem for root or the console user; Apple [pmset source](https://github.com/apple-oss-distributions/PowerManagement/blob/main/pmset/pmset.m) shows native error handling. No root workaround or helper-issued system sleep is adopted. The first handoff tests real callback delivery at idle with CHIE=0, not active isolation or uninstall. Those hardware gates remain open.


## Active sleep preparation — 2026-10-20

BAT-029 uses public IOPMFindPowerManagement/IOPMSleepSystem only in the ordinary console-user app, after a retained authenticated helper session confirms known-eight checkpointed preparation. The helper remains charge-only and keeps the existing three-second watchdog. No AppleEvents permission, root shortcut, sleep assertion or wake schedule is needed. SDK admission/error semantics and Apple pmset reference were reviewed; refusal cancels/restores. Only actual adapterRestored-at-sleep receipt plus same-instance wake/native/source evidence can pass. Idle callback delivery or timer-first rollback is insufficient. The first authorized build-21 trial restores before sleep and later provides paired same-instance wake/CHIE-zero/native/source evidence, but its CLI exits wakeNotObserved. Software-requested sleep returns before full wake; transition and DarkWake can exhaust the immediate observation budget. Wake observation must be armed before the request and collection bounded after wake; no longer hardware lease or repeated real attempt is justified. BAT-029 owns the correction and limits.


## Wake barrier correction — 2026-10-20

Build 22 uses app-only [NSWorkspace willSleep](https://developer.apple.com/documentation/appkit/nsworkspace/willsleepnotification) and [didWake](https://developer.apple.com/documentation/appkit/nsworkspace/didwakenotification) through the workspace's own notification center, as Apple requires. Register before preparation/request and buffer paired wake before awaiting it; the callback never blocks sleep. A separate 60-awake-second event bound precedes the unchanged post-wake receipt/source budget. Workspace wake only schedules collection: authenticated same-instance helper receipts still establish the observed recovery. No assertion, longer hardware lease, privileged sleep request, dependency or new helper selector is needed. Injected tests pass; the new real trial remains unauthorized/open in BAT-029.


## Corrected active sleep accepted — 2026-10-21

The single authorized installed build-22 trial now exits 0 with the workspace wake barrier and unchanged watchdog. Independent same-instance paired helper receipts, direct CHIE=0, no control, native preservation and adapter source confirm the bounded observed recovery (BAT-029). No repeated request or longer hardware lease was needed. Active removal, broader failure timing/platforms and sustained physical behavior remain separate gates; Discharge stays disabled.


## Active adapter removal preparation — 2026-10-21

BAT-030 reuses the fixed checkpoint preparation and existing restoration acknowledgement, then ordinary app-only [SMAppService.unregister](https://developer.apple.com/documentation/servicemanagement/smappservice/unregister(completionhandler:)) once. Native API is already used by Monny, so no custom uninstaller or new dependency is justified. Direct unprivileged CHIE reads before preparation/after removal avoid contacting or relaunching a removed helper. Pre-unregister native preservation and post-removal byte/source evidence remain explicitly distinct. The helper exposes no unregister/shell/PID API. Software checks pass; no actual removal or hardware write occurred and real execution needs new authorization (BAT-030).


## Bounded active removal accepted — 2026-10-21

The single authorized installed build-23 trial exits 0: active restoration acknowledgement and matching native settings precede unregister, direct unprivileged CHIE=0 and adapter source follow it. Independent launchd/process lookups show absence without XPC or registration. Native preservation is measured before removal only. Helper stays unregistered; no reinstall or further experiment is authorized. This accepts the observed removal path, not client-exit, sustained physical behavior or broader platforms (BAT-030).


## Main implementation simplified — 2026-10-21

All helper/Discharge code and verification tools are preserved on experiments/discharge at abe3a80. Main now has no SMC setter or privileged helper. Ordinary-user runtime-checked PowerUI getters and distinct target setter/read-back succeeded locally; a final restore verified the original pair. Reasserting enable resets the target on the observed runtime, so direct control enables only when needed before setting the target. No adapter isolation was performed. The persistent system-preference contract supersedes old temporary native ownership: macOS enforces the chosen target after quit. macOS 26.4 execution and private API compatibility remain open ([APP-007](../tasks/APP-007-native-simplification-design-parity.md)).
