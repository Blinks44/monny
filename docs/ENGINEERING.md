# Monny: engineering standards

Read before changing app code or choosing a reading/charging mechanism. Workflow and design ownership live in [AGENTS](../AGENTS.md), [WORKFLOW](WORKFLOW.md) and [DESIGN](DESIGN.md).

## Platform and baseline

- **macOS 26+ on Apple silicon only** (user decision 2026-10-18). Intel Macs are out of scope; Release builds should target `arm64` only (set in the release task).
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

- Register with `SMAppService.daemon(plistName:)`; an explicit connection retry may re-register an approved item once after transport failure, without unregistering. Refresh/startup never register. The user approves it in System Settings. No `SMJobBless` or manual launchd plists. Removal requires a compatible authenticated non-controlling/restoration acknowledgement, including the manual-verification helper. No transport-failure bypass in live operations. Historical non-writing fixtures retain that explicit exception; malformed, mismatched or restoration-failure replies fail closed.
- XPC: the helper validates the connecting client's code-signing requirement (expected identifier and same validated signer: Apple anchor/team or an exact certificate pin for the experimental self-signed path) before accepting any message, exposes bounded native-limit apply/restore, status, explicit diagnostics/verification and removal acknowledgement and never runs shell commands.
- Fail safe: on helper start, client disconnect without an active policy, uninstall or an unknown SMC key, restore default macOS charging. Define and test behavior across sleep/wake.
- Native-setting transactions must checkpoint before setters and recover the original pair before new commands on restart. Never accept a journal path from IPC; the fixed root-owned private location, single executor ownership and restart availability must be verified before enabling production writes ([BAT-013](tasks/BAT-013-native-recovery-journal.md)).
- Native UI sessions retain one authenticated owner connection, renew a fixed 30-second lease every 10 seconds and never replay on startup/wake. Build 12 preserves existing native-limit ownership/journal through sleep, suspends its deadline, validates read-back on wake and rearms a 30-second awake window without setters. Legacy injected SMC modes still restore before sleep. Native request/renewal timing uses SuspendingClock so sleeping time does not cause a false timeout. The registered daemon uses KeepAlive so journal restoration can run after an unexpected process exit; OS availability and synchronous private-API stalls remain runtime limits. The expired owner token is revoked before restoration, including restoration failure, and command admission rechecks validity after expiry. Build 12 requires native session revision 3 before enabling control; older helpers remain readable/removable through the unchanged protocol-1 status/removal contract. Positive capability advertisement is required before any new selector is sent ([BAT-018](tasks/BAT-018-native-limit-interface.md)).
- Explicit adapter diagnostics use a separate positively advertised selector and fixed CHIE/CH0I/CH0J allowlist; status/legacy charge diagnostics never start it. One off-main cached/coalesced read per helper process, with session/lifecycle revalidation after suspension; readability never grants write support ([BAT-021](tasks/BAT-021-adapter-diagnostics.md)).
- Adapter verification preparation reuses secure recovery storage with fixed native/adapter namespaces; native defaults/schema remain unchanged. The injected three-second transaction is not a live watchdog or writer. Injected single-owner startup/expiry/disconnect/sleep/removal recovery is covered; a helper-only compile condition includes a fixed CHIE setter; full physical-mode source acquisition remains unbound. Physical cable evidence needs an explicit independent provider; never derive it from source selection or default missing readings. Build 16 supplies a pulse-only backend; full physical verification remains adapterVerificationAvailable=false. The full-isolation revision-1 selector/CLI is prepared with injected backends only; reserve the entire request across awaits and require independent post-rollback evidence before a success exit ([BAT-024](tasks/BAT-024-adapter-verification-ipc.md)) ([BAT-022](tasks/BAT-022-adapter-verification-preparation.md)).
- Read-only cable evidence is collected by an app-only, unprivileged command with strict allowlisted fields and no SMC/XPC/native-limit access. Treat raw connection flags and adapter descriptions as unverified observations, never as a production physical-presence provider. Diagnostic routing must bypass eager app-model/reader creation ([BAT-023](tasks/BAT-023-adapter-power-observation.md)).
- The injected no-dwell byte-research core records unknown raw/source readings without relaxing normal physical verification. It shares checkpoint recovery, never writes native settings and permits absent native data during isolation to avoid an extra private getter there. Build 16 adds a separately advertised revision-1 pulse selector/CLI, fixed journal startup recovery before native recovery, known-open-lid admission and no native getter during isolation. It performs one synchronous executor turn with no dwell or retry; synchronous stalls remain a runtime limitation. No UI invokes it and no hardware execution is implied ([BAT-025](tasks/BAT-025-adapter-byte-pulse.md)).
- Build 17 separately advertises bounded byte observation (revision 1): one isolation attempt, up to two seconds/eight reads within the three-second watchdog budget, reservation across awaits and telemetry-independent rollback. Zero exit requires battery/no-charge observation, byte-zero rollback, matching native endpoints and an observed adapter-source return. This research capability never supplies independent physical presence or enables Discharge ([BAT-026](tasks/BAT-026-bounded-adapter-observation.md)).
- Build 18 observation revision 2 adds an independent two-second/eight-read post-rollback settling window, only after zero-byte acknowledgement/journal clearance. It keeps request reservation, validates zero before each read and never extends isolation or retries setters. Explicit return status/count distinguish delayed publication, bounds and interruption. The CLI timeout is seven seconds; old observation helpers are refused before the selector.
- Build 19 adds additive process-instance/startup adapter-recovery receipts and a separate explicit revision-1 self-termination experiment. After checkpoint/known-eight admission only the helper may exit itself once; there is no PID/signal/path input. Client mutation is never replayed and recovery requires a new instance with actual pending-eight-to-zero receipt, native preservation and adapter source. KeepAlive restart has no hard deadline; do not run this selector without scoped hardware authorization ([BAT-027](tasks/BAT-027-adapter-restart-recovery.md)).
- Build 20 records per-instance versioned sleep/wake/removal-preparation counts and outcomes through authenticated diagnostics. Set sleeping phase before lease validation so failure can retry on wake; removal-state wake recovery retains the removal gate. Receipt delivery at idle does not prove active adapter recovery on real sleep/removal ([BAT-028](tasks/BAT-028-adapter-lifecycle-evidence.md)).
- Build 21 adds separate typed active-sleep preparation on a retained authenticated owner connection. It never labels an isolated adapter idle. Only the ordinary app requests system sleep; the helper keeps its unchanged three-second watchdog and restores before acknowledging sleep. Same-instance paired callback/native/source evidence is required after wake; timer rollback before sleep cannot count as active recovery ([BAT-029](tasks/BAT-029-active-adapter-sleep.md)).
- Build 22 arms app-only workspace sleep/wake observation before preparation/request, buffers early paired wake and waits with a separate 60-awake-second transition bound. The unchanged 15-second/30-read helper collection starts afterward; workspace wake alone never proves restoration. Helper revision 1 and the three-second hardware watchdog are unchanged.
- Build 23 adds purpose-specific revision-1 removal preparation using the same lifecycle session/checkpoint core. Existing removal acknowledgement must prove active restoration and native preservation before one async SMAppService unregister; direct app CHIE/source checks afterward never open XPC or re-register. Actual removal needs scoped authorization ([BAT-030](tasks/BAT-030-active-adapter-removal.md)).
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
