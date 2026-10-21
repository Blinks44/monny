# Monny: roadmap

Updated 2026-10-21. [STATE](STATE.md) indexes current evidence; [SPEC](SPEC.md) owns behavior. Builds or injected tests alone do not establish real sensor or charging support.

## Current slice

[APP-007](tasks/APP-007-native-simplification-design-parity.md): native-only main with the system charge limit, reviewed and simplified for production on 2026-10-21. Next is an installed review of a fresh build. Discharge/helper work stays on **experiments/discharge** (abe3a80) until it is planned again.

## App phases

1. Native shell, readings and history are implemented; complete real sensor/chart acceptance.
2. Reconcile all implemented popover/dashboard/settings surfaces with Sketch; finish feasible interactions, natural copy and loading/unavailable states.
3. Native-only battery limit: supported 80–100% system setting, ordinary-user read/write/read-back, explicit user gestures, no recurring control loop or setter at startup/wake. macOS owns enforcement and persistence. Validate macOS 26.4+ and private-runtime limitations.
4. Onboarding, accessibility/localization and performance/release review. Existing login item and manual update check remain.
5. Signed release preparation, then website in apps/website.

Sailing, manual heat-driven charge control, forced Discharge, calibration and trip automation remain deferred. The app does not show them; their Sketch frames remain for later.

## Next features

Chosen by the user on 2026-10-21 after a comparison with Vitals-style monitors. Items 1–3 and 5 plus native onboarding are designed ([DES-002](tasks/DES-002-native-onboarding-next-features.md)) and planned before the first release; item 4 is research after it. Each item still needs an implementation task record.

1. **Processes grouped by app.** Helper processes roll up into their owning app (one row for Chrome with summed CPU, memory and energy), as Activity Monitor does. Research the public source first (coalition/responsible-process info via `proc_pidinfo`); read-only.
2. **Readings in the menu bar.** Optional CPU %, temperature and battery level next to the status item. Off by default; enabled per value in Settings → Menu bar. Must not raise idle cost beyond the shared sampler.
3. **Sustained app load notification.** Alert when one app keeps high CPU or memory for several minutes; once per episode, toggle in Settings → Notifications. Builds on item 1.
4. **Discharge to a lower level on adapter.** Research whether Monny can run the Mac from battery down to a user target (for example 20%) while plugged in, then let it charge again. The earlier helper/SMC experiment is preserved on **experiments/discharge** (abe3a80). Main currently forbids a helper and SMC writes ([AGENTS](../AGENTS.md#3-non-negotiable-boundaries), [SPEC §5](SPEC.md#5-battery-control)); first record the mechanism, safety (fail to charging) and distribution impact in [research](research/README.md), then let the user decide before any code on main.
5. **Current power draw on the Battery page.** Show what the Mac consumes now in watts both on adapter and on battery, and the battery charge/discharge rate. Today the Battery card shows only `SystemPowerIn` while on adapter and the popover shows the adapter's rated watts. `AppleSmartBattery` already exposes `PowerTelemetryData.SystemLoad` (mW, total consumption) and `Voltage` × `Amperage` (battery flow); confirm the on-battery values against `powermetrics`/System Information on a real Mac before showing them. The popover keeps the adapter's rated watts for now.

Other comparison ideas (GPU load, battery health trend, widgets) are not planned for now.

## Release gates

- [ ] Every current SPEC requirement implemented or explicitly limited (onboarding and next-feature items 1–3, 5 open).
- [x] Direct native setting verified: user changed the limit in build 27 and saw it in System Settings (2026-10-21).
- [x] Reading comparisons accepted by the user (2026-10-21, informal check).
- [ ] Idle cost measured with popover, dashboard and background.
- [ ] Keyboard, VoiceOver, Increase Contrast, Reduce Motion. Six languages reviewed by the user (2026-10-21).
- [x] Works on macOS 26 (user report 2026-10-21; minor version not recorded) and macOS 27.0.1.
- [ ] Clean-Mac DMG installation. Distribution route chosen: Apple Development signature without notarization until a Developer ID exists; first launch per [README](../README.md#install).
