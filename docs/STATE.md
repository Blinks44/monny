# Monny: current state

Updated **2026-10-21**. Current work: [APP-007](tasks/APP-007-native-simplification-design-parity.md) production review on main. Main is a native monitor with the macOS 26.4+ system charge limit; no helper, XPC, SMC writes or Discharge. The helper/Discharge experiment is preserved on **experiments/discharge** at abe3a80.

## Product and implementation

- macOS 26+ / Apple silicon, SwiftUI/AppKit, Swift 6 complete concurrency. Target/module `monny`, product `Monny.app`, bundle ID `blinks44.monny`. Monitoring works independently of charge-limit availability. Below macOS 26.4, a localized information banner replaces the charge-limit controls and explains that monitoring remains available.
- Direct charge limit requires macOS 26.4+ and a supported PowerUI runtime. Ordinary-user getters, a distinct supported target/read-back and final original-pair restoration succeed locally on macOS 27.0.1. Enable can reset the target: enable only when necessary, then set and read back. Private API and macOS 26.4 execution remain limitations.
- The selected native limit is a persistent system preference, as requested; macOS enforces it through app quit, sleep and restart. Launch/wake only refresh state. No recurring setter, journal, lease or forced discharge. Unknown data disables controls. Do not infer immediate discharge from lowering a limit.
- Users of helper builds (≤ 23) remove the helper in the old app before replacing it. Discharge, sailing, heat protection, trips and calibration are deferred and not shown in the app; their Sketch frames remain.
- One shared sampler supplies real CPU/memory/disk/network/process/battery readings, SMC temperatures/fans and NVMe health. History spans 1m–7d. Notifications for charge limit reached (once per plug-in), heat, low battery and memory pressure, login item, global shortcut, language and manual update check exist. Native three-step onboarding opens on first launch (build 30, [APP-009](tasks/APP-009-native-onboarding.md)). Optional CPU/temperature/battery readings next to the status item (build 31, [APP-010](tasks/APP-010-menu-bar-readings.md)) and an optional alert when one app keeps the Mac busy (build 33, [APP-011](tasks/APP-011-busy-app-alert.md)). The Battery page shows the Mac's current power draw (build 35, [APP-013](tasks/APP-013-power-draw.md)). Updates use Sparkle with an appcast on GitHub Releases (build 34, [APP-012](tasks/APP-012-sparkle-updates.md)); nothing is published yet.
- Popover Battery now follows the live Sketch hero/gauge/target geometry. Footer/header typography, window content insets and toolbar spacing are reconciled with Sketch. Loading says “Collecting data…”; unavailable readings remain unavailable.
- Six-language String Catalog: EN/RU/DE/FR/ES/zh-Hans. Retired helper text removed; retained copy reviewed and terminology corrected. Light/Dark/localized renders are temporary local evidence.
- Distribution remains signed DMG outside the App Store; existing Apple Development signer, Hardened Runtime, App Sandbox off for system monitoring. Signed does not mean notarized. Website work remains deferred.

**Candidate:** `apps/monny/build/release/Monny-1.0-35.dmg` with `appcast.xml` (signed Apple Development, not notarized): 037d588 (grouped processes, keyboard, lower dashboard cost) plus native onboarding, menu bar readings, keyboard-only focus rings, the busy app alert, Sparkle and the power draw card, uncommitted; 39 tests/9 suites pass.

## Work and open checks

| Task | Stage | Next step |
| --- | --- | --- |
| [APP-007](tasks/APP-007-native-simplification-design-parity.md) | awaiting_verification | Installed build 27 accepted by the user, including a limit change seen in System Settings. Remaining: release gates below. |
| [CORE-002](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Compare temperature/fan readings with a reference on real hardware. |
| [CORE-003](tasks/CORE-003-history.md) | awaiting_verification | User rechecks chart/hover behavior with accumulated history. |
| [APP-003](tasks/APP-003-settings-alerts.md) | awaiting_verification | Actual notification delivery and settings acceptance. |
| [APP-008](tasks/APP-008-grouped-processes-keyboard-idle-cost.md) | awaiting_verification | User checks that rings appear only after keyboard use (build 32) and Tab order with Keyboard navigation on; popover cost still unmeasured. |
| [APP-009](tasks/APP-009-native-onboarding.md) | awaiting_verification | User confirms the build 31 window layout fix; other languages' wrapping. |
| [APP-010](tasks/APP-010-menu-bar-readings.md) | awaiting_verification | User checks readings in a dark menu bar, popover position and badge with readings on. |
| [APP-011](tasks/APP-011-busy-app-alert.md) | awaiting_verification | User sees the banner for a busy app and checks the copy. |
| [APP-012](tasks/APP-012-sparkle-updates.md) | awaiting_verification | End-to-end update between two published releases; off-device copy of the update key. |
| [APP-013](tasks/APP-013-power-draw.md) | awaiting_verification | Compare on-battery values with the adapter unplugged. |
| [DES-002](tasks/DES-002-native-onboarding-next-features.md) | done | All designed features are implemented; Settings › About update switch still undrawn. |
| [REL-001](tasks/REL-001-signing-workflow.md) | awaiting_verification | Clean second-Mac signing/install, signing backup restore/off-device copy. |

Helper/Discharge task and verification records (BAT-*, APP-005/006) live on experiments/discharge only.

## Remaining release gates

User-accepted on 2026-10-21: installed build 27, charge-limit change visible in System Settings, macOS 26, six languages, reading comparisons. Open: onboarding user walkthrough (SPEC §6), VoiceOver/contrast/motion and the keyboard check, popover idle cost, real notification delivery, clean-Mac installation. Notarization waits for a paid Developer ID. [PLAN](PLAN.md) owns release sequencing; [SPEC](SPEC.md) owns behavior.

Before release (user decision 2026-10-21): native onboarding (build 30), processes grouped by app (build 29), optional menu bar readings (build 31), sustained app load alert (build 33), Sparkle updates (build 34) and current power draw (build 35), all designed in [DES-002](tasks/DES-002-native-onboarding-next-features.md). Discharge research follows the release ([PLAN](PLAN.md#next-features)).
