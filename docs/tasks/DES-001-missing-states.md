# DES-001: Missing design states

- Updated: 2026-10-18
- Stage: done (saved design; current native implementation is in main)
- Owner: unassigned (design pass released 2026-10-18)
- Owned surfaces: Monny.sketch pages `01 · Popover`, `02 · Window`, `03 · Flows & System` (new frames, Settings rows, Welcome spacing, app icon), the `…/Banner/…` symbol sources; `apps/monny/monny/AppIcon.icon`, `docs/images/app-icon.png`, README
- Requirements: [SPEC](../SPEC.md) §3, §4, §6, §7, §8 (unavailable values); phases 3–5 in [PLAN](../PLAN.md)
- Code baseline: committed on `main` after 6271702 (`AppIcon.icon` added, empty `AppIcon.appiconset` removed)

## Outcome and scope

Draw every state SPEC needs so implementation does not have to invent them: first-launch history, unavailable sensors, a Mac without a battery, Settings errors, update available, helper uninstall confirmation and onboarding without the helper step. Also apply the user's 2026-10-18 decisions: the popover opens on click only, Intel is out of scope, the icon has no baseline. Each state has a Light and a Dark frame, built from the existing screens with the same geometry, cards, symbols and color variables.

## Sketch source

Monny.sketch, saved 2026-10-18. New frames (Light on the top row, Dark below):

- `08 · Popover · Overview · No battery`: Mac mini. No menu bar battery glyph. A thermal-state strip (state, fan speed) replaces the battery strip. All three tabs stay.
- `09 · Popover · Battery · No battery`: the Battery tab shows the same empty state and copy as the window, with Open Sensors.
- `09 · Window · Overview · First launch`: live KPI values. Sparklines become a "Collecting history…" track with a short "collected so far" segment. The CPU chart keeps its grid and shows a "Collecting history" empty state. The battery 24 h chart shows only the current bar.
- `10 · Window · Sensors · Unavailable sensors`: fanless MacBook Air. SSD, Palm rest and Ambient show "—" with "Unavailable" and no gauge. SSD is removed from the chart legend. Fan reads "None" with a passive-cooling note.
- `11 · Window · Battery · No battery`: Mac mini. One empty-state card with an Open Sensors button (`Button/Secondary`).
- `12 · Window · Settings · Errors`: the helper chip is `Chip/Danger` "Not installed". A `Banner/Danger` says the helper wasn't installed (approve it in Login Items & Extensions), with Open System Settings… and Try Again. The update row reads "Couldn't check for updates · offline" with Try Again.
- `13 · Window · Settings · Update available`: "Monny 1.1 is available", "You have 1.0 (42)", Download… (opens the GitHub release page).
- `14 · Window · Settings · Uninstall helper`: alert sheet "Uninstall the battery helper?" explaining that charging goes back to macOS, with Cancel / Uninstall.
- `07 · Onboarding · Welcome · No battery` and `08 · Onboarding · Ready · No battery`: two steps. "Sensors and history" replaces "Charge limit", and the login hint no longer mentions the charge limit.

Changes to existing frames: the "Open popover with" row is removed from every Settings frame. The Welcome items now have even spacing. The app icon has lost its baseline, with the bars re-centred.

Symbol change: the six `Light|Dark/Banner/*` sources now pin Bg/Title/Body left and right and Icon/Icon tile left, so a banner can stretch to a 382 pt Settings column. Existing 328 pt popover banners render unchanged.

## Implementation and verification

Sketch saved 2026-10-18. The app icon is wired as `AppIcon.icon` (the empty `AppIcon.appiconset` was removed). `scripts/dev.sh build` passed and the bundle contains `AppIcon.icns`. Every new frame was checked by MCP screenshot in Light and Dark after its last edit, and the popover helper-required banner was rechecked after the symbol change. New shapes bind fills to color variables. Text colors use the variable hex values, as the existing screens do. Copy is English only. The other five languages are checked in the app.

## Open checks / dependency

- Settled 2026-10-18: on a Mac without a battery, Battery stays in both the sidebar and the popover and shows an empty state.
- The app icon is verified only as an `ictool` render and as the built `AppIcon.icns`. The Dock and Finder appearance on macOS 26 still needs checking when the app runs.

## Next handoff

App shell and native monitoring states are implemented; helper-era frames remain deferred with the experiment. No shell implementation request remains. Inspect Dock/Finder icon appearance on macOS 26 during the next platform review; the original record only verified exported/built icon artifacts.
