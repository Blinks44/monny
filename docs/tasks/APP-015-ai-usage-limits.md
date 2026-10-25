# APP-015: AI usage limits

- Updated: 2026-10-25
- Stage: awaiting_verification
- Owner: unassigned (Copilot implementation complete; installed comparison next)
- Owned surfaces: `apps/monny/monny/AI/`, AI popover/dashboard, Settings/onboarding, alerts and quota history
- Requirements: [SPEC](../SPEC.md) §§3–4, 6–8; [design](DES-003-ai-usage-limits.md); [mechanisms and licensing](../research/ai-usage-limits.md)
- Implementation: builds 43–49, baseline main `713defe` (build 50); repeated-alert fix in build 60, based on `e7db28d` (see the commit history for monitor/tests/project changes).

## Current outcome

JetBrains AI is added in build 59 by [DES-004](DES-004-power-search-quit-ai-tools.md#jetbrains-ai-implementation--2026-10-25): local-only monthly quota and separate top-up balance, source-time freshness, Settings/history/alerts. The user compared its quota with the IDE in 1.1.0 and it matched (2026-10-25). Copilot is added in build 61 below; in 1.1.0 the user compared it with GitHub and it matched (2026-10-25). This record retains all provider account/history gates.

Opt-in limits with a checkbox per detected tool; off by default. Only enabled tools' own sign-ins are read. Claude Code/Codex show plan windows, supported model limits and credits; Cursor shows monthly included usage; Grok shows weekly/monthly credits; Copilot uses the saved GitHub CLI account for monthly premium requests and separate chat/completion quotas, unlimited labels and consumed credits. Gemini is unsupported. No browser-cookie import, token refresh, custom credential folders, multiple accounts or menu bar AI value.

Popover AI cards show quota left, pace marks, reset times and fresh/stale/signed-out/API-key/error states. Running low means **below 10% left**, independent of pace, for the chip, orange value and notification. Small chips and title-sized tabs fit localized labels. The window has tool tiles, 24h/7d quota history with resets, forecasts labelled as estimates, next resets and connection status. Service marks and saved frames are indexed in DESIGN.

Checks run every **2 minutes while visible, 5 minutes otherwise**; HTTP 429 waits at least 5 minutes. Visibility comes from the actual popover/AI-page state. Saved readings seed alert episodes so relaunch does not repeat a low-window notification; model alerts name the model. A fresh reading remains Connected through a 429 cooldown. Stale windows that have reset show unavailable values.

## Dated verification

- 2026-10-22, M1 Max/macOS 27.0.1, build 43: agent-observed live Claude Code/Codex limits through the test host without a Keychain dialog. Account quota values are intentionally omitted. User reported the displayed limits matched the services.
- Build 44: user accepted limits, below-10% rule, small chip and localized tabs. Six-language offscreen checks passed.
- Builds 45–49: Cursor/Grok, model limits/credits, API-key state, visibility/alert fixes and service marks implemented. Cursor/Grok used decoding fixtures, a temporary SQLite database and unauthenticated endpoint checks; these do not prove signed-in usage.
- Latest feature-suite run recorded for build 47: 61 tests pass, including decoding, token expiry, forecast, alerts and fresh-only history. Light/Dark injected renders cover normal, exhausted, stale/reset, empty and four-tool layouts. Builds through 49 were packaged; no new test/build run during the documentation cleanup. Build-50 verification is in [history](../history/2026-10.md#2026-10-23-align-menu-commands-with-rebind).
- Sketch frames/symbols saved 2026-10-22, including model limits, Cursor/Grok, four-tool window, per-tool Settings and service marks. Copy supports all six languages.

## Repeated low-limit notification fix — 2026-10-25

The user reported an exhausted Claude notification every two minutes. Build 59 (`e7db28d`) changed low-window tracking to compare reset timestamps exactly; any correction to that timestamp, or its disappearance/return, generated another alert on the polling cadence. Synthetic repeated responses reproduce this defect; the live provider responses were not captured.

Build 60 tracks a continuous low episode through reset corrections and missing timestamps. It re-arms on recovery, after the previous reset, or when the reported new period starts at/after the previous reset. This preserves JetBrains' new-month notification without requiring an intermediate recovered sample. No cadence, threshold or product copy changes.

Verification: two new regression tests fail on the baseline (seven failed assertions), then `apps/monny/scripts/dev.sh test` passes all **102 tests in 14 suites**, including the existing new-month regression. Local result: `apps/monny/build/DerivedData/Logs/Test/Test-monny-2026.10.25_22-50-02-+0300.xcresult`. The initial sandboxed invocation could not write Xcode/SPM caches; the authorized rerun completed. User follow-up on 2026-10-25 reports the fix appears to work; observation duration, view state and individual reset scenarios were not restated, so multi-poll/new-period acceptance remains open.

Artifact: `apps/monny/build/release/Monny-1.0.0-60.dmg`, SHA-256 `d4501cfbb28ee10b6086d5906b9bc6d4b83350fbf19481554245f438425825e4`. `apps/monny/scripts/release.sh` succeeded: arm64 Release, app/nested-code/DMG signatures, image verification and signed appcast. Apple Development signed, not notarized; packaging did not install or publish the candidate. `git diff --check` passed. Existing unrelated `BatteryTab` Text-concatenation deprecation warnings remain.

Next: continue observing build 60 across several two-minute checks of the same exhausted Claude window and a later genuinely new low period; retain the user’s positive initial report without treating it as full reset-cycle acceptance.

## Copilot implementation — 2026-10-25

Build 61, baseline `f07b427` plus uncommitted AI model/reader/views, popover/dashboard, HistoryMetric, Theme, catalog, project and `CopilotUsageTests` changes. Reuses the active github.com sign-in from `gh auth token --hostname github.com --no-refresh`, with environment token/host/config overrides removed; discovery reads no credentials. Only standard Homebrew CLI locations and the standard `~/.config/gh` configuration are supported. No login, refresh, cookie import, new dependency or stored token. [Research](../research/ai-usage-limits.md#github-copilot--2026-10-25) records CodexBar revision, fields and limitations.

Monthly premium/chat/completions retain distinct identities. Unlimited allowances are text; zero-entitlement placeholders and unknown/malformed categories never become percentages. Consumed credits are not remaining balance and overlapping counters are not added. Legacy free-plan counters preserve chat/completion identity. Only premium requests enter history; category-specific low episodes use the shared notification logic. A known reset is displayed, but without a known start there is no pace/forecast. Existing per-tool Settings opt-out and polling/429/stale handling are reused; GitHub redirects are refused.

Live `Monny.sketch` frame `23` reviewed in Light/Dark on 2026-10-25, including exact graphite C tile colors; no design edits/save. Sixty native fixtures (five states × six languages × Light/Dark) and two six-tool dashboard layouts reviewed. Long category labels use a shorter category-only fallback; low/exhausted chips move below the bar. Fixtures use injected account-free readings; shared date/relative-time helpers retain the test process's locale, so complete date localization still needs installed review. Initial ImageRenderer popover captures were blank because of TimelineView; replaced with NSHostingView captures. Temporary render/live tests removed before the final suite.

Verification: read-only GitHub CLI probe returned HTTP 200; the actual `AIUsageReader.read(.copilot)` also succeeded from Monny's Debug test host on macOS 27.0.1 without a Keychain prompt. Tokens, account identifiers and real quota values were neither logged nor retained. This proves access/decoding, not agreement with the GitHub UI. Twelve permanent tests cover decoding, category isolation, unlimited/placeholder/credit semantics, numeric strings, legacy quotas, unknown fields, no invented pace, resets, alert repetition/history freshness, cached-reading compatibility, environment isolation and redirect refusal. Final test/release evidence follows after packaging.

Accepted 2026-10-25: in installed 1.1.0 the Copilot reading matched GitHub (user report; plan/quota values not recorded). Open: tool opt-out, keyboard/VoiceOver/Increase Contrast and real expiry/403/429; verify other plan shapes and a later monthly reset. The internal endpoint and editor headers are undocumented and may change; old `gh` versions without `--no-refresh` show setup guidance. Enterprise hosts, separate Copilot login, budgets/browser cookies and inferred/user-entered credit ceilings are outside this slice.

## Review of the day's AI/process work — 2026-10-25

Build 62 reviews the process actions, battery power panel, JetBrains reader, repeated-alert fix and Copilot slice. No correctness defects found; behavior is unchanged. Simplified: one `AIQuotaWindow.isPlanLimit` replaces the duplicated history/Next-resets filter, the low/exhausted chip is one `QuotaRow` view, and the letter tile uses the tool name's initial. `apps/monny/scripts/dev.sh test` passed 114 tests in 15 suites; `release.sh` packaged signed `Monny-1.0.0-62.dmg` (not notarized). The installed Copilot comparison was later accepted in 1.1.0 (above).

Build 63: GitHub CLI discovery adds MacPorts and Nix paths; no other behavior change. Copilot without `gh` was researched and not adopted ([research](../research/ai-usage-limits.md#copilot-without-the-github-cli--reviewed-2026-10-25)). 114 tests passed; signed `Monny-1.0.0-63.dmg` packaged.

## Open checks and next handoff

- Verify Cursor/Grok with real signed-in accounts; model limits, credits and API-key state with accounts that expose them.
- After a few days of real readings, verify chart/reset/forecast behavior, token-expiry staleness and one notification on a genuinely low window.
- Observe Anthropic HTTP 429 behavior over a long session with the implemented 2-minute visible cadence.
- Before public release, check service marks against their owners' brand guidelines.

Next: use suitable accounts and accumulated history for those checks. No design work is currently open; do not request another implementation of Cursor/Grok.
