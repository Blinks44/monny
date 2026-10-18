# APP-001: App foundations (menu bar, popover and dashboard shell)

- Updated: 2026-10-18
- Stage: done (2026-10-18; keyboard and VoiceOver review moves to the PLAN accessibility gate)
- Owner: unassigned
- Ownership checked: 2026-10-18; released after the shell pass
- Owned surfaces: `apps/monny/monny/` app entry, scenes, design tokens, shared components, String Catalogs
- Requirements: SPEC §§2–4, §7 (structure only), §8; PLAN phase 1
- Code baseline: committed on `main` after 13d99da

## Outcome and scope

Replace the Xcode template with the Monny shell: status item, popover with Overview/Battery/Processes, dashboard window with sidebar pages and Settings, design tokens and shared components. Out of scope: real readings (CORE-001), history storage, battery helper, onboarding, global shortcut.

## Decisions

- **`NSStatusItem` + `NSPopover`, not `MenuBarExtra`.** `MenuBarExtra` offers either a menu or a window, not both, and cannot draw the colored attention badge on a template icon. A left click toggles the popover; a right click or Control-click opens the menu (`NSMenu.popUp`). The badge is a 7 pt subview, so the icon stays a template image.
- **Dock icon only while the dashboard is open** (accessory app otherwise), as in Rebind. Confirmed by the user 2026-10-18 (SPEC §2).
- **Tokens are a Swift type, not asset colors.** [Theme.swift](../../apps/monny/monny/DesignSystem/Theme.swift) is generated from all 88 Sketch Color Variables (44 Light/Dark pairs, same names in camelCase), plus the 12 text styles, spacing and radii. This matches Rebind and keeps one reviewable file.
- **No invented values.** Until the sampler exists, every reading shows "—" (`UnavailableValue`) and the charts show the first-launch state. Real static facts are shown: chip, P/E core counts, memory size, macOS version, uptime, battery presence (IOKit power sources).
- Controls that need later phases are visible but disabled: Install Battery Helper…, Check for Updates, the battery menu items. The global shortcut is shown as text only. Launch at login is wired to `SMAppService.mainApp`. Preferences are stored with `@AppStorage`.

## Acceptance

- [x] Status item with idle/open/attention states and the right-click menu items from SPEC §2 (battery items disabled; hidden without a battery). *Built; clicks and menu placement not observed yet.*
- [x] Popover with header, tabs and footer matching Sketch `01 · Popover` structure in Light and Dark (offscreen render checked).
- [x] Dashboard window with sidebar, page header, time-range control and collapse button; Settings page sections present (offscreen render checked).
- [x] Tokens for all Sketch color variables and text styles; shared card, chip, banner, icon button, ring, capsule bar and button styles.
- [x] String Catalog entries for all 88 shell strings in six languages.
- [ ] Keyboard focus and VoiceOver labels checked in the running app. Moved to the PLAN accessibility release gate; labels are set in code.
- [x] Runtime check (user-reported 2026-10-18, works): left/right click on the status item, popover highlight, Open Dashboard from the menu and the popover, collapse back to the popover, Dock icon appearing and leaving, appearance setting, Launch at login.
- [x] Task, STATE and affected contracts updated.

## Sketch source

Monny.sketch pages `01 · Popover`, `02 · Window`, `03 · Flows & System` and `04 · Foundations`, inspected live 2026-10-18.

## Implementation and verification

Files: `apps/monny/monny/` `monnyApp.swift` (app, delegate, Dock policy, appearance), `App/` (model, menu bar controller, preferences, system facts, login item), `DesignSystem/` (Theme, components), `Popover/`, `Dashboard/`, `Localizable.xcstrings`, `MonnyMenuBar.imageset` (16×14 template). The template `ContentView.swift` was removed.

2026-10-18, Xcode 27.1, macOS 27.0.1, Apple M1 Max: `scripts/dev.sh build` passed with no warnings. `scripts/dev.sh test` passed: 3 tests (bundle identity, sidebar order, uptime text). The popover tabs and the Overview/CPU/Settings pages were rendered offscreen in Light and Dark in a temporary test (deleted afterwards) under the Russian system locale; layout matches the Sketch structure. `scripts/dev.sh run` launches Monny as an accessory app. Screen control was declined, so the agent saw no clicks, menus or the Dock. The user then reported that the status item, popover, menu and dashboard work.

## Open checks / dependency

- Global shortcut ⌥⌘M needs a library decision (for example KeyboardShortcuts) recorded in research.
- The Release build should target arm64 only (Apple silicon only); this is a release-task change.

## Review

Self-review against the acceptance list above. Sketch details deferred to phase 3 because they need real data: sparklines, charts, core bars, mode tiles, charge slider and the process list.

## Next handoff

Engineering: CORE-001 reading sources and the sampler, then phase 3 screens on real readings.
