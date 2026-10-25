# APP-015: AI usage limits for Claude Code, Codex, Cursor and Grok

- Updated: 2026-10-23
- Stage: awaiting_verification
- Owner: unassigned
- Owned surfaces: `apps/monny/monny/AI/`, AI popover/dashboard, Settings/onboarding, alerts and quota history
- Requirements: [SPEC](../SPEC.md) §§3–4, 6–8; [design](DES-003-ai-usage-limits.md); [mechanisms and licensing](../research/ai-usage-limits.md)
- Implementation: builds 43–49, present in baseline main `713defe` (build 50)

## Current outcome

JetBrains AI is added in build 59 by [DES-004](DES-004-power-search-quit-ai-tools.md#jetbrains-ai-implementation--2026-10-25): local-only monthly quota and separate top-up balance, source-time freshness, Settings/history/alerts. Software/layout tested; real IDE quota comparison remains open there. This record retains the earlier providers’ account/history gates.

Opt-in limits with a checkbox per detected tool; off by default. Only enabled tools' own sign-ins are read. Claude Code/Codex show plan windows, supported model limits and credits; Cursor shows monthly included usage; Grok shows weekly/monthly credits. Gemini is unsupported. No browser-cookie import, token refresh, custom credential folders, multiple accounts or menu bar AI value.

Popover AI cards show quota left, pace marks, reset times and fresh/stale/signed-out/API-key/error states. Running low means **below 10% left**, independent of pace, for the chip, orange value and notification. Small chips and title-sized tabs fit localized labels. The window has tool tiles, 24h/7d quota history with resets, forecasts labelled as estimates, next resets and connection status. Service marks and saved frames are indexed in DESIGN.

Checks run every **2 minutes while visible, 5 minutes otherwise**; HTTP 429 waits at least 5 minutes. Visibility comes from the actual popover/AI-page state. Saved readings seed alert episodes so relaunch does not repeat a low-window notification; model alerts name the model. A fresh reading remains Connected through a 429 cooldown. Stale windows that have reset show unavailable values.

## Dated verification

- 2026-10-22, M1 Max/macOS 27.0.1, build 43: agent-observed live Claude Code/Codex limits through the test host without a Keychain dialog. Account quota values are intentionally omitted. User reported the displayed limits matched the services.
- Build 44: user accepted limits, below-10% rule, small chip and localized tabs. Six-language offscreen checks passed.
- Builds 45–49: Cursor/Grok, model limits/credits, API-key state, visibility/alert fixes and service marks implemented. Cursor/Grok used decoding fixtures, a temporary SQLite database and unauthenticated endpoint checks; these do not prove signed-in usage.
- Latest feature-suite run recorded for build 47: 61 tests pass, including decoding, token expiry, forecast, alerts and fresh-only history. Light/Dark injected renders cover normal, exhausted, stale/reset, empty and four-tool layouts. Builds through 49 were packaged; no new test/build run during the documentation cleanup. Build-50 verification is in [history](../history/2026-10.md#2026-10-23-align-menu-commands-with-rebind).
- Sketch frames/symbols saved 2026-10-22, including model limits, Cursor/Grok, four-tool window, per-tool Settings and service marks. Copy supports all six languages.

## Open checks and next handoff

- Verify Cursor/Grok with real signed-in accounts; model limits, credits and API-key state with accounts that expose them.
- After a few days of real readings, verify chart/reset/forecast behavior, token-expiry staleness and one notification on a genuinely low window.
- Observe Anthropic HTTP 429 behavior over a long session with the implemented 2-minute visible cadence.
- Before public release, check service marks against their owners' brand guidelines.

Next: use suitable accounts and accumulated history for those checks. No design work is currently open; do not request another implementation of Cursor/Grok.
