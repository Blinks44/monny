# DES-002: Native onboarding and next-feature screens

- Updated: 2026-10-21
- Stage: done (design saved; all its features implemented through build 35; Settings › About update switch still undrawn)
- Owner: unassigned (design pass released 2026-10-21)
- Owned surfaces: Monny.sketch pages `01 · Popover`, `02 · Window`, `03 · Flows & System` (frames listed below)
- Requirements: [SPEC](../SPEC.md) §2, §3, §4, §6, §7; [PLAN](../PLAN.md#next-features) items 1–3 and 5, onboarding release gate
- Code baseline: main at 28b5a04; no code changed by this task

## Outcome and scope

Draw the screens needed to implement native-only onboarding and the user-chosen next features (2026-10-21): processes grouped by app, optional menu bar readings, the sustained app load notification and current power draw. Discharge research has no design yet. Helper-era frames stay in Sketch for the experiments branch.

## Sketch source

Monny.sketch, saved 2026-10-21. Light and Dark for every frame:

- `01 · Onboarding · Welcome`: the Charge limit item now describes the native 80–100% limit (no draining); item spacing evened.
- `12 · Onboarding · Charge limit` (new, step 2, replaces the helper step for main): what the native limit does, that macOS keeps it after quit/restart, where to change it. Buttons Not Now / Use 80% Limit (an explicit user gesture that enables the limit at 80%).
- `03 · Onboarding · Ready` and `08 · … · No battery`: login hint no longer ties launch at login to the charge limit. 2026-10-21: the login row became a two-row card with “Check for updates automatically” (on; “Monny asks before installing a new version”) for Sparkle; header and menu bar mock moved up to fit.
- `10 · Popover · Processes · Grouped by app` (new): one row per app with summed values and “N processes”; system processes stay single rows. Sort pills are CPU / Memory / Energy (Network removed, as SPEC says).
- `05 · System · Menu bar & notifications`: new “With readings” status item (Monny glyph, then CPU %, temperature and battery level with SF Symbols); note that readings are off by default. Right-click menu now matches the app (Turn Off Charge Limit, Set Limit to 100%). New “Xcode is keeping your Mac busy” notification replaces Calibration complete; the heat notification no longer mentions paused charging.
- `17 · Window · Settings · Native` (new, current Settings for main): Battery uses the native switch and 80–100 slider; Menu bar adds “Show in menu bar” with CPU load / Temperature / Battery level checkboxes, all off; Notifications add “An app keeps the Mac busy”; About has no policy link.
- `18 · Battery · Power card` (new): the Battery page Power KPI shows what the Mac uses now in three states (on adapter, charging with watts going into the battery, on battery with macOS's time estimate). No sparkline until power history exists.
- `16 · Battery · Native limit control`: copy aligned with the app (“Use charge limit”, persistence note).

## Implementation and verification

Design only. Each new or changed frame was checked by MCP screenshot in Light and Dark after its last edit. Copy is English; the other five languages are checked in the app. New layers reuse existing symbols and duplicated styled layers.

## Open checks / dependency

- Sustained-load alert implemented with 80 % of one core for 5 minutes ([APP-011](APP-011-busy-app-alert.md)).
- Power card implemented with shorter copy (no “Mac uses ·”, fits the minimum window width); on-battery values are compared against the battery's own output ([APP-013](APP-013-power-draw.md)).
- Settings › About in frame `17` still lacks the “Check for updates automatically” row; build 34 adds it as an ordinary switch row with the onboarding copy. The old custom “update available” Settings state is replaced by Sparkle's standard window.
- The menu bar label width in German/French and the readings layout on a crowded menu bar are checked in the app.

## Next handoff

Engineering: onboarding is implemented ([APP-009](APP-009-native-onboarding.md)); implement the remaining PLAN next-feature items using the frames above. Read them live through Sketch MCP.
