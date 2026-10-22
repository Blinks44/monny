# DES-003: AI usage limits (Claude Code, Codex, Cursor) exploration

- Updated: 2026-10-22
- Stage: in_design (Light and Dark frames and edge states saved; awaiting user review)
- Owner: unassigned (design pass released 2026-10-22)
- Owned surfaces: Monny.sketch page `01 · Popover` frames `11`–`13`, page `02 · Window` frames `19`–`20`, page `03 · Flows & System` frame `13`
- Requirements: none yet. Not in [SPEC](../SPEC.md) or [PLAN](../PLAN.md); user idea 2026-10-22 to explore the look before deciding on implementation.
- Code baseline: main at 0636518; no code changed by this task

## Outcome and scope

Explore how Monny could show the usage limits of Claude Code and Codex (5-hour and weekly windows) and Cursor (monthly included usage) in the popover and the main window. Design first, mechanism later.

Known data constraints (checked 2026-10-22): Codex writes `rate_limits` (primary 300-minute and secondary 10080-minute windows with `used_percent` and `resets_at`) into its local session logs, so it can be read offline but only refreshes when Codex is used. Claude Code keeps no local limit data; the known sources are an undocumented network endpoint (conflicts with SPEC §7 network policy) or a user-configured statusline script. Cursor has monthly included usage per billing cycle rather than rolling windows; its source is not researched yet. A SPEC/research decision is required before implementation.

## Sketch source

Monny.sketch, saved 2026-10-22, Light and Dark for every frame. Bars show the quota **left** (full = available, empty = used up, user decision 2026-10-22); the pace mark shows the time left in the period, so a bar shorter than its mark runs out before the reset.

- `11 · Popover · AI limits`: fourth popover tab “AI”. One card per tool (icon, plan, last update): Claude and Codex with a 5-hour and a weekly bar, Cursor with one monthly bar (“$12.40 of $20 left”). The cards sit in a scroll area so the popover keeps its height; an overlay scroller signals more content. Each bar has a pace mark; a “Running low” chip and orange value when the quota left is far below the time left. Footnote below the cards explains the mark and the local source.
- `12 · Popover · AI limits · States`: limit reached (empty bar on a red-tinted track, “0% left”, “Limit reached” chip, “Available again in …”), stale reading (orange “3 days ago”, dimmed values, “—” for a window that has reset since), signed out (message and Open Cursor button).
- `13 · Popover · AI limits · No tools`: shown when the setting is on but no supported tool is found; Hide AI Limits turns the setting off.
- `19 · Window · AI limits`: sidebar item “AI usage”; range control reduced to 24h / 7d. One tile per tool with its bars and pace marks; “Quota left over 7 days” chart; “Next resets” list with an estimated pace forecast; Sources (connection status, full width). Chart lines jump back to 100 % at each reset.
- `20 · Window · Settings · AI limits` (copy of frame `17`, which stays the current Settings): one-row AI LIMITS group (Show AI limits, found tools in the subtitle) in the left column and an “AI limit is running low” checkbox in Notifications, where all Monny notifications live (user decision 2026-10-22; the reset notification was dropped). Sidebar shows AI usage when the switch is on. The page scrolls in the app, so this frame draws the window 40 pt taller to show all content.
- `03 · Flows & System` › `13 · Onboarding · Ready · AI limits` (copy of frame `03`): optional third row Show AI limits, off by default; the window is 24 pt taller.

Service colors are raw values for the exploration (Claude coral, Codex graphite, Cursor indigo); they would become Color Variables if accepted.

## Open checks / dependency

- User review of the direction.
- Decided 2026-10-22: the feature is opt-in (Settings switch, optional onboarding row, off by default); the AI tab and sidebar item appear only when it is on.
- Open: the Settings privacy line (“network only for updates”) depends on the data-source decision; a window-level state frame.
- Mechanism and privacy decision for each tool (especially Claude and Cursor) in research/SPEC before any implementation.

## Next handoff

Design: apply user feedback to the frames above. Engineering: nothing to implement until SPEC adopts the feature.
