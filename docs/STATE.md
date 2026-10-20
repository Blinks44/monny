# Monny: current state

Updated **2026-10-20**. Baseline: `main` at 1dc16bd with monitoring, Battery UI/helper foundations and release signing committed. Command safety/lifecycle, read-only helper diagnostics, branded DMG and clearer helper approval are uncommitted. Phase 4: build-8 helper connection recovered locally; normal controls remain disabled. App 9 → existing helper 8 connection verified; helper replacement/restart and physical charge/lifecycle checks remain. One authorized native target/rollback check passes.

## Product and baseline

Native macOS **26+** (Apple silicon only) menu bar resource monitor with battery charge control, SwiftUI/AppKit, Swift 6 strict concurrency. Scheme/module `monny`, product `Monny.app`, bundle `blinks44.monny`. Distribution: signed DMG on GitHub Releases outside the App Store; App Sandbox off, Hardened Runtime on. Languages: EN/RU/DE/FR/ES/zh-Hans. Xcode 27.1 / Swift 6.4 / SDK 27 on Apple silicon macOS 27.0.1.

Contracts: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [DESIGN](DESIGN.md), [ENGINEERING](ENGINEERING.md).

## What already exists

- Xcode project in `apps/monny/` with Monny settings, the app icon (`AppIcon.icon`), a shared scheme, `scripts/dev.sh`, one package (KeyboardShortcuts), a hosted Swift Testing target (162 tests), the battery helper target and an NVMe SMART bridging header.
- App shell ([APP-001](tasks/APP-001-foundations.md)): status item with popover and right-click menu, dashboard window with sidebar and Settings, Sketch tokens and shared components, six-language String Catalog. Public-API readings (CPU, memory, disk, network, battery, processes) are live ([CORE-001](tasks/CORE-001-readings-research.md)); CPU/GPU/SSD/battery temperatures and fans come from the SMC ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- Monny.sketch with popover, dashboard, settings, onboarding, calibration, menu bar/notification and foundations pages, including empty, unavailable, no-battery and error states ([DESIGN](DESIGN.md)).
- Window pages Overview, CPU, Memory, Disk, Network and Sensors draw from the history store ([CORE-003](tasks/CORE-003-history.md)).
- Battery dashboard now shows real level, health, cycles, adapter load, history, temperature and capacities. Charging, calibration and trip controls stay disabled. A pure policy covers limit/hold/discharge, sailing, heat and fail-safe decisions; it is not connected to hardware ([BAT-001](tasks/BAT-001-battery-foundations.md)).
- Bundled helper verifies XPC peers/versions and supports explicit registration/approval/removal. The explicit native verification now passes one authorized setting/read-back/restoration test; normal controls stay disabled ([BAT-016](tasks/BAT-016-manual-native-verification.md)).
- Settings: notifications (heat, low battery, memory pressure), attention badge, global shortcut recorder, update check and app language picker work ([APP-003](tasks/APP-003-settings-alerts.md)).
- Agent workflow (AGENTS, CLAUDE.md adapter, docs) and 14 reviewed project skills ([manifest](../.agents/skills/manifest.json)).
- `apps/website/` is reserved; work starts after the app.

## Recent changes

- **2026-10-19:** Build-2 removal/popover retention is user-confirmed; visual/accessibility review remains ([BAT-008](tasks/BAT-008-helper-recovery-ui.md)).

- **2026-10-19:** User-supplied installed helper diagnostic completes; all six keys reject metadata reads, matching unprivileged results. Build 3 native diagnostics succeed through the installed helper with 80/85/90/95/100; the same binary first hits AMFI launch rejection, then runs after user-owned registration. Self-signed installation remains unreliable ([BAT-011](tasks/BAT-011-native-limit-diagnostics.md)) ([BAT-007](tasks/BAT-007-helper-read-only-diagnostics.md)).

- **2026-10-20:** Native one-shot verification passes: apply 80%, read back and restore original settings; independent getter confirms restoration. Earlier software/package evidence is retained ([BAT-016](tasks/BAT-016-manual-native-verification.md)). Build-8 helper connects on first install after authorized BTM reset/restart; running job and authenticated diagnostics verified ([BAT-017](tasks/BAT-017-helper-launch-recovery.md)). Live removal requires acknowledgement.

