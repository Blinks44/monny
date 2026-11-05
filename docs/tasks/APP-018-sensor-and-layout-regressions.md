# APP-018: Reliable temperatures and hardware-dependent layouts

- Updated: 2026-11-04
- Stage: awaiting_verification
- Owner: unassigned; implementation complete, affected-device check pending
- Ownership checked: main `9327dab`; implementation committed in `d7f9d02`; ownership released
- Owned surfaces: SensorReader/SMC decoding, CPU per-core card, related sensor UI, regression tests and affected documentation
- Requirements: SPEC §3–4 (shared readings, per-core load, unavailable sensors); ENGINEERING readings/UI contracts
- Code baseline: main `9327dab` (published 1.4.0/build 82); source released in `d7f9d02` as 1.5.0/build 87

## Outcome and scope

Investigate the reported alternating low CPU temperature and overflowing per-core card. Compare the previous implementation and review adjacent variable-size layouts and sensor failure states for the same classes of bugs. Keep monitoring read-only and use the existing shared sampler.

## Acceptance

- [x] Software fixtures exclude low idle-core placeholders; an entirely invalid sample is unavailable, without inventing or holding a temperature.
- [x] Per-core render fixtures stay inside the card, including 10 P + 4 E and Ultra layouts.
- [x] Adjacent confirmed sensor-display problems fixed and checked.
- [x] Full native tests and a signed local DMG ready.
- [ ] Affected-device temperature comparison and installed core-list acceptance.

## Investigation

The sensor adapter and CPU card are unchanged between the pre-network revision `d65c0d3` and build 82. The card constrains a variable-length column to 284 pt. Temperature averaging accepts 1–150 °C, including the 1.5–5 °C power-gated-core placeholders documented in [Stats issue 3692](https://github.com/exelban/stats/issues/3692) and fixed by [5de1171](https://github.com/exelban/stats/commit/5de1171). Reporter hardware/OS and raw sensor comparison are pending.

## Implementation and verification

- CPU/GPU aggregates filter current values to 10–120 °C; battery/SSD retain 1–150 °C. Nonfinite SMC floats are rejected. No last-value hold or smoothing. Existing key lists and read-only SMC connection remain unchanged.
- Per-core height grows with content, retaining the nominal 284 pt minimum and existing two-column design. Counts follow the rendered topology. The enclosing dashboard scrolls; Details starts below the complete row.
- Fan count/read failures now stay unavailable, distinct from a confirmed fanless Mac and a stopped fan. Malformed counts cannot trap or enumerate unbounded keys; incomplete maximum speeds do not produce a percentage. History omits unavailable fan readings.
- CPU/Overview and Sensors temperature charts expand for valid temperatures above 100 °C (Sensors also covers colder battery/SSD readings). Sensors legends move below the title and wrap within adaptive columns; a French overlap found in the first render was fixed and rechecked.
- Live CPU/Sensors Sketch frames inspected on 2026-11-04 in Monny.sketch through MCP (Sketch 2026.3.1); no edits/save. Native render fixtures: six topologies (4P/4E, 6P/6E, 10P/4E, 12P/4E, 24P/8E, 32P/8E) × six languages × Light/Dark; per-core heights 284, 284, 339, 393, 717 and 933 pt. Twelve Sensors fixtures cover 612/776 pt content widths and all six languages; selected long translations and core-list boundaries visually reviewed. A further 72 local fixtures cover Overview, CPU, Memory, Disk, Network and Sensors at narrow width across six languages and both appearances. These are offscreen renders: mounted-volume ScrollView contents and lifecycle-driven process/network details require installed interaction, not ImageRenderer acceptance.
- Agent-observed live source check on MacBookPro18,2 / M1 Max, macOS 27.2: CPU temperature and fan readings available; stopped fans correctly remain measured zero. This does not prove M2–M5 sensor accuracy or reproduce the reporter's hardware.
- Six permanent regression tests cover mixed valid/placeholder samples, all-invalid/recovery, validity boundaries, NaN/infinity, unknown/fanless/stopped fans and malformed counts. `dev.sh test` on the isolated candidate passed **161 tests in 20 suites**. Earlier shared-checkout run passed 163 including two temporary render/source checks; temporary diagnostic sources were removed. A separate one-test screen-render pass succeeded. Existing toolchain warnings (including simulator support and unrelated Copilot awaits) are not new failures.
- `release.sh` succeeded on an isolated copy of `9327dab` plus only this task's app/test changes. Concurrent Kimi integration changes in the shared checkout were preserved and excluded from this candidate. Packaged sensor/layout sources match the working copy. App/nested-code/DMG signatures and image verification passed; Apple Development signed, not notarized, not installed/published.

Local artifact: `apps/monny/build/regression-83/Monny.dmg`, **1.4.0/build 83**, 4,898,031 bytes. SHA-256: `48ba0fb95aac46b549807b6751bffee14164b4c67ec320abfefd17c82e1ccae9`. The DMG and checksum are ignored local output. Owned temporary builds, source copy and diagnostic images were removed after review.

## Review limits and next step

The bounded review covered CPU topology/layout, common dashboard sizing, sensor aggregates/decoding, fan failure states, temperature chart bounds/legends and shared history handling. It is not exhaustive hardware or accessibility acceptance. A plausible in-range placeholder such as 40 °C cannot be identified by range alone; [research](../research/README.md#temperatures-and-fans-smc) retains this limitation. No new chip-key mapping is claimed without affected-model evidence.

Next: check build 83 on the reporter's Mac at idle and during normal work, compare the CPU temperature with an independent sensor tool and confirm all P/E rows stay within their card. Record chip/macOS and the comparison; investigate model-specific raw keys if low readings persist. Combined 1.5.0 publication was authorized on 2026-11-04; affected-device verification remains open.

Combined review 2026-11-04: the sensor/fan/layout diff was re-read alongside Kimi; no blocking code defect found. Shared build 84 contains both scopes and retains the recorded 168-test passing result; no tests rerun or app code changed during review. Build 83 above remains the isolated sensor artifact. Update/signing compatibility evidence and next-release numbering: [APP-015](APP-015-ai-usage-limits.md#combined-review-and-update-compatibility--2026-11-04). Affected-device acceptance stays open.

Published with Kimi Code in [1.5.0/build 87](https://github.com/Blinks44/monny/releases/tag/v1.5.0) on 2026-11-04, source `d7f9d02`. All 172 combined tests pass and public asset/appcast checks match. The affected-Mac runtime checks above remain open.

Popover fan-visibility clarification (2026-11-04): the supplied MacBook Overview screenshot shows the battery strip, as required by SPEC §3. `OverviewTab` renders `ThermalStrip` (including fan rpm) only in the `!SystemInfo.hasBattery` branch; on laptops `BatteryStrip` occupies that slot. This is existing layout behavior, not evidence of an unreadable fan or a new sensor regression. The dashboard Overview sensor card and Sensors thermal-state card remain the places to inspect fan rpm on a MacBook. No code, design, app build or hardware probe changed/run for this clarification. Existing affected-device sensor checks remain open.
