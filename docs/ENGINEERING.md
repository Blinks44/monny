# Monny: engineering standards

Read before changing app code or choosing a reading/charging mechanism. Workflow and design ownership live in [AGENTS](../AGENTS.md), [WORKFLOW](WORKFLOW.md) and [DESIGN](DESIGN.md).

## Platform and baseline

- **macOS 15+ on Apple silicon only** (deployment target lowered from 26 by user decision 2026-10-29; Apple silicon only by user decision 2026-10-18). Intel Macs are out of scope; Release builds should target `arm64` only (set in the release task).
- Swift 6 language mode, complete strict concurrency, `MainActor` default isolation, approachable concurrency (all set in the Xcode project). Current stable Xcode toolchain.
- SwiftUI for UI, Swift Charts for charts, AppKit only where SwiftUI is insufficient (status item with right-click menu, global shortcut, window/popover behavior). Prefer `MenuBarExtra` if it satisfies the status-item states and right-click menu; otherwise an `NSStatusItem` hosting SwiftUI content.
- One app process; no privileged helper/XPC service on main. Native limit is a direct system preference; experimental helper/SMC control is on experiments/discharge.
- App Sandbox off (system readings), Hardened Runtime on, no custom entitlements unless a mechanism requires one and research records why.
- No Electron/web UI, accounts, cloud backend, analytics or telemetry.

## Architecture

Keep it small and direct:

- **Readers**: one small type per source (CPU, memory, disk, network, power/battery, thermal/sensors, processes), each returning value types. No UI, no timers.
- **Sampler**: one owner of the refresh cadence that calls readers off the main actor and publishes a snapshot to an `@Observable` main-actor model. Views never call readers or IOKit directly.
- **History**: a bounded store for the 1m–7d ranges (mechanism decided in research; downsample older data).
- **Battery setting**: one observable UI controller and one actor serialize private native getters/setters off main. Only explicit user actions write. macOS owns charging enforcement.
- **UI**: popover and window compose shared SwiftUI components built from the Sketch symbols and tokens.

Do not add protocols, dependency-injection containers or view models where a plain type, `@State` or `@Environment` value suffices. Introduce an abstraction when a second real implementation or a test needs it.

## Swift rules

- `@Observable` for shared UI state, `@State` for owned models, `@Bindable`/`@Environment` as appropriate; no new `ObservableObject`.
- Structured concurrency for sampling. Do not silence data-race diagnostics with unjustified `@unchecked Sendable` or `nonisolated(unsafe)`; wrap C/IOKit handles in a narrowly owned type.
- FormatStyle for every displayed value (bytes, rates, percentages, temperatures with `Measurement`, durations, dates); no `String(format:)` or legacy formatters.
- `Logger` with a subsystem per component; mark process names and paths `.private` unless they are the user's own visible data in the UI.
- Avoid force-unwraps/force-tries, singletons and polling where a notification or callback exists (power source changes, thermal state).
- Comments explain unusual system behavior, units, SMC keys or ownership, not obvious code.

## Readings

- Prefer public APIs: `host_statistics64`/`host_processor_info` for CPU and memory, `ProcessInfo.thermalState`, IOKit power sources and `AppleSmartBattery` properties, `getifaddrs`/`NWPathMonitor` for interfaces, `statfs`/IOKit block storage statistics for disk, `proc_pid_rusage`/libproc for processes.
- Temperatures and fans on Apple silicon need IOKit HID sensor services or SMC keys; both vary by model. Isolate any private or undocumented source behind one small adapter, record the model/OS matrix in research and show unsupported values as unavailable.
- Every reader states units and sampling semantics (instantaneous vs delta over the interval) and has tests with recorded fixture values for the math.

## Native charge-limit setting

- Main has no charging helper, XPC, SMC setter, adapter isolation, restoration journal or lease. Complete old code/evidence is preserved on experiments/discharge at 09595b5.
- Native preference support requires macOS 26.4+ and verified runtime signatures. The isolated Objective-C bridge loads only the system PowerUI framework, validates method/argument/return encodings, validates returned limits and fails unavailable on missing/changed interfaces. This is a private API, not a public Apple support guarantee.
- One actor serializes calls off the main actor. UI refresh/launch/wake only read; no timer writes or automatic enable. Unknown snapshots/unsupported targets prevent mutations. After each user operation require actual enabled/target read-back and show failure plus the actual fresh state otherwise.
- Enable only if needed, before setting the target: the locally observed enable call resets the target. Disabling does not require writing an irrelevant target. Do not conflate a setter acknowledgement with read-back.
- The user-selected system preference persists through app quit/sleep/restart; macOS enforces it. No old-setting restoration on quit. Lowering the target does not imply forced discharge or an exact battery threshold.
- Monitoring SMC is read-only and remains shared with sensor readers. No root, process-kill, framework patch, preference-file or entitlement workaround.

## UI rules

- Native controls and keyboard focus; `Button` for actions, not tap gestures. Use `foregroundStyle`, current `onChange`, `clipShape(.rect(cornerRadius:))`.
- Translate Sketch with logical points, color variables mapped to adaptive color assets/tokens, text styles to shared fonts. Build repeated pieces (card, chip, metric header, sparkline, core bar, banner) once and reuse them.
- Charts animate only when Reduce Motion is off; keep chart data bounded so redraws stay cheap.
- Check Light/Dark, Increase Contrast, VoiceOver labels for every value (with units), and localized expansion in all six languages.

## Copy and translations

App strings live in `Localizable.xcstrings`, website strings in `apps/website/src/integrations/i18n/messages/*.json`. Write natural copy in each language rather than word-for-word translation, keep placeholders and plural rules, and keep one term per concept across app and website.

- Follow Apple's terminology for each language (Activity Monitor, System Settings, Battery, memory types). Keep **Mac** in Latin script and product, tool and command names unchanged.
- Thermal state values: EN Nominal/Fair/Serious/Critical; RU Норма/Тепло/Горячо/Критично; DE Normal/Erhöht/Hoch/Kritisch; FR Normal/Modéré/Élevé/Critique; ES Normal/Moderado/Grave/Crítica; zh 正常/偏高/过高/危急. The website thermal demo uses the same words.
- Russian uses «лимит зарядки», «ЦП» in compact UI, «Конфиденциальность», «вход»/«сеанс» rather than literal “window”/“sign-in” calques. German uses informal *du* throughout; ES uses *tú*.
- Avoid filler and marketing phrasing; explain unavailable readings and estimates plainly. References: [Apple Russian Mac/battery terms](https://support.apple.com/ru-ru/102397), [memory terms](https://support.apple.com/ru-ru/guide/activity-monitor/view-memory-usage-actmntr1004/mac), [charge-limit behavior](https://support.apple.com/en-us/102338).

## Dependencies and skills

Before building non-trivial functionality from scratch, search native APIs, Swift Package Index and maintained open-source macOS projects. Check macOS 15 compatibility, maintenance and license; prefer the simpler reliable option and record decisions in [research](research/README.md). GPL sources may inform research but must not be copied.

Reviewed project skills live in `.agents/skills/` with `manifest.json` recording source, revision, license and reasons for skipped candidates. Read only the relevant skill; routing is in AGENTS §5. Upstream iOS-only advice (UIKit, `UIScreen`, BGTaskScheduler) does not apply.
