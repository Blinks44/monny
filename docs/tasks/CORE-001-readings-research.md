# CORE-001: Research reading sources and the shared sampler

- Updated: 2026-10-17
- Stage: planned
- Owner: unassigned
- Ownership checked: 2026-10-17, workflow setup; released
- Owned surfaces: `docs/research/`, future `apps/monny/monny/Readings/` and sampler
- Requirements: SPEC §§3–4, §8 (idle cost), ENGINEERING “Readings”; PLAN phase 2
- Code baseline: workflow setup baseline on `main`

## Outcome and scope

Choose and document, per metric, the API that produces it on Apple silicon macOS 26+: CPU total/P/E/per core, memory used and pressure, swap, disk free and read/write rates, network rates per interface, battery level/health/cycles/capacity/temperature/adapter wattage/time estimates, thermal state, temperatures (CPU die, GPU, SSD, SoC, clusters, battery, palm rest, ambient), fan speed, top processes by CPU/memory/energy/network. Then implement the sampler and readers for the public-API metrics first.

Also decide history storage for the 1m–7d ranges (in-memory ring buffers persisted to a small file, SwiftData, or SQLite) with size and write-frequency estimates.

## Acceptance

- [ ] `docs/research/README.md` lists each metric's source, public/private status, units/semantics, model/OS limits and license of any referenced code.
- [ ] Sampler and readers for public-API metrics implemented with fixture-based tests for the math.
- [ ] Values compared with Activity Monitor/System Information on a named Mac and recorded in verification.
- [ ] Idle CPU cost measured with the popover open and closed.
- [ ] Task, STATE and affected contracts updated before final handoff.

## Implementation and verification

Not started.

## Open checks / dependency

Temperature and fan sources on Apple silicon need hardware checks per chip family; record which Macs were available.

## Next handoff

Engineering: “research Monny's reading sources” can start in parallel with APP-001; they share no files until the sampler is wired into the UI.