- **2026-10-19:** Branded Finder DMG saved in Sketch, implemented in release.sh and verified in the mounted window. Helper approval now has one primary action and six-language guidance; local installation and Connected after DMG update are user-confirmed; app/Mac restart and removal/reinstallation are also user-confirmed ([REL-002](tasks/REL-002-branded-dmg.md), [APP-006](tasks/APP-006-helper-approval-clarity.md)).

- **2026-10-19:** Original self-signed keys/backups preserved; current release.sh now shares the verified Apple Development identity with Rebind. Build 9 DMG passes packaging/security checks; current-key backup remains open ([REL-001](tasks/REL-001-signing-workflow.md), [guide](SIGNING.md)).

## Open work / next steps

- **Next (user):** recheck the window charts and hover line after the fixes ([CORE-003](tasks/CORE-003-history.md)); turn on a notification and see it arrive ([APP-003](tasks/APP-003-settings-alerts.md)); compare CPU/GPU temperatures with Stats or iStat Menus and watch the fan speed under heavy load ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- **Next (user):** older status-only lifecycle and a subsequent diagnostic-capable connection are user-confirmed; removal/popover retention is also user-confirmed; test a downloaded DMG on a clean second Mac ([BAT-003](tasks/BAT-003-self-signed-helper.md)). Executor/session and lifecycle software tests pass; new native hooks and hardware recovery remain unverified before writes.
- **Design:** complete for the first release ([DES-001](tasks/DES-001-missing-states.md)).
- **Open product decisions:** [SPEC §9](SPEC.md#9-open-product-decisions).

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [BAT-017](tasks/BAT-017-helper-launch-recovery.md) | awaiting_verification | App engineering | App 9 connects to existing helper 8; fresh helper replacement/post-update restart remains. |
| [BAT-008](tasks/BAT-008-helper-recovery-ui.md) | awaiting_verification | Unassigned | Connection/removal/popover retention confirmed; visual and keyboard/VoiceOver review remain. |
| [APP-006](tasks/APP-006-helper-approval-clarity.md) | awaiting_verification | Unassigned | User checks clearer approval step when next needed; native menu/focus review remains. |
| [BAT-005](tasks/BAT-005-helper-lifecycle.md) | awaiting_verification | Unassigned | Injected native lifecycle is tested; verify real observer, restart availability and physical restoration before writes. |
| [REL-001](tasks/REL-001-signing-workflow.md) | awaiting_verification | Unassigned | Current scripts/package checks pass; shared Apple Development P12 exported; restore/signing check and off-device copy remain; app 8 → 9 connection verified, daemon replacement remains. |
| [APP-005](tasks/APP-005-battery-design-parity.md) | awaiting_verification | Unassigned | User reviews final Battery layout and charging guidance. |
| [BAT-003](tasks/BAT-003-self-signed-helper.md) | awaiting_verification | Unassigned | Continue self-signing by user choice; intermittent launch rejection, runtime wrong-signer/clean-Mac checks remain. |
| [BAT-002](tasks/BAT-002-helper-connection.md) | awaiting_verification | Unassigned | Local lifecycle confirmed; wire restoration and runtime negative checks before writes. |
| [BAT-001](tasks/BAT-001-battery-foundations.md) | awaiting_verification | Unassigned | Review the polished Battery page (APP-005); hardware control remains next. |
| [CORE-002](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Unassigned | User compares temperatures with a reference tool. |
| [APP-003](tasks/APP-003-settings-alerts.md) | awaiting_verification | Unassigned | User checks that a notification arrives (shortcut confirmed). |
| [CORE-003](tasks/CORE-003-history.md) | awaiting_verification | Unassigned | User rechecks the charts and hover after the series and hover fixes. |
| [DES-001](tasks/DES-001-missing-states.md) | ready_for_implementation | Unassigned | Implement the drawn states with their screens in phases 3–4. |

Release gates are listed in [PLAN](PLAN.md).
