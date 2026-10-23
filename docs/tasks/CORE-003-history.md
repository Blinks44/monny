# CORE-003: History for the 1m–7d ranges

- Updated: 2026-10-19
- Stage: awaiting_verification (user rechecks the charts and hover)
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
- [x] Background cost measured over a few minutes with the popover closed: 0.21 % of one core, 26 MB ([verification](../verification/idle-cost.md)).

## Implementation and verification

- Detail pages (2026-10-18): shared `DashboardComponents` (`CardHeader`, `FactRow`, `ProcessListCard`, `HistoryChart` with hover tooltip and zones, `PeriodBars`). New readings: CPU user/system, load average, GPU utilization and cores, memory composition, pressure %, compression ratio, page-ins and swap-ins, mounted volumes, per-process disk I/O, connection details, fan maximum; history adds load average, GPU, memory pressure, swap and compressed. 88 strings in six languages. Agent screenshots of every page in Russian on the 1m range: values filled, no clipping after fixes (Details rows 30 pt, single per-core column, shorter Russian labels).
- Differences from the Sketch frames, because the data has no public source yet (research table): CPU Frequency shows unavailable; Disk shows used/free instead of the category breakdown (SSD health and S.M.A.R.T. added 2026-10-19, see below); Network has no Connections KPI (Signal instead) and no per-process card (This week spans the row); Sensors shows CPU/GPU/SSD/battery only, without the cluster, SoC, palm rest and ambient tiles.

- Overview (2026-10-18): history gained `cpuPerformance`, `cpuEfficiency` and `charging`; the battery reading gained full charge capacity (`NominalChargeCapacity`, 8 175 mAh on the M1 Max vs 8 694 design). Process enumeration runs while any process list is visible (popover Processes or window Overview). Monotone interpolation and clipped plots keep curves inside the axes (catmull-rom overshot 100 %). 23 new strings in six languages. Agent screenshots of the running app on the 1m range after 20–30 s: all cards filled, Russian labels fit; the 24 h battery chart stays in "Collecting history" for its first hour.

- SSD health (2026-10-19): `SSDHealthReader` reads the NVMe SMART log through Apple's public user client without privileges ([research](../research/README.md), [verification](../verification/ssd-smart.md)). The Disk page follows the Sketch frame: an SSD health KPI (health %, "wear · verified", no sparkline because health has no history) and an SSD health card (S.M.A.R.T. Verified/Failing, wear, data written, temperature). 9 strings in six languages, 3 tests (`SSDHealthTests`). `dev.sh build` and `dev.sh test` (28 tests) pass; agent-observed on M1 Max in Russian: probe and app values agreed; personal wear/lifetime-write values omitted ([comparison](../verification/ssd-smart.md)).

- Cost (2026-10-19, [verification](../verification/idle-cost.md)): background free-space refresh skipped while nothing is visible; charts (`Sparkline`, `HistoryChart`, CPU card) moved to vectorized `LinePlot`/`AreaPlot`; the sampler's default refresh is 2 s as Settings shows (it read 1 s when no rate was saved). Dashboard Overview went from 15–43 % to 5–12 % CPU depending on range. The first version joined all lines of a chart into one path (no series key); fixed with `PlotPoint` series keys. The hover line sat 15–20 pt right of the pointer because the pointer was converted without the y axis offset; it now subtracts the plot frame origin. Agent-observed after both fixes on Overview, CPU, Memory and Network.

- Tests: bucketing average, span trimming, sleep gaps, unavailable values, plist round trip (`HistoryTests`, 5 tests). `dev.sh test`: 21 tests pass.
- Quit via AppleScript after 25 s wrote `History.plist` (622 bytes); `plutil -p` showed the pending 1-minute bucket with sums and counts for all 12 metrics.

## Next handoff

User: recheck the charts and the hover line after the series and hover fixes. Engineering: investigate an observed chart regression if present; later dashboard cost fell to 2.9 % in build 29 ([idle-cost evidence](../verification/idle-cost.md)). Battery controls are already implemented. Independent SMART/controller checks remain in the linked verification record.
