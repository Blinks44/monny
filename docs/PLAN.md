# Monny: roadmap

Updated 2026-10-21. [STATE](STATE.md) indexes current evidence; [SPEC](SPEC.md) owns behavior. Builds or injected tests alone do not establish real sensor or charging support.

## Current slice

[APP-007](tasks/APP-007-native-simplification-design-parity.md): native-only main with the system charge limit, reviewed and simplified for production on 2026-10-21. Next is an installed review of a fresh build. Discharge/helper work stays on **experiments/discharge** (abe3a80) until it is planned again.

## App phases

1. Native shell, readings and history are implemented; complete real sensor/chart acceptance.
2. Reconcile all implemented popover/dashboard/settings surfaces with Sketch; finish feasible interactions, natural copy and loading/unavailable states.
3. Native-only battery limit: supported 80–100% system setting, ordinary-user read/write/read-back, explicit user gestures, no recurring control loop or setter at startup/wake. macOS owns enforcement and persistence. Validate macOS 26.4+ and private-runtime limitations.
4. Onboarding, accessibility/localization and performance/release review. Existing login item remains; the manual update check moves to Sparkle (next feature 6).
5. Signed release preparation and the landing page in apps/website (built 2026-10-22, [WEB-001](tasks/WEB-001-landing-page.md); not published).

Sailing, manual heat-driven charge control, forced Discharge, calibration and trip automation remain deferred. The app does not show them; their Sketch frames remain for later.

## Next features

Chosen by the user on 2026-10-21 after a comparison with Vitals-style monitors. Items 1–3 and 5 plus native onboarding are designed ([DES-002](tasks/DES-002-native-onboarding-next-features.md)) and planned before the first release; item 4 is research after it. Native onboarding is implemented ([APP-009](tasks/APP-009-native-onboarding.md)); each remaining item still needs an implementation task record.

1. **Processes grouped by app.** Helper processes roll up into their owning app (one row for Chrome with summed CPU, memory and energy), as Activity Monitor does. Implemented in the popover on 2026-10-21 ([APP-008](tasks/APP-008-grouped-processes-keyboard-idle-cost.md)); read-only.
2. **Readings in the menu bar.** Optional CPU %, temperature and battery level next to the status item. Off by default; enabled per value in Settings → Menu bar. Implemented in build 31 ([APP-010](tasks/APP-010-menu-bar-readings.md)); background cost with readings on is about 1.6 % at 2 s.
3. **Sustained app load notification.** Alert when one app keeps high CPU for several minutes; once per episode, toggle in Settings → Notifications. Implemented in build 33 ([APP-011](tasks/APP-011-busy-app-alert.md)): 80 % of one core for 5 minutes, off by default.
4. **Discharge to a lower level on adapter.** Research whether Monny can run the Mac from battery down to a user target (for example 20%) while plugged in, then let it charge again. The earlier helper/SMC experiment is preserved on **experiments/discharge** (abe3a80). Main currently forbids a helper and SMC writes ([AGENTS](../AGENTS.md#3-non-negotiable-boundaries), [SPEC §5](SPEC.md#5-battery-control)); first record the mechanism, safety (fail to charging) and distribution impact in [research](research/README.md), then let the user decide before any code on main.
5. **Current power draw on the Battery page.** Implemented in build 35 ([APP-013](tasks/APP-013-power-draw.md)); on-battery values still to compare. Show what the Mac consumes now in watts both on adapter and on battery, and the battery charge/discharge rate. Today the Battery card shows only `SystemPowerIn` while on adapter and the popover shows the adapter's rated watts. `AppleSmartBattery` already exposes `PowerTelemetryData.SystemLoad` (mW, total consumption) and `Voltage` × `Amperage` (battery flow); confirm the on-battery values against `powermetrics`/System Information on a real Mac before showing them. The popover keeps the adapter's rated watts for now.

6. **Automatic updates with Sparkle.** Implemented in build 34 ([APP-012](tasks/APP-012-sparkle-updates.md)); the first end-to-end update needs two published releases. Replace the GitHub Releases check with [Sparkle 2](https://sparkle-project.org) (user decision 2026-10-21) before the first public release, so 1.0 users can update in place. Check automatically at launch and periodically when enabled; use Sparkle's standard window for release notes, download, user-confirmed installation and relaunch. Settings › About keeps Check for Updates and adds the automatic-check toggle; the toggle is drawn in onboarding Ready ([DES-002](tasks/DES-002-native-onboarding-next-features.md)), but Settings › About still needs design. Release flow gains an EdDSA key (private key outside the repository), an appcast published with GitHub releases and update-archive signing in `release.sh`. First verify same-signer updates with the current Apple Development signature without notarization. [SPEC §7](SPEC.md#7-settings) and [AGENTS](../AGENTS.md#3-non-negotiable-boundaries) already reflect this decision; integration research remains open in [research](research/README.md#other-dependencies).

7. **AI usage limits (opt-in).** Claude Code and Codex 5-hour and weekly limits in a popover tab, a window page and a running-low notification (user decision 2026-10-22). Implemented in builds 43–45 ([APP-015](tasks/APP-015-ai-usage-limits.md)) with Cursor and Grok; Gemini is not possible without browser cookies.

Other comparison ideas (GPU load, battery health trend, widgets) are not planned for now.

## Release gates

- [x] Every current SPEC requirement implemented or explicitly limited. Pre-release features accepted by the user on build 37 (2026-10-21); Sparkle's first end-to-end update needs two published releases ([APP-012](tasks/APP-012-sparkle-updates.md)), so it is checked after 1.0.
- [x] Direct native setting verified: user changed the limit in build 27 and saw it in System Settings (2026-10-21).
- [x] Reading comparisons accepted by the user (2026-10-21, informal check).
- [x] Idle cost measured: background 0.0 %, dashboard 2.9 % (build 29), popover about 2 % (build 37, user) ([verification](verification/idle-cost.md)).
- [x] Keyboard, VoiceOver, Increase Contrast, Reduce Motion (user, build 37) and six languages (user, 2026-10-21).
- [x] Works on macOS 26 (user report 2026-10-21; minor version not recorded) and macOS 27.0.1.
- [ ] Clean-Mac DMG installation. Distribution route chosen: Apple Development signature without notarization until a Developer ID exists; first launch per [README](../README.md#install).
