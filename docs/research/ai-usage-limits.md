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

## JetBrains AI — implementation decision, 2026-10-25

- Checked native Foundation XML/JSON/FileHandle APIs and [JetBrains AI quota documentation](https://www.jetbrains.com/help/ai-assistant/installation-guide-ai-assistant.html). The IDE reports monthly credits and separate purchased top-ups. A local-only source satisfies the requirement; no provider SDK or dependency is needed. Reviewed active MIT CodexBar at `d34fbb47afe73f81dd591bae28a60f72c39a9fe4`: [provider notes](https://github.com/steipete/CodexBar/blob/d34fbb47afe73f81dd591bae28a60f72c39a9fe4/docs/jetbrains.md), `JetBrainsStatusProbe`, `JetBrainsQuotaLogReader` and their tests. Reference informs field/record names only; no implementation or test code is copied.
- Detect supported IDE configuration directories under `~/Library/Application Support/{JetBrains,Google}` (bounded, nonrecursive), and the matching `~/Library/Logs/<vendor>/<IDE>/idea.log`. Existence/metadata discovery runs off the main actor, without reading quota contents while AI limits or the tool are off. No browser, credential, Keychain, command, IDE setting or network access.
- XML: `<IDE>/options/AIAssistantQuotaManager2.xml`, component `AIAssistantQuotaManager2`, `quotaInfo` / `nextRefill` option JSON attributes. Foundation handles XML entities; reject external document types and bound input to 256 KiB. `type=Available`; `tariffQuota.current/maximum` are monthly usage/limit, strings or finite numbers. Legacy top-level values are accepted together only without a tariff or positive top-up pool; malformed monthly values never borrow from totals. Require nonnegative finite usage and a positive maximum. Missing values are not zero. `topUpQuota.available/maximum` is a separate balance, converted at 100,000 units per displayed credit, without a bar. No license/account IDs are retained.
- Logs: read at most a captured 4 MiB tail, discard the first partial line, and reject an unfinished last line or a short/truncated read. Only quota records are parsed; unrelated text remains temporary. Support flat `Available(...tariffQuota=QuotaDetails(...))`, newer `Available(quota=JbaiQuota(...tariffQuota=Details(...)))`, and Junie's `AiaActivationTransmitter - Received message from junie: quota_update:` JSON (amounts nested as `{amount: ...}`). The local line timestamp is the reading date, parsed with Foundation ParseStrategy. Unknown/malformed latest quota states invalidate the log instead of reviving older entries. Skip only the documented `AIAssistantForbiddenException` disabled-assistant state after Air migration. Refill `Known(...)` / `Known(refill=JbaiQuotaRefill(...))` supplies `next` and duration/period; Junie alone has no reset. `quotaInfo.until` is subscription expiry and is never a reset.
- Select the newest XML by modification date and consider only that installation's log, which replaces it only with a strictly newer complete quota snapshot. If XML is absent, select the newest log by modification date; do not fall back to another IDE/account when it has no supported quota. XML mtime or log record time stays `AIUsage.date`, so repeated reads do not freshen old cache. Refills/top-ups stay with their selected snapshot; never borrow XML reset dates into logs. Unknown duration disables the pace/forecast, unknown reset omits it. Quota age/reset semantics feed the existing stale rendering/history; stale/reset cache cannot trigger a new low-limit alert.
- Local inspection found an IDE log but no quota XML or recognized quota amounts in its bounded tail; only record presence/types were inspected and no account values retained. This establishes source availability limits, not a real plan reading. Fixture tests and localized renders will validate software behavior; real IDE quota/reset/top-up comparison remains an acceptance gate in [DES-004](../tasks/DES-004-power-search-quit-ai-tools.md).

## GitHub Copilot — 2026-10-25

Implementation decision: reuse the active github.com account from `gh auth token --hostname github.com --no-refresh`. [GitHub CLI documents this reader](https://cli.github.com/manual/gh_auth_token); the flag prevents automatic renewal. Only the installed CLI's saved account is used, with token environment overrides removed. The CLI is looked up at fixed Homebrew, official-installer, MacPorts and Nix (profile, nix-darwin, home-manager) paths, never through a login-shell PATH (build 63). Detection checks the CLI/config only, never credentials. No device flow, browser cookies, pasted tokens, Enterprise hosts or separate Monny sign-in. Older CLI versions without `--no-refresh` fail closed.

Reference: active MIT CodexBar at `d34fbb47afe73f81dd591bae28a60f72c39a9fe4`, [fetcher](https://github.com/steipete/CodexBar/blob/d34fbb47afe73f81dd591bae28a60f72c39a9fe4/Sources/CodexBarCore/Providers/Copilot/CopilotUsageFetcher.swift) and [response models](https://github.com/steipete/CodexBar/blob/d34fbb47afe73f81dd591bae28a60f72c39a9fe4/Sources/CodexBarCore/CopilotUsageModels.swift). Reviewed protocol/field names and edge cases; no implementation/test code copied. Native Foundation plus the existing CLI suffice; no provider package is needed.

- `GET https://api.github.com/copilot_internal/user`, GitHub OAuth token directly (`Authorization: token …`), JSON, editor/plugin/API-version headers matching the reference. Cookies/cache disabled; redirects refused. The token stays in memory, never logs or persisted readings.
- `copilot_plan`, `quota_snapshots.premium_interactions`, `chat`, `completions`: finite `percent_remaining`, or `remaining / entitlement` with a positive denominator. Preserve category names; never label completions as premium. Explicit unlimited and zero-entitlement placeholders never become percentage bars. Numeric strings accepted. Legacy `monthly_quotas` + `limited_user_quotas` cover chat/completions only when both counters exist.
- Monthly reset uses a valid service date; UTC date-only reset is parsed as UTC midnight. Without a known period start, no pace/forecast is inferred. Unlimited quotas show a text row. `credits_used` is consumption, not balance; premium wins, chat is fallback, never sum overlapping pools or invent a ceiling. Credit-billed plans without a metered quota explain that GitHub reports no quota limit.
- Existing polling, stale, per-tool switches, history and once-per-low-episode alerts apply. Only premium requests enter Copilot history; chat/completions are independent rows/alerts. 401/403 hides an old reading; 429 keeps the shared cooldown.
- Read-only live probe on 2026-10-25: the existing GitHub CLI account received HTTP 200 with the expected quota/reset fields, without a Keychain prompt. Sandbox prevented credential access; ordinary-user unsandboxed probe succeeded. No account identifiers, tokens or quota values retained. The actual Monny reader also succeeded from the Debug test host on macOS 27.0.1, without a Keychain prompt; account data was not logged or saved. Installed signed-app access and comparison with GitHub remain acceptance gates.

### Copilot without the GitHub CLI — reviewed 2026-10-25

- CodexBar (`d34fbb4`, 2026-10-24) does not use `gh` or Copilot's local files. It runs its own GitHub OAuth device flow with the VS Code client ID and `read:user`, then stores the token in its config/Keychain; `COPILOT_API_TOKEN` and pasted tokens are alternatives. `~/.config/github-copilot` appears there only in storage-footprint accounting. That is a separate Monny sign-in, outside the current decision; it needs an explicit product decision.
- The Copilot language server (Xcode, JetBrains, Neovim plugins) writes `~/.config/github-copilot/`. On the reviewed Mac, `auth.db` holds encrypted `token_ciphertext` per editor plus a `legacy_files_migration_done` marker; the plaintext `oauth.json` is the migrated legacy file. Reading it would depend on a file GitHub is retiring, and the encrypted store's key is not ours to read. Not adopted. Validity of the legacy token against the usage endpoint was not tested.
- VS Code keeps its Copilot session in its own encrypted secret storage (Keychain-protected); excluded for the same reason as other apps' Keychain items.

## Planned tools (candidates, not implemented)

Screened 2026-10-24 against CodexBar's [providers.md](https://github.com/steipete/CodexBar/blob/main/docs/providers.md) at d34fbb4 (110 provider IDs). Rule (user decision 2026-10-24): Monny reuses the tool's own sign-in on this Mac; no browser cookies, pasted API keys, separate Monny login or Keychain prompt. Most CodexBar providers fail this rule. JetBrains AI now has its implemented decision above; the remaining candidates are unimplemented and unverified. Each needs its file/command shape, fields and failure modes written here before code, and fixtures where no account is available.

| Tool | Source in CodexBar | Open question |
| --- | --- | --- |
| JetBrains AI | Local XML and bounded same-IDE log; decision above | Implemented in build 59; real quota comparison remains open |
| Windsurf | `~/Library/Application Support/Windsurf/User/globalStorage/state.vscdb` (SQLite cache) | Key names and how stale the cache gets; web session source not used |
| Amp | `amp usage` CLI | Output format stability, run time; access token and cookie fallbacks not used |
| Kiro | `kiro-cli chat --no-interactive "/usage"` | Up to 20 s per run and leftover empty session files; may be too costly |
| Cline | `cline auth` session in `~/.cline/data/settings/providers.json` (`auth.accessToken`) | Usage endpoint and expiry handling (no token renewal by Monny) |
| Codebuff | Credentials file from `codebuff login`; `POST /api/v1/usage`, `GET /api/user/subscription` | File path and weekly window fields |
| Kilo | `~/.local/share/kilo/auth.json` (`kilo.access`), `app.kilo.ai/api/trpc` | tRPC request shape |
| Augment | `auggie account status` CLI | Output format; cookie fallback not used |
| GitHub Copilot | GitHub CLI saved sign-in → `copilot_internal` API | HTTP 200 verified; implemented decision above |

Excluded: Zed and Muse Code (Keychain items of another app, prompt likely), Antigravity (local server probe), Gemini (below), and every cookie-, API-key- or WebView-based provider.

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

- Opt-in (Settings › AI limits, off by default; each found tool can be unchecked, and an unchecked tool is not read). Off, Monny reads no credentials and makes no requests. On, the only requests go to the services of the shown tools, with the user's own tokens, which never leave memory or go anywhere else. Only quota readings (percentages, reset times, plan names, optional credit counters/unlimited categories) and the reading time are stored (`aiUsage` in UserDefaults, quota history in the existing history file).
- Checks: every 2 minutes while the popover AI tab or the AI usage page is shown, every 5 minutes otherwise (for history and the running-low notification). HTTP 429 waits for `Retry-After`, at least 5 minutes.
- The usage endpoints are undocumented and may change. Decoding ignores unknown fields; a failed decode shows Couldn’t check and keeps the last reading as stale.

## Pace math

The pace mark sits at the share of the window's time left. A window is running low below 10 % left, whatever the pace (user decision 2026-10-22: the previous pace rule flagged ample remaining quota early in a window). The forecast divides the quota used by the elapsed time of the window and reports a run-out time only when it falls before the reset; it is labelled an estimate.
