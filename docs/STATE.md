# Monny: current state

Updated **2026-10-21**. Baseline: battery-control work through build 23; see current Git HEAD. Native-limit behavior, bounded adapter source/return, helper-exit recovery and idle sleep/wake are accepted on the observed setup. Build-22 active sleep and build-23 active removal pass; client-exit and sustained behavior remain open; Discharge/full physical verification stay disabled. [BAT-030](tasks/BAT-030-active-adapter-removal.md) owns removal evidence; the helper remains unregistered.

## Product and baseline

Native macOS **26+**, Apple silicon, SwiftUI/AppKit, Swift 6 strict concurrency. Scheme/module `monny`, product `Monny.app`, bundle `blinks44.monny`. Signed DMG on GitHub Releases; App Sandbox off, Hardened Runtime on. Languages: EN/RU/DE/FR/ES/zh-Hans. Xcode 27.1 / Swift 6.4 / SDK 27 on Apple silicon macOS 27.0.1.

Contracts: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [DESIGN](DESIGN.md), [ENGINEERING](ENGINEERING.md).

## What already exists

- Xcode app/helper and shared scheme in `apps/monny/`, `scripts/dev.sh`, KeyboardShortcuts, hosted Swift Testing (287 tests) and NVMe SMART bridge.
- App shell ([APP-001](tasks/APP-001-foundations.md)): status item with popover and right-click menu, dashboard window with sidebar and Settings, Sketch tokens and shared components, six-language String Catalog. Public CPU/memory/disk/network/battery/process readings are live ([CORE-001](tasks/CORE-001-readings-research.md)); CPU/GPU/SSD/battery temperatures and fans come from the SMC ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- Monny.sketch owns screens, components and empty/unavailable/error states ([DESIGN](DESIGN.md)).
- Window pages Overview, CPU, Memory, Disk, Network and Sensors draw from the history store ([CORE-003](tasks/CORE-003-history.md)).
- Battery dashboard shows live facts/history. Native 80–100% limits have explicit opt-in; Discharge, calibration and trips stay disabled. The separate pure policy covers automatic holding, sailing, heat and fail-safe decisions, without hardware wiring ([BAT-001](tasks/BAT-001-battery-foundations.md)).
- Bundled helper validates XPC peers/versions, supports explicit install/removal and native control. One native setting/read-back/restoration test passes ([BAT-016](tasks/BAT-016-manual-native-verification.md)).
- Settings: notifications (heat, low battery, memory pressure), attention badge, global shortcut recorder, update check and app language picker work ([APP-003](tasks/APP-003-settings-alerts.md)).
- `apps/website/` is reserved; work starts after the app.

## Recent changes

- **2026-10-20:** Build-19 single authorized helper-only unclean exit passes: new instance recovers pending CHIE 8→0, native settings preserved and adapter source confirmed ([BAT-027](tasks/BAT-027-adapter-restart-recovery.md)).

- **2026-10-21:** One authorized build-22 active sleep exits 0; independent CHIE=0, same-instance paired callbacks, native preservation and adapter source pass in [BAT-029](tasks/BAT-029-active-adapter-sleep.md).

- **2026-10-21:** One build-23 active removal exits 0; direct CHIE=0/source and absent service/process confirmed. Helper remains removed ([BAT-030](tasks/BAT-030-active-adapter-removal.md)).

- **2026-10-20:** Sketch, app policy and Settings use 80–100%, with manual Hold removed; automatic holding remains ([BAT-020](tasks/BAT-020-remove-manual-hold.md)).

## Open work / next steps

- **Next (engineering):** prepare bounded client-exit recovery verification. Active removal is accepted ([BAT-030](tasks/BAT-030-active-adapter-removal.md)); helper reinstall and any further hardware trial need explicit user action.

