# APP-010: Readings in the menu bar

- Updated: 2026-10-21
- Stage: awaiting_verification
- Owner: unassigned (released 2026-10-21)
- Owned surfaces: `App/MenuBarController.swift` (readings, badge anchor), `Readings/Sampler.swift` (`updatesMenuBar`), Settings › Menu bar row, `PreferenceKey.menuBar*`, `shortTemperatureText`
- Requirements: [SPEC](../SPEC.md#2-menu-bar-presence) §2, §7 Menu bar; [PLAN](../PLAN.md#next-features) item 2
- Code baseline: main at 037d588 plus uncommitted APP-009 and this task; build 31

## Outcome and scope

Settings › Menu bar has “Show in menu bar” with CPU load, Temperature and Battery level checkboxes (all off; Battery level only on a Mac with a battery), as in Sketch frame `17`. Each enabled value follows the icon with its SF Symbol, as in frame `05` “With readings”: CPU % (`cpu`), CPU temperature without the unit letter in the chosen unit (`thermometer.medium`), battery level with a quarter-step battery symbol (bolt while charging). An unreadable value shows “—”. The status item is square again when all are off.

While any reading is on, the shared sampler keeps the user's refresh rate in the background but skips the visible-only work (processes, free space, health reads).

## Implementation and verification

- Agent-observed on the M1 Max, macOS 27.0.1, light menu bar, Russian locale, Debug build: all three readings render as template-tinted symbols and monospaced digits next to the icon (`37 %`, `61°`, `80 %`).
- Idle cost with all three on: about 1.6 % CPU at 2 s ([verification](../verification/idle-cost.md#2026-10-21-build-31-menu-bar-readings)).
- `dev.sh test`: 38 tests in 9 suites pass (new short temperature test). Signed `Monny-1.0-31.dmg` built.

## Open checks / dependency

- User: dark menu bar and wallpaper tinting, popover position under the wider item, the attention badge position with readings on, German/French Settings row width, crowded menu bar behavior.
- The 1.6 % background cost is acceptable for now but unprofiled; profile the pass if it matters for the release gate.

## Next handoff

Engineering: sustained app load notification (PLAN item 3).
