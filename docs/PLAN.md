# Monny: roadmap

Updated 2026-10-21. [STATE](STATE.md) indexes current evidence; [SPEC](SPEC.md) owns behavior. Builds or injected tests alone do not establish real sensor or charging support.

## Current slice

[APP-007](tasks/APP-007-native-simplification-design-parity.md): simplify main, use the system charge-limit preference without a helper where supported, reconcile the app with unchanged live Sketch, review all six localizations and prepare a signed candidate. Build 25 is packaged; 34 tests and constrained multilingual renders pass. Next is installed user review. Discharge/helper experiments are preserved on **experiments/discharge** at abe3a80 and are outside the first-release implementation. No further adapter-isolation work runs on main.

## App phases

1. Native shell, readings and history are implemented; complete real sensor/chart acceptance.
2. Reconcile all implemented popover/dashboard/settings surfaces with Sketch; finish feasible interactions, natural copy and loading/unavailable states.
3. Native-only battery limit: supported 80–100% system setting, ordinary-user read/write/read-back, explicit user gestures, no recurring control loop or setter at startup/wake. macOS owns enforcement and persistence. Validate macOS 26.4+ and private-runtime limitations.
4. Onboarding, accessibility/localization and performance/release review. Existing login item and manual update check remain.
5. Signed release preparation, then website in apps/website.

Sailing, manual heat-driven charge control, forced Discharge, calibration and trip automation remain deferred. Existing Sketch future-mode frames are not edited in this slice and cannot be used as evidence of working controls.

## Release gates

- [ ] Every current SPEC requirement implemented or explicitly limited.
- [ ] Direct native setting verified on supported OS/hardware, including read-back, persistence and System Settings coexistence. No unsupported immediate-discharge claim.
- [ ] CPU/memory/network/disk and sensor comparisons accepted; history/hover reviewed.
- [ ] Idle cost measured with popover, dashboard and background.
- [ ] Keyboard, VoiceOver, Increase Contrast, Reduce Motion and all six languages at minimum width.
- [ ] macOS 26 monitoring / macOS 26.4+ native limit checked, not only macOS 27.
- [ ] Clean-Mac signed DMG installation and selected distribution/notarization route verified; user-initiated update check points to the public repository.