- **Next (user):** recheck the window charts and hover line after the fixes ([CORE-003](tasks/CORE-003-history.md)); turn on a notification and see it arrive ([APP-003](tasks/APP-003-settings-alerts.md)); compare CPU/GPU temperatures with Stats or iStat Menus and watch the fan speed under heavy load ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- **Next (user):** test a downloaded DMG on a clean second Mac ([BAT-003](tasks/BAT-003-self-signed-helper.md)); earlier status-only lifecycle/removal acceptance is retained there. New helper replacement and physical recovery remain unverified.
- **Design:** first-release states exist ([DES-001](tasks/DES-001-missing-states.md)); manual Hold cleanup and 80–100% controls are saved/reviewed ([BAT-020](tasks/BAT-020-remove-manual-hold.md)).
- **Open product decisions:** [SPEC §9](SPEC.md#9-open-product-decisions).

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [BAT-026](tasks/BAT-026-bounded-adapter-observation.md) | awaiting_verification | App engineering | Build-18 source/settling passes; adapter recovery follow-up belongs to BAT-027. |
| [BAT-025](tasks/BAT-025-adapter-byte-pulse.md) | awaiting_verification | App engineering | Real byte round trip passes; physical follow-up belongs to BAT-026. |
| [BAT-024](tasks/BAT-024-adapter-verification-ipc.md) | awaiting_verification | User / app engineering | Native rollback accepted; bounded exit/sleep/removal accepted in BAT-027/029/030; client-exit/sustained gates remain. |
| [BAT-022](tasks/BAT-022-adapter-verification-preparation.md) | awaiting_verification | App engineering | Byte/source and bounded exit recovery accepted; independent cable provider and sustained behavior remain. |
| [BAT-018](tasks/BAT-018-native-limit-interface.md) | awaiting_verification | App engineering | User confirms build-12 sleep/wake preservation; native helper restart/rollback confirmed; app crash, sustained physical behavior and broader platforms remain. |
| [BAT-017](tasks/BAT-017-helper-launch-recovery.md) | awaiting_verification | App engineering | App 9 connects to existing helper 8; fresh helper replacement/post-update restart remains. |
| [BAT-008](tasks/BAT-008-helper-recovery-ui.md) | awaiting_verification | Unassigned | Connection/removal/popover retention confirmed; visual and keyboard/VoiceOver review remain. |
| [APP-006](tasks/APP-006-helper-approval-clarity.md) | awaiting_verification | Unassigned | User checks clearer approval step when next needed; native menu/focus review remains. |
| [BAT-005](tasks/BAT-005-helper-lifecycle.md) | awaiting_verification | Unassigned | Native restart/rollback user-confirmed; remaining lifecycle/physical gates stay open. |
| [REL-001](tasks/REL-001-signing-workflow.md) | awaiting_verification | Unassigned | Current scripts/package checks pass; shared Apple Development P12 exported; restore/signing check and off-device copy remain; app 8 → 9 connection verified, daemon replacement remains. |
| [APP-005](tasks/APP-005-battery-design-parity.md) | awaiting_verification | Unassigned | User reviews final Battery layout and charging guidance. |
| [BAT-003](tasks/BAT-003-self-signed-helper.md) | awaiting_verification | Unassigned | Apple Development is the current local signer; historical self-signed launch rejection and clean-Mac/runtime negative checks remain recorded. |
| [BAT-002](tasks/BAT-002-helper-connection.md) | awaiting_verification | Unassigned | Local lifecycle confirmed; wire restoration and runtime negative checks before writes. |
| [BAT-001](tasks/BAT-001-battery-foundations.md) | awaiting_verification | Unassigned | Review the polished Battery page (APP-005); hardware control remains next. |
| [CORE-002](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Unassigned | User compares temperatures with a reference tool. |
| [APP-003](tasks/APP-003-settings-alerts.md) | awaiting_verification | Unassigned | User checks that a notification arrives (shortcut confirmed). |
| [CORE-003](tasks/CORE-003-history.md) | awaiting_verification | Unassigned | User rechecks the charts and hover after the series and hover fixes. |
| [DES-001](tasks/DES-001-missing-states.md) | ready_for_implementation | Unassigned | Implement the drawn states with their screens in phases 3–4. |

Release gates are listed in [PLAN](PLAN.md).
