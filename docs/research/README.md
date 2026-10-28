# Monny: mechanism and dependency decisions

> Battery helper and Discharge task/verification records referenced here (BAT-*, APP-005/006, helper verification) were retired from main on 2026-10-21; they are preserved on the `experiments/discharge` branch.

Updated 2026-10-25. Readings and history storage are decided; battery control on main uses the native macOS charge limit. Record dates, sources, revisions, licenses and what was actually tested.

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
| Battery health ("Maximum Capacity", condition) | `system_profiler SPPowerDataType -json` (public tool), run off the main actor at launch and every few hours | Percent and condition exactly as System Information shows them | NominalCharge ÷ Design does not match Apple's reported value, so it is not used | System Information |
| Thermal state | `ProcessInfo.thermalState` + `thermalStateDidChangeNotification` (public) | Nominal/Fair/Serious/Critical | — | |
| Top processes | `proc_listallpids` + `proc_pid_rusage(RUSAGE_INFO_V6)` (public libproc) | CPU % = CPU-time delta ÷ wall time (100 % = one core, as in Activity Monitor); memory = `ri_phys_footprint` | Other users' processes are hidden for an unprivileged app, as in Activity Monitor without admin | |
| Energy per process | `ri_energy_nj` delta from `rusage_info_v6` (public libproc) | Average watts over the interval; the kernel's estimate, not Activity Monitor's "Energy Impact" | Labelled as an estimate. `ri_billed_energy` gave implausible values (µW at a full core) | Rebind ≈ 3 W at 100 % of a core |
| Processes grouped by app | Responsible process from `responsibility_get_pid_responsible_for_pid` (exported by libsystem, no public header; looked up with `dlsym`, missing symbol = each process is its own), then the outermost `.app` in its `proc_pidpath` (public). Coalition info (`PROC_PIDCOALITIONINFO`) is not in the SDK either | Owner looked up once per PID; helpers, XPC/WebKit content and tools an app launched sum into it, as in Activity Monitor; no `.app` = system process | Checked 2026-10-21 on M1 Max, macOS 27.0.1: Chrome helpers and crashpad → Chrome, Mail's WebKit processes → Mail, `SafariPlatformSupport.Helper` → the app using it. Bundle-path-only grouping missed WebKit and shared helpers | Activity Monitor |
| Network per process | None public (nettop uses private NetworkStatistics) | — | Not shown; SPEC updated | |
| CPU user/system | Same ticks as CPU total | System = system ticks ÷ all; user = busy − system | — | Unit test |
| Load average | `getloadavg` (public libc) | Runnable threads over 1/5/15 min | — | `sysctl vm.loadavg` |
| GPU utilization, cores | `IOAccelerator` registry: `PerformanceStatistics."Device Utilization %"`, `gpu-core-count` (public registry) | Percent of the last interval; core count | M1 Max: 32 cores | `ioreg -rc IOAccelerator` |
| CPU frequency | None public: `powermetrics` needs root, IOReport is private | — | Shown as unavailable | |
| Memory composition, pressure % | `vm_statistics64` (app = internal − purgeable, wired, compressor pages, external = cached files, free, purgeable, `total_uncompressed_pages_in_compressor`, `pageins`, `swapins`); `kern.memorystatus_level` (public) | Bytes; pressure = 100 − level; page-ins/s and swap-ins/min as deltas | — | `sysctl kern.memorystatus_level` |
| Volumes | `FileManager.mountedVolumeURLs(.skipHiddenVolumes)` with volume resource keys (public) | Name, format, internal/network, free/total; refreshed every 30 s with free space | — | Finder |
| Process disk I/O | `ri_diskio_bytesread/byteswritten` deltas in `rusage_info_v6` (public libproc) | Bytes per second | Own user's processes only | |
| SSD wear, S.M.A.R.T., lifetime writes | NVMe SMART user client from the public SDK header `IOKit/storage/nvme/NVMeSMARTLibExternal.h` (via the bridging header; the IOKit Swift module omits it), on the first service with `NVMe SMART Capable` (public, no privileges) | Wear = `PERCENTAGE_USED`, health = 100 − wear; verified = no `CRITICAL_WARNING` and spare ≥ threshold; written = `DATA_UNITS_WRITTEN` × 512 000 bytes. Read off the main actor at most hourly while a surface is visible | First capable controller only; with an external NVMe drive attached the choice is unchecked. No `smartctl` on the test Mac, so values were compared only with a standalone probe of the same API | [verification](../verification/ssd-smart.md) |
| Space by category | None cheap: needs a full scan or private API | — | Not shown; startup volume card shows used/free | |
| Connection details | `SCDynamicStore` `State:/Network/Global/IPv4` and `/DNS`, `getifaddrs`, CoreWLAN `rssiValue`, `transmitRate`, `wlanChannel`, `activePHYMode` (public) | Read every 10 s while the Network page is open | The Wi-Fi name needs Location Services and is not shown | `scutil` |
| Open connections | No cheap public count | — | Not shown | |
| Fan maximum | SMC `F<n>Mx` | rpm | Same SMC caveats as below | |
| Temperatures, fans, battery temperature | SMC keys through the `AppleSMC` user client (undocumented layout, no privileges) | °C, rpm | Key lists per chip generation; see below | [verification](../verification/sensors-smc.md) |

### Temperatures and fans (SMC)

Decided 2026-10-18 on the M1 Max.

