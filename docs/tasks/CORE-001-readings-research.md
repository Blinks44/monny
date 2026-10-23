# CORE-001: Research reading sources and the shared sampler

- Updated: 2026-10-18
- Stage: done (2026-10-18; user checked the running app)
- Owner: unassigned
- Ownership checked: 2026-10-18; released
- Owned surfaces: `docs/research/`, future `apps/monny/monny/Readings/` and sampler
- Requirements: SPEC §§3–4, §8 (idle cost), ENGINEERING “Readings”; PLAN phase 2
- Code baseline: 8a3a1d2

## Outcome and scope

Choose the source of every metric on Apple silicon macOS 26+ and implement the shared sampler with the public-API readers. Temperatures and fans moved to [CORE-002](CORE-002-temperatures-fans.md); history storage is decided here and built with the phase 3 charts.

## Acceptance

- [x] [research](../research/README.md#readings) lists each metric's source, public/private status, semantics and limits; history storage decided.
- [x] Sampler and readers for public-API metrics, with fixture tests for the math (CPU ticks and wrap, memory formula, rates and counter resets, power-source estimates, `system_profiler` parsing).
- [x] Values compared with `top`, `vm_stat`, `df`, `pmset`, `ps` and System Information on a named Mac ([verification](../verification/readings-public.md)).
- [x] Side-by-side check in the running app (user reported on 2026-10-18 that the current work looks right; no numbers recorded).
- [x] Task, STATE and affected contracts updated.

## Implementation and verification

`apps/monny/monny/Readings/`: `CPUReader` (ticks, P/E from the device tree), `MemoryReader`, `DiskReader` (free space every 30 s, throughput every pass), `NetworkReader` (64-bit counters), `PowerReader` + `BatteryHealthReader`, `ProcessReader` (`rusage_info_v6`, `ri_energy_nj`), `RateCounter`, and `Sampler` (actor `ReadingSource` off the main actor; runs only while the popover or dashboard is visible; the process list only while it is shown). The popover Overview, Battery and Processes tabs and the window KPI row show the readings; temperatures stay "—" until CORE-002, and charts until phase 3.

2026-10-18, M1 Max, macOS 27.0.1: `scripts/dev.sh build` passed with no warnings; `scripts/dev.sh test` passed (10 tests). Offscreen render with live readings in the Russian locale checked layout, units and plural forms. Details and costs in [verification](../verification/readings-public.md).

Decisions while implementing: `ri_billed_energy` gave implausible values, so energy uses `ri_energy_nj` (Rebind ≈ 3 W at a full core). Per-process network has no public source and was removed from the Processes sorts (SPEC updated).

## Open checks / dependency

Later implementation closed the initial missing-history/background-cadence work. Popover/dashboard cost is recorded in [idle-cost evidence](../verification/idle-cost.md). Remaining temperature/fan and history/load checks belong to CORE-002/003.

## Next handoff

No reader-foundation implementation remains. Use [STATE](../STATE.md) for remaining sensor/history verification.
