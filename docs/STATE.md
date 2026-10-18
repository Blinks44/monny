# Monny: current state

Updated **2026-10-18**. Baseline: `main` with the APP-001 shell. No reading or battery feature is implemented.

## Product and baseline

Native macOS **26+** (Apple silicon only) menu bar resource monitor with battery charge control, SwiftUI/AppKit, Swift 6 strict concurrency. Scheme/module `monny`, product `Monny.app`, bundle `blinks44.monny`, test target `monnyTests`. Distribution: signed DMG on GitHub Releases outside the App Store; App Sandbox off, Hardened Runtime on. Languages: EN/RU/DE/FR/ES/zh-Hans. Xcode 27.1 / Swift 6.4 / SDK 27 on Apple silicon macOS 27.0.1.

Contracts: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [DESIGN](DESIGN.md), [ENGINEERING](ENGINEERING.md).

## What already exists

- Xcode project in `apps/monny/` with Monny settings, the app icon (`AppIcon.icon`), a shared scheme, `scripts/dev.sh` and a hosted Swift Testing target (3 tests).
- App shell ([APP-001](tasks/APP-001-foundations.md)): status item with popover and right-click menu, dashboard window with sidebar and Settings, Sketch tokens and shared components, six-language String Catalog. Readings show as unavailable until CORE-001.
- Monny.sketch with popover, dashboard, settings, onboarding, calibration, menu bar/notification and foundations pages, including empty, unavailable, no-battery and error states ([DESIGN](DESIGN.md)).
- Agent workflow (AGENTS, CLAUDE.md adapter, docs) and 14 reviewed project skills ([manifest](../.agents/skills/manifest.json)).
- `apps/website/` is reserved; work starts after the app.

## Recent changes

- **2026-10-18:** APP-001 shell done: built, tested, and the user confirmed that it works in the running app ([APP-001](tasks/APP-001-foundations.md)).
- **2026-10-18:** Design complete for the first release. Monny.sketch now has every SPEC state (first launch, unavailable sensors, Mac without a battery, Settings errors, update available, uninstall confirmation, onboarding without the helper). The app icon is wired via Icon Composer and shown in README. Decisions: click-only popover, Apple silicon only ([DES-001](tasks/DES-001-missing-states.md)).
- **2026-10-17:** Workflow setup: monorepo layout, Xcode settings aligned with Rebind (macOS 26, Swift 6, no sandbox, Hardened Runtime, six regions), test target, docs and skills; `dev.sh build`, `test` and `release` pass ([history](history/2026-10.md#2026-10-17-workflow-setup)).

## Open work / next steps

- **Next (engineering):** [Reading sources and sampler](tasks/CORE-001-readings-research.md).
- **Open (user):** confirm the Dock proposal (SPEC §9).
- **Design:** complete for the first release ([DES-001](tasks/DES-001-missing-states.md)).
- **Open product decisions:** [SPEC §9](SPEC.md#9-open-product-decisions).

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [CORE-001](tasks/CORE-001-readings-research.md) | planned | Unassigned | Research each metric's API and history storage; record in research. |
| [DES-001](tasks/DES-001-missing-states.md) | ready_for_implementation | Unassigned | Implement the drawn states with their screens in phases 3–4. |

Release gates are listed in [PLAN](PLAN.md).
