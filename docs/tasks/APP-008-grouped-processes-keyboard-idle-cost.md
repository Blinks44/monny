# APP-008: Processes grouped by app, keyboard navigation and idle cost

- Updated: 2026-10-21
- Stage: done
- Owner: unassigned (released 2026-10-21)
- Owned surfaces: `Readings/ProcessReader.swift`, `Popover/ProcessesTab.swift`, `Readings/History.swift`, `Dashboard/Sidebar.swift`, `DesignSystem/Components.swift` (SegmentedControl), `Popover/PopoverView.swift`, `Dashboard/CPUHistoryCard.swift`
- Requirements: [SPEC](../SPEC.md) §3 Processes, §8 keyboard navigation and idle cost; [PLAN](../PLAN.md#next-features) and release gates
- Code baseline: main at fb2080e plus uncommitted changes; build 29

## Outcome and scope

1. Popover Processes shows one row per app (Sketch `10 · Popover · Processes · Grouped by app`): helpers, web content and tools an app launched are summed into it, with “N processes”; processes that belong to no app say “system”. The thread count line was dropped, as in the frame. Dashboard process lists stay per process.
2. Keyboard: the popover tabs, the sort chips, the dashboard time range and the sidebar are each one keyboard stop that the arrow keys move along, and they take focus even with Keyboard navigation off in System Settings (as text fields and lists do). The popover opens with the tabs focused; the window opens with the sidebar focused. Their ring or outline shows only after a key press and hides after a click (`DesignSystem/FocusVisibility.swift`, build 32), because the user saw a permanent ring on build 31. Buttons, cards and switches follow the system setting: with Keyboard navigation on, Tab reaches them and Space activates them.
3. Idle cost measured for background and dashboard and reduced ([verification](../verification/idle-cost.md#2026-10-21-build-29)).

## Implementation and verification

- Grouping: owner = the responsible process (`responsibility_get_pid_responsible_for_pid`, looked up with `dlsym`, falls back to the process itself) when its executable is inside an `.app`; looked up once per PID ([research](../research/README.md#readings)). `ProcessUsage.groupedByApp` sums CPU, memory, energy and disk.
- Cost: history tiers notify views only when a bucket closes; the CPU chart no longer animates every new point. Dashboard Overview at 2 s went from 6.7 % to 2.9 % CPU; background 0.0–0.2 %.
- Agent-observed on the M1 Max, macOS 27.0.1, Debug build through Accessibility: grouping showed PhpStorm as one row of 37 processes and Mail with its WebKit processes (10); ←/→ switched popover tabs and sort, Tab moved between them, ↑/↓ changed the dashboard page, Tab reached the time range and ←/→ changed it.
- Tests: 37 tests in 9 suites pass (new `ProcessGroupingTests`, history publishing test). Signed `Monny-1.0-29.dmg` built.
- Build 32, agent-observed in the dashboard: no sidebar outline on open, outline after an arrow key, none after a click. Popover tabs use the same flag but were not checked live.

## Open checks / dependency

Build-37 keyboard focus/navigation, accessibility and popover-cost acceptance is recorded below. Earlier build-32 review requests are closed by that acceptance; no feature handoff remains.

## User acceptance — 2026-10-21

User, build 37: focus rings appear only with the keyboard; keyboard navigation, VoiceOver, Increase Contrast and Reduce Motion pass; open popover costs about 2 % CPU.

## Next handoff

None.
