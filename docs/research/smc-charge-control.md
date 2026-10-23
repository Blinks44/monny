# SMC control below 80%, Hold and Discharge

> Battery helper and Discharge task/verification records referenced here (BAT-*, APP-005/006, helper verification) were retired from main on 2026-10-21; they are preserved on the `experiments/discharge` branch.

Reviewed **2026-10-20** for BAT-019. Historical research for the retired helper/Discharge experiment; current main supports only the native limit. CHIE is a candidate for separately verified adapter isolation, not permission to enable a charging mode.

Product scope update (2026-10-20): charge-limit targets below 80% and separate Hold-at-current-level are removed in [SPEC §5](../SPEC.md#5-battery-control). The comparison below retains the researched inhibition distinction; the experiment still required a separate at-limit mechanism. Discharge is now deferred on main. This removal does not make CHIE-only adapter isolation sufficient for those behaviors.

## Mechanisms and product fit

| Mechanism | Below-80% limit | Hold on adapter | Plugged-in Discharge | Local evidence / decision |
| --- | --- | --- | --- | --- |
| Native PowerUI / system Charge Limit | No advertised value below 80 | No arbitrary immediate Hold | No explicit adapter isolation | Experiment BAT-018: setting round trip and ordinary sleep preservation accepted |
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


## Final experiment findings and remaining gates

2026-10-20/21, M1 Max/macOS 27.0.1, builds 16–23: byte rollback and bounded adapter→battery→adapter source observations succeeded. Raw/external connection flags became false during isolation, so neither proves physical cable presence. Registry AdapterDetails remained populated even when unplugged, so it also fails as a connection predicate. Firmware publication can lag after byte-zero restoration; a separate read-only settling window was needed. A quick no-dwell byte pulse alone did not establish a physical transition.

Bounded helper-restart, active sleep/wake and removal recovery were observed on this setup. They do not prove client-exit recovery, sustained electrical control, all timing boundaries or broader hardware support. Full physical Discharge remains unverified. Exact artifacts, commands, receipts and all open experiment acceptance remain on **experiments/discharge** at `09595b5` (BAT-019–030); [related source review](opendente-aldente-chie.md).

Main has no SMC writer/helper. Next: use the native limit; any new experiment requires a separate product/safety decision and concrete authorization. Do not infer support from metadata, setter success, tests or a third-party compatibility claim.
