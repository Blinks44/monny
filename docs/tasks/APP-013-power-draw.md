# APP-013: Current power draw on the Battery page

- Updated: 2026-10-21
- Stage: awaiting_verification
- Owner: unassigned (released 2026-10-21)
- Owned surfaces: `BatteryReading.systemLoad`/`batteryPower` in `Readings/PowerReader.swift`, Power card in `Dashboard/BatteryPage.swift`, System load row in `Dashboard/OverviewPage.swift`, `KPICard.footnote`
- Requirements: [PLAN](../PLAN.md#next-features) item 5; Sketch `18 · Battery · Power card` (page `02 · Window`)
- Code baseline: main at 037d588 plus uncommitted APP-009 to APP-012; build 35

## Outcome and scope

The Battery page Power card shows what the whole Mac consumes now, on adapter and on battery: `AppleSmartBattery` `PowerTelemetryData.SystemLoad` (mW). Below it: “From adapter”, “+N W to battery” while charging at 1 W or more (battery `Voltage` × `Amperage`), or “From battery”; then the adapter's rated watts or macOS's time-left estimate. The Overview System load row also reads `SystemLoad` and names the source. The popover keeps the adapter's rated watts. Unavailable values show the usual dash.

Copy differs from Sketch: the “Mac uses ·” prefix was dropped and “About … left” became “… left”, because at the 900 pt minimum window width a KPI card has about 113 pt for text and “Mac uses · from adapter” (130 pt in English, longer elsewhere) was truncated. The card title “Power” carries the meaning.

## Implementation and verification

- Agent-observed on the M1 Max (65 W adapter, limit held at 80 %), macOS 27.0.1: `SystemLoad` equals `SystemPowerIn` on adapter (14.29 W both); the Debug Battery page shows “17 W · From adapter · Adapter 65 W” in Russian, matching the frame.
- Test `batteryPowerIsSignedByCurrent`; 39 tests in 9 suites pass. Signed `Monny-1.0-35.dmg` built.

## Open checks / dependency

- On battery: `SystemLoad` should match the battery's output (−`Voltage` × `Amperage`) and the card should say From battery with the time left. Needs the adapter unplugged for a minute; a comparison logger was run for that (result below once recorded). `powermetrics` reports only CPU/GPU/ANE power on Apple silicon, so it cannot confirm the whole-system value.
- Charging with a battery below the limit: “+N W to battery”.
- At the minimum window width the Russian “+32 Вт в аккумулятор” is a few points too wide and truncates.

## Next handoff

Release gates in [PLAN](../PLAN.md#release-gates).
