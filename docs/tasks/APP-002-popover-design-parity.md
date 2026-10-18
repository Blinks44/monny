# APP-002: Popover and window chrome match the Sketch frames

- Updated: 2026-10-18
- Stage: done
- Owner: unassigned
- Owned surfaces: `App/MenuBarPanel.swift`, `App/MenuBarController.swift`, `DesignSystem/` (RingGauge, SegmentedControl, PanelBackground, tokens), `Popover/`, window time-range control
- Requirements: SPEC §3 (popover), DESIGN; phase 3
- Code baseline: `main`, committed in e1b21b1

## Outcome and scope

After the user's review of the running app: the popover had a system arrow, the rings were smaller than drawn so the percent nearly touched them, the tabs were the system segmented control, and Processes did not follow its frame. Compared against `01 · Popover` frames 01–03 (Light/Dark) through Sketch MCP on 2026-10-18.

## Acceptance

- [x] No arrow: a borderless rounded glass panel (radius 26) under the status item, closed by a click outside, Escape or the status item.
- [x] Rings as drawn: 9 pt stroke centred on a 68 pt circle, value 19 bold, unit 9 medium.
- [x] Section tabs and the window time range: recessed capsule track with a raised selected pill; sort chips as separate capsules with a dark selected one. Both expose a standard segmented picker to VoiceOver.
- [x] Processes: 30 pt icons, name with memory · threads (CPU when sorted by memory), value with a bar relative to the top row, nine rows, Activity Monitor link in the footer. No Network sort (no public source, SPEC §3).
- [x] The user checked the popover in the running app (2026-10-18): look, fade, outside click and the second icon click work.
- [x] Window chrome (2026-10-18, after the user saw the sidebar blend into the window): the window is translucent glass (`Window glass`: behind-window blur under a #FBFBFD 90 % → #F5F5F7 85 % gradient), the sidebar a lighter panel (`Sidebar glass`: white 70 % → 55 %, white hairline, 0/4/14 8 % shadow), the selection a white 12 pt pill with a 0/2/8 12 % shadow, the section label tertiary. Dark values come from the Dark frames.
- [x] The user checked the window in the running app (2026-10-18).

## Implementation and verification

- `NSPopover` always draws an arrow, so the content moved to `MenuBarPanel` (`NSPanel`, borderless, non-activating, `NSVisualEffectView` `.popover` behind window plus the Sketch panel gradient and hairline). Global and local mouse monitors close it like a transient popover.
- New strings `%lld threads` (plural, six languages) and `Activity Monitor %@`; the unused "Open Activity Monitor" and "Energy is an estimate" were removed; energy values carry "≈".
- `dev.sh build` and `test` (21 tests) pass. Offscreen `ImageRenderer` renders of all three tabs in Light/Dark were compared with the frames.
- The first build opened a zero-size, invisible panel: `NSHostingView.sizingOptions = [.preferredContentSize]` dropped the intrinsic size, so `fittingSize` was zero. Fixed by keeping the default sizing options. Then the panel was opened in the running app through the window's "Show in the menu bar" button: 360 × 637 pt under the status item, no arrow, glass and content as drawn (agent screenshot, Light). Opening from the status item itself and closing by an outside click were not agent-tested (no Accessibility permission for clicks in the menu bar).
- Second user review: dark rim and square material corners, no close on a second icon click, no fade. Fixes: the system window shadow is off and `PanelChrome` draws the Sketch hairline and both shadows (Light 18/8 %, Dark 44/24 %) outside the shape in a transparent margin; the blur is an `NSVisualEffectView` with a continuous-corner `maskImage` (a layer corner radius left the corners square); the outside-click monitor ignores clicks on the status item by its screen rectangle, so its action toggles; the panel fades in (0.12 s) and out (0.2 s) like a menu. Agent screenshot after the fix: clean corners, white hairline, no rim (Light). The user confirmed the look and fade; the second icon click still did not close the panel: the status item's mouse-down reached the global monitor, which closed the panel, and the mouse-up reopened it. Both monitors now ignore clicks on the status item by position; the user confirmed the toggle.

Sketch sync (2026-10-18, saved): `Surface/Sidebar Start` and `End` now hold the frame values (Light white 70 %/55 %, Dark #3A3A3E/#2A2A2E 70 %), and new variables `Surface/Window Top`, `Window Bottom` and `Sidebar Selection` (Light/Dark) were added, 94 in total. All 100 `Window glass`, `Sidebar glass` and `Selection` layers on pages 02 and 03 are linked to them, borders to `Surface/Card Stroke`; the Calibration Light sidebar, which still had the old grey, now matches. Screenshots of Overview Dark and Calibration Light checked.

## Next handoff

None.
