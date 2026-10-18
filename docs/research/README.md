# Monny: mechanism and dependency decisions

Updated 2026-10-18. Readings and history storage are decided ([CORE-001](../tasks/CORE-001-readings-research.md)); the battery-control task fills the helper table. Record dates, sources, revisions, licenses and what was actually tested.

## Readings

Researched 2026-10-18 on a MacBook Pro M1 Max (2 E + 8 P cores) running macOS 27.0.1 with Xcode 27.1. "Public" means a documented API or a documented IOKit registry class that any unprivileged process can read.

| Metric | Source (public/private) | Units and semantics | Model/OS limits | Evidence |
| --- | --- | --- | --- | --- |
| CPU total, per core | `host_processor_info(PROCESSOR_CPU_LOAD_INFO)` (public Mach) | Tick deltas between samples: busy = user + system + nice ÷ all | — | Matches `top` within a few % |
| P/E split | `IODeviceTree:/cpus/*` `cluster-type` "E"/"P" per `logical-cpu-id` (public registry); fallback: `hw.perflevel1.logicalcpu` E cores first | Averages of the per-core loads in each cluster | M1 Max: cpu0–1 E, cpu2–9 P | `ioreg -p IODeviceTree -rn cpus` |
| Memory used | `host_statistics64(HOST_VM_INFO64)` (public) | Activity Monitor's "Memory Used" = app (internal − purgeable) + wired + compressor-occupied pages × page size | 16 KB pages on Apple silicon | `vm_stat` |
| Memory pressure | `kern.memorystatus_vm_pressure_level` sysctl (public) | 1 normal, 2 warning, 4 critical | — | `memory_pressure` |
| Swap | `vm.swapusage` sysctl (public) | Bytes used / total | — | |
| Disk free | `URLResourceValues.volumeAvailableCapacityForImportantUsage` and `volumeTotalCapacity` on `/` (public) | Bytes; "important usage" matches Finder's available space, including purgeable | — | |
| Disk read/write | `IOBlockStorageDriver` `Statistics` "Bytes (Read)/(Write)" (public registry) | Byte deltas per second, summed over drivers | — | `ioreg -rc IOBlockStorageDriver` |
| Network rates | `sysctl NET_RT_IFLIST2` with `if_msghdr2`/`if_data64` (public) | 64-bit byte counter deltas per second, physical interfaces only (no `lo`, tunnels, bridges) | `getifaddrs` exposes 32-bit counters that wrap at 4 GB, so it is not used | `netstat -ib` |
| Battery level, charging, adapter | IOPowerSources (`IOPSCopyPowerSourcesInfo`, `IOPSCopyExternalPowerAdapterDetails`), change notification `IOPSNotificationCreateRunLoopSource` (public) | Percent, state, adapter watts, macOS time estimates (0/65535 = calculating or unknown) | — | |
| Cycle count, capacities, voltage, amperage, system power in | `AppleSmartBattery` registry (public) | `CycleCount`, `BatteryData.DesignCapacity/NominalChargeCapacity` (mAh), `Voltage` (mV), `Amperage` (mA), `PowerTelemetryData.SystemPowerIn` (mW) | macOS 27 no longer exposes `Temperature` or `AppleRawMaxCapacity` here without privileges | `ioreg -rn AppleSmartBattery` |
| Battery health ("Maximum Capacity", condition) | `system_profiler SPPowerDataType -json` (public tool), run off the main actor at launch and every few hours | Percent and condition exactly as System Information shows them | NominalCharge ÷ Design (94 %) does not match Apple's value (97 %), so it is not used | System Information |
| Thermal state | `ProcessInfo.thermalState` + `thermalStateDidChangeNotification` (public) | Nominal/Fair/Serious/Critical | — | |
| Top processes | `proc_listallpids` + `proc_pid_rusage(RUSAGE_INFO_V6)` (public libproc) | CPU % = CPU-time delta ÷ wall time (100 % = one core, as in Activity Monitor); memory = `ri_phys_footprint` | Other users' processes are hidden for an unprivileged app, as in Activity Monitor without admin | |
| Energy per process | `ri_energy_nj` delta from `rusage_info_v6` (public libproc) | Average watts over the interval; the kernel's estimate, not Activity Monitor's "Energy Impact" | Labelled as an estimate. `ri_billed_energy` gave implausible values (µW at a full core) | Rebind ≈ 3 W at 100 % of a core |
| Network per process | None public (nettop uses private NetworkStatistics) | — | Not shown; SPEC updated | |
| CPU user/system | Same ticks as CPU total | System = system ticks ÷ all; user = busy − system | — | Unit test |
| Load average | `getloadavg` (public libc) | Runnable threads over 1/5/15 min | — | `sysctl vm.loadavg` |
| GPU utilization, cores | `IOAccelerator` registry: `PerformanceStatistics."Device Utilization %"`, `gpu-core-count` (public registry) | Percent of the last interval; core count | M1 Max: 32 cores | `ioreg -rc IOAccelerator` |
| CPU frequency | None public: `powermetrics` needs root, IOReport is private | — | Shown as unavailable | |
| Memory composition, pressure % | `vm_statistics64` (app = internal − purgeable, wired, compressor pages, external = cached files, free, purgeable, `total_uncompressed_pages_in_compressor`, `pageins`, `swapins`); `kern.memorystatus_level` (public) | Bytes; pressure = 100 − level; page-ins/s and swap-ins/min as deltas | — | `sysctl kern.memorystatus_level` |
| Volumes | `FileManager.mountedVolumeURLs(.skipHiddenVolumes)` with volume resource keys (public) | Name, format, internal/network, free/total; refreshed every 30 s with free space | — | Finder |
| Process disk I/O | `ri_diskio_bytesread/byteswritten` deltas in `rusage_info_v6` (public libproc) | Bytes per second | Own user's processes only | |
| SSD wear, S.M.A.R.T., lifetime writes; space by category | Not researched yet (NVMe SMART user client; category sizes need a scan or private API) | — | Not shown; Disk page shows SSD temperature and used/free instead | |
| Connection details | `SCDynamicStore` `State:/Network/Global/IPv4` and `/DNS`, `getifaddrs`, CoreWLAN `rssiValue`, `transmitRate`, `wlanChannel`, `activePHYMode` (public) | Read every 10 s while the Network page is open | The Wi-Fi name needs Location Services and is not shown | `scutil` |
| Open connections | No cheap public count | — | Not shown | |
| Fan maximum | SMC `F<n>Mx` | rpm | Same SMC caveats as below | |
| Temperatures, fans, battery temperature | SMC keys through the `AppleSMC` user client (undocumented layout, no privileges) | °C, rpm | Key lists per chip generation; see below | [verification](../verification/sensors-smc.md) |

