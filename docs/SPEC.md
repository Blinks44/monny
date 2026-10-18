# Monny: product specification

**Status:** initial specification, derived on 2026-10-17 from the saved Monny.sketch screens and the user's setup decisions. Implementation and hardware support must be independently verified; a requirement here does not mean it exists.
**Platform:** macOS 26+ on Apple silicon only (Intel Macs are out of scope, user decision 2026-10-18), native SwiftUI/AppKit, distributed outside the Mac App Store.
**Companion files:** [AGENTS](../AGENTS.md), [STATE](STATE.md), [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [DESIGN](DESIGN.md). Visual states, layout and exact copy live in Sketch; this file owns behavior and acceptance.

## 1. Product vision

A calm, native menu bar utility that answers “what is my Mac doing?” in one click and keeps a plugged-in MacBook's battery healthy. It should feel like a first-party macOS app, cost almost nothing to run, and never claim a reading it cannot make.

**Primary test of success:** readings match Activity Monitor/System Information within stated tolerances, the app stays light while open, and an enabled charge limit is respected across sleep, restart and quit without ever leaving the Mac unable to charge.

### Non-goals

Not a process killer, system cleaner, fan controller, network firewall, cloud dashboard or analytics collector. No account, no remote access, no tuning of system settings beyond charging through the helper.

### Capability labels

Each metric, sensor and battery mode is reported with one label: `not implemented`, `implemented` (software-tested), `verified` (checked on a named Mac model and macOS version), `unsupported` (the hardware/OS does not expose it; the UI says so). Labels are recorded per task/verification record.

## 2. Menu bar presence

- A template status item (Sketch: `05 · System · Menu bar & notifications`). States: idle, popover open, needs attention (a 7 pt badge for heat or danger; can be turned off in Settings).
- Left click opens the popover; there is no hover mode (user decision 2026-10-18). Right click opens a menu: Open Dashboard (⌥⌘M), Settings…, Pause Battery Control, Charge to 100% Now, Start Calibration…, About Monny, Quit Monny. Battery items are disabled without the helper and hidden on a Mac without a battery.
- A global shortcut (default ⌥⌘M, changeable) opens the dashboard.
- No Dock icon, except while the dashboard window is open (user decision 2026-10-18).

## 3. Popover

Header: app icon, Monny, Mac model · chip · uptime; buttons to open the dashboard and Settings. Three tabs.

**Overview:** CPU load with P/E split and CPU temperature chip (warns when hot), memory used with pressure chip, disk free space and read/write rates, network down/up rates with a short sparkline, per-core load bars grouped by Performance/Efficiency, and a battery card with level, current mode and a charge-limit toggle. Footer: Open Dashboard, shortcut, refresh interval.
**Thermal alert state:** when the Mac is hot, the CPU card and battery card show it (for example “Charging paused · too hot” when heat protection acts).

**Battery:** state line (adapter wattage and time to limit, or on battery with time remaining), large level gauge with limit marker, health · cycles · temperature, mode buttons Charge (up to limit) / Hold (run on adapter) / Discharge (while plugged), charge-limit slider 50–100 %, Sailing mode and Heat protection toggles, Calibrate…. States: charging, holding, on battery (modes disabled, “Connect power to switch modes”), helper required (banner, read-only controls, Install Battery Helper… with “Asks for your admin password once. Only controls charging.”), no battery (the tab stays and shows the same empty state as the dashboard Battery page).

On a Mac without a battery the Overview battery strip shows the thermal state and fan speed instead.

**Processes:** top processes sorted by CPU, Memory or Energy (Energy is a relative estimate; per-process network has no public source and is not shown), with icon, name, memory/threads or tabs/system note and value; a link to Activity Monitor. Read-only.

## 4. Dashboard window

Sidebar: Overview, CPU, Memory, Disk, Network, Battery, Sensors; Settings at the bottom. Header: page title and machine summary, time range 1m / 1h / 24h / 7d, and a button that collapses back to the popover.

- **Overview:** summary cards with sparklines (CPU, Memory, Temperature, Battery), CPU load & temperature chart with hover tooltip naming the top process, 24 h battery level chart with limit line, battery facts (health, cycles, capacity, system load), top processes, sensor tiles and fan speed.
- **CPU, Memory, Disk, Network:** the detailed history and breakdowns drawn in the corresponding Sketch frames.
- **Battery:** level, health, cycles and power cards; charging mode segmented control, charge limit, sailing mode and heat protection; calibration card with its four steps; Full charge before trips (day selection and time; charges to 100 % before then, then returns to the limit).
- **Battery without a battery:** the range control and cards are replaced by one empty state (“This Mac has no battery”) with Open Sensors.
- **Sensors:** CPU die, GPU, SSD and battery cards with peaks, temperature chart, thermal state (Nominal/Fair/Serious/Critical), fan speed, and tiles for each available sensor. Missing sensors are omitted or marked unavailable, never invented; a Mac without a fan says so.

Before history exists (first launch), current values show immediately and charts show a “Collecting history” state instead of empty or zero lines.

History must survive the window closing and an app restart for the 24 h and 7 d ranges. Storage mechanism is an open engineering decision (research).

## 5. Battery control

Requires a Mac with a battery and the installed helper. All modes are explicit user choices; defaults come from Settings.

- **Charge limit** 50–100 %: stop charging at the limit and run on the adapter.
- **Sailing range:** after reaching the limit, let the level drift down by the range (for example to 75 %) before topping up.
- **Hold:** stop charging immediately at the current level. **Discharge:** run from the battery while plugged in, down to the limit.
- **Heat protection:** pause charging above a battery temperature (default 35 °C) and resume when it cools.
- **Charge to 100 % now** and **Full charge before trips** (scheduled) temporarily override the limit, then return to it.
- **Calibration:** charge to 100 %, rest 1 hour, discharge to 15 %, recharge to the limit; shows progress, can be hidden or stopped, continues if the window closes, and notifies when finished.
- **Fail-safe:** pausing battery control, quitting, uninstalling the helper, a crash or an unknown hardware state returns charging to macOS. Behavior across sleep and restart must be defined in the helper task and verified on hardware.

## 6. Onboarding

Three steps (Sketch page `03`): Welcome (menu bar stats, charge limit, works offline), Battery helper (why, password once, only touches charging, how to remove; can be skipped), Ready (where Monny lives, ⌥⌘M, Launch at login recommended so the limit always applies). Macs without a battery skip the helper step: two steps, with Sensors and history instead of Charge limit on Welcome.

## 7. Settings

- **General:** Launch at login, refresh rate, temperature unit, appearance, language (System or one of the six; applies after Monny restarts, with a Restart button; user request 2026-10-18).
- **Menu bar:** global shortcut, show alert badge.
- **Battery:** default charge limit, sailing range, heat protection threshold, helper status with version and Uninstall Helper…. Uninstalling asks for confirmation first and returns charging to macOS. If installation fails or is not approved, a banner explains it, with Open System Settings… (Login Items & Extensions) and Try Again.
- **Notifications:** charge limit reached, Mac is running hot, calibration finished, battery below 20 %, memory pressure is high (each toggle). Each fires once when its condition starts and again only after it has cleared.
- **About:** version and build, Check for Updates (compares with the latest GitHub release), privacy note (no analytics; network only for updates). Results: up to date; a newer version (Download… opens the GitHub release page in the browser; Monny does not install updates itself); check failed (Try Again).

## 8. Cross-cutting requirements

- Light and Dark appearance; Increase Contrast, Reduce Motion, VoiceOver and full keyboard navigation in popover and window.
- Localized in English, Russian, German, French, Spanish and Simplified Chinese; numbers, units, temperatures and dates use the user's locale and chosen temperature unit.
- Readings never leave the Mac. The update check is the only network request.
- Idle cost: the popover and dashboard must not keep the CPU busy; target and measurement method are defined in the sampling task.

## 9. Open product decisions

- Time estimates (“about 1 h 05 min left”, “80% in 25 min”): proposal is to show macOS's own estimate and hide it while macOS is still calculating, instead of computing our own.
