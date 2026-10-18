# CORE-002: Temperatures and fans

- Updated: 2026-10-18
- Stage: planned
- Owner: unassigned
- Owned surfaces: future `apps/monny/monny/Readings/` sensor adapter, `docs/research/`
- Requirements: SPEC §3 (CPU temperature chip, thermal alert), §4 Sensors page, §5 heat protection; PLAN phase 2
- Code baseline: `main` after the CORE-001 readers

## Outcome and scope

Read CPU die, GPU, SSD, SoC/cluster, battery, palm rest and ambient temperatures and fan speed on Apple silicon, behind one small adapter, and show missing sensors as unavailable. Battery temperature is no longer in `AppleSmartBattery` on macOS 27 ([research](../research/README.md#readings)), so it needs the SMC (`TB0T`-style keys) or HID sensors too.

## Acceptance

- [ ] Research records the source per sensor (SMC keys through the `AppleSMC` user client, HID temperature services), private/public status, chip-family differences and license of any reference (exelban/stats is MIT; GPL tools are reference only).
- [ ] Adapter with fixture tests for decoding (SMC data types such as `flt `, `sp78`, `fpe2`).
- [ ] Values compared with a reference on a named Mac; a fanless Mac shows "No fan".
- [ ] Sensors page, temperature KPI and the CPU temperature chip use the readings.

## Next handoff

Engineering: research the SMC/HID sources on the M1 Max available here, then implement the adapter.
