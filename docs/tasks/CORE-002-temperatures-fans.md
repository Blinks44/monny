# CORE-002: Temperatures and fans

- Updated: 2026-10-18
- Stage: awaiting_verification (adapter built and checked on M1 Max; independent reference, spinning fan and fanless Mac open)
- Owner: unassigned
- Owned surfaces: `apps/monny/monny/Readings/SMC.swift`, `SensorReader.swift`, `docs/research/`
- Requirements: SPEC §3 (CPU temperature chip, thermal alert), §4 Sensors page, §5 heat protection; PLAN phase 2
- Code baseline: commit "feat: read temperatures and fans from the SMC"

## Outcome and scope

Read CPU, GPU, SSD and battery temperatures and fan speeds on Apple silicon behind one small adapter, show missing sensors as unavailable and use the readings in the screens that already exist. The Sensors page (all tiles, peaks, chart) is built with the phase 3 screens.

## Acceptance

- [x] Research records the source, private status, chip-family differences and the reference license ([research](../research/README.md#temperatures-and-fans-smc)).
- [x] Adapter with fixture tests for decoding (`flt `, `sp78`, `fpe2`, integers), chip generation and sensor averaging.
- [ ] Values checked on M1 Max: CPU tracks load, fans read 0 rpm while stopped ([verification](../verification/sensors-smc.md)). Open: an independent reference tool, a spinning fan, a fanless Mac showing "No fan".
- [ ] Popover CPU temperature chip (amber/red by macOS thermal state), Battery tab "health · cycles · temperature", window Temperature KPI with GPU, no-battery strip with fan speed or "No fan". Sensors page: phase 3. Visual check against Sketch open (Sketch MCP was not available in this session).

## Implementation and verification

`SMCConnection` opens the `AppleSMC` user client (no privileges) and reads keys with cached key info. `SensorReader` averages the per-generation CPU/GPU key lists, reads `TH0x`, `TB0T`–`TB2T` and `F<n>Ac`, ignoring readings outside 1–150 °C. Unknown chip generations show CPU/GPU as unavailable. `Snapshot.sensors` is `nil` when the SMC cannot be opened. Shared `temperatureText(_:)` formats in the Settings unit; this also fixed Settings, which showed °C for Fahrenheit in locales whose weather unit is Celsius.

2026-10-18, M1 Max, macOS 27.0.1: `scripts/dev.sh build` passed with no warnings; `scripts/dev.sh test` passed (16 tests). Hardware check and render in [verification](../verification/sensors-smc.md).

## Open checks

- User: compare the CPU/GPU temperature with Stats or iStat Menus, and check that the fan speed appears once the fans spin (heavy load).
- A fanless Mac and M2–M5 Macs: unverified key lists.
- Hot-Mac notification and heat protection use these readings in phases 3–4.

## Next handoff

History, charts and the Sensors page are implemented. Next: compare readings with an independent reference and verify spinning-fan/fanless/later-chip behavior. Visual sensor/no-fan states still need their explicit review; fixture rendering alone is insufficient.
