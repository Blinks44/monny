# Public-API readings: comparison with system tools

- Date: 2026-10-18; CORE-001 readers before commit (historical revision after `70e1441`).
- Hardware/software context: MacBook Pro M1 Max, macOS 27.0.1; agent-observed.
- Method: two `ReadingSource` samples 2 s apart; reference commands immediately afterwards. Not simultaneous. Account, process, storage and battery-state values are intentionally omitted.

| Metric | Reference | Observed comparison |
| --- | --- | --- |
| CPU total | `top -l 2` user + system | Within 1 percentage point |
| P/E layout | `ioreg -p IODeviceTree -rn cpus` | Matches |
| Memory used | `vm_stat` page calculation | Within 2% |
| Memory pressure / swap | `memory_pressure`, `vm.swapusage` | Matches |
| Free space | `df` | Expected difference: important-usage capacity includes purgeable space |
| Battery level / state / cycles / health | `pmset -g batt`, System Information | Matches |
| Top process CPU | `ps` | Comparable to one core's reference load; process identity omitted |
| Process energy | No independent reference | Estimate only; not validated |

Sampling cost (median of 10 passes): 5.7 ms without processes, 26 ms with processes. Free-space lookup took 54 ms, so refreshed every 30 s. Battery health via `system_profiler` took 0.14 s in this check and runs at most every six hours.

Not covered by this check: Activity Monitor side by side, popover cost, network/disk throughput under load or a Mac without a battery. Later performance results: [idle cost](idle-cost.md); remaining acceptance: [CORE-003](../tasks/CORE-003-history.md).
