# Battery control: current mechanism and historical alternatives

Updated 2026-10-23. Main uses the persistent macOS 26.4+ charge-limit preference as an ordinary user. No helper, XPC, SMC writes or adapter isolation. Current behavior: [SPEC §5](../SPEC.md#5-battery-control); implementation/acceptance: [APP-007](../tasks/APP-007-native-simplification-design-parity.md).

## Native limit decision

The runtime-checked `PowerUISmartChargeClient` bridge refuses unknown/mismatched signatures. Explicit changes validate target and matching read-back; enable only when needed because enabling can reset the target. 100% disables the limit. Optimized Battery Charging is independent and shown only when readable. Launch/wake only read; macOS owns enforcement and persistence, with no restoration on quit.

2026-10-21, M1 Max/macOS 27.0.1: ordinary-user getter, distinct target/read-back and restoration of the original pair succeeded in a standalone probe; the user confirmed the installed app changed System Settings. 2026-10-22, build 38: user confirmed slider and optimization changes. Private API compatibility, macOS 26.4–26.x and other hardware remain unverified.

Apple's [charging documentation](https://support.apple.com/en-us/102338) was reviewed 2026-10-19: optimization and Charge Limit are distinct; thresholds can be approximate and occasional full charges support state-of-charge estimation. Lowering a limit does not imply forced discharge.

## Optimized Battery Charging runtime — 2026-10-22

The independently checked selectors are `isSmartChargingCurrentlyEnabled:` (`Q`, `^@`), `enableSmartCharging:` and `disableSmartCharging:` (`B`, `^@`). A signature mismatch hides only the Optimized switch. The read-only M1 Max/macOS 27.0.1 probe established coexistence with an enabled native limit. The user confirmed the optimization write/read-back in build 38; an already-open System Settings Battery sheet needs reopening to show it. The runtime reports a disabled limit as target 100. No dependency or third-party implementation was adopted.

## Historical helper and dependency review — 2026-10-19

The following describes the retired experiment, not main's implementation or future authorization.

## Installation and IPC

Use Apple's [SMAppService daemon](https://developer.apple.com/documentation/servicemanagement/smappservice/daemon(plistname:)) with the launchd property list inside `Contents/Library/LaunchDaemons` and a bundled helper executable. Follow Apple's [Service Management sample](https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api). Installation remains an explicit user action; observe service status and direct pending approval to Login Items & Extensions. Require restoration acknowledgement before unregistering any charging-capable helper. The current non-writing contract permits explicit unregister after transport failure/timeout; invalid/mismatched/restoration-failure replies remain blocked (BAT-008). Do not use shell installers or SMJobBless.

Use native `NSXPCConnection` and a small versioned interface. Apple's [setCodeSigningRequirement](https://developer.apple.com/documentation/foundation/nsxpcconnection/setcodesigningrequirement(_:)) enforces requirements on the actual peer and must be called before resume. Require the expected identifier and the same validated signer in both directions: Apple anchor/team for Apple-issued identities, or an exact leaf-certificate pin for the experimental self-signed path; reject absent identities. Do not authorize by PID, executable path or bundle ID alone. Stable signing and a negative test with a differently signed client remain required before enabling privileged commands.

Alternative evaluated: [SecureXPC](https://github.com/trilemma-dev/SecureXPC) (MIT). It supports SMAppService and secure peer checking. The [Swift Package Index](https://swiftpackageindex.com/trilemma-dev/SecureXPC) lists 0.8.0 and a sparse release history; Swift 6 strict-concurrency/macOS 26 integration is not established here. Native Foundation already provides the needed peer enforcement, so another dependency is unnecessary. No package installed.

## Charging support varies with firmware

[batt's compatibility notes](https://github.com/charlie0129/batt#compatibility-matrix) and [issue 152](https://github.com/charlie0129/batt/issues/152) report legacy keys `CH0B`/`CH0C`/`CHTE` and firmware limits `bfF0`/`bfD0`/`bfE0`. New firmware can expose empty placeholders or deny access even to root. This can affect an older OS after firmware updates; model/OS checks alone cannot establish support. These are third-party reports, not a Monny hardware result.

Do not infer write access from key existence/readability, install a helper automatically, request private entitlements or change SIP. Unsupported charging stays with macOS. Cutting adapter power makes the Mac discharge and can affect clamshell use; it does not implement Hold and is not an automatic fallback. Hardware commands require their own capability and restoration evidence.

Licensing: [batt](https://github.com/charlie0129/batt/blob/master/LICENSE) is GPL-2.0; only compatibility documentation was consulted, no implementation copied. [actuallymentor/battery](https://github.com/actuallymentor/battery) has an [MIT root license](https://github.com/actuallymentor/battery/blob/main/LICENSE), but its shell/GUI installation and bundled SMC tool are not a ready native SMAppService integration. No code or binaries adopted; a root license alone would not establish licensing for every bundled component. No suitable ready charging package was established by the Swift Package Index search.


## Experiment disposition and open acceptance

Full helper implementation, task/verification records (BAT-*, APP-005/006) and dated lifecycle research are preserved on **experiments/discharge** at `09595b5`. Read them there before resuming that work; no duplicate implementation journal is maintained on main. [SMC research](smc-charge-control.md) retains mechanism/licensing findings and bounded results.

Observed experiment checks included native-setting round trips, bounded helper restart rollback, CHIE byte rollback, bounded adapter-source transitions, active sleep recovery and removal (builds 16–23, 2026-10-20/21). They do not establish a production Discharge mode, sustained electrical behavior or every failure boundary. Open: client-exit recovery, sustained control, broader hardware/firmware, clean-Mac and runtime negative-peer acceptance. Reconcile exact task evidence on the experiment branch before planning anything further.

Next: finish main's native compatibility checks. Any return to Discharge needs a product/safety/distribution decision; this record authorizes no helper install or hardware experiment.
