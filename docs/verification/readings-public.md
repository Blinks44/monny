# Public-API readings: comparison with system tools

- Date: 2026-10-18
- Revision: `main` after 70e1441 (CORE-001 readers, before commit)
- Mac: MacBook Pro 14″ 2021 (MacBookPro18,2), Apple M1 Max, 2 E + 8 P cores, 32 GB, macOS 27.0.1, on a 60 W adapter
- Method: agent-observed. A temporary test ran `ReadingSource` twice, 2 s apart; the reference commands ran right after it. Values drift a little between the two runs.

| Metric | Monny | Reference | Result |
| --- | --- | --- | --- |
| CPU total | 22.8 % | `top -l 2`: 22.0 % (user + sys) | Within 1 point |
| Core layout | cpu0–1 E, cpu2–9 P | `ioreg -p IODeviceTree -rn cpus` | Matches |
| Memory used | 21.89 GB (binary) | `vm_stat`: (anonymous − purgeable + wired + compressor) × 16 KB = 21.57 GB | Within 2 % |
| Memory pressure / swap | normal / 0 | `memory_pressure`, `vm.swapusage` | Matches |
| Disk free | 895 GB "important usage" | `df`: 891 GB available | Expected: Finder-style value includes purgeable space |
| Battery level / state | 85 %, on adapter, not charging, 60 W | `pmset -g batt`: 85 %, AC attached, not charging | Matches |
| Cycle count | 96 | System Information: 96 | Matches |
| Health | 97 %, Good | System Information: Maximum Capacity 97 %, Normal | Matches |
| Top process CPU | Rebind 100.4 % of a core | `ps`: 99.0 % | Matches |
| Process energy | Rebind ≈ 3.0 W at 100 % CPU | — | Plausible; `ri_energy_nj` estimate, no reference tool |

Sampling cost (same Mac, median of 10 passes): 5.7 ms without processes, 26 ms with the process list (722 processes). Free-space lookup alone took 54 ms, so it is refreshed every 30 s. Battery health via `system_profiler` took 0.14 s and runs at most every six hours.

Not covered: Activity Monitor side by side in the running app, the app's own CPU use with the popover open, network rates under load, disk throughput under load, a Mac without a battery.
