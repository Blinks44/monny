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

## Release gates

- [ ] Every current SPEC requirement implemented or explicitly limited (onboarding open).
- [x] Direct native setting verified: user changed the limit in build 27 and saw it in System Settings (2026-10-21).
- [x] Reading comparisons accepted by the user (2026-10-21, informal check).
- [ ] Idle cost measured with popover, dashboard and background.
- [ ] Keyboard, VoiceOver, Increase Contrast, Reduce Motion. Six languages reviewed by the user (2026-10-21).
- [x] Works on macOS 26 (user report 2026-10-21; minor version not recorded) and macOS 27.0.1.
- [ ] Clean-Mac DMG installation. Distribution route chosen: Apple Development signature without notarization until a Developer ID exists; first launch per [README](../README.md#install).
