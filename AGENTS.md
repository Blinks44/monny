# Monny: agent instructions

Act as a senior macOS engineer or product designer working on a production native system monitor with battery charge control. Follow the user's current authorized task and preserve existing work. This file is the entry point for **both code and design agents**; instructions do not imply shared chat memory or automatic synchronization.

The repository is a monorepo: the app lives in `apps/monny/` (Xcode project, sources, tests, `scripts/dev.sh`), `apps/website/` is the public landing page ([its README](apps/website/README.md)), and `docs/`, `AGENTS.md` and `.agents/` at the root serve every part.

## 1. Start or resume a task

1. Read this file and [docs/STATE.md](docs/STATE.md) from disk. Follow [docs/WORKFLOW.md](docs/WORKFLOW.md), including its startup and completion rules.
2. For continuing/product work, read the short [docs/PLAN.md](docs/PLAN.md), the relevant [docs/SPEC.md](docs/SPEC.md) sections and an existing task record in [docs/tasks/](docs/tasks/). First-time product orientation needs the full SPEC; focused fixes need only the affected contracts. An isolated typo does not require a full product/design read.
3. Inspect the actual checkout: Git branch/HEAD, status, recent relevant changes, affected implementation, Xcode settings and dependencies. Never infer that a requirement in SPEC is already implemented, or that an open checkbox means code is absent.
4. For app code, read [docs/ENGINEERING.md](docs/ENGINEERING.md). For UI/brand/design work, read [docs/DESIGN.md](docs/DESIGN.md) and inspect the live Monny.sketch frames through Sketch MCP before changing visuals or implementing them.
5. Establish the task outcome, ownership and required checks. Reuse a task record when continuing work; create one for a feature, design handoff, multi-session change or shared-file work. Tiny fixes can use a concise history entry instead.
6. Re-read relevant state/task files after compaction, before a dependent handoff, and before editing shared records. If project instructions changed during this chat, read the changed instructions from disk and reconcile the current task before continuing. Changes in another running chat are not automatically in this chat's context.

Missing Sketch access blocks design-dependent work, not independent engineering (sampling, helper, storage, tests). Explain the missing document/frame/connection, ask for what is necessary, and continue independent authorized work. Do not invent the current design or silently use an old PNG.

Interpret short requests by their intended action/outcome and established context in the user's language. Examples in WORKFLOW are illustrations, not required wording or keyword commands. Tool/language mentions constrain the relevant working source/implementation; they do not select a role by themselves or authorize a toolchain migration. Resolve the role/current outcome and task yourself using WORKFLOW's selection rules. Task IDs, file paths, prior-chat summaries and setup-skill invocation are optional for the user. A fresh unqualified Monny development request defaults to app implementation; preserve an established design role or explicit design request. Website work follows [WEB-001](docs/tasks/WEB-001-landing-page.md) and the website README. Explain the selected user-visible outcome briefly and proceed.

## 2. Sources of truth

| Source | Owns |
| --- | --- |
| User's latest explicit instruction | Authorized outcome and scope; reconcile changed contracts in docs |
| SPEC | Required product behavior, scope, acceptance criteria |
| Root README / DEVELOPMENT | Public project overview / detailed build, signing and local setup |
| DESIGN + live Sketch | Short source locator/direction; Monny.sketch owns frames, components, color variables, visual states, copy and annotations |
| Source code and actual app artifacts | What is implemented now |
| Task records + verification | Work status, evidence, limitations and handoffs |
| STATE | Short current summary and active/next task index |
| PLAN | Roadmap and remaining phase exit gates |
| research | Mechanism and dependency decisions (sensors, SMC, helper) |
| History | Dated evidence and reasons; may contain superseded decisions |

When sources disagree, inspect the implementation/artifact and evidence, state the discrepancy and repair the relevant record. Never silently weaken SPEC, claim a mocked reading proves real hardware behavior, or treat historical instructions as current. STATE is an index, not a replacement for inspecting code or Sketch.

## 3. Non-negotiable boundaries

