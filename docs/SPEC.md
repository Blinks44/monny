# Monny: product specification

**Status:** specification derived from saved Monny.sketch; native-only scope revised by user instruction on 2026-10-21. Implementation and hardware support must be independently verified; a requirement here does not mean it exists.
**Platform:** macOS 26+ on Apple silicon only (Intel Macs are out of scope, user decision 2026-10-18), native SwiftUI/AppKit, distributed outside the Mac App Store.
**Companion files:** [AGENTS](../AGENTS.md), [STATE](STATE.md), [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [DESIGN](DESIGN.md). Visual states, layout and exact copy live in Sketch; this file owns behavior and acceptance.

## 1. Product vision

A calm, native menu bar utility that answers “what is my Mac doing?” in one click and keeps a plugged-in MacBook's battery healthy. It should feel like a first-party macOS app, cost almost nothing to run, and never claim a reading it cannot make.

**Primary test of success:** readings match Activity Monitor/System Information within stated tolerances, the app stays light while open, and an enabled charge limit is respected across sleep, restart and quit without ever leaving the Mac unable to charge.

### Non-goals

Not a process killer, system cleaner, fan controller, network firewall, cloud dashboard or analytics collector. No account, no remote access, no tuning of system settings beyond the native macOS charge-limit preference.

### Capability labels

Each metric, sensor and battery mode is reported with one label: `not implemented`, `implemented` (software-tested), `verified` (checked on a named Mac model and macOS version), `unsupported` (the hardware/OS does not expose it; the UI says so). Labels are recorded per task/verification record.

## 2. Menu bar presence

- A template status item (Sketch: `05 · System · Menu bar & notifications`). States: idle, popover open, needs attention (a 7 pt badge for heat or danger; can be turned off in Settings).
- Left click opens the popover; there is no hover mode (user decision 2026-10-18). Right click opens a menu: Open Dashboard (⌥⌘M), Settings…, Turn Off Charge Limit, Set Limit to 100%, About Monny, Quit Monny. Current battery actions disable the system limit or set it to 100%; disable them when native support is unavailable and hide them without a battery. Calibration remains deferred.
- Optional readings next to the icon: CPU load, CPU temperature and battery level (battery only on a Mac with a battery). Each is off by default and turned on separately in Settings → Menu bar (user decision 2026-10-21). They use the shared sampler's values and refresh rate.
- A global shortcut (default ⌥⌘M, changeable) opens the dashboard.
- No Dock icon, except while the dashboard window is open (user decision 2026-10-18).

## 3. Popover

Header: app icon, Monny, Mac model · chip · uptime; buttons to open the dashboard and Settings. Three tabs.

**Overview:** CPU load with P/E split and CPU temperature chip (warns when hot), memory used with pressure chip, disk free space and read/write rates, network down/up rates with a short sparkline, per-core load bars grouped by Performance/Efficiency, and a battery card with level, current mode and a charge-limit toggle. Footer: Open Dashboard, shortcut, refresh interval.
**Thermal alert state:** when the Mac is hot, the CPU card and battery card show it (for example “Charging paused · too hot” when heat protection acts).

**Battery:** measured adapter/source state, large level gauge with system limit marker, health · cycles · temperature, supported native charge-limit slider and enable switch, system charging guidance. Missing readings stay unavailable/loading. Discharge and advanced automation in the Sketch frames are deferred and not shown (production review 2026-10-21). A no-battery Mac keeps the same empty state as the dashboard Battery page. Do not invent a time-to-limit from a time-to-full estimate.

On a Mac without a battery the Overview battery strip shows the thermal state and fan speed instead.

Each Overview card opens its dashboard page: CPU and cores → CPU, memory → Memory, disk → Disk, network → Network, battery strip → Battery, thermal strip → Sensors (user request 2026-10-21).

**Processes:** top apps sorted by CPU, Memory or Energy. Helper processes are grouped under the app they belong to, with summed values and a process count; processes without an app (system) stay single rows (Energy is a relative estimate; per-process network has no public source and is not shown), with icon, name, memory/threads or tabs/system note and value; a link to Activity Monitor. Read-only.

## 4. Dashboard window

Sidebar: Overview, CPU, Memory, Disk, Network, Battery, Sensors; Settings at the bottom. Header: page title and machine summary, time range 1m / 1h / 24h / 7d, and a button that collapses back to the popover.

- **Overview:** summary cards with sparklines (CPU, Memory, Temperature, Battery), CPU load & temperature chart with hover tooltip naming the top process, 24 h battery level chart with limit line, battery facts (health, cycles, capacity, system load), top processes, sensor tiles and fan speed.
- **CPU, Memory, Disk, Network:** the detailed history and breakdowns drawn in the corresponding Sketch frames.
- **Battery:** level, health, cycles and power cards (Power shows what the Mac uses now on adapter and on battery, plus watts going into the battery while charging; on-battery values are verified against a reference before they are shown), history and native charge-limit controls. Sailing, heat protection, calibration and trip cards from Sketch are not shown until implemented (production review 2026-10-21: no disabled placeholders in the release).
- **Battery without a battery:** the range control and cards are replaced by one empty state (“This Mac has no battery”) with Open Sensors.
- **Sensors:** CPU die, GPU, SSD and battery cards with peaks, temperature chart, thermal state (Nominal/Fair/Serious/Critical), fan speed, and tiles for each available sensor. Missing sensors are omitted or marked unavailable, never invented; a Mac without a fan says so.

Before history exists, current values show immediately and charts/process lists explain “Collecting data…” instead of suggesting permanent emptiness or showing invented zero lines.

History must survive the window closing and an app restart for the 24 h and 7 d ranges. Storage mechanism is an open engineering decision (research).

## 5. Battery control

Main implements the **native macOS charge-limit preference only**, without a privileged helper. Requires an internal battery, macOS 26.4+ and a compatible native runtime. On macOS below 26.4, replace the charge-limit controls with an informational message explaining the minimum version and that battery monitoring still works. The runtime returns supported targets (currently 80/85/90/95/100). Only explicit user actions set the target/enable state; startup, activation and wake read back settings without replaying a target.

Monny changes the same system preference shown in Battery Settings. macOS owns charging enforcement and the preference persists after app quit, crash, sleep and restart. No restoration-on-quit, privileged helper, XPC, SMC writer, isolation or recurring policy is required on main. On failure, re-read state and report that the setting could not be confirmed. Unsupported/unknown readings disable mutation; no root/entitlement/preferences-file workaround. The private runtime interface is not a public API guarantee and must fail unavailable when signatures change.

Enable only when necessary, before setting the target (enable can reset it); require actual enabled/target read-back. Optimized Battery Charging may independently delay charging and is not changed. The system may charge within a few percentage points of the target and occasionally reach 100% for estimation. Do not claim exact thresholds, immediate forced discharge on lowering a target or a fabricated time-to-limit. Provide a Battery Settings link and explain that the setting persists.

Discharge, sailing, manual heat protection, calibration and trip automation are deferred to **experiments/discharge**, preserved at abe3a80. Their Sketch frames remain for later work; the app does not show them.

Users of historical helper builds remove that helper through the old app before replacement. The new app never silently installs/uninstalls a daemon or deletes old recovery storage.

## 6. Onboarding

Three steps from Sketch page `03`: Welcome, Charge limit and Ready; no helper step or administrator approval. Charge limit explains the native limit and offers Not Now or Use 80% Limit (an explicit gesture that enables it); it is skipped on a Mac without a battery or where the native limit is unavailable. Explain menu bar monitoring, offline behavior, supported native system limit and the global shortcut. Launch at login is a monitoring convenience, not required for macOS to enforce a persistent limit. Ready also offers Check for updates automatically (on by default, user decision 2026-10-21); it is the same setting as in Settings › About and replaces Sparkle's own permission prompt. Macs without a battery omit charging references. Onboarding implementation remains a separate release gate; no Sketch edits are authorized in this slice.

## 7. Settings

- **General:** Launch at login, refresh rate, temperature unit, appearance, language (System or one of the six; applies after Monny restarts, with a Restart button; user request 2026-10-18).
- **Menu bar:** global shortcut, show alert badge, show in menu bar (CPU load, Temperature, Battery level; all off by default).
- **Battery:** the same supported native limit/enable setting as the Battery page. Advanced automation preferences are deferred.
- **Notifications:** charge limit reached, Mac is running hot, an app keeps the Mac busy (one app, helpers included, above 80 % of one core for 5 minutes; off by default), battery below 20 %, memory pressure is high (each toggle; battery ones only on a Mac with a battery). Each alert fires once per episode; charge limit reached fires once per plug-in, because macOS lets the level drift slightly below the limit. Calibration finished comes with calibration.
- **About:** version and build, Check for Updates, Check for updates automatically (toggle), privacy note (no analytics; network only for updates). Updates use Sparkle (user decision 2026-10-21): Sparkle's standard window shows release notes and Install Update / Skip This Version / Remind Me Later; Monny installs and relaunches only after the user confirms. Automatic checks run in the background (daily) only while the toggle is on; no silent installs and no system profile is sent. Updates are verified with an EdDSA signature. Up to date and check failed use Sparkle's standard alerts.

## 8. Cross-cutting requirements

- Light and Dark appearance; Increase Contrast, Reduce Motion, VoiceOver and full keyboard navigation in popover and window.
- Localized in English, Russian, German, French, Spanish and Simplified Chinese; numbers, units, temperatures and dates use the user's locale and chosen temperature unit.
- Readings never leave the Mac. Update checks (manual, or automatic when enabled) and update downloads are the only network requests.
- Idle cost: the popover and dashboard must not keep the CPU busy; target and measurement method are defined in the sampling task.

## 9. Open product decisions

- Time estimates (“about 1 h 05 min left”, “80% in 25 min”): proposal is to show macOS's own estimate and hide it while macOS is still calculating, instead of computing our own.
