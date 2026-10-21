# Idle and dashboard cost

- Date: 2026-10-19
- Revision: `main` after 1962fb7 (uncommitted), Release build
- Mac: MacBook Pro 14″ 2021 (MacBookPro18,2), Apple M1 Max, macOS 27.0.1, Russian UI
- Method: agent-observed. CPU time from `ps -o time` before and after a fixed interval, `top -stats cpu,mem,power,idlew`; per-reader cost from a temporary test calling each reader 20 times (Debug); `sample` for main-thread profiles. Refresh rate left at the default. The screen was locked during the dashboard runs, so the window was not on screen.

## Background (popover and window closed)

| Build | Interval | CPU time | Average | Memory | Wakeups |
| --- | --- | --- | --- | --- | --- |
| Debug, before | 300 s | 0.92 s | 0.31 % | 26 MB | ~1/s |
| Release, after | 300 s | 0.64 s | 0.21 % | 26 MB | <1/s |

Per pass (every 10 s): SMC sensors about 5 ms, every other reader under 1 ms. Free disk space (about 25 ms) was refreshed every 30 s in the background although nothing shows it; it is now read once and then only while a surface is visible.

## Dashboard open on Overview (30 s per range)

| Range | Before | After |
| --- | --- | --- |
| 1m | 28 % | 9.5 % |
| 1h | 22 % | 10 % |
| 24h | 43 % | 12 % |
| 7d | 15 % | 5 % |

Fix check (window on screen, 1m): 5.3 % after the series fix below.

Causes found: every chart drew one `LineMark`/`AreaMark` per point and was rebuilt on every sample (the in-progress bucket changes each pass); and with no saved refresh rate the sampler ran every 1 s while Settings showed 2 s. Charts now use vectorized `LinePlot`/`AreaPlot` with a series key per point (without it Charts joins every line of a chart into one path, which the user caught on the first try), and the sampler defaults to 2 s.

Open: the popover was not measured (it cannot be opened without the screen); the remaining dashboard cost is mostly SwiftUI view updates (process rows, cards) and needs a view-level audit. Agent-observed after the fix: Overview, CPU, Memory and Network charts draw separate series, and the hover line sits under the pointer.

## 2026-10-21, build 29

- Revision: main at fb2080e plus uncommitted APP-008 changes; signed Release build 29. Same Mac and OS as above; window on screen; refresh 2 s.
- Method: agent-observed `top -l N -s 30|60 -stats cpu,idlew,power,mem` after the app settled; `sample` for main-thread profiles.

| State | Build 28 | Build 29 |
| --- | --- | --- |
| Background, 60 s | 0.2 % | 0.0 % |
| Dashboard Overview, 1h range, 30 s | 6.7 % | 2.8–2.9 % |

Cause: every sample changed the in-progress bucket of all four history tiers, so every chart redrew (24 h and 7 d too), and the CPU chart animated each new point with a spring, which rendered many extra frames per tick (about half of the main thread's busy time). Tiers now notify views only when a bucket closes; the per-point animation is gone. Readers themselves are about 2 % of the busy time; the rest is SwiftUI layout and rendering.

Open: popover cost (it needs a click; UI automation was unavailable).

## 2026-10-21, build 31: menu bar readings

- Revision: main at 037d588 plus uncommitted APP-009/APP-010 changes; signed Release build 31; same Mac and OS; refresh 2 s; no window or popover open.
- Method: agent-observed `top -l 13 -s 5 -stats cpu` after 15 s settling, CPU load, temperature and battery level all shown.
- Result: 1.2–2.1 %, about 1.6 % on average (background without readings stays 0.0–0.2 % at the 10 s cadence). The sampler pass now runs every 2 s instead of every 10 s; which part of the pass dominates has not been profiled.

## 2026-10-21, build 33: busy app alert

- Revision: as build 31 plus APP-011; Debug build; same Mac and OS; no window or popover open; “An app keeps the Mac busy” on; menu bar readings off.
- Method: agent-observed `top -l 30 -s 10 -stats cpu`. Total CPU on this Mac stayed above one core, so processes were read on every 10 s background pass.
- Result: 0.2–0.5 % (0.0–0.2 % with the alert off).

## 2026-10-21, build 37: popover

- User-reported on the M1 Max, macOS 27.0.1, signed Release build 37: about 2 % CPU with the popover open.
