# APP-015: AI usage limits for Claude Code, Codex, Cursor and Grok

- Updated: 2026-10-22
- Stage: awaiting_verification
- Owner: unassigned (released 2026-10-22)
- Owned surfaces: `monny/AI/`, `Popover/AILimitsTab.swift`, `Dashboard/AIUsagePage.swift`; AI parts of Settings, Sidebar, PopoverView, DashboardView, Onboarding Ready, Alerts, History metrics and `Sampler.extraHistoryValues`
- Requirements: [SPEC](../SPEC.md) §3, §4, §6, §7, §8 (AI limits, user decision 2026-10-22); design [DES-003](DES-003-ai-usage-limits.md)
- Code baseline: main 19ef2ce; build 47, committed 2026-10-22

## Outcome and scope

Optional monitoring of the 5-hour and weekly plan limits of Claude Code and Codex, as CodexBar does it ([research](../research/ai-usage-limits.md)). Off by default; turned on in Settings › AI limits or onboarding Ready. On: popover tab AI, sidebar page AI usage, the “AI limit is running low” notification (off by default), and the privacy line mentions AI limits. Cursor from the Sketch frames is not implemented.

- Popover: one card per tool found (`~/.claude`, `~/.codex`), bars of quota left with a pace mark, Running low / Limit reached chips, stale reading (orange age, gray bars, “—” for a window that has reset, a refresh hint), Signed out, Checking…, No AI tools found with Hide AI Limits. Footer: Checked every minute.
- Window: tiles, “Quota left over 24 hours / 7 days” (weekly windows from history with reset marks), Next resets with the pace forecast, Sources with a connection chip. Range control 24h / 7d only.
- Copy differs from Sketch where it named Cursor; the Sketch “Open Cursor” button has no Claude/Codex counterpart, so signed out shows a sign-in hint only.

## Implementation and verification

- Agent-observed on the M1 Max, macOS 27.0.1, 2026-10-22: a test in the app's test host read real limits for both tools (Claude Pro: 5 h 76 % left, week 48 %; Codex Plus: 5 h 95 %, week 62 %) with no Keychain dialog.
- Views rendered offscreen from injected readings (normal, used up, stale with a reset window, no tools, 7-day history with resets) in Light and Dark and compared with Sketch frames `11`, `12`, `13`, `19`; the render test was temporary and removed.
- `AIUsageTests` (decoding fixtures with invented values, JWT expiry, pace mark, running low, forecast, one alert per episode, history only from fresh readings). 53 tests in 10 suites pass. Release `Monny-1.0-43.dmg` built and signed (Apple Development, not notarized).
- Strings added in all six languages.

## User check of build 43 — 2026-10-22

Limits matched the services. Fixed in build 44: Running low appeared at 62 % left (the pace rule); now below 10 % left only, for the chip, the orange value and the notification. The chip is the small 18 pt variant with 10 pt text (new `Chip/Small Warning` and `Chip/Small Danger` symbols, frames `11` and `12`; Codex weekly example now 8 % left in frames `11` and `19`, Sketch saved). Russian “5-hour window” became “5 часов” so the label fits next to the chip. A weekly window used up shows “Available again Sat 13:04” instead of hours. Popover tabs no longer overflow in Russian: segments size to their titles ([DESIGN](../DESIGN.md#rules-that-apply-to-every-screen)). Checked offscreen in all six languages; 53 tests pass.

## User acceptance — 2026-10-22

User, build 44: AI limits, the 10 % rule, the small chip and the tabs accepted.

## Cursor, Grok and per-tool choice — build 45, 2026-10-22

User request: add Cursor, Grok and Gemini where possible. Cursor (Cursor.app sign-in, monthly included usage with dollars) and Grok (Grok CLI sign-in, weekly or monthly credits) added from CodexBar's sources ([research](../research/ai-usage-limits.md#cursor)); Gemini is not possible without cookies or scraped OAuth secrets ([research](../research/ai-usage-limits.md#gemini-not-implemented)). Settings › AI limits lists a checkbox per found tool; unchecked tools are hidden and not read. Window: four tiles form two rows, the chart draws each tool's longest window and lists only tools with history, Next resets shows four rows. Grok uses slate (its black-and-white brand would match Codex) and a “G” glyph; Sketch has no Grok frame yet. Neither tool is installed on the test Mac: fixtures (`decodesCursorIncludedUsage`, `decodesGrokCredits`, `picksTheSuperGrokSignIn`, a temporary SQLite state database), both endpoints answer 401 without credentials, offscreen renders with four tools. 58 tests pass; `Monny-1.0-45.dmg` built.

## User check of build 45 and follow-up — build 46, 2026-10-22

- Old limits for minutes after relaunch: Anthropic's endpoint returned HTTP 429 after a few requests a minute (measured, [research](../research/ai-usage-limits.md#claude-code)); the answer itself is current within 20–30 s. Checks now run every 2 minutes while visible, and a 429 pauses 5 minutes.
- Window tiles: rows stuck together after the 18 pt chip row; tiles use the drawn 14 pt line, 5 pt to the bar and 12 pt between rows again.
- Model limits (Claude weekly per model, Codex Spark) and Codex credits drawn in Sketch frame `14 · Popover · AI limits · Model limits` (Light/Dark, saved) and implemented; window tiles grow and keep a row's height equal. API key logins show “API key” instead of Signed out. CodexBar credited in the README.
- Decided by the user: no custom config folders or several accounts for now; no AI value in the menu bar.
- 61 tests pass; fixtures for model limits and credits; offscreen renders.

## Review before commit — build 47, 2026-10-22

- The popover panel only orders out, so the AI tab's `onDisappear` did not fire and the monitor counted it as visible: background checks ran every 2 minutes. Visibility is now a set fed by the status item (popover shown and AI tab selected) and the AI usage page, as `Sampler` does.
- A window already low before quitting no longer notifies again at launch (saved readings seed the episode state).
- Notifications for model limits name the model (“Claude Opus limit is running low”).
- Sources shows Connected while a fresh reading survives a 429 pause, instead of a red Couldn’t check.
- VoiceOver hears “Running low” with the value.
- User decision: what cannot be checked without accounts (Cursor, Grok, model limits, credits, API key login) stays open below. Monny-1.0-47.dmg built; 61 tests pass.

## Open checks / dependency

- Cursor and Grok against a real signed-in account (needs a Mac with them).
- Model limits, credits and the API key state against real accounts (this Mac's plans have none).

- Chart and forecast with real history (needs a few days of readings), a stale reading after Claude Code's token expires, and the notification on a real low window.
- Whether a 1-minute check while visible triggers HTTP 429 from Anthropic over a long session.

## Next handoff

Later, with suitable accounts: Cursor, Grok, model limits, credits, API key login. Wait for a few days of history, then check the chart, forecast, a stale reading and the notification. Design: a Grok card and the four-tile window layout are not drawn in Sketch.
