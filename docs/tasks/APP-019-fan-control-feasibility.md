# APP-019: Cooling controls proposal and feasibility

- Updated: 2026-11-16
- Stage: planned
- Owner: proposal/research session complete; no implementation owner
- Baseline: main `c25bea9`, Monny 1.7.0/build 94
- Scope: user requested product/UX/mechanism planning before drawing or implementation
- Contracts: SPEC §1 non-goals, AGENTS §3, ENGINEERING platform/readings boundaries remain unchanged pending an accepted scope change

## Outcome

Initial proposal (not selected for implementation): a dedicated Cooling popover tab with one shared **System / Quieter** policy, a temporary quieter session (proposed 30 minutes), verified actual fan speeds and a clear return to System. No individual fan sliders, curve editor or hard RPM cap. A Cooler mode is deferred. The [research refresh](../research/fan-control.md#2026-11-16-dependency-and-product-proposal-refresh) owns dependency findings, proposed safety architecture and hardware acceptance gates.

## Navigation and screen proposal (not drawn or accepted)

Current code is a 360 pt popover with 320 pt usable width, three text segments plus optional AI and a fixed 488 pt content region. Live Monny.sketch Overview power Light/Dark were inspected through MCP on 2026-11-16; their 560×820 presentation frames include the desktop around the narrow popover. No Sketch edits/save or exports.

Recommend a single horizontal row with an icon above each visible label: Overview, Battery, Cooling, Processes, AI (AI conditional as today). Start the design study around a 400 pt popover; final width and adaptive item widths need six-language/native text-fit checks, never clipped labels or arbitrary smaller type. Keep existing surfaces, token styles and content hierarchy. Five text-only segments are too tight at current width. A labelled vertical rail needs roughly 80–100 pt in addition to existing content and insets, or steals card width. Icon-only rail loses discoverability. Do not merge Battery and Cooling under a vague Controls tab or bury the main action in Settings.

Cooling content: one calm status card with fan symbol, thermal condition and compact per-fan RPM readings; a System/Quieter control; one brief explanation and session time remaining; contextual inline refusal/error when needed; a secondary Sensors dashboard link for detailed readings/history. No spinning decorative gauges, presumed decibels, large default charts or separate fan controls. An Overview temperature-chip entry can open Cooling without another full card in the already full Overview.

Required future frames: System; applying/settling (not immediately confirmed); Quieter active with expiry and return action; thermal refusal/returned to System; permission setup; unreadable/unsupported; confirmed fanless; write/restore failure with unconfirmed state. Keep fanless separate from unreadable, do not promise guaranteed silence, and do not label a selected-but-unconfirmed target as applied. A confirmed fanless Mac omits the cooling tab; unsupported fan-equipped Macs can explain monitoring-only availability. Live Sketch owns exact final copy and visual design after approval.

## Evidence and limits

Inspected current PopoverView, OverviewTab, SensorReader/SMCConnection, Package.resolved and Xcode settings: read-only SMC, no control dependency; macOS 15, Swift 6 complete strict concurrency/MainActor, build 94. Rechecked upstream primary references and recorded package-review gaps. No app/runtime/hardware tests, service installation, fan writes or new DMG: documentation-only proposal. Link checks and git diff --check are the required completion checks.

## Next

The user raised safety concerns; the current recommendation is to defer direct fan control. Compare with [plugged-in discharge](APP-020-plugged-in-discharge-assessment.md) before selecting any feature. The navigation proposal remains available if fan control is explicitly resumed. Before implementation or a hardware experiment, explicitly reconcile the accepted fan-control/service scope in SPEC/AGENTS/ENGINEERING and define the prototype hardware and recovery gates; do not copy generic fan writes into the sampler.