- macOS **26+**, native SwiftUI with AppKit only where SwiftUI is insufficient (status item, right-click menu), Swift 6 language mode with complete strict concurrency and main-actor default isolation. Preserve target/scheme/module `monny`, product `Monny.app`, bundle ID `blinks44.monny` and existing project settings unless a justified change is required.
- Use `apps/monny/scripts/dev.sh doctor|build|release|build-for-testing|test|resolve|run`; see [DEVELOPMENT](docs/DEVELOPMENT.md). Do not change system-wide `xcode-select`. Xcode MCP build/documentation/preview tools are preferred when suitable and available.
- Distribution is a signed DMG on GitHub Releases outside the Mac App Store (user decision 2026-10-17). App Sandbox stays **off** for native system monitoring; Hardened Runtime stays on. Main uses direct ordinary-user access to the native macOS charge-limit preference where available, with no privileged helper or SMC writes. Discharge/helper experiments remain on experiments/discharge. No root shortcuts, SIP changes or kernel extensions.
- Monitoring is read-only and local: no analytics, telemetry, accounts or network access other than Sparkle update checks/downloads and the opt-in AI limit checks with the tools' own sign-in (SPEC §7–8, user decision 2026-10-22). No process termination or system tuning unless SPEC adds it.
- Sampling must stay cheap: one shared sampler, the user-chosen refresh rate while a view is visible and only what history, charge control and notifications need otherwise. Measure before optimizing; never block the main actor with I/O, IOKit/SMC calls or process enumeration.
- Battery control must fail safe: if the native setting API or reading is unavailable or unknown, do not write and explain availability. macOS owns charging and the persistent system limit; Monny does not restore an old limit on quit or replay setters on wake. Never isolate adapter input on main.
- Distinguish real readings from estimates and unsupported sensors. Show "unavailable" rather than invented values; hardware support differs by Mac model.
- All product copy supports EN/RU/DE/FR/ES and Simplified Chinese through String Catalogs (user decision 2026-10-17). Sketch screens are drawn in English; other languages are verified in the app.
- No overengineering: choose the simplest correct solution and keep it understandable and readable.
- Prefer an existing, maintained library, system API or add-on over a custom implementation whenever it satisfies the need; write custom code only when no suitable ready solution exists.
- No hacks or workarounds: fix the actual cause or record the limitation explicitly; do not mask symptoms.
- Research non-trivial mechanisms (SMC keys, sensor sources, helper installation, update checks) before adding custom implementations. Check native APIs, GitHub, Swift Package Index, maintenance and licensing; record decisions in [research](docs/research/README.md). No blind dependency installs or copying GPL sources without an explicit licensing decision.
- Preserve user changes. Coordinate ownership before editing the same code, docs section or Sketch source. Never stage/commit/reset/push unrelated work. Git commits and Sketch saves are separate operations; record both when actually performed.
- Write repository documentation, instructions, comments and skill content in English. Reply to the user in their preferred language. Preserve app translations and purposeful Unicode/localization test data.
- Commit technical outcomes and concise verification results, not chat transcripts, verbatim user replies, personal paths, real machine data or temporary logs. Verification screenshots/exports stay local by default; version images only for a specific documented purpose under WORKFLOW.
- Follow the project's commented `.gitignore` policy. Keep shared instructions/skills, STATE/tasks/evidence, source/design inputs and lockfiles versioned. New tools/output paths need narrow exclusions checked with Git; never hide an entire agent directory or automatically untrack files.
- This workflow does not authorize creating agents/chats, messaging other chats, installing the helper or changing charging on the user's Mac, editing Sketch, publishing or deploying. Proceed within the user's authorized scope without adding routine confirmation gates.

An explicit request to continue/create design authorizes scoped edits to the established Monny design within existing requirements; resolve its source/frames from DESIGN and live MCP. Setup/instructions alone do not authorize those edits.

## 4. Finish or hand off

After any app code change (fix, refinement or feature), finish with a ready DMG for the user: increment `CURRENT_PROJECT_VERSION` (Debug and Release), run `apps/monny/scripts/dev.sh test`, then `apps/monny/scripts/release.sh`, and report the DMG path and SHA-256. Documentation-only work does not need a build. If the release fails (for example a missing signing identity), report it instead of skipping silently.

Follow WORKFLOW's completion contract **before the final response**. Update the affected task/evidence, STATE, and any changed SPEC/DESIGN/PLAN/research record. Record tests/builds actually run, exact evidence, unresolved checks and one actionable next step. Use `awaiting_verification` when implementation exists but required runtime/hardware acceptance (real sensors, charging on a named Mac) is open; never mark a feature done just because the build passes.

For design-only work, make the saved Sketch document self-contained and review it live. Keep repository completion notes short: source/date, ready scope, remaining work and next step. Do not routinely export PNGs or duplicate frame/style inventories.

Tell the user the outcome in plain language: what is ready, what is still open, and what this role or the receiving role can do next. Lead with meaningful task names; IDs/links are optional. If another role is needed, provide a short natural-language request that works without a task ID.

Maintain the affected documentation as part of ordinary completion: replace stale current claims and completed next steps, link to owning evidence, and reduce redundant detail. Preserve unique decisions, dated verification and every open check before retiring a record; repair incoming links. Follow [record lifecycle](docs/WORKFLOW.md#incremental-documentation-maintenance). Keep STATE around 1–2 pages, PLAN a short roadmap and this file practical. Documentation-only work needs review of affected links, facts and `git diff --check`, not an app launch.

## 5. Relevant skills

Read only relevant `.agents/skills/<name>/SKILL.md` and its required references. Provenance, licenses and reviewed-but-skipped candidates: `.agents/skills/manifest.json`. Claude Code reaches the same folder through the `.claude/skills` symlink and loads this file through `CLAUDE.md`.

- Ordinary SwiftUI/UI work: `swiftui-pro` + `swiftui-design-principles`; component guidance from `swiftui-ui-patterns` selectively.
- Sampling, helper XPC, shared state and Swift 6 diagnostics: `swift-concurrency-pro`; behavioral tests: `swift-testing-pro`.
- Displaying bytes, rates, percentages, temperatures, durations and dates: `swift-format-style` (FormatStyle, no legacy formatters).
- Logging and signposts for sampling cost and the helper: `observability`, limited to `Logger`, `OSSignposter` and local `OSLogStore` export. Never add analytics, MetricKit upload pipelines or third-party telemetry SDKs.
- Charts, live popover and refresh cost: `swiftui-performance-audit` for measured problems.
- System materials: `swiftui-liquid-glass` only where Sketch shows a system material; check **macOS** availability.
- New Swift contracts: `swift-api-design-guidelines-skill` locally, without mass renaming.
- Product copy: `writing-for-interfaces`, preserving behavior and all six languages.
- Accessibility: `swiftui-accessibility-auditor` for SwiftUI views, `appkit-accessibility-auditor` for the status item and menus.
- Workflow setup/review: `agent-workflow-setup`; it configures project context rather than activating on ordinary feature implementation.

Monny's SPEC, DESIGN, actual toolchain and the macOS platform take precedence over upstream iOS examples in these skills.
