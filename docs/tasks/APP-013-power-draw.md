# APP-013: Current power draw on the Battery page

- Updated: 2026-10-21
- Stage: done
- Owner: unassigned (released 2026-10-21)
- Owned surfaces: `BatteryReading.systemLoad`/`batteryPower` in `Readings/PowerReader.swift`, Power card in `Dashboard/BatteryPage.swift`, System load row in `Dashboard/OverviewPage.swift`, `KPICard.footnote`
- Requirements: [PLAN](../PLAN.md#next-features); Sketch `18 · Battery · Power card` (page `02 · Window`)
- Code baseline: 1e56b15 (build 35) plus the on-battery follow-up; build 36

## Outcome and scope

The Battery page Power card shows what the whole Mac consumes now, on adapter and on battery: `AppleSmartBattery` `PowerTelemetryData.SystemLoad` (mW). Below it: “From adapter”, “+N W to battery” while charging at 1 W or more (battery `Voltage` × `Amperage`), or “From battery”; then the adapter's rated watts or macOS's time-left estimate. The Overview System load row also reads `SystemLoad` and names the source. Popover Battery on battery (Sketch `05`, user request on build 35 because header and chip both said “On battery”): header shows the time left, the chip says Discharging and the facts line starts with “Draw N W” instead of the cycle count. On adapter the popover keeps the adapter's rated watts. Unavailable values show the usual dash.

The battery's gauge reports power once a minute (`UpdateTime`), on adapter and on battery. After a plug-in or unplug it first repeats the old state and then reports a partial minute (0.3 W measured right after unplugging), so power is hidden until the first report a full minute after the change (up to about two minutes).

Copy differs from Sketch: the “Mac uses ·” prefix was dropped, “About … left” became “… left” and the popover header drops “On battery ·” (239 pt in Russian next to the chip, about 175 pt available), because at the 900 pt minimum window width a KPI card has about 113 pt for text and “Mac uses · from adapter” (130 pt in English, longer elsewhere) was truncated. The card title “Power” carries the meaning.

## Implementation and verification

- Agent-observed on the M1 Max (65 W adapter, limit held at 80 %), macOS 27.0.1: `SystemLoad` equals `SystemPowerIn` on adapter (14.29 W both); the Debug Battery page shows “17 W · From adapter · Adapter 65 W” in Russian, matching the frame.
- On battery (user unplugged for about two minutes, build 35, agent log every 5 s): `SystemLoad` equalled the battery's output, −`Voltage` × `Amperage`, at every report (10.38 W both), and the negative current reads correctly. The values changed once a minute; the first report after unplugging was 0.3 W and, after plugging back in, the last battery value (−19.45 W) stayed for a minute, which led to the freshness rule.
- Tests `batteryPowerIsSignedByCurrent`, `powerWaitsForAFullGaugeMinuteAfterUnplugging`; 40 tests in 9 suites pass. Signed `Monny-1.0-36.dmg` built.

## Open checks / dependency

- User: build 36 on battery shows a dash for up to two minutes after unplugging, then the draw in the card and popover. `powermetrics` reports only CPU/GPU/ANE power on Apple silicon, so the whole-system value is checked only against the battery's own output.
- Charging with a battery below the limit: “+N W to battery”.
- At the minimum window width the Russian “+32 Вт в аккумулятор” is a few points too wide and truncates.

## User acceptance — 2026-10-21

User, build 37: popover and Battery card on battery accepted.

## Next handoff

None.
