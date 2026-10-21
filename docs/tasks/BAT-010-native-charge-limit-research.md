# BAT-010: Native charge-limit capability investigation

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-19
- Stage: done
- Owner: unassigned; bounded investigation complete
- Baseline: main 1dc16bd plus preserved uncommitted battery/helper/design/release work
- Scope: native PowerUI read-only capability/limit queries, maintained project comparison, local SDK checks and backend decision; no product UI or charging writes

## Outcome

Establish whether the native limit client can be queried on the development Mac without private entitlements or root, what range it advertises, and how its behavior differs from SPEC's direct charge/Hold modes. Check maintained/native options before adding a controller. No setter, preference change, service install or charging test.

## Acceptance

- [x] Inspect native API availability and alternative-project source/licensing/maintenance.
- [x] Read-only capability queries with bounded process timeout; no setter/disable calls or private-preference edits.
- [x] Record exact observed versus third-party claims, failure behavior and a concrete implementation/verification handoff.

## Mechanism and sources — 2026-10-19

Reviewed batt at **4574ecb0f3b2d5f1829154a2aae89c3cc3b0b716** (GitHub API mainline date 2026-10-12). Its [PowerUI fallback](https://github.com/charlie0129/batt/tree/4574ecb0f3b2d5f1829154a2aae89c3cc3b0b716/pkg/powerui) loads the system private PowerUI framework and uses the native SmartChargeClient. This is an ObjC bridge in a Go application, not a Swift package to install; GPL-2.0 implementation remains outside Monny and was not compiled, run or copied. An [open battery PR 480](https://github.com/actuallymentor/battery/pull/480) independently reports a native-client path on an M1 Pro, with sub-80 limits rejected and firmware-controlled hysteresis. It remains a proposed change, not a maintained ready integration. [Ampere's technical description](https://amperebattery.app/tech.html) was reviewed as another first-party implementation report; private preference/root-domain editing is not adopted.

The public IOKit power-source headers in the installed Xcode SDK expose no manual battery-limit controller. PowerUI is a private runtime dependency and is not made public/supported by being reachable. [Apple's user documentation](https://support.apple.com/en-us/102338) describes manual 80–100% limits, charging within a few percentage points, resuming after more than a 5% drop, and occasional full charges for estimation. These semantics differ from exact thresholds, an app-chosen sailing band or a universal immediate Hold.

## Local read-only evidence

Development M1 Max / macOS 27.0.1 / Xcode 27.1. An independently written temporary Objective-C introspector loaded the installed system framework and verified five getter/initializer method encodings from its runtime metadata. A separate temporary program declared only those verified getters and queried support, advertised limits, current limit and enabled state. It ran as the ordinary user without sudo, helper invocation, private entitlement, system preference edits, setter or disable selectors. Its process was bounded by an eight-second subprocess timeout; it exited successfully in under one second. No third-party implementation was executed. Raw current machine settings remain in temporary local JSON, outside Git.

Observed: native client exists, isMCLSupported is true, available limits are **80, 85, 90, 95, 100**. Current-limit/enabled getters also completed without NSError. No setter invocation, charge behavior or physical restoration is established. These positive reads supersede the earlier broad assumption that every native-limit query needs an entitlement; the lower-level powerd/IOPS path may still be gated. A permissive read does not prove a setter succeeds for Monny's signed helper identity or across OS releases.

## Decision and implementation handoff

Use the native-limit client as the next backend candidate on this firmware, before considering adapter cycling. It can potentially configure macOS's own target without a root-preference workaround or disabling wall power. Keep private API handling isolated, verify class/selector/signature availability on every supported OS, bound requests off the main actor, and fail unavailable on errors. Do not ship a blind objc_msgSend cast or shell/JXA bridge. No suitable ready maintained Swift wrapper was established; a small native bridge is justified only for the verified contract, not an extra framework.

The getter-only native adapter/diagnostic is now implemented in [BAT-011](BAT-011-native-limit-diagnostics.md), including range/state validation; installed-helper reads are verified. Journal/transaction lifecycle is tested in BAT-012–014, and a disconnected guarded setter adapter is prepared in [BAT-015](BAT-015-native-writer-preparation.md). Actual setter semantics, entitlement and physical recovery remain unverified. Later native control must capture the user's prior native limit/enabled state before first mutation, acknowledge actual read-back, avoid a recurring fight with System Settings, and restore prior settings when relinquishing control rather than indiscriminately disabling the user's own limit. Unknown snapshot/read-back must prevent writes. The same helper remains the only potential privileged writer; no separate daemon.

Native-only support should advertise only returned limits and leave sub-80, configurable sailing, heat-driven immediate pause, calibration and arbitrary Hold unavailable unless separately verified. This is an implementation candidate, not authorization to weaken SPEC or silently enable fewer controls. Adapter mode remains a distinct potential opt-in discharge behavior; no automatic fallback from Hold/Charge. UI/design contract changes need live Sketch and a clearly documented user decision. Any real setter test requires explicit authorization, an exact temporary target, rollback to the captured state and power/quit/sleep/crash verification appropriate to that backend.

## Checks and limits

Research and temporary getter probes only; production source, installed app/helper, system settings and charging remain unchanged. No app build/tests required or claimed. Reviewed affected local links and git diff --check; no permanent probe tool, dependency, Git commit or publication. Native getter success does not close BAT-005 physical recovery, runtime wrong-signer, macOS 26 or clean-Mac distribution gates.
