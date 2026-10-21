# Monny: current state

Updated **2026-10-21**. Current work: [APP-007](tasks/APP-007-native-simplification-design-parity.md) production review on main. Main is a native monitor with the macOS 26.4+ system charge limit; no helper, XPC, SMC writes or Discharge. The helper/Discharge experiment is preserved on **experiments/discharge** at abe3a80.

## Product and implementation

- macOS 26+ / Apple silicon, SwiftUI/AppKit, Swift 6 complete concurrency. Target/module `monny`, product `Monny.app`, bundle ID `blinks44.monny`. Monitoring works independently of charge-limit availability. Below macOS 26.4, a localized information banner replaces the charge-limit controls and explains that monitoring remains available.
- Direct charge limit requires macOS 26.4+ and a supported PowerUI runtime. Ordinary-user getters, a distinct supported target/read-back and final original-pair restoration succeed locally on macOS 27.0.1. Enable can reset the target: enable only when necessary, then set and read back. Private API and macOS 26.4 execution remain limitations.
- The selected native limit is a persistent system preference, as requested; macOS enforces it through app quit, sleep and restart. Launch/wake only refresh state. No recurring setter, journal, lease or forced discharge. Unknown data disables controls. Do not infer immediate discharge from lowering a limit.
- Users of helper builds (≤ 23) remove the helper in the old app before replacing it. Discharge, sailing, heat protection, trips and calibration are deferred and not shown in the app; their Sketch frames remain.
- One shared sampler supplies real CPU/memory/disk/network/process/battery readings, SMC temperatures/fans and NVMe health. History spans 1m–7d. Notifications for charge limit reached (once per plug-in), heat, low battery and memory pressure, login item, global shortcut, language and manual update check exist.
- Popover Battery now follows the live Sketch hero/gauge/target geometry. Footer/header typography, window content insets and toolbar spacing are reconciled with Sketch. Loading says “Collecting data…”; unavailable readings remain unavailable.
- Six-language String Catalog: EN/RU/DE/FR/ES/zh-Hans. Retired helper text removed; retained copy reviewed and terminology corrected. Light/Dark/localized renders are temporary local evidence.
- Distribution remains signed DMG outside the App Store; existing Apple Development signer, Hardened Runtime, App Sandbox off for system monitoring. Signed does not mean notarized. Website work remains deferred.

**Candidate:** `apps/monny/build/release/Monny-1.0-28.dmg` (signed Apple Development, not notarized): build 27 review changes plus Overview cards that open their dashboard page, uncommitted; 33 tests/8 suites pass.

## Work and open checks

| Task | Stage | Next step |
| --- | --- | --- |
| [APP-007](tasks/APP-007-native-simplification-design-parity.md) | awaiting_verification | Installed build 27 accepted by the user, including a limit change seen in System Settings. Remaining: release gates below. |
| [CORE-002](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Compare temperature/fan readings with a reference on real hardware. |
| [CORE-003](tasks/CORE-003-history.md) | awaiting_verification | User rechecks chart/hover behavior with accumulated history. |
| [APP-003](tasks/APP-003-settings-alerts.md) | awaiting_verification | Actual notification delivery and settings acceptance. |
| [DES-002](tasks/DES-002-native-onboarding-next-features.md) | ready_for_implementation | Implement native onboarding, then the designed next-feature items. |
| [REL-001](tasks/REL-001-signing-workflow.md) | awaiting_verification | Clean second-Mac signing/install, signing backup restore/off-device copy. |

Helper/Discharge task and verification records (BAT-*, APP-005/006) live on experiments/discharge only.

## Remaining release gates

User-accepted on 2026-10-21: installed build 27, charge-limit change visible in System Settings, macOS 26, six languages, reading comparisons. Open: onboarding (SPEC §6), VoiceOver/keyboard/contrast/motion, idle cost, real notification delivery, clean-Mac installation. Notarization waits for a paid Developer ID. [PLAN](PLAN.md) owns release sequencing; [SPEC](SPEC.md) owns behavior.

Before release (user decision 2026-10-21): native onboarding, processes grouped by app, optional menu bar readings, sustained app load alert and current power draw, all designed in [DES-002](tasks/DES-002-native-onboarding-next-features.md). Discharge research follows the release ([PLAN](PLAN.md#next-features)).
