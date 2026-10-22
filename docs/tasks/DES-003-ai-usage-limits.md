# DES-003: AI usage limits (Claude Code, Codex, Cursor) exploration

- Updated: 2026-10-22
- Stage: done for Claude Code and Codex (implemented in [APP-015](APP-015-ai-usage-limits.md), build 43); Cursor not implemented
- Owner: unassigned (design pass released 2026-10-22)
- Owned surfaces: Monny.sketch page `01 · Popover` frames `11`–`13`, page `02 · Window` frames `19`–`20`, page `03 · Flows & System` frame `13`
- Requirements: [SPEC](../SPEC.md) §3, §4, §6, §7 (adopted 2026-10-22 for Claude Code and Codex)
- Code baseline: main at 0636518; no code changed by this task

## Outcome and scope

Explore how Monny could show the usage limits of Claude Code and Codex (5-hour and weekly windows) and Cursor (monthly included usage) in the popover and the main window. Design first, mechanism later.

Data sources were decided on 2026-10-22 after reviewing CodexBar ([research](../research/ai-usage-limits.md)): both tools' usage endpoints with their own sign-in, opt-in only. Cursor (monthly included usage) is not researched or implemented.

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

- Decided 2026-10-22: the feature is opt-in (Settings switch, optional onboarding row, off by default); the AI tab and sidebar item appear only when it is on.
- Implemented without a Sketch frame: the privacy line becomes “No analytics · network only for updates and AI limits” while the switch is on; window states reuse the popover messages and the No AI tools view.
- Copy in the frames names Cursor; the app drops it. Sketch can be updated later.

## Next handoff

Design: optionally remove Cursor from the frames or keep it for a later Cursor task. Engineering: none.
