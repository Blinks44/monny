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
