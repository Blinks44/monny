# Monny: current state

Updated **2026-10-22**. Current work: AI limits ([APP-015](tasks/APP-015-ai-usage-limits.md)) and the [APP-007](tasks/APP-007-native-simplification-design-parity.md) production review on main. Main is a native monitor with the macOS 26.4+ system charge limit; no helper, XPC, SMC writes or Discharge. The helper/Discharge experiment is preserved on **experiments/discharge** at abe3a80.

## Product and implementation

- macOS 26+ / Apple silicon, SwiftUI/AppKit, Swift 6 complete concurrency. Target/module `monny`, product `Monny.app`, bundle ID `blinks44.monny`. Monitoring works independently of charge-limit availability. Below macOS 26.4, a localized information banner replaces the charge-limit controls and explains that monitoring remains available.
- Direct charge limit requires macOS 26.4+ and a supported PowerUI runtime. Ordinary-user getters, a distinct supported target/read-back and final original-pair restoration succeed locally on macOS 27.0.1. Enable can reset the target: enable only when necessary, then set and read back. Private API and macOS 26.4 execution remain limitations.
- The selected native limit is a persistent system preference, as requested; macOS enforces it through app quit, sleep and restart. Launch/wake only refresh state. No recurring setter, journal, lease or forced discharge. Unknown data disables controls. Do not infer immediate discharge from lowering a limit.
- Users of helper builds (≤ 23) remove the helper in the old app before replacing it. Discharge, sailing, heat protection, trips and calibration are deferred and not shown in the app; their Sketch frames remain.
- One shared sampler supplies real CPU/memory/disk/network/process/battery readings, SMC temperatures/fans and NVMe health. History spans 1m–7d. Notifications for charge limit reached (once per plug-in), heat, low battery and memory pressure, login item, global shortcut, language and manual update check exist. Native three-step onboarding opens on first launch (build 30, [APP-009](tasks/APP-009-native-onboarding.md)). Optional CPU/temperature/battery readings next to the status item (build 31, [APP-010](tasks/APP-010-menu-bar-readings.md)) and an optional alert when one app keeps the Mac busy (build 33, [APP-011](tasks/APP-011-busy-app-alert.md)). The Battery page shows the Mac's current power draw (build 35, [APP-013](tasks/APP-013-power-draw.md)). Updates use Sparkle with an appcast on GitHub Releases (build 34, [APP-012](tasks/APP-012-sparkle-updates.md)); nothing is published yet.
- Popover Battery now follows the live Sketch hero/gauge/target geometry. Footer/header typography, window content insets and toolbar spacing are reconciled with Sketch. Loading says “Collecting data…”; unavailable readings remain unavailable.
- Six-language String Catalog: EN/RU/DE/FR/ES/zh-Hans. Retired helper text removed; retained copy reviewed and terminology corrected. Light/Dark/localized renders are temporary local evidence.
- Distribution remains signed DMG outside the App Store; existing Apple Development signer, Hardened Runtime, App Sandbox off for system monitoring. Signed does not mean notarized. Website work remains deferred.

Optional AI limits ([APP-015](tasks/APP-015-ai-usage-limits.md)): Claude Code and Codex (build 44, accepted), Cursor and Grok (build 45, unverified on real accounts) in a popover tab, an AI usage page and a running-low notification, off by default, with a checkbox per tool. On, Monny calls the services' usage endpoints with the tools' own sign-in on this Mac ([research](research/ai-usage-limits.md)); this is the one network exception besides Sparkle. Gemini is not possible without cookies.

**Candidate:** `apps/monny/build/release/Monny-1.0-49.dmg` with `appcast.xml` (signed Apple Development, not notarized): main with the AI limits commits (tabs size to their titles; Sketch frames for Cursor, Grok and four tools) and service marks (build 49); 61 tests/10 suites pass.

## Work and open checks

| Task | Stage | Next step |
| --- | --- | --- |
| [APP-007](tasks/APP-007-native-simplification-design-parity.md) | awaiting_verification | Pre-release review in build 37, accepted by the user with its copy. Open: charge limit on macOS 26.4–26.x. |
| [CORE-002](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Compare temperature/fan readings with a reference on real hardware. |
| [CORE-003](tasks/CORE-003-history.md) | awaiting_verification | User rechecks chart/hover behavior with accumulated history. |
| [APP-012](tasks/APP-012-sparkle-updates.md) | awaiting_verification | End-to-end update between two published releases; off-device copy of the update key. |
| [DES-002](tasks/DES-002-native-onboarding-next-features.md) | awaiting_verification | Revised Settings layout (stacked menu bar readings, About in the right column) implemented in build 42. User checks Settings in German/French. |
| [APP-015](tasks/APP-015-ai-usage-limits.md) | awaiting_verification | Claude/Codex accepted in build 44. Build 47 reviewed and committed. Open, waiting for accounts: Cursor, Grok, model limits and credits on real accounts; chart, forecast, stale reading and notification after a few days of real history; HTTP 429 over long sessions. Design source: [DES-003](tasks/DES-003-ai-usage-limits.md); Cursor not implemented. |
| [REL-001](tasks/REL-001-signing-workflow.md) | awaiting_verification | Clean second-Mac signing/install, signing backup restore/off-device copy. |

Helper/Discharge task and verification records (BAT-*, APP-005/006) live on experiments/discharge only.

## Remaining release gates

User-accepted on 2026-10-21: installed build 27, charge-limit change visible in System Settings, macOS 26, six languages, reading comparisons; on build 37 the copy, onboarding, menu bar readings, busy app banner, power on battery, keyboard/VoiceOver/contrast/motion, popover cost (about 2 %) and real notification delivery ([APP-003](tasks/APP-003-settings-alerts.md), [APP-008](tasks/APP-008-grouped-processes-keyboard-idle-cost.md)–[APP-013](tasks/APP-013-power-draw.md)). Open: clean-Mac installation and signing/update key backups ([REL-001](tasks/REL-001-signing-workflow.md)), the first end-to-end Sparkle update ([APP-012](tasks/APP-012-sparkle-updates.md)). Notarization waits for a paid Developer ID. [PLAN](PLAN.md) owns release sequencing; [SPEC](SPEC.md) owns behavior.

Before release (user decision 2026-10-21): native onboarding (build 30), processes grouped by app (build 29), optional menu bar readings (build 31), sustained app load alert (build 33), Sparkle updates (build 34) and current power draw (build 35), all designed in [DES-002](tasks/DES-002-native-onboarding-next-features.md). Discharge research follows the release ([PLAN](PLAN.md#next-features)).
