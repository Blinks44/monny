# DES-003: AI usage limits design

- Updated: 2026-10-23
- Stage: done (saved design; implementation verification belongs to APP-015)
- Owner: unassigned
- Source: Monny.sketch, saved 2026-10-22, Light/Dark
- Requirements: [SPEC](../SPEC.md) §§3–4, 6–8; implementation/evidence: [APP-015](APP-015-ai-usage-limits.md)

## Ready scope

Claude Code, Codex, Cursor and Grok cards, quota-left bars with pace marks, low/exhausted/stale/signed-out/empty states, model limits and credits; four-tool window with history/forecast/reset/source sections; opt-in Settings with per-tool checkboxes and optional onboarding row. Running low uses below 10% left, independent of pace. Copy and availability in the app follow the current SPEC and research; older exploration annotations do not override them.

[DESIGN](../DESIGN.md#readiness) is the source locator for popover frames 11–15, window frames 19–22, onboarding frame 13 and service-mark symbols. It owns the short frame index; inspect the saved source live before edits. No duplicated component inventory or exports are needed here.

## Verification and next step

2026-10-22: new/changed frames reviewed live in Light/Dark and saved. Claude/Codex implemented in build 43, accepted in 44; Cursor/Grok and their saved four-tool/model/Settings frames implemented through build 49. There is no outstanding Cursor design handoff. Six-language expansion and runtime/account/history acceptance are app checks in APP-015; service-mark brand review remains open there.

Next: verify APP-015 with suitable accounts/history. Reopen design only for an observed gap.
