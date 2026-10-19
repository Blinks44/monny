# APP-004: Window and Settings match the Sketch frames

- Updated: 2026-10-19
- Stage: done
- Owner: unassigned (released 2026-10-19)
- Owned surfaces: `DesignSystem/Components.swift` (switch, checkbox, popup button), `DesignSystem/Theme.swift` (control tokens), `Dashboard/SettingsPage.swift`, `Dashboard/DashboardComponents.swift` (`CardHeader`), `Dashboard/CPUHistoryCard.swift`, `Dashboard/NetworkPage.swift`
- Requirements: [SPEC](../SPEC.md) Settings; [DESIGN](../DESIGN.md); phase 3
- Code baseline: committed on `main` in fd8ba18 (also includes SSD health and cost fixes)

## Outcome and scope

User request: before new features, bring the app to the drawn design. Settings used native macOS 26 switches, popup buttons and checkboxes that differ from the Sketch symbols, and rows with two-line text touched the separators. Every window page was compared with its Sketch frame.

## Implementation and verification

- New shared controls drawn from the Sketch symbols: `SwitchStyle` (`Toggle/On|Off`, 40 × 22), `CheckboxStyle` (`Checkbox/On|Off`, 18 pt) and `PopupPicker` (`Popup Button`, 28 pt raised capsule with a chevron, opening the system menu). Their colors are Theme tokens (`control*`, `toggleOffTrack`, `checkboxStroke`) taken from the symbol fills, which have no Color Variables. VoiceOver still sees a switch, checkbox and menu button.
- Fixes after the user's review (2026-10-19): the popup menus showed only a checkmark because the row's custom toggle style reached the menu items (inline picker items are toggles), so `PopupPicker` resets the toggle style inside its menu; popup and checkbox borders lost their top or left edge at 0.5 pt, so they are drawn 1 pt at half the opacity in an overlay. Agent-observed: the Language menu lists all seven options; borders are continuous.
- Settings: rows get 8 pt vertical padding so wrapped titles and subtitles keep clear of separators; section gap 28 pt as drawn; the shortcut recorder is held at the library's 130 pt minimum.
- `CardHeader` now puts the legend or chip on the title line and lets the subtitle span the card, as in every Sketch card; the CPU chart card uses it, so long localized summaries no longer squeeze under the legend. The Network connection card lists its rows from the top instead of pinning them to the bottom.
- 2026-10-19, M1 Max, macOS 27.0.1, Russian UI: `dev.sh build` and `dev.sh test` (25 tests) pass. Agent-observed in the running app: Overview, CPU, Memory, Disk, Network, Sensors and Settings in Light, Settings in Dark; switch and checkbox toggle through the accessibility action.

Known differences that are not visual bugs: data without a public source stays out (Disk categories, Network connections and per-process network, extra sensor tiles, CPU frequency; see [CORE-003](CORE-003-history.md), which also owns the subsequently added SSD health); Battery controls and helper rows wait for phase 4 ([BAT-001](BAT-001-battery-foundations.md) adds the read-only Battery window); Sketch's Privacy "Read policy" link has no policy page to open yet, so the row has no button; in Russian the "Global shortcut" title wraps beside the 130 pt recorder. The popover was not re-captured (the panel is not reachable by the screenshot tool); it was accepted in [APP-002](APP-002-popover-design-parity.md) and uses none of the changed components.

## Result

- 2026-10-19: the user reviewed the app and accepted it ("all good"). Remaining visual differences are the data and phase 4 gaps listed above.
