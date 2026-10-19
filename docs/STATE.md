# Monny: current state

Updated **2026-10-19**. Baseline: `main` at fd8ba18 with monitoring, Settings and accepted design polish committed. Battery work (BAT-001–003) and Battery visual parity/guidance (APP-005) are uncommitted. Phase 4 has started; hardware charge control is not implemented.

## Product and baseline

Native macOS **26+** (Apple silicon only) menu bar resource monitor with battery charge control, SwiftUI/AppKit, Swift 6 strict concurrency. Scheme/module `monny`, product `Monny.app`, bundle `blinks44.monny`, test target `monnyTests`. Distribution: signed DMG on GitHub Releases outside the App Store; App Sandbox off, Hardened Runtime on. Languages: EN/RU/DE/FR/ES/zh-Hans. Xcode 27.1 / Swift 6.4 / SDK 27 on Apple silicon macOS 27.0.1.

Contracts: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [DESIGN](DESIGN.md), [ENGINEERING](ENGINEERING.md).

## What already exists

- Xcode project in `apps/monny/` with Monny settings, the app icon (`AppIcon.icon`), a shared scheme, `scripts/dev.sh`, one package (KeyboardShortcuts), a hosted Swift Testing target (63 tests), the battery helper target and an NVMe SMART bridging header.
- App shell ([APP-001](tasks/APP-001-foundations.md)): status item with popover and right-click menu, dashboard window with sidebar and Settings, Sketch tokens and shared components, six-language String Catalog. Public-API readings (CPU, memory, disk, network, battery, processes) are live ([CORE-001](tasks/CORE-001-readings-research.md)); CPU/GPU/SSD/battery temperatures and fans come from the SMC ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- Monny.sketch with popover, dashboard, settings, onboarding, calibration, menu bar/notification and foundations pages, including empty, unavailable, no-battery and error states ([DESIGN](DESIGN.md)).
- Window pages Overview, CPU, Memory, Disk, Network and Sensors draw from the history store ([CORE-003](tasks/CORE-003-history.md)).
- Battery dashboard now shows real level, health, cycles, adapter load, history, temperature and capacities. Charging, calibration and trip controls stay disabled. A pure policy covers limit/hold/discharge, sailing, heat and fail-safe decisions; it is not connected to hardware ([BAT-001](tasks/BAT-001-battery-foundations.md)).
- Status-only helper is bundled with a launchd plist; native XPC verifies peer signing and versions. Explicit registration/approval/removal UI exists, but ad-hoc builds cannot install it. No helper installed by the agent or charge commands exposed ([BAT-002](tasks/BAT-002-helper-connection.md)).
- Settings: notifications (heat, low battery, memory pressure), attention badge, global shortcut recorder, update check and app language picker work ([APP-003](tasks/APP-003-settings-alerts.md)).
- Agent workflow (AGENTS, CLAUDE.md adapter, docs) and 14 reviewed project skills ([manifest](../.agents/skills/manifest.json)).
- `apps/website/` is reserved; work starts after the app.

## Recent changes

- **2026-10-19:** Monny/Rebind release scripts now select an existing exact signing identity and never create replacements; private-key backup/reinstall instructions added. Original Monny key migrated to the user keychain; ordinary signed release passed. Both encrypted .p12 backups passed isolated restore/signing checks; user must retain off-device copies ([REL-001](tasks/REL-001-signing-workflow.md), [guide](SIGNING.md)).

- **2026-10-19:** Battery charging rows, slider preview, calibration and trip cards brought closer to live Sketch; six-language manual macOS charging guidance added and saved in Sketch. Final user visual review remains open ([APP-005](tasks/APP-005-battery-design-parity.md)).

- **2026-10-19:** Self-signed arm64 test DMG prepared with persistent local identity, certificate-pinned authentication and Hardened Runtime. Native signed artifact checks pass; daemon installation and clean-Mac distribution remain unverified ([BAT-003](tasks/BAT-003-self-signed-helper.md)).

- **2026-10-19:** Helper target, authenticated status/removal interface and shared UI added; Debug tests (61) and Release build pass. Local anonymous XPC verified replies, both peer-rejection directions and timeout/cancellation; real signed daemon registration remains open ([BAT-002](tasks/BAT-002-helper-connection.md)).
- **2026-10-19:** Battery dashboard implemented from live Sketch, 22 strings added in six languages, 41 tests pass. Helper/firmware research recorded; source reports of gated charging keys require capability checks, not OS-version assumptions. Final interactive visual check remains open ([BAT-001](tasks/BAT-001-battery-foundations.md), [verification](verification/battery-foundations.md)).
- **2026-10-19:** Cost measured: background 0.21 % CPU; dashboard down from 15–43 % to 5–12 % after vectorized charts and the 2 s default refresh fix ([verification](verification/idle-cost.md)).
- **2026-10-19:** Disk page shows SSD health from NVMe SMART (wear, S.M.A.R.T. status, data written), read without privileges ([CORE-003](tasks/CORE-003-history.md)).
- **2026-10-19:** APP-004: Settings switches, checkboxes and popup buttons drawn as the Sketch symbols, row spacing fixed; card headers and the Network connection card follow the frames; all window pages compared with Sketch; accepted by the user ([APP-004](tasks/APP-004-design-polish.md)).

## Open work / next steps

- **Next (user):** recheck the window charts and hover line after the fixes ([CORE-003](tasks/CORE-003-history.md)); turn on a notification and see it arrive ([APP-003](tasks/APP-003-settings-alerts.md)); compare CPU/GPU temperatures with Stats or iStat Menus and watch the fan speed under heavy load ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- **Next (user):** user owns installation/approval of the status-only self-signed helper; verify IPC/restart/removal, then test a downloaded DMG on a clean second Mac ([BAT-003](tasks/BAT-003-self-signed-helper.md)). Command lease/restoration and hardware fixtures still precede writes.
- **Design:** complete for the first release ([DES-001](tasks/DES-001-missing-states.md)).
- **Open product decisions:** [SPEC §9](SPEC.md#9-open-product-decisions).

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [REL-001](tasks/REL-001-signing-workflow.md) | awaiting_verification | Unassigned | User copies both verified .p12 backups off-device and keeps their password separately. |
| [APP-005](tasks/APP-005-battery-design-parity.md) | awaiting_verification | Unassigned | User reviews final Battery layout and charging guidance. |
| [BAT-003](tasks/BAT-003-self-signed-helper.md) | awaiting_verification | Unassigned | Explicit local status-only installation; then clean-Mac DMG verification. |
| [BAT-002](tasks/BAT-002-helper-connection.md) | awaiting_verification | Unassigned | Verify a matching signed app/helper; implement lease/restoration before writes. |
| [BAT-001](tasks/BAT-001-battery-foundations.md) | awaiting_verification | Unassigned | Review the polished Battery page (APP-005); hardware control remains next. |
| [CORE-002](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Unassigned | User compares temperatures with a reference tool. |
| [APP-003](tasks/APP-003-settings-alerts.md) | awaiting_verification | Unassigned | User checks that a notification arrives (shortcut confirmed). |
| [CORE-003](tasks/CORE-003-history.md) | awaiting_verification | Unassigned | User rechecks the charts and hover after the series and hover fixes. |
| [DES-001](tasks/DES-001-missing-states.md) | ready_for_implementation | Unassigned | Implement the drawn states with their screens in phases 3–4. |

Release gates are listed in [PLAN](PLAN.md).
