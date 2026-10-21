# Monny: current state

Updated **2026-10-21**. Current implementation work: [APP-007](tasks/APP-007-native-simplification-design-parity.md), based on main abe3a80. The complete Discharge/helper experiment is preserved on **experiments/discharge** at abe3a80. Main is now a native monitor with a small direct system charge-limit setting; no privileged helper, XPC, SMC writer or engineering mutation commands.

## Product and implementation

- macOS 26+ / Apple silicon, SwiftUI/AppKit, Swift 6 complete concurrency. Target/module `monny`, product `Monny.app`, bundle ID `blinks44.monny`. Monitoring works independently of charge-limit availability. Below macOS 26.4, a localized information banner replaces the charge-limit controls and explains that monitoring remains available.
- Direct charge limit requires macOS 26.4+ and a supported PowerUI runtime. Ordinary-user getters, a distinct supported target/read-back and final original-pair restoration succeed locally on macOS 27.0.1. Enable can reset the target: enable only when necessary, then set and read back. Private API and macOS 26.4 execution remain limitations.
- The selected native limit is a persistent system preference, as requested; macOS enforces it through app quit, sleep and restart. Launch/wake only refresh state. No recurring setter, journal, lease or forced discharge. Unknown data disables controls. Do not infer immediate discharge from lowering a limit.
- The previous helper was explicitly removed in the accepted build-23 test. No automatic installation/removal/migration. Users of older helper builds must remove their helper in the old app before replacing it. Discharge, sailing, manual heat control, trip schedules and calibration are deferred; existing design references remain unchanged.
- One shared sampler supplies real CPU/memory/disk/network/process/battery readings, SMC temperatures/fans and NVMe health. History spans 1m–7d. Notifications for measured charge-limit attainment/heat/low battery/memory pressure, login item, global shortcut, language and manual update check exist.
- Popover Battery now follows the live Sketch hero/gauge/target geometry. Footer/header typography, window content insets and toolbar spacing are reconciled with Sketch. Loading says “Collecting data…”; unavailable readings remain unavailable.
- Six-language String Catalog: EN/RU/DE/FR/ES/zh-Hans. Retired helper text removed; retained copy reviewed and terminology corrected. Light/Dark/localized renders are temporary local evidence.
- Distribution remains signed DMG outside the App Store; existing Apple Development signer, Hardened Runtime, App Sandbox off for system monitoring. Signed does not mean notarized. Website work remains deferred.

**Candidate:** signed build 25, 34 tests/9 suites pass and 252 local renders generated; read-only DMG review confirms no helper. Source and records are saved together in one main-branch commit; the experiment branch is preserved.

## Work and open checks

| Task | Stage | Next step |
| --- | --- | --- |
| [APP-007](tasks/APP-007-native-simplification-design-parity.md) | awaiting_verification | Install/review build 25; verify direct setting/persistence and the updated UI. |
| [CORE-002](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Compare temperature/fan readings with a reference on real hardware. |
| [CORE-003](tasks/CORE-003-history.md) | awaiting_verification | User rechecks chart/hover behavior with accumulated history. |
| [APP-003](tasks/APP-003-settings-alerts.md) | awaiting_verification | Actual notification delivery and settings acceptance. |
| [APP-005](tasks/APP-005-battery-design-parity.md) | awaiting_verification | Final native-only Battery visual review now belongs to APP-007. |
| [REL-001](tasks/REL-001-signing-workflow.md) | awaiting_verification | Clean second-Mac signing/install, signing backup restore/off-device copy. |

The old BAT/helper tasks retain historical evidence, not current main implementation requirements. Their continued experiment gates belong to experiments/discharge. Accepted bounded adapter source/return, helper restart, active sleep and removal tests do not establish sustained Discharge. No further adapter experiment is authorized.

## Remaining release gates

User review of the native-only signed app, direct setting operations on supported macOS 26.4/hardware, real reading comparisons, idle cost, accessibility (VoiceOver/keyboard/contrast/motion), all languages at minimum window size, clean-Mac signing and notarized distribution. [PLAN](PLAN.md) owns release sequencing; [SPEC](SPEC.md) owns behavior and [DESIGN](DESIGN.md) points to the unchanged live Sketch source.
