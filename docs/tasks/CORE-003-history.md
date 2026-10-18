# CORE-003: History for the 1m–7d ranges

- Updated: 2026-10-18
- Stage: implementing (open: background cost, SSD health research)
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
- [x] CPU, Memory, Disk, Network and Sensors pages built from the Sketch frames on the same tiers (2026-10-18), with the data Monny can read publicly; see the differences below.
- [x] The user checked the five pages in the running app (2026-10-18).
- [ ] Background cost measured over a few minutes with the popover closed.

## Implementation and verification

- Detail pages (2026-10-18): shared `DashboardComponents` (`CardHeader`, `FactRow`, `ProcessListCard`, `HistoryChart` with hover tooltip and zones, `PeriodBars`). New readings: CPU user/system, load average, GPU utilization and cores, memory composition, pressure %, compression ratio, page-ins and swap-ins, mounted volumes, per-process disk I/O, connection details, fan maximum; history adds load average, GPU, memory pressure, swap and compressed. 88 strings in six languages. Agent screenshots of every page in Russian on the 1m range: values filled, no clipping after fixes (Details rows 30 pt, single per-core column, shorter Russian labels).
- Differences from the Sketch frames, because the data has no public source yet (research table): CPU Frequency shows unavailable; Disk shows SSD temperature instead of SSD health/S.M.A.R.T., used/free instead of the category breakdown, and a Startup disk card instead of SSD health; Network has no Connections KPI (Signal instead) and no per-process card (This week spans the row); Sensors shows CPU/GPU/SSD/battery only, without the cluster, SoC, palm rest and ambient tiles.

- Overview (2026-10-18): history gained `cpuPerformance`, `cpuEfficiency` and `charging`; the battery reading gained full charge capacity (`NominalChargeCapacity`, 8 175 mAh on the M1 Max vs 8 694 design). Process enumeration runs while any process list is visible (popover Processes or window Overview). Monotone interpolation and clipped plots keep curves inside the axes (catmull-rom overshot 100 %). 23 new strings in six languages. Agent screenshots of the running app on the 1m range after 20–30 s: all cards filled, Russian labels fit; the 24 h battery chart stays in "Collecting history" for its first hour.

- Tests: bucketing average, span trimming, sleep gaps, unavailable values, plist round trip (`HistoryTests`, 5 tests). `dev.sh test`: 21 tests pass.
- Quit via AppleScript after 25 s wrote `History.plist` (622 bytes); `plutil -p` showed the pending 1-minute bucket with sums and counts for all 12 metrics.

## Next handoff

Engineering: research NVMe SMART for SSD health and the remaining sensor keys, then measure idle cost; Battery page follows with battery control (phase 4).
