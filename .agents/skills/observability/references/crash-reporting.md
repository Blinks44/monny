# Crash, Hang, and OOM Observability

The first diagnostic question is always: **does this failure mode leave a
report at all, and where does it land?**

## What leaves what

| Failure | .ips crash report | MetricKit | Organizer | Notes |
|---|---|---|---|---|
| Crash (signal / Mach exception / unhandled ObjC exception) | yes | `MXCrashDiagnostic` (next launch) | yes (opted-in users) | The normal case |
| Watchdog kill (launch/resume/background transition too slow) | yes, exception code `0x8badf00d` | crash diagnostic with watchdog termination | yes | ~20s budget for scene transitions |
| Background file-lock kill | yes, `0xdead10cc` | crash diagnostic | yes | held a file/db lock while suspending |
| **OOM / jetsam** | **no report** | `MXAppExitMetric` memory exit counts; iOS 27 `memoryException` diagnostic with stack | partially (as "terminations") | The famous blind spot |
| Hang (main thread unresponsive) | no | `MXHangDiagnostic` (immediate, iOS 15+) | Hangs organizer pane | app kept running |
| Sustained CPU spin | no | `MXCPUExceptionDiagnostic` | Energy pane | background threads over threshold |
| Excessive disk writes | no | `MXDiskWriteExceptionDiagnostic` (~1 GB/day) | Disk Writes pane | |
| User force-quit, OS update, normal exit | no | counted in `applicationExitMetrics` as normal exits | no | do not chase these |

## Reading a crash report (.ips)

Since iOS 15 crash reports are JSON (`.ips`). Read in this order: exception
type first, then the crashed thread, then the clues elsewhere.

- **`exception.type`**: `EXC_BAD_ACCESS (SIGSEGV/SIGBUS)` (invalid memory -
  dangling pointer, overrelease, buffer overflow), `EXC_CRASH (SIGABRT)`
  (unhandled ObjC exception, abort), `EXC_BREAKPOINT (SIGTRAP)` /
  `EXC_BAD_INSTRUCTION (SIGILL)` (Swift runtime traps: `fatalError`,
  force-unwrap of nil, array out of bounds, arithmetic overflow),
  `EXC_CRASH (SIGKILL)` (the OS killed the process - read the termination
  reason).
- **`exception.codes` / termination reason**: watchdog `0x8badf00d`
  ("exhausted real clock time allowance" - launch/transition took too
  long), `0xdead10cc` (held a file lock while suspending), `0xc00010ff`
  (thermal), invalid code signature. Jetsam reports live separately
  (JetsamEvent logs, not app crash reports).
- **`asi` (Application Specific Information) / `lastExceptionBacktrace`**:
  the Swift `fatalError`/precondition message ("Unexpectedly found nil...",
  "Index out of range"), or the ObjC exception message and throwing stack -
  often more useful than the crashing thread. Sometimes withheld on iOS for
  privacy; more complete on macOS/simulator.
- **All thread stacks, not just the crashed one**: other threads show what
  the process was doing (the network call in flight, the queue being
  drained) and expose races - the same class appearing on several threads
  across logs in one crash group is the classic threading-bug signature.
- **`usedImages` + per-frame image index/offset**: what symbolication
  consumes (`symbolication.md`).
- A report whose app frames show only addresses means missing dSYMs, not a
  corrupt report.

Memory-error signatures worth recognizing:

- Crash inside `objc_msgSend` / `objc_release` / deallocation machinery:
  almost always a memory error in *other* code, not where it crashed.
- Bad-access address that looks like a heap pointer rotated/shifted: malloc
  free-list poisoning, i.e. use-after-free.
- `unrecognized selector` on a plausible-looking object: a freed object's
  address was reused by a different allocation.
- `abort` inside `malloc`/`free`: heap corruption or double free.
- Follow up locally with Address Sanitizer or the Zombies instrument once
  the report narrows the suspect area.
- For "where was this object allocated/freed" provenance, enable
  **MallocStackLogging** (scheme > Diagnostics > Malloc Stack Logging >
  All Allocation and Free History): the OS then records a stack trace per
  heap allocation and free. Xcode's Memory Graph Debugger shows the
  allocation backtrace of any selected object in its inspector, and the
  `malloc_history` CLI queries the same records for a paused process.
  History even for freed addresses is exactly what use-after-free
  investigations need - the crash tells you the address, the malloc log
  tells you who allocated and who freed it.

