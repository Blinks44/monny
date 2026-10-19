# Monny: current state

Updated **2026-10-19**. Baseline: `main` at 1962fb7 with the popover, history, window pages and Settings/alerts (APP-003) committed; the design polish (APP-004, accepted), SSD health and the cost fixes are uncommitted. No battery control yet.

## Product and baseline

Native macOS **26+** (Apple silicon only) menu bar resource monitor with battery charge control, SwiftUI/AppKit, Swift 6 strict concurrency. Scheme/module `monny`, product `Monny.app`, bundle `blinks44.monny`, test target `monnyTests`. Distribution: signed DMG on GitHub Releases outside the App Store; App Sandbox off, Hardened Runtime on. Languages: EN/RU/DE/FR/ES/zh-Hans. Xcode 27.1 / Swift 6.4 / SDK 27 on Apple silicon macOS 27.0.1.

Contracts: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [DESIGN](DESIGN.md), [ENGINEERING](ENGINEERING.md).

## What already exists

- Xcode project in `apps/monny/` with Monny settings, the app icon (`AppIcon.icon`), a shared scheme, `scripts/dev.sh`, one package (KeyboardShortcuts) and a hosted Swift Testing target (28 tests), a bridging header for the NVMe SMART C header.
- App shell ([APP-001](tasks/APP-001-foundations.md)): status item with popover and right-click menu, dashboard window with sidebar and Settings, Sketch tokens and shared components, six-language String Catalog. Public-API readings (CPU, memory, disk, network, battery, processes) are live ([CORE-001](tasks/CORE-001-readings-research.md)); CPU/GPU/SSD/battery temperatures and fans come from the SMC ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- Monny.sketch with popover, dashboard, settings, onboarding, calibration, menu bar/notification and foundations pages, including empty, unavailable, no-battery and error states ([DESIGN](DESIGN.md)).
- Window pages Overview, CPU, Memory, Disk, Network and Sensors draw from the history store ([CORE-003](tasks/CORE-003-history.md)).
- Settings: notifications (heat, low battery, memory pressure), attention badge, global shortcut recorder, update check and app language picker work ([APP-003](tasks/APP-003-settings-alerts.md)).
- Agent workflow (AGENTS, CLAUDE.md adapter, docs) and 14 reviewed project skills ([manifest](../.agents/skills/manifest.json)).
- `apps/website/` is reserved; work starts after the app.

## Recent changes

- **2026-10-19:** Cost measured: background 0.21 % CPU; dashboard down from 15–43 % to 5–12 % after vectorized charts and the 2 s default refresh fix ([verification](verification/idle-cost.md)).
- **2026-10-19:** Disk page shows SSD health from NVMe SMART (wear, S.M.A.R.T. status, data written), read without privileges ([CORE-003](tasks/CORE-003-history.md)).
- **2026-10-19:** APP-004: Settings switches, checkboxes and popup buttons drawn as the Sketch symbols, row spacing fixed; card headers and the Network connection card follow the frames; all window pages compared with Sketch; accepted by the user ([APP-004](tasks/APP-004-design-polish.md)).
- **2026-10-18:** APP-003: alerts and badge, global shortcut, update check; app language picker added to Sketch and the app at the user's request ([APP-003](tasks/APP-003-settings-alerts.md)).
- **2026-10-18:** Window glass and sidebar follow the Sketch frames; Sketch surface variables synced and linked ([APP-002](tasks/APP-002-popover-design-parity.md)).
- **2026-10-18:** APP-002 (done, user-checked): popover brought to the Sketch frames (no arrow, glass panel, rings, capsule tabs and chips, Processes rows) ([APP-002](tasks/APP-002-popover-design-parity.md)). CORE-003: history tiers 1m–7d with 24h/7d persisted, 10 s background sampling, popover network sparkline ([CORE-003](tasks/CORE-003-history.md)).
- **2026-10-18:** CORE-002: SMC temperatures and fans read without privileges, shown in the CPU chip, Battery tab, Temperature KPI and no-battery strip; checked under load on M1 Max ([verification](verification/sensors-smc.md)). CORE-001 closed after the user's check.
- **2026-10-18:** CORE-001: sources researched, shared sampler and public-API readers built, compared with system tools ([verification](verification/readings-public.md)).
- **2026-10-18:** APP-001 shell done: built, tested, and the user confirmed that it works in the running app ([APP-001](tasks/APP-001-foundations.md)).
- **2026-10-18:** Design complete for the first release. Monny.sketch now has every SPEC state (first launch, unavailable sensors, Mac without a battery, Settings errors, update available, uninstall confirmation, onboarding without the helper). The app icon is wired via Icon Composer and shown in README. Decisions: click-only popover, Apple silicon only ([DES-001](tasks/DES-001-missing-states.md)).
- **2026-10-17:** Workflow setup: monorepo layout, Xcode settings aligned with Rebind (macOS 26, Swift 6, no sandbox, Hardened Runtime, six regions), test target, docs and skills; `dev.sh build`, `test` and `release` pass ([history](history/2026-10.md#2026-10-17-workflow-setup)).

## Open work / next steps

- **Next (user):** recheck the window charts and hover line after the fixes ([CORE-003](tasks/CORE-003-history.md)); turn on a notification and see it arrive ([APP-003](tasks/APP-003-settings-alerts.md)); compare CPU/GPU temperatures with Stats or iStat Menus and watch the fan speed under heavy load ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- **Next (engineering):** phase 4 battery control (helper research first); optional SwiftUI audit of the remaining dashboard cost and a popover cost measurement.
- **Design:** complete for the first release ([DES-001](tasks/DES-001-missing-states.md)).
- **Open product decisions:** [SPEC §9](SPEC.md#9-open-product-decisions).

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [CORE-002](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Unassigned | User compares temperatures with a reference tool. |
| [APP-003](tasks/APP-003-settings-alerts.md) | awaiting_verification | Unassigned | User checks that a notification arrives (shortcut confirmed). |
| [CORE-003](tasks/CORE-003-history.md) | awaiting_verification | Unassigned | User rechecks the charts and hover after the series and hover fixes. |
| [DES-001](tasks/DES-001-missing-states.md) | ready_for_implementation | Unassigned | Implement the drawn states with their screens in phases 3–4. |

Release gates are listed in [PLAN](PLAN.md).
