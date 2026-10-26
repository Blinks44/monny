# CORE-002: Temperatures and fans

- Updated: 2026-10-26
- Stage: done (accepted by the user within available-device coverage, 2026-10-26)
- Owner: unassigned
- Owned surfaces: `apps/monny/monny/Readings/SMC.swift`, `SensorReader.swift`, `docs/research/`
- Requirements: SPEC §3 (CPU temperature chip, thermal alert), §4 Sensors page, §5 heat protection; PLAN phase 2
- Code baseline: commit "feat: read temperatures and fans from the SMC"

## Outcome and scope

Read CPU, GPU, SSD and battery temperatures and fan speeds on Apple silicon behind one small adapter, show missing sensors as unavailable and use the readings in the screens that already exist. The Sensors page (all tiles, peaks, chart) is built with the phase 3 screens.

## Acceptance

- [x] Research records the source, private status, chip-family differences and the reference license ([research](../research/README.md#temperatures-and-fans-smc)).
- [x] Adapter with fixture tests for decoding (`flt `, `sp78`, `fpe2`, integers), chip generation and sensor averaging.
- [x] User accepts available-device monitoring (2026-10-26); prior evidence: values checked on M1 Max: CPU tracks load, fans read 0 rpm while stopped ([verification](../verification/sensors-smc.md)). Independent reference, spinning-fan and fanless coverage were not separately documented.
- [x] User accepts current UI (2026-10-26); implementation: popover CPU temperature chip (amber/red by macOS thermal state), Battery tab "health · cycles · temperature", window Temperature KPI with GPU, no-battery strip with fan speed or "No fan". The Sensors page is implemented; the original 2026-10-18 session lacked Sketch access. Current UI acceptance is user-reported, not a new agent visual comparison.

## Implementation and verification

`SMCConnection` opens the `AppleSMC` user client (no privileges) and reads keys with cached key info. `SensorReader` averages the per-generation CPU/GPU key lists, reads `TH0x`, `TB0T`–`TB2T` and `F<n>Ac`, ignoring readings outside 1–150 °C. Unknown chip generations show CPU/GPU as unavailable. `Snapshot.sensors` is `nil` when the SMC cannot be opened. Shared `temperatureText(_:)` formats in the Settings unit; this also fixed Settings, which showed °C for Fahrenheit in locales whose weather unit is Celsius.

2026-10-18, M1 Max, macOS 27.0.1: `scripts/dev.sh build` passed with no warnings; `scripts/dev.sh test` passed (16 tests). Hardware check and render in [verification](../verification/sensors-smc.md).

## Current acceptance — 2026-10-26

The user accepted monitoring/sensors/history as a whole after completing the checks available to them. Close this task for the current installed app (latest recorded release 1.1.0 build 63; version/model/OS not restated). This is user-reported acceptance, not a new agent measurement or independent hardware comparison. Previously untested chip families, fanless/spinning-fan cases and independent source checks remain coverage limitations, not pending tasks requiring more of this user's time. Reopen only for a concrete regression or newly available hardware.
