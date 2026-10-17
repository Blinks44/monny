# Monny: current state

Updated **2026-10-17**. Baseline: the initial commit on `main` (workflow setup). No product feature is implemented.

## Product and baseline

Native macOS **26+** menu bar resource monitor with battery charge control, SwiftUI/AppKit, Swift 6 strict concurrency. Scheme/module `monny`, product `Monny.app`, bundle `blinks44.monny`, test target `monnyTests`. Distribution: signed DMG on GitHub Releases outside the App Store; App Sandbox off, Hardened Runtime on. Languages: EN/RU/DE/FR/ES/zh-Hans. Xcode 27.1 / Swift 6.4 / SDK 27 on Apple silicon macOS 27.0.1.

Contracts: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [DESIGN](DESIGN.md), [ENGINEERING](ENGINEERING.md).

## What already exists

- Xcode project in `apps/monny/` with Monny settings, a shared scheme, `scripts/dev.sh` and a hosted Swift Testing target with one bundle-identity smoke test. The app UI is still the Xcode template.
- Monny.sketch with popover, dashboard, settings, onboarding, calibration, menu bar/notification and foundations pages ([DESIGN](DESIGN.md)).
- Agent workflow (AGENTS, CLAUDE.md adapter, docs) and 14 reviewed project skills ([manifest](../.agents/skills/manifest.json)).
- `apps/website/` is reserved; work starts after the app.

## Recent changes

- **2026-10-17:** Workflow setup: monorepo layout, Xcode settings aligned with Rebind (macOS 26, Swift 6, no sandbox, Hardened Runtime, six regions), test target, docs and skills; `dev.sh build`, `test` and `release` pass ([history](history/2026-10.md#2026-10-17-workflow-setup)).

## Open work / next steps

- **Next (engineering):** [App foundations](tasks/APP-001-foundations.md) — menu bar item, popover and dashboard shell with Sketch tokens.
- **In parallel (engineering):** [Reading sources and sampler](tasks/CORE-001-readings-research.md).
- **Design:** draw the missing states listed in [DESIGN readiness](DESIGN.md#readiness) before their screens are implemented.
- **Open product decisions:** [SPEC §9](SPEC.md#9-open-product-decisions).

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [APP-001](tasks/APP-001-foundations.md) | ready_for_implementation | Unassigned | Build the status item, popover tabs and dashboard sidebar with shared tokens. |
| [CORE-001](tasks/CORE-001-readings-research.md) | planned | Unassigned | Research each metric's API and history storage; record in research. |

Release gates are listed in [PLAN](PLAN.md).
