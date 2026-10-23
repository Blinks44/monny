# SMC temperatures and fans: hardware check

- Date: 2026-10-18
- Revision: `main` after 8a3a1d2 (CORE-002 adapter, before commit)
- Mac: MacBook Pro 14″ 2021 (MacBookPro18,2), Apple M1 Max, macOS 27.0.1, on a 60 W adapter
- Method: agent-observed. A temporary test ran `SensorReader` ten times; a standalone probe listed every SMC key (2 251 keys, about 250 temperature keys, `flt ` type). Load: ten `yes` processes for 75 s.

| Reading | Idle | Under load (75 s, all cores) | After 20 s rest | Result |
| --- | --- | --- | --- | --- |
| CPU (mean of 10 `Tp…` keys) | 55–59 °C | Tp01 56 → 69 °C, rising steadily | Tp01 60 °C | Tracks CPU load |
| GPU (mean of 4 `Tg…` keys) | 53–55 °C | Tg05 53 → 61 °C | — | Plausible (shared die heat) |
| SSD (`TH0x`) | 36 °C | — | — | Plausible |
| Battery (mean of `TB0T`–`TB2T`) | 32.5 °C | — | — | Plausible on adapter |
| Fans (`FNum` = 2, `F0Ac`/`F1Ac`) | 0 rpm | 0 rpm | 0 rpm | M1 Max keeps fans stopped at these temperatures; non-zero speed not observed |

Cost: median 4.2–5.1 ms per `SensorReader` pass (about 20 SMC calls with cached key info), run every sampling pass while a view is visible.

Render check: offscreen render of the popover Overview, Battery tab, no-battery thermal strip (with fans and without a fan) and window KPI row in English and Russian, with live readings.

Not covered: comparison with an independent tool (no Stats/iStat on this Mac; `powermetrics` needs root), a spinning fan, a fanless Mac (MacBook Air), M2–M5 key lists (taken from exelban/stats, unverified here), the Sensors page (phase 3).
