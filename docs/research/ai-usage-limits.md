# AI usage limits: data sources

Decided 2026-10-22 for [APP-015](../tasks/APP-015-ai-usage-limits.md). Checked on an M1 Max, macOS 27.0.1, with Claude Code and Codex signed in (account values omitted).

## Reference: CodexBar

[steipete/CodexBar](https://github.com/steipete/CodexBar) (MIT, active; read at 71e3e56, 2026-10-22) is a menu bar app for many AI providers. Monny follows its preferred sources for Claude and Codex; no code is copied, only the endpoint, header and field names below. CodexBar adds browser-cookie sources, CLI scraping through a PTY, token refresh, multiple accounts and cost scanning of local logs; Monny needs none of that for two plan limits.

## Claude Code

- **Source:** `GET https://api.anthropic.com/api/oauth/usage` with `Authorization: Bearer <access token>` and `anthropic-beta: oauth-2025-04-20`. Undocumented: the same endpoint Claude Code's `/usage` uses. Response: `five_hour` and `seven_day` with `utilization` (percent used) and `resets_at` (ISO 8601 with microseconds); many other fields (model-specific weeks, extra usage, `limits[]`) are ignored. Needs the `user:profile` scope, which a normal `claude` sign-in has.
- **Credentials:** Claude Code 2 keeps `{"claudeAiOauth": {accessToken, refreshToken, expiresAt (ms), subscriptionType, …}}` in the login Keychain item `Claude Code-credentials`; older versions use `~/.claude/.credentials.json`, which Monny reads first.
- **Keychain access:** Claude Code writes the item with `/usr/bin/security`, so that tool is on the item's access list. A direct `SecItemCopyMatching` from Monny asks the user to allow access, and CodexBar reports that Claude Code resets the item's access list on every token renewal, so the dialog would return about daily. Monny therefore reads the item with `security find-generic-password -s "Claude Code-credentials" -w`, with a 3 s timeout so an unexpected dialog cannot block refreshes. Verified: no dialog from the test host and the signed app. CodexBar offers the same reader as an experimental option. If Claude Code changes how it writes the item, Monny shows Signed out.
- **Model limits:** Max plans add model-specific weekly limits as `limits[]` entries with `kind: weekly_scoped`, `group: weekly`, `percent`, `resets_at` (ISO 8601 or Unix seconds) and `scope.model.display_name`; older answers use `seven_day_opus` / `seven_day_sonnet`. Shown as “Opus only · weekly” rows after the plan windows; not in history or Next resets (CodexBar `ClaudeScopedWeeklyLimitMapper`).
- **API key:** without OAuth credentials, the Keychain item `Claude Code` (checked for existence only) or `primaryApiKey` in `~/.claude.json` means an API key login: shown as “API key”, which has no plan limits. Unverified on a real API-key login.
- **Rate limit (measured 2026-10-22):** after four requests in about 90 s from one token (a 20 s probe plus Monny), the endpoint answered HTTP 429 with `Retry-After: 0` and kept refusing for minutes. Monny therefore waits at least 5 minutes after a 429 (CodexBar's cooldown) and checks at most every 2 minutes while a view is open. The answer itself was current: utilization rose within 20–30 s of use.
- **Expiry:** the access token lasts about 8 hours. Monny does not refresh it: refreshing rotates the refresh token, and Monny would have to write Claude Code's credentials. An expired token shows the last reading as stale until Claude Code is used again.

## Codex

- **Source:** `GET https://chatgpt.com/backend-api/wham/usage` with the bearer token and `ChatGPT-Account-Id`. Response: `plan_type` and `rate_limit.primary_window` / `secondary_window` with `used_percent`, `reset_at` (Unix seconds) and `limit_window_seconds` (18 000 and 604 800). Undocumented; it is what the Codex CLI reads.
- **Model limits and credits:** `additional_rate_limits[]` (`limit_name` such as GPT-5.3-Codex-Spark, with its own `rate_limit` windows) become “Spark only · 5 hours / weekly” rows; `credits` (`has_credits`, `unlimited`, `balance` as a string) a Credits line when the account has any. Entries decode one by one, so a malformed one is skipped.
- **Credentials:** `~/.codex/auth.json` after `codex login` with ChatGPT: `tokens.access_token` (a JWT; its `exp` is checked first) and `tokens.account_id`. API-key sign-ins have no plan limits and show Signed out. A Codex set to keep credentials in the system keyring is not supported. `CODEX_HOME` is not visible to an app started from Finder, so only `~/.codex` is read.
- **Rejected:** the `rate_limits` events in `~/.codex/sessions/*.jsonl` are offline but update only while Codex runs. `codex app-server` (`account/rateLimits/read`) needs the CLI on the app's `PATH` and a child process per check.

## Cursor

Added 2026-10-22 from CodexBar's [cursor.md](https://github.com/steipete/CodexBar/blob/main/docs/cursor.md) at 71e3e56. Not installed on the test Mac: decoding is tested with fixtures and the endpoint was confirmed to answer 401 without a session; a real reading is unverified.

- **Credentials:** Cursor.app keeps `cursorAuth/accessToken` (a JWT) in `ItemTable` of `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`. Monny opens it read-only through the system SQLite (`immutable=1` when there is no `-wal` file, so nothing is created in Cursor's folder). The user ID is the last `|` part of `sub`. An expired token waits for Cursor to renew it.
- **Source:** `GET https://cursor.com/api/usage-summary` with the cookie `WorkosCursorSessionToken=<user ID>%3A%3A<token>`. Fields: `billingCycleStart/End`, `membershipType`, `individualUsage.plan` (`used`/`limit` in cents, `totalPercentUsed`, or `autoPercentUsed` and `apiPercentUsed`, already in percent); team members get `individualUsage.overall` instead. Shown as one Monthly window with “$x of $y left”.
- **Not used:** browser cookie import, on-demand spend, team pools and the Grok Bot allowance CodexBar also shows.

## Grok

Added 2026-10-22 from CodexBar's [grok.md](https://github.com/steipete/CodexBar/blob/main/docs/grok.md). Not installed on the test Mac; fixtures only, endpoint answers 401 without a token.

- **Credentials:** `~/.grok/auth.json` from `grok login` (xAI's Grok CLI): entries keyed by scope; the SuperGrok entry (`https://auth.x.ai::…`) wins over the older `https://accounts.x.ai/sign-in` one. `key` is the bearer token, `expires_at` ISO 8601.
- **Source:** `GET https://cli-chat-proxy.grok.com/v1/billing?format=credits` with the bearer and `x-xai-token-auth: xai-grok-cli`. `config.creditUsagePercent` (or `onDemandUsed.val / onDemandCap.val`) and `config.currentPeriod.start/end` (else `billingPeriodStart/End`); periods over 8 days show as Monthly. A period without a percentage reads as Couldn’t check; CodexBar then tries grok.com's gRPC-web billing, which Monny skips.
- **Not used:** `grok agent stdio` JSON-RPC (a child process per check), browser cookies, the xAI developer Management API (prepaid API credit, not plan limits).

## Gemini (not implemented)

Checked 2026-10-22. Google stopped Gemini CLI OAuth for individual, AI Pro and Ultra accounts on 2026-06-18; only Code Assist Standard/Enterprise accounts still have it, and its quota is per model (Pro/Flash), not 5-hour/weekly. Renewing its token needs the OAuth client secret scraped from the installed CLI. The consumer limits at gemini.google.com/usage are reachable only with browser cookies (a Keychain prompt per browser for Chrome's Safe Storage, Full Disk Access for Safari), and the Antigravity replacement needs a local `agy` server with CSRF and process cleanup. Each conflicts with Monny's no-hacks, no-cookies rule; revisit if Google publishes a usage API.

## Service marks

Added 2026-10-22 at the user's request. The SVGs come from [thesvg.org](https://thesvg.org/), a third-party collection the user chose, not from each company's brand page; the marks remain their owners' trademarks and identify the services only. Asset catalog `AIClaude`, `AICodex`, `AICursor`, `AIGrok` (vector, original rendering), mirrored by the Sketch symbols `Light/…` and `Dark/AI Logo/<tool>`.

| Mark | Tile | Change from the source |
| --- | --- | --- |
| Claude | `#D97757` | Fill `#D97757` → white; `<title>` kept |
| Codex (OpenAI) | white | Fill white → black |
| Cursor | black | None (`#EDECEC`) |
| Grok | white | Fills white → black |

The tiles keep a 1 pt hairline (black 10 % / white 12 %) so white tiles stay visible on white cards. Before a public release, compare with each owner's brand guidelines (Anthropic, OpenAI, Cursor, xAI) and replace a mark if its owner restricts recoloring.

## Privacy and cost

- Opt-in (Settings › AI limits, off by default; each found tool can be unchecked, and an unchecked tool is not read). Off, Monny reads no credentials and makes no requests. On, the only requests go to the services of the shown tools, with the user's own tokens, which never leave memory or go anywhere else. Only percentages, reset times, plan names and the reading time are stored (`aiUsage` in UserDefaults, quota history in the existing history file).
- Checks: every 2 minutes while the popover AI tab or the AI usage page is shown, every 5 minutes otherwise (for history and the running-low notification). HTTP 429 waits for `Retry-After`, at least 5 minutes.
- The usage endpoints are undocumented and may change. Decoding ignores unknown fields; a failed decode shows Couldn’t check and keeps the last reading as stale.

## Pace math

The pace mark sits at the share of the window's time left. A window is running low below 10 % left, whatever the pace (user decision 2026-10-22: the previous pace rule flagged ample remaining quota early in a window). The forecast divides the quota used by the elapsed time of the window and reports a run-out time only when it falls before the reset; it is labelled an estimate.
