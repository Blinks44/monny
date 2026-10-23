# APP-010: Readings in the menu bar

- Updated: 2026-10-21
- Stage: done
- Owner: unassigned (released 2026-10-21)
- Owned surfaces: `App/MenuBarController.swift` (readings, badge anchor), `Readings/Sampler.swift` (`updatesMenuBar`), Settings › Menu bar row, `PreferenceKey.menuBar*`, `shortTemperatureText`
- Requirements: [SPEC](../SPEC.md#2-menu-bar-presence) §2, §7 Menu bar; [PLAN](../PLAN.md#next-features)
- Code baseline: main at 037d588 plus uncommitted APP-009 and this task; build 31

## Outcome and scope

Settings › Menu bar has “Show in menu bar” with CPU load, Temperature and Battery level checkboxes (all off; Battery level only on a Mac with a battery), as in Sketch frame `17`. Each enabled value follows the icon with its SF Symbol, as in frame `05` “With readings”: CPU % (`cpu`), CPU temperature without the unit letter in the chosen unit (`thermometer.medium`), battery level with a quarter-step battery symbol (bolt while charging). An unreadable value shows “—”. The status item is square again when all are off.

While any reading is on, the shared sampler keeps the user's refresh rate in the background but skips the visible-only work (processes, free space, health reads).

## Implementation and verification

- Agent-observed on the M1 Max, macOS 27.0.1, light menu bar, Russian locale, Debug build: all three readings render as template-tinted symbols and monospaced digits next to the icon (`37 %`, `61°`, `80 %`).
- Idle cost with all three on: about 1.6 % CPU at 2 s ([verification](../verification/idle-cost.md#2026-10-21-build-31-menu-bar-readings)).
- `dev.sh test`: 38 tests in 9 suites pass (new short temperature test). Signed `Monny-1.0-31.dmg` built.

## Open checks / dependency

Build-37 readings, popover position and badge were user-accepted below. German/French Settings width and crowded-menu-bar review remain with [DES-002](DES-002-native-onboarding-next-features.md). Wallpaper tint/dark-menu-bar appearance was not separately recorded. Background cost is measured (~1.6%) but not profiled; profile only for an observed issue.

## User acceptance — 2026-10-21

User, build 37: readings in the menu bar, popover position and badge accepted.

## Next handoff

None.
