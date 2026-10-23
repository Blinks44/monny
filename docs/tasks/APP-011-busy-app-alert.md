# APP-011: Sustained app load notification

- Updated: 2026-10-21
- Stage: done
- Owner: unassigned (released 2026-10-21)
- Owned surfaces: busy app rule in `App/Alerts.swift`, background process gate in `Readings/Sampler.swift`, Notifications row in `Dashboard/SettingsPage.swift`
- Requirements: [SPEC](../SPEC.md#7-settings) §7 Notifications; [PLAN](../PLAN.md#next-features); copy from Sketch `05 · System · Menu bar & notifications` and `17 · Window · Settings · Native`
- Code baseline: main at 037d588 plus uncommitted APP-009/APP-010 and focus changes; build 33

## Outcome and scope

“An app keeps the Mac busy” in Settings › Notifications, off by default like the other non-safety alerts. One app, its helpers summed as in the popover (responsible PID), above 80 % of one core for 5 minutes posts “<App> is keeping your Mac busy” / “Over 80% CPU for the last 5 minutes. Quit it if you don’t need it.” Once per episode per app; dropping below the threshold ends the episode and restarts the 5 minutes. Each app has its own notification identifier. Read-only: Monny never quits the app.

Thresholds chosen by the agent under the user's go-ahead (2026-10-21), as proposed in SPEC.

## Implementation and verification

- Processes are read in the background only while the alert is on and the whole CPU does at least 0.8 of a core of work (total load × logical CPUs), since below that no app can pass the threshold. Otherwise background passes stay as before.
- Test `busyAppFiresAfterFiveMinutesOncePerEpisode` (helpers summed, 5 min, re-arm); 39 tests in 9 suites pass. Signed `Monny-1.0-33.dmg` built.
- Agent-observed on the M1 Max, macOS 27.0.1, Debug build with a temporary 30 s duration and debug output (both removed): a `yes` process started from PhpStorm's terminal was summed into PhpStorm, and the alert was posted once for PhpStorm after 30 s. Background cost with the alert on was 0.2–0.5 % CPU at the 10 s cadence ([verification](../verification/idle-cost.md#2026-10-21-build-33-busy-app-alert)).

## Open checks / dependency

Build-37 delivery/copy acceptance is recorded below; the earlier delivery request is closed. Long developer builds can trigger the alert as designed; it remains off by default.

## User acceptance — 2026-10-21

User, build 37: the busy app banner arrives and its copy is accepted.

## Next handoff

None.
