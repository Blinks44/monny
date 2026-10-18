# APP-001: App foundations (menu bar, popover and dashboard shell)

- Updated: 2026-10-17
- Stage: ready_for_implementation
- Owner: unassigned
- Ownership checked: 2026-10-17, workflow setup; released
- Owned surfaces: `apps/monny/monny/` app entry, scenes, design tokens, shared components, String Catalogs
- Requirements: SPEC §§2–4, §7 (structure only), §8; PLAN phase 1
- Code baseline: workflow setup baseline on `main` (Xcode template app with the Monny project settings)

## Outcome and scope

Replace the Xcode template with the Monny shell: a menu bar status item that opens the popover with the Overview/Battery/Processes tabs, a dashboard window with the sidebar pages and Settings, and the design tokens and shared components the Sketch screens use. Content uses static preview values clearly marked as placeholders until CORE-001 delivers readings. Out of scope: real readings, history storage, battery helper, onboarding.

The app icon is already wired: [AppIcon.icon](../../apps/monny/monny/AppIcon.icon/) (Icon Composer) is the only app-icon input. The menu bar template imageset still needs adding here. Decide in this task, with the reason recorded here: `MenuBarExtra` vs `NSStatusItem` (right-click menu and attention badge are required), Dock icon policy proposal for SPEC §9, and how color variables map to code (asset catalog colors vs a token type).

## Acceptance

- [ ] Status item with idle/open/attention states and the right-click menu items from SPEC §2 (battery items disabled).
- [ ] Popover with header, tabs and footer matching Sketch `01 · Popover` structure in Light and Dark.
- [ ] Dashboard window with sidebar, page header, time-range control and collapse button; Settings page sections present.
- [ ] Tokens for all Sketch color variables and text styles; shared card, chip, banner and button styles reused across screens.
- [ ] String Catalog entries for all shell copy in the six languages (or explicitly listed missing translations).
- [ ] Build and tests pass; keyboard focus and VoiceOver labels checked for the shell controls.
- [ ] Task, STATE and affected contracts updated before final handoff.

## Sketch source

Monny.sketch pages `01 · Popover`, `02 · Window` (Settings frame), `03 · Flows & System` (menu bar states, right-click menu), `04 · Foundations` and `Symbols`, reviewed 2026-10-17. Inspect live through MCP.

## Implementation and verification

Not started.

## Open checks / dependency

None for the shell. Real values depend on CORE-001.

## Review

Not started.

## Next handoff

Engineering: implement the shell (“build the Monny app shell”). Design: no blocker.
