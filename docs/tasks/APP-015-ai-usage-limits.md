# APP-015: AI usage limits

- Updated: 2026-10-26
- Stage: awaiting_verification
- Owner: unassigned (build-65 implementation complete; real-account comparison next)
- Owned surfaces: `apps/monny/monny/AI/`, AI popover/dashboard, Settings/onboarding, alerts and quota history
- Requirements: [SPEC](../SPEC.md) §§3–4, 6–8; [design](DES-003-ai-usage-limits.md); [mechanisms and licensing](../research/ai-usage-limits.md)
- Implementation: builds 43–49, baseline main `713defe` (build 50); repeated-alert fix in build 60, based on `e7db28d` (see the commit history for monitor/tests/project changes).

## Current outcome

JetBrains AI is added in build 59 by [DES-004](DES-004-power-search-quit-ai-tools.md#jetbrains-ai-implementation--2026-10-25): local-only monthly quota and separate top-up balance, source-time freshness, Settings/history/alerts. The user compared its quota with the IDE in 1.1.0 and it matched (2026-10-25). Copilot is added in build 61 below; in 1.1.0 the user compared it with GitHub and it matched (2026-10-25). This record retains all provider account/history gates.

Opt-in limits with a checkbox per detected tool; off by default. Only enabled tools' own sign-ins are read. Claude Code/Codex show plan windows, supported model limits and credits; Cursor shows monthly included usage; Grok shows weekly/monthly credits; Copilot uses the saved GitHub CLI account for monthly premium requests and separate chat/completion quotas, unlimited labels and consumed credits. ClinePass/Codebuff are added in build 64 using their existing CLI sessions; build 65 adds bounded Amp/Augment CLI usage reads and Nous Portal through Hermes-owned credentials (below). Gemini is unsupported. No browser-cookie import, token refresh, custom credential folders, multiple accounts or menu bar AI value.

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

## ClinePass / Codebuff — 2026-10-26

Authorized scope: add remaining tools that reuse their own local sign-in with simple read-only sources. Research decision recorded before code in [sources](../research/ai-usage-limits.md#clinepass-and-codebuff--implementation-decision-2026-10-26). Reuse existing cards/letter tiles, settings, history and alerts. Live saved Monny.sketch frame `23` Light inspected through MCP; no Sketch edits. ClinePass/Codebuff use the existing neutral letter-tile pattern rather than new service marks. Implementation complete in uncommitted build 64 over main `b264759`: `AI/` reader/session/response models, dashboard, history, six-language catalog, project build number and tests. ClinePass uses only Cline's saved OAuth session, with 5-hour/weekly/monthly windows when reported and no invented monthly pace. Codebuff shows the reported weekly subscription allowance and separate remaining credits; no percentage/reset is inferred from an undated credit balance. Existing detection/settings/history/alerts and 2/5-minute cadence are reused. All token-bearing service requests now refuse redirects; no credentials are read from a disabled new tool and no CLI process, key storage or dependency is added.

Verification on macOS 27.0.1:

- Final `apps/monny/scripts/dev.sh test`: **124 tests in 16 suites passed**, after removing the temporary render harness. Ten new test functions (including parameterized cases) cover session selection/no API-key fallback, token/JWT expiry and bounds, strict quota decoding, missing/invalid counters, independent credit balance, histories/alert episodes, exact HTTP hosts/methods/auth/body and second-request 429 without a partial refresh. Existing redirect test now covers GitHub, Cline and Codebuff hosts.
- Earlier suite with temporary native render harness: 125 tests in 17 suites passed. Reviewed **48 offscreen NSHostingView popover fixtures**: two tools × quota/missing-sign-in × six languages × Light/Dark. Quota states include low and exhausted windows, unknown monthly pace and separate credits. Text fits 328 pt content width; numeric/date formatting follows the host locale while copy follows the per-view locale. Temporary harness removed; images stay outside Git. This does not establish installed focus/VoiceOver or real-account readings.
- Initial sandboxed run could not write Xcode/SwiftPM caches; authorized ordinary test reruns passed. The first new-test run had two floating-point equality assertions; corrected to tolerance and reran successfully. Existing BatteryPage Text-concatenation/AppIntents warnings remain. No system/project signing changes or security bypass.
- `apps/monny/scripts/release.sh` passed: Apple Development signed **Monny 1.1.0 build 64**, nested-code/app/DMG signature checks, image integrity and signed appcast. `apps/monny/build/release/Monny.dmg`, SHA-256 `d03386e36519f05a971b1f49e56d4b616b464987f469602c6c4b8abb72e4021b`. Not notarized, installed or published. `git diff --check`, new six-language keys and affected local links checked.

Next: compare ClinePass and Codebuff with their own account usage screens on a Mac with those CLI sessions; then observe history/reset/expiry/429 behavior. No live account request or sign-in was performed during development. Amp/Augment/Nous are implemented in the next slice below; Windsurf/Kilo/Kiro remain candidates for separate source work; no further provider is required to complete this bounded implementation.

## Further provider screening — 2026-10-26

Reviewed CodexBar for additional useful sources at the user's request; no code, build, sign-in or live account fetch. [Research](../research/ai-usage-limits.md#additional-screening--2026-10-26) adds Nous/Hermes and Bailian CLI candidates, retains Amp/Augment/Kilo, and identifies Kiro's direct API as an investigation rather than requiring its costly chat command. This review led to the authorized Amp/Augment/Nous slice below, preserving build-64 work and all real-account gates. Credential-expiry alerts remain a separate optional product idea. Account setup and browser access were not performed.

## Amp / Augment / Nous — 2026-10-26

Implement the straightforward provider slice authorized after screening. Baseline: main `b264759` plus this session's uncommitted build-64 implementation. Source/field/safety decision recorded before code in [research](../research/ai-usage-limits.md#amp-augment-and-nous--implementation-decision-2026-10-26). Existing saved frame `23` refreshed live through Sketch MCP; reuse its card/letter-tile pattern, no Sketch edits. Implementation: parsers/readers, three per-tool detection/settings entries, separate quota metrics/alerts, typed Amp labels and Decimal USD rows; no dependencies, new login flow, credential writes, browser import or shell/PTY. Amp uses the live saved coral A tile; Augment/Nous use neutral letter tiles. Detection reads metadata only; only enabled tools run their usage commands/read credentials. Existing build-64 ClinePass/Codebuff and user acceptance documentation are preserved. Code, project version 65, catalog/tests and related records remain uncommitted over `b264759`.

Verification on macOS 27.0.1:

- Final `apps/monny/scripts/dev.sh test`: **137 tests in 17 suites passed**, after removing the temporary render harness. Thirteen new test functions (with parameterized cases) cover current/legacy Amp and Augment formats, exact versus missing/invalid dates, independent Agent/Orb/cash counters, invalid/absent amounts, Hermes explicit/single-pool/shared selection, expiry/host rejection, null fallbacks, fixed HTTP method/host/header and no invalid-primary fallback, USD/cache round-trip, fresh-only history and nonrepeating alerts. The fake HTTP transport gained Nous; redirect refusal covers its host too. No actual provider sign-in or live account fetch was used.
- Command fixtures exercise simultaneous stdout/stderr draining, nonzero status, missing executable, output overflow, timeout and task cancellation. Both timeout/cancellation tests observed the test-owned child PID disappear; no existing user process was stopped. Minimal command environment is checked. These establish runner behavior, not real installed CLI startup cost, token renewal or account agreement.
- Temporary suite: **138 tests in 18 suites passed**. Reviewed **108 native offscreen popover fixtures** (three tools × low/exhausted, signed-out, stale × six languages × Light/Dark) and two Russian 11-tool dashboards. New USD rows use the view locale; legacy relative/date/allowance helpers retain the host locale. Text fits 328 pt content width. Initial 11-tool capture reproduced legend overflow that pushed the reset card outside the dashboard; a standard adaptive legend grid for more than four series fixes it, verified in final Light/Dark captures. Existing smaller legend layout stays in place. Images stay local; temporary harness removed. No installed VoiceOver or real provider account comparison is claimed.
- Initial compiler failures were ambiguous `Decimal.init` overloads; explicit conversion fixed them. Final suite passed. Existing unrelated Text-concatenation/AppIntents and test-host service diagnostics remain; no new compiler error, system/security change or dependency.

- `apps/monny/scripts/release.sh` passed: **Monny 1.1.0 build 65**, Apple Development signed app/nested Sparkle/DMG, strict signature and image-integrity checks, signed appcast. Artifact: `apps/monny/build/release/Monny.dmg`; SHA-256 `78f54b56e8bb578b3d5eabeffb1bcf244d8cedec3c273de609da94c2ca372e17`. Not notarized, installed or published. `git diff --check`, affected file links and all nine new six-language keys passed review.

Next: compare each provider against its own usage command/account page on a Mac where it is signed in, observe the normal 2/5-minute cadence and a later reset/expiry. Missing CLI/custom paths, multi-entry Hermes pools and unsupported output shapes remain explicit source limitations; Kiro/Kilo/Bailian and optional menu-bar/credential-alert features are outside this completed source slice.

## Vendor marks — 2026-10-26

Replaced all seven remaining letter placeholders with authentic marks; the four existing marks remain. Sources, transformations and notice are in [research](../research/ai-usage-limits.md#remaining-vendor-marks--2026-10-26). Baseline is the same uncommitted build-65 work over `b264759`; final build is 66. Native Copilot/JetBrains/Amp examples and responsive website badges/copy are saved in Monny.sketch; all 11 marks are present in its website sections. No source/account-reading behavior changed.

Verification: 137 tests in 17 suites passed on macOS 27.0.1. Temporary native render check passed (138 tests/18 suites); reviewed all 11 marks at 20/30 pt in Light/Dark, then removed the harness and reran the permanent suite. Initial temporary harness needed an explicit ForEach identity. Sandbox cache restrictions required the ordinary authorized Xcode rerun. Signed final DMG: `apps/monny/build/release/Monny.dmg`, 1.1.0 build 66, SHA-256 **8a7a729e07ad63a836cf3784710b77f48886ccfddc1c4e861f9b0aaebdafd447**. Release script verifies nested signatures, app/DMG integrity and signs the appcast. Not installed, notarized or published.

Next: install the candidate and compare new providers with their own account sources. Existing account/reset/history and owner-brand-guideline release gates remain open.

## 1.1.1 publication — 2026-10-26

Published [v1.1.1](https://github.com/Blinks44/monny/releases/tag/v1.1.1) through gh at the user's request. Release source/tag: `53e34d3` (version 1.1.1, build 67 in Debug and Release); website deployment remains with the user. The tag includes this conversation's provider/logo/website work and dated acceptance records. Release notes retain the five providers' real-account limitations.

Final `dev.sh test`: 137 tests in 17 suites passed on macOS 27.0.1. `release.sh` passed after one transient Finder status-bar configuration error required a standard packaging retry; no workaround or signing-setting change. Apple Development app/nested-code/DMG signatures, image integrity and the Sparkle EdDSA signature passed. Mounted the final DMG read-only and extracted its app to temporary storage: version 1.1.1/build 67 and strict deep signature verified. This was a package-content check, not an installed launch/update acceptance.

Assets: `Monny.dmg`, `SHA256SUMS.txt`, `appcast.xml`. Local DMG: `apps/monny/build/release/Monny.dmg`, SHA-256 `9730775d8f9e597c74a2b17fdee855b92c6d514e0c246b1db846059d85075942`. Published as latest stable, not a draft/prerelease. Unauthenticated downloads through `releases/latest/download/` match the local DMG checksum and byte-identical appcast; public appcast version, build, enclosure URL/length and update signature verified. Not notarized. No website deployment or real-account requests were performed.

User acceptance 2026-10-26: the in-app update to 1.1.1 worked. The five new providers will be compared gradually; this confirms the update flow, not account readings.

Next: compare each new tool against its own usage screen/command when a signed-in account is available. Existing account/reset/history, other hardware and owner-brand-guideline limitations remain.