- **Source:** `IOServiceOpen("AppleSMC")` + `IOConnectCallStructMethod` selector 2 with the 80-byte `SMCParamStruct` (read key info, then bytes). Public IOKit calls, undocumented struct and keys. Works without privileges or entitlements with App Sandbox off.
- **Rejected:** HID temperature services. `IOHIDEventSystemClientCreateSimpleClient` lists the sensors but returns no values; reading them needs the private `IOHIDEventSystemClientCreate`/`IOHIDServiceClientCopyEvent`, and the names ("PMU tdie3") do not say which part is CPU or GPU. `powermetrics` needs root. No maintained Swift SMC package exists (beltex/SMCKit is Intel-era and unmaintained), so the reader is about 100 lines of our own code.
- **Keys:** CPU and GPU lists per generation (M1–M5) follow exelban/stats `Modules/Sensors/values.swift` at revision 5731455 (MIT; key names only, no code copied). Chip generation comes from `machdep.cpu.brand_string`. Generic: `TH0x` SSD, `TB0T`/`TB1T`/`TB2T` battery, `FNum` and `F<n>Ac` fans. Values are `flt ` (little-endian Float) on Apple silicon; `sp78`/`fpe2`/integers are decoded too.
- **Limits:** only M1 Max checked. Absent sensors read 0, so values outside 1–150 °C are dropped. Fans read 0 rpm while stopped. Palm rest (`Ts0P`/`Ts1P`) and airflow (`TaLP`/`TaRF`) keys exist on M1 Max but are not used until their meaning is confirmed.

### History storage (decision)

In-memory ring buffers per metric, one per range: 1m = raw samples (60 × 2 s), 1h = 10 s averages (360), 24h = 1 min (1 440), 7d = 10 min (1 008). Only the 24h and 7d tiers are persisted: about 12 metrics × 2 448 points × 8 bytes ≈ 235 KB, written as a binary property list in Application Support every 5 minutes and at quit. SwiftData/SQLite were rejected as heavier than the need (fixed-size series, no queries). Implemented 2026-10-18 with 1 s buckets for the 1m tier (refresh can be 1 s) and a 10 s background cadence.

## Battery control

| Area | Decision | Evidence |
| --- | --- | --- |
| Charge limit on main | macOS 26.4+ system charge limit (System Settings › Battery) through the private `PowerUISmartChargeClient` in `PowerUI.framework`, called as the ordinary user. Signatures checked at runtime; any mismatch reads as unavailable. No helper, SMC writes or entitlements | [battery-control.md](battery-control.md); ordinary-user read/write/read-back verified on M1 Max, macOS 27.0.1 ([APP-007](../tasks/APP-007-native-simplification-design-parity.md)) |
| Discharge, Hold, sailing, calibration | Need SMC/adapter control through a privileged helper; deferred | [smc-charge-control.md](smc-charge-control.md), [OpenDente/AlDente review](opendente-aldente-chie.md); implementation on `experiments/discharge` |

## Other dependencies

Explicit process Quit/Force Quit uses native AppKit and Darwin APIs, with sampled launch identities and per-target validation: [process actions decision](process-actions.md) (2026-10-25).

| Need | Candidates to evaluate | Decision |
| --- | --- | --- |
| Global shortcut | Native `NSEvent` global monitors (need Accessibility permission), Carbon `RegisterEventHotKey` by hand, sindresorhus/KeyboardShortcuts | KeyboardShortcuts 1.17.0 (MIT, active, Swift 6, Carbon hot keys without permissions, recorder UI localized in our languages); 2026-10-18 |
| Update check | GitHub Releases API vs Sparkle | 2026-10-21: [Sparkle](https://github.com/sparkle-project/Sparkle) 2.10.0 (MIT) through SPM for checks and installs (user decision; replaces the 2026-10-18 GitHub Releases API check, which only opened the release page). Same setup as Rebind, already in use there: `SPUStandardUpdaterController`, appcast attached to each GitHub release and read from `releases/latest/download/appcast.xml`, the DMG as the update archive, `generate_appcast` in `release.sh`, Sparkle's nested code re-signed with the app's identity for Hardened Runtime. Own EdDSA key ([SIGNING](../SIGNING.md#update-signing-key)). In-app updates between published builds were accepted by the user (1.0.0 → 1.1.0 on 2026-10-25, to 1.1.1 on 2026-10-26) |
| History storage | Ring buffers + file, SwiftData, SQLite | Ring buffers + binary plist (see above) |
| AI usage limits | CodexBar's sources: OAuth usage endpoints, browser cookies, CLI PTY, local session logs, `codex app-server` | 2026-10-22: Anthropic and ChatGPT usage endpoints with the tools' own sign-in, Claude's read through `/usr/bin/security`; Copilot via saved GitHub CLI sign-in (2026-10-25); no refresh, no cookies ([ai-usage-limits.md](ai-usage-limits.md)) |

## DMG packaging — 2026-10-19

Use installed [create-dmg](https://github.com/create-dmg/create-dmg) 1.3.0 (MIT), already used by Rebind, for Finder background/icon layout and Applications target. It remains a build-time tool, not an app dependency; no sources or binaries copied. Native hdiutil still verifies the final image, and existing codesign checks remain. A single shipping TIFF is exported from live Sketch, with no permanent generator. The release command stops with setup instructions if the tool is missing.

## Recording a new decision

Use the affected task for a small decision; a broad mechanism can have a focused file here. Record the problem, sources with URLs/revisions, license/maintenance/platform limits, alternatives (including native APIs), the choice and what was tested. Explicitly supersede a previous decision. Any third-party code adopted gets a bundled notice and an entry here.