### Temperatures and fans (SMC)

Decided 2026-10-18 on the M1 Max ([CORE-002](../tasks/CORE-002-temperatures-fans.md)).

- **Source:** `IOServiceOpen("AppleSMC")` + `IOConnectCallStructMethod` selector 2 with the 80-byte `SMCParamStruct` (read key info, then bytes). Public IOKit calls, undocumented struct and keys. Works without privileges or entitlements with App Sandbox off.
- **Rejected:** HID temperature services. `IOHIDEventSystemClientCreateSimpleClient` lists the sensors but returns no values; reading them needs the private `IOHIDEventSystemClientCreate`/`IOHIDServiceClientCopyEvent`, and the names ("PMU tdie3") do not say which part is CPU or GPU. `powermetrics` needs root. No maintained Swift SMC package exists (beltex/SMCKit is Intel-era and unmaintained), so the reader is about 100 lines of our own code.
- **Keys:** CPU and GPU lists per generation (M1–M5) follow exelban/stats `Modules/Sensors/values.swift` at revision 5731455 (MIT; key names only, no code copied). Chip generation comes from `machdep.cpu.brand_string`. Generic: `TH0x` SSD, `TB0T`/`TB1T`/`TB2T` battery, `FNum` and `F<n>Ac` fans. Values are `flt ` (little-endian Float) on Apple silicon; `sp78`/`fpe2`/integers are decoded too.
- **Limits:** only M1 Max checked. Absent sensors read 0, so values outside 1–150 °C are dropped. Fans read 0 rpm while stopped. Palm rest (`Ts0P`/`Ts1P`) and airflow (`TaLP`/`TaRF`) keys exist on M1 Max but are not used until their meaning is confirmed.

### History storage (decision)

In-memory ring buffers per metric, one per range: 1m = raw samples (60 × 2 s), 1h = 10 s averages (360), 24h = 1 min (1 440), 7d = 10 min (1 008). Only the 24h and 7d tiers are persisted: about 12 metrics × 2 448 points × 8 bytes ≈ 235 KB, written as a binary property list in Application Support every 5 minutes and at quit. SwiftData/SQLite were rejected as heavier than the need (fixed-size series, no queries). Implemented 2026-10-18 with 1 s buckets for the 1m tier (refresh can be 1 s) and a 10 s background cadence ([CORE-003](../tasks/CORE-003-history.md)).

## Battery control

| Area | Decision | Evidence / open question |
| --- | --- | --- |
| Helper installation | SMAppService daemon (ENGINEERING) | Approval flow, signing requirement and update path to research |
| Charging keys | Not researched | Per chip family; existing open-source tools are reference only and several are GPL |
| Fail-safe | Restore macOS charging when control stops (SPEC §5) | Sleep/wake and restart behavior to verify on hardware |

## Other dependencies

| Need | Candidates to evaluate | Decision |
| --- | --- | --- |
| Global shortcut | Native `NSEvent` monitors vs a maintained shortcut package | Open |
| Update check | GitHub Releases API vs Sparkle | Open |
| History storage | Ring buffers + file, SwiftData, SQLite | Ring buffers + binary plist (see above) |

## Recording a new decision

Use the affected task for a small decision; a broad mechanism can have a focused file here. Record the problem, sources with URLs/revisions, license/maintenance/platform limits, alternatives (including native APIs), the choice and what was tested. Explicitly supersede a previous decision. Any third-party code adopted gets a bundled notice and an entry here.