Sources of .ips files: Xcode Organizer (opted-in users), device
Settings > Privacy & Security > Analytics & Improvements > Analytics Data
(users can AirDrop a log to you), Devices & Simulators > View Device Logs,
XCTest result bundles (crashes during test runs are collected and
symbolicated), Console.app (macOS + simulator crashes), sysdiagnose
archives, TestFlight (all testers report crashes; since Xcode 13 TestFlight
crashes appear in the Organizer within minutes, with tester crash feedback
- comments, device, battery, connectivity - attached to the crash group).

Two watchdog gotchas: OS terminations (watchdog, thermal, code-signature)
do not always appear in the Crashes Organizer - check the Devices window or
Console when counts look implausibly low. And the launch watchdog is
**disabled in the simulator and under the debugger** - launch-timeout kills
only reproduce running the app standalone on a device.

## OOM: observing what leaves no report

Jetsam kills the process with no in-process notification and no .ips crash
report. Observability strategy:

1. **Count them**: `MXAppExitMetric` (`applicationExitMetrics`) splits
   foreground/background exits by cause - `memoryResourceLimit`,
   `memoryPressureExit`, plus `watchdogExit`, `badAccessExit`,
   `abnormalExit`, `illegalInstructionExit`,
   `backgroundTaskAssertionTimeoutExit`, `suspendedWithLockedFileExit`,
   `cpuResourceLimitExit`, and `normalAppExit`. Foreground abnormal exits are
   user-visible pain; trend them per release.
2. **Get stacks (iOS 27+)**: `DiagnosticResult.memoryException` finally
   attaches a call stack tree to memory kills.
3. **Heuristic OOM detection (pre-27, if needed)**: on launch, if the
   previous session neither crashed (no crash diagnostic), nor exited
   normally (you persist a clean-shutdown flag), nor was force-quit
   (imperfectly inferable), it was likely an OOM or watchdog - the technique
   third-party SDKs use. Accept the false positives or skip it.
4. **Reduce, not just observe**: Apple's guidance is under **50 MB in the
   background** (smaller is better - jetsam can strike seconds after
   backgrounding) and under ~200 MB across the lifecycle for the oldest
   supported hardware; the footprint limit is the same foreground and
   background. On `didReceiveMemoryWarning` /
   `UIApplication.didReceiveMemoryWarningNotification`, **change policy**
   (stop caching, cap `NSCache` limits, cancel prefetching, drop
   regenerable resources). Do not eagerly iterate large collections to free
   them - the OS has likely compressed those pages, and touching them forces
   decompression, spiking footprint at the worst moment. Prefer `NSCache`
   (auto-evicting, non-copying) over dictionary caches you must drain by
   hand.
5. **Soften the blow**: with state restoration in place, many users never
   notice a background termination - the app resumes instead of relaunching
   from scratch. Jetsam is inevitable; a restored session makes it
   invisible.
6. **Measure the footprint you are defending**: export a `.memgraph` from
   Xcode's Memory Graph Debugger (or target a running process by name) and
   run `vmmap --summary` on it - the `Physical footprint` / peak lines are
   the numbers jetsam judges, and the dirty + compressed columns are what
   to shrink (clean memory pages out harmlessly). Grep the summary by
   framework to attribute the weight (a fat Image IO region usually means
   un-downsampled image decoding). With MallocStackLogging enabled,
   `vmmap -stacks` adds allocation backtraces per region; `leaks` and
   `heap` accept the same `.memgraph` files. Compare memgraphs before and
   after a fix to prove the win.

Background-task timeouts deserve their own note: exceeding the ~30 s
`beginBackgroundTask` allowance kills the app with **no crash log** - only
`MXBackgroundExitData.cumulativeBackgroundTaskAssertionTimeoutExitCount`
counts it. A production-grade detector: drop paired mxSignpost events when
tasks begin/end (and in the expiration handler) and watch for imbalances in
the signpost counts of the daily payload.

## Hangs

- A hang is the main thread failing to update UI or process input because
  it is busy or blocked. Perception thresholds that Apple's tooling encodes:
  under ~100 ms feels instant; tools report hangs from **250 ms** (labeled
  "micro hangs" - still worth fixing, since a micro hang at your desk is a
  severe hang on the oldest supported device under thermal pressure);
  **500 ms+** is labeled a severe hang; over 1 s always reads as stuck.
