# DES-004: Power draw, process search and quit, more AI tools; Sketch matches the app

- Updated: 2026-10-25
- Stage: ready_for_implementation (design accepted by the user 2026-10-25)
- Owner: unassigned (released 2026-10-25)
- Owned surfaces: Monny.sketch pages `01 · Popover`, `02 · Window`, `03 · Flows & System`
- Requirements: SPEC §3 (Overview, Battery, Processes, AI), §1 non-goals; next release after 1.0.0
- Code baseline: main at 412fd4e; no app code changed

## Outcome and scope

Requested for the next release (user, 2026-10-24):

1. Overview battery strip shows what the Mac uses now (`BatteryReading.systemLoad`) on the right, like the fan reading of the thermal strip. Only Macs with a battery have this source; a desktop Mac keeps the thermal strip unchanged.
2. Popover Battery gets a power panel below the gauge, so the header only says the source. On adapter: total in use (Mac + battery) with the adapter rating, a split bar of the adapter's watts (Mac amber like the window Power card, battery green, rest track) and a legend “Mac 17 W · Battery +12 W” (revised 2026-10-25 at the user's request for a more expressive row). On battery: “10 W from battery” and macOS's time left, no bar. Health, cycles and temperature stay in the facts line.
3. Processes gets a search field above the sort chips. It filters all grouped rows the sampler already reads (app or process name); the list keeps the sort and the rows that fit. Processes of other users and root are not readable and therefore not searchable; the empty result says so.
4. Right click on a process row: Quit and Force Quit…. Apps use `NSRunningApplication.terminate()` / `forceTerminate()`, processes without an app SIGTERM / SIGKILL. Only Force Quit asks for confirmation (user decision 2026-10-24). Monny itself and `loginwindow` must not be offered. This reverses the SPEC non-goal “not a process killer” by user decision.
5. More AI tools, only those that work from the tool's own local sign-in without browser cookies, pasted keys or Keychain prompts (user decision 2026-10-24). Candidates from CodexBar (`steipete/CodexBar`, read at d34fbb4 on 2026-10-24): JetBrains AI (local quota XML/log, no network), Windsurf (local `state.vscdb`), Amp (`amp usage`), Kiro (`kiro-cli … /usage`), Cline (`~/.cline/data/settings/providers.json`), Codebuff (CLI credentials file), Kilo (`~/.local/share/kilo/auth.json`), Augment (`auggie account status`). GitHub Copilot only if the `gh` CLI token reads `copilot_internal`; otherwise it needs a device login and is out. Excluded: Zed and Muse (Keychain prompts), Gemini (unchanged), Antigravity, all cookie/API-key providers. Each source needs a research note in [ai-usage-limits](../research/ai-usage-limits.md) before code; real accounts are unavailable, so verification is fixture-based like Cursor/Grok.

Also requested 2026-10-24: Sketch shows the actual app only; unimplemented ideas are removed and redrawn when they are taken up.

## Sketch source

Saved 2026-10-25, Light and Dark.

- Current app, corrected: popover `01` (no Limit switch in the strip), `02 · Battery` and `05 · Battery · On battery` rebuilt as hero + native limit card, `08`/`09` no-battery copy and fan reading; window `06 · Battery` rebuilt from `BatteryPage` (Level/Health/Cycles/Power, charge level, Charging card, Details), `11` copy; right-click menu shows Check for Updates.
- Removed (absent from the app): popover `03` Processes (ungrouped), `04` Charging, `06` Helper required, `07` Thermal alert; window `08` Settings (helper era), `12` Errors, `13` Update available (Sparkle's window), `14` Uninstall helper; flows `02` Battery helper, `03` Ready (superseded by `13`), `04` Calibration, `10`/`11` Helper. Deferred Discharge/sailing/calibration/trips designs survive only in Sketch version history and the experiments/discharge branch.
- Proposals for this task: popover `16 · Overview · Power draw`, `17 · Battery · Power · Charging`, `18 · Battery · Power · On battery`, `19 · Processes · Search`, `20 · Search results & menu`, `21 · No results`, `22 · Force quit confirmation`, `23 · AI limits · More tools` (letter tiles stand in for the services' marks).

Not drawn: Battery “on adapter, not charging” power row (adapter and Mac use only), Settings tool list with more tools (the existing checkbox list grows), window AI page with more tiles (2-column grid scrolls).

## Open checks / dependency

- Design and Sketch cleanup accepted by the user on 2026-10-25. SPEC §1/§3/§8 updated the same day.
- Before each AI tool: complete its row in [research](../research/ai-usage-limits.md#planned-tools-candidates-not-implemented); Copilot only if `gh auth token` reads `copilot_internal`.
- Six-language copy for the new strings; Russian widths of the power panel and strip (“Мак потребляет”).

## Next handoff

App: implement in this order, each with tests: Overview strip watts, Battery power panel, process search, Quit/Force Quit with confirmation, then AI tools one by one with marks from the same SVG source. Bump the build, run `apps/monny/scripts/dev.sh test` and `release.sh`, hand over the DMG.
