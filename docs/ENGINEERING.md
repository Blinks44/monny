# Monny: engineering standards

Read before changing app code or choosing a reading/charging mechanism. Workflow and design ownership live in [AGENTS](../AGENTS.md), [WORKFLOW](WORKFLOW.md) and [DESIGN](DESIGN.md).

## Platform and baseline

- **macOS 26+**, Apple silicon first. Intel support is an open SPEC decision; do not claim it without testing.
- Swift 6 language mode, complete strict concurrency, `MainActor` default isolation, approachable concurrency (all set in the Xcode project). Current stable Xcode toolchain.
- SwiftUI for UI, Swift Charts for charts, AppKit only where SwiftUI is insufficient (status item with right-click menu, global shortcut, window/popover behavior). Prefer `MenuBarExtra` if it satisfies the status-item states and right-click menu; otherwise an `NSStatusItem` hosting SwiftUI content.
- Single app process plus one privileged helper for charge control. No other helpers, XPC services, login agents or extensions without a demonstrated need.
- App Sandbox off (helper and system readings), Hardened Runtime on, no custom entitlements unless a mechanism requires one and research records why.
- No Electron/web UI, accounts, cloud backend, analytics or telemetry.

## Architecture

Keep it small and direct:

- **Readers**: one small type per source (CPU, memory, disk, network, power/battery, thermal/sensors, processes), each returning value types. No UI, no timers.
- **Sampler**: one owner of the refresh cadence that calls readers off the main actor and publishes a snapshot to an `@Observable` main-actor model. Views never call readers or IOKit directly.
- **History**: a bounded store for the 1m–7d ranges (mechanism decided in research; downsample older data).
- **Battery control**: an app-side client of the helper's XPC interface plus the policy (limit, sailing, heat, schedules) that decides what to request. The helper only executes charging commands.
- **UI**: popover and window compose shared SwiftUI components built from the Sketch symbols and tokens.

Do not add protocols, dependency-injection containers or view models where a plain type, `@State` or `@Environment` value suffices. Introduce an abstraction when a second real implementation or a test needs it.

## Swift rules

- `@Observable` for shared UI state, `@State` for owned models, `@Bindable`/`@Environment` as appropriate; no new `ObservableObject`.
- Structured concurrency for sampling and XPC. Do not silence data-race diagnostics with unjustified `@unchecked Sendable` or `nonisolated(unsafe)`; wrap C/IOKit handles in a narrowly owned type.
- FormatStyle for every displayed value (bytes, rates, percentages, temperatures with `Measurement`, durations, dates); no `String(format:)` or legacy formatters.
- `Logger` with a subsystem per component; mark process names and paths `.private` unless they are the user's own visible data in the UI.
- Avoid force-unwraps/force-tries, singletons and polling where a notification or callback exists (power source changes, thermal state).
- Comments explain unusual system behavior, units, SMC keys or ownership, not obvious code.

## Readings

- Prefer public APIs: `host_statistics64`/`host_processor_info` for CPU and memory, `ProcessInfo.thermalState`, IOKit power sources and `AppleSmartBattery` properties, `getifaddrs`/`NWPathMonitor` for interfaces, `statfs`/IOKit block storage statistics for disk, `proc_pid_rusage`/libproc for processes.
- Temperatures and fans on Apple silicon need IOKit HID sensor services or SMC keys; both vary by model. Isolate any private or undocumented source behind one small adapter, record the model/OS matrix in research and show unsupported values as unavailable.
- Every reader states units and sampling semantics (instantaneous vs delta over the interval) and has tests with recorded fixture values for the math.

## Battery helper

- Register with `SMAppService.daemon(plistName:)`; the user approves it in System Settings. No `SMJobBless` or manual launchd plists.
- XPC: the helper validates the connecting client's code-signing requirement (same team/identifier) before accepting any message, exposes the smallest command set (set charging allowed/inhibited, set adapter on/off, read state, version) and never runs shell commands.
- Fail safe: on helper start, client disconnect without an active policy, uninstall or an unknown SMC key, restore default macOS charging. Define and test behavior across sleep/wake.
- Version the XPC protocol; the app detects an outdated helper and offers to update it.
- SMC key choices are a research decision per chip family; do not copy GPL code (several existing battery tools are GPL). Reference only, with the license decision recorded.

## UI rules

- Native controls and keyboard focus; `Button` for actions, not tap gestures. Use `foregroundStyle`, current `onChange`, `clipShape(.rect(cornerRadius:))`.
- Translate Sketch with logical points, color variables mapped to adaptive color assets/tokens, text styles to shared fonts. Build repeated pieces (card, chip, metric header, sparkline, core bar, banner) once and reuse them.
- Charts animate only when Reduce Motion is off; keep chart data bounded so redraws stay cheap.
- Check Light/Dark, Increase Contrast, VoiceOver labels for every value (with units), and localized expansion in all six languages.

## Dependencies and skills

Before building non-trivial functionality from scratch, search native APIs, Swift Package Index and maintained open-source macOS projects. Check macOS 26 compatibility, maintenance and license; prefer the simpler reliable option and record decisions in [research](research/README.md). Likely candidates to evaluate rather than assume: a global keyboard-shortcut package, an update-check approach (plain GitHub Releases API vs Sparkle), and sensor/SMC references. GPL sources may inform research but must not be copied.

Reviewed project skills live in `.agents/skills/` with `manifest.json` recording source, revision, license and reasons for skipped candidates. Read only the relevant skill; routing is in AGENTS §5. Upstream iOS-only advice (UIKit, `UIScreen`, BGTaskScheduler) does not apply.