- The tool per phase: **Thread Performance Checker** (scheme > Diagnostics)
  flags priority inversions and non-UI work on the main thread while
  debugging; **Time Profiler / CPU Profiler label hangs on the timeline**
  (Xcode 14+), plus a standalone hang-tracing instrument with a configurable
  threshold; **on-device hang detection**
  (Settings > Developer > Hang Detection, 250 ms+ threshold, dev-signed and
  TestFlight apps) posts real-time notifications and produces shareable
  text hang logs + tailspins without Xcode; **MetricKit** delivers
  `histogrammedApplicationHangTime` and per-incident `MXHangDiagnostic`
  stacks in the field; **Organizer > Hangs** aggregates opted-in users into
  signatures ranked by share of total hang time, with per-OS/device
  breakdowns (also via the App Store Connect API).
- Triage split: high main-thread CPU during the hang = the work itself is
  too slow (profile it); near-idle CPU = blocked on I/O, a lock, IPC, or a
  lower-priority thread (priority inversion) - System Trace territory,
  where Time Profiler shows nothing.
- Dev-time tripwire: run with the `LIBDISPATCH_COOPERATIVE_POOL_STRICT=1`
  environment variable (scheme > Arguments) to trap unsafe blocking
  primitives on Swift Concurrency's cooperative thread pool - the class of
  bug that surfaces in production as hangs under load.
- Hang time is measured across the whole session. If launch responsiveness
  matters separately (it does), instrument first-input-delay yourself: record
  the first user gesture after launch and measure to the next frame via
  `CADisplayLink`; watch the run loop for >50-100 ms stalls to declare
  "time to interactive". See `production-monitoring.md`.
- The diagnostic stack shows where the main thread was, which is the answer
  ~80% of the time (sync I/O, decoding on main, lock contention). Pair with
  the Time Profiler / swift-concurrency skills for the fix.

## Xcode Organizer panes (Window > Organizer)

Crashes, Hangs, Disk Writes, Energy, Launch Time, Terminations, Feedback,
plus metrics with an **Insights/Regressions** section - aggregated per
version from **users who opted in to sharing analytics**, with about a day
of lag and a minimum-usage threshold before data appears (low-usage
versions show a margin-of-error indicator). Use it for triage and
cross-version trends without building anything; use MetricKit + your
pipeline when you need all users, custom dimensions, or dashboards in your
own tooling.

Workflow features worth knowing:

- Crashes: grouped into signatures ranked by unique devices, filterable by
  product (app / App Clip / watch app / extensions), version/build,
  TestFlight vs App Store, and time period (up to a year); "Open in
  Project" jumps to the crashing line; crash links are shareable with
  teammates; TestFlight crashes arrive within minutes with tester feedback
  attached.
- Regressions: flagged when a metric trends up and the latest version
  exceeds the average of recent versions, grouped across devices and
  percentiles. **Enable regression notifications** (bell button in the
  Regressions view, Xcode 13.2+) - a rising hang rate or termination rate
  is usually the first sign of trouble.
- Disk Writes reports: signatures with the percentage of writes each
  accounts for, plus an insights repository of known anti-patterns (e.g.
  "SQLite table scanned without an index - add one") with documentation
  links. Validate fixes with the File Activity instrument.
- Terminations: exit-reason categories (memory limit, launch timeout, ...)
  comparable across versions, split foreground/background.

The same metrics, insights, and diagnostic signatures/logs are available
programmatically via the App Store Connect **Power and Performance API** -
see `production-monitoring.md`.

## Review checklist for crash observability

- Crash reporting exists beyond "we look at Organizer sometimes": either
  MetricKit diagnostics flow to a backend, or a third-party SDK is wired
  (never both crash *handlers* - `third-party-sdks.md`).
- Every release archives dSYMs (and uploads them wherever stacks are
  symbolicated).
- Exit-reason metrics are tracked per release; a foreground-OOM or watchdog
  regression is treated like a crash-rate regression.
- A clean-shutdown flag or equivalent distinguishes "user closed the app"
  from "the OS killed us" if the team relies on pre-iOS-26 OOM inference.
- Hang data is looked at per release, not only when users complain.
