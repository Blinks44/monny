# CORE-003: History for the 1m–7d ranges

- Updated: 2026-10-18
- Stage: implementing (Overview done)
- Owner: unassigned
- Owned surfaces: `Readings/History.swift`, `Readings/Sampler.swift` cadence, `monnyApp.swift` load/save, `Sparkline` component
- Requirements: SPEC §4 (history, "Collecting history"), research [history decision](../research/README.md#history-storage-decision); phase 3
- Code baseline: `main`; store committed after e1b21b1

## Outcome and scope

Readings are kept for the 1m, 1h, 24h and 7d ranges and the 24h/7d tiers survive a restart, so charts can be built on them. First consumer: the network sparkline in the popover Overview card.

## Acceptance

- [x] Four tiers: 1 s buckets over 60 s, 10 s over 1 h, 1 min over 24 h, 10 min over 7 d; averages per bucket, unavailable readings not stored, gaps kept.
- [x] Sampler reads every 10 s while nothing is visible (no process enumeration), at the user's rate while visible.
- [x] 24h/7d saved as a binary plist in `~/Library/Application Support/blinks44.monny/History.plist` every 5 minutes and at quit, loaded off the main actor at launch.
- [x] Popover network sparkline from the 1m tier; fewer than two points draw nothing.
- [x] Window Overview on the tiers: KPI sparklines for the chosen range, CPU load & temperature (P/E areas, dashed temperature, hover tooltip), battery level per hour over 24 h (amber where it charged), battery facts, top processes, sensor tiles and fan; "Collecting history" while a series has fewer than two points.
- [x] The user accepted the window Overview (2026-10-18). Tooltip shows time, load and temperature; the top process per moment is not recorded (processes are read only while a list is visible).
- [ ] CPU, Memory, Disk, Network and Sensors pages from Sketch on the same tiers.
- [ ] Background cost measured over a few minutes with the popover closed.

## Implementation and verification

- Overview (2026-10-18): history gained `cpuPerformance`, `cpuEfficiency` and `charging`; the battery reading gained full charge capacity (`NominalChargeCapacity`, 8 175 mAh on the M1 Max vs 8 694 design). Process enumeration runs while any process list is visible (popover Processes or window Overview). Monotone interpolation and clipped plots keep curves inside the axes (catmull-rom overshot 100 %). 23 new strings in six languages. Agent screenshots of the running app on the 1m range after 20–30 s: all cards filled, Russian labels fit; the 24 h battery chart stays in "Collecting history" for its first hour.

- Tests: bucketing average, span trimming, sleep gaps, unavailable values, plist round trip (`HistoryTests`, 5 tests). `dev.sh test`: 21 tests pass.
- Quit via AppleScript after 25 s wrote `History.plist` (622 bytes); `plutil -p` showed the pending 1-minute bucket with sums and counts for all 12 metrics.

## Next handoff

Engineering: CPU, Memory, Disk, Network and Sensors pages from Sketch on the same tiers, then measure idle cost.
