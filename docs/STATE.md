# Monny: current state

Updated **2026-10-18**. Baseline: `main` with CORE-002 sensors committed. No battery control yet.

## Product and baseline

Native macOS **26+** (Apple silicon only) menu bar resource monitor with battery charge control, SwiftUI/AppKit, Swift 6 strict concurrency. Scheme/module `monny`, product `Monny.app`, bundle `blinks44.monny`, test target `monnyTests`. Distribution: signed DMG on GitHub Releases outside the App Store; App Sandbox off, Hardened Runtime on. Languages: EN/RU/DE/FR/ES/zh-Hans. Xcode 27.1 / Swift 6.4 / SDK 27 on Apple silicon macOS 27.0.1.

Contracts: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [DESIGN](DESIGN.md), [ENGINEERING](ENGINEERING.md).

## What already exists

- Xcode project in `apps/monny/` with Monny settings, the app icon (`AppIcon.icon`), a shared scheme, `scripts/dev.sh` and a hosted Swift Testing target (3 tests).
- App shell ([APP-001](tasks/APP-001-foundations.md)): status item with popover and right-click menu, dashboard window with sidebar and Settings, Sketch tokens and shared components, six-language String Catalog. Public-API readings (CPU, memory, disk, network, battery, processes) are live ([CORE-001](tasks/CORE-001-readings-research.md)); CPU/GPU/SSD/battery temperatures and fans come from the SMC ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- Monny.sketch with popover, dashboard, settings, onboarding, calibration, menu bar/notification and foundations pages, including empty, unavailable, no-battery and error states ([DESIGN](DESIGN.md)).
- Agent workflow (AGENTS, CLAUDE.md adapter, docs) and 14 reviewed project skills ([manifest](../.agents/skills/manifest.json)).
- `apps/website/` is reserved; work starts after the app.

## Recent changes

- **2026-10-18:** CORE-002: SMC temperatures and fans read without privileges, shown in the CPU chip, Battery tab, Temperature KPI and no-battery strip; checked under load on M1 Max ([verification](verification/sensors-smc.md)). CORE-001 closed after the user's check.
- **2026-10-18:** CORE-001: sources researched, shared sampler and public-API readers built, compared with system tools ([verification](verification/readings-public.md)).
- **2026-10-18:** APP-001 shell done: built, tested, and the user confirmed that it works in the running app ([APP-001](tasks/APP-001-foundations.md)).
- **2026-10-18:** Design complete for the first release. Monny.sketch now has every SPEC state (first launch, unavailable sensors, Mac without a battery, Settings errors, update available, uninstall confirmation, onboarding without the helper). The app icon is wired via Icon Composer and shown in README. Decisions: click-only popover, Apple silicon only ([DES-001](tasks/DES-001-missing-states.md)).
- **2026-10-17:** Workflow setup: monorepo layout, Xcode settings aligned with Rebind (macOS 26, Swift 6, no sandbox, Hardened Runtime, six regions), test target, docs and skills; `dev.sh build`, `test` and `release` pass ([history](history/2026-10.md#2026-10-17-workflow-setup)).

## Open work / next steps

- **Next (user):** compare CPU/GPU temperatures with Stats or iStat Menus and watch the fan speed under heavy load ([CORE-002](tasks/CORE-002-temperatures-fans.md)).
- **Next (engineering):** phase 3 history storage and charts, then the Sensors page from Sketch.
- **Design:** complete for the first release ([DES-001](tasks/DES-001-missing-states.md)).
- **Open product decisions:** [SPEC §9](SPEC.md#9-open-product-decisions).

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [CORE-002](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Unassigned | User compares temperatures with a reference tool. |
| [DES-001](tasks/DES-001-missing-states.md) | ready_for_implementation | Unassigned | Implement the drawn states with their screens in phases 3–4. |

Release gates are listed in [PLAN](PLAN.md).
