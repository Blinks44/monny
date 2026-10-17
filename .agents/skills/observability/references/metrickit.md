# MetricKit: Production Metrics and Diagnostics

MetricKit delivers aggregated performance metrics and diagnostic call stacks
from real users' devices directly into your app - no SDK, no backend
required to collect (you provide the backend only if you want fleet-wide
aggregation; see `production-monitoring.md`).

Two API generations:

- **`MXMetricManager` (iOS 13+, macOS 12+)** - the delegate-style API every
  production codebase uses today. Deprecated as of iOS 27 but fully
  functional.
- **`MetricManager` (iOS 27+, WWDC 2026)** - Swift-native replacement,
  rebuilt from the ground up: `AsyncSequence` report streams, typed
  `MetricResult`/`DiagnosticResult` enums, `Codable` reports, launch-task
  tracking, custom app-state domains via the StateReporting framework. All
  new capabilities (memory-exception diagnostics, Metal frame rate,
  state-contextualized metrics) are exclusive to the new API.

## MXMetricManager (iOS 13-25 and current production)

```swift
import MetricKit

final class MetricsSubscriber: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricsSubscriber()

    func start() { MXMetricManager.shared.add(self) }   // call in App init / didFinishLaunching

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // background queue - persist or upload, no UI
            upload(payload.jsonRepresentation())
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            upload(payload.jsonRepresentation())
        }
    }
}
```

Delivery contract:

- **Metric payloads**: at most once per 24h per metric source, covering the
  previous day, delivered shortly after launch/foreground. Multiple payloads
  can arrive at once (undelivered days accumulate; more than one source can
  produce separate payloads).
- **Diagnostic payloads**: iOS 15+ delivers hang/CPU/disk-write diagnostics
  immediately after the event; **crash diagnostics arrive at the next
  launch**. On iOS 13-14 everything was daily - a diagnostic payload arrived
  alongside its companion metric payload, mapping 1:1 to the same window.
- Values arrive in three aggregation shapes: **cumulative** counters (CPU
  time, network bytes), **averages** (pixel luminance, suspended memory),
  and **bucketized histograms** (launch, hang, cellular condition).
- Callbacks arrive **on a background queue**. Subscribing is cheap and safe
  on the launch path.
- `pastPayloads` / `pastDiagnosticPayloads` only return data if the app had
  subscribed before - subscribe unconditionally, early, on every launch.
- If the user deletes the app, undelivered payloads are gone; expect
  systematic under-reporting from churned users.
- Real devices only. Nothing is delivered on the simulator.

### MXMetricPayload contents (headline fields)

| Group | Type | What to watch |
|---|---|---|
| Launch | `applicationLaunchMetrics` | `histogrammedTimeToFirstDraw`, `histogrammedApplicationResumeTime`, `histogrammedOptimizedTimeToFirstDraw` (prewarmed launches, iOS 15.2+), `histogrammedExtendedLaunch` (iOS 16+) |
| Responsiveness | `applicationResponsivenessMetrics` | `histogrammedApplicationHangTime` - main-thread unresponsive time |
| Exits | `applicationExitMetrics` (iOS 14+) | foreground/background exit counts by reason - the only OOM visibility (see `crash-reporting.md`) |
| CPU / GPU | `cpuMetrics`, `gpuMetrics` | `cumulativeCPUTime`, `cumulativeCPUInstructions` |
| Memory | `memoryMetrics` | `peakMemoryUsage`, `averageSuspendedMemory` |
| Disk | `diskIOMetrics` | `cumulativeLogicalWrites` (the 1 GB/day exception threshold's sibling) |
| Network | `networkTransferMetrics` | wifi/cellular up/down |
| Battery-ish | `applicationTimeMetrics`, `locationActivityMetrics`, `cellularConditionMetrics`, `displayMetrics` | foreground/background time, GPS accuracy time, pixel luminance |
| Custom | `signpostMetrics` | your `mxSignpost` histograms |
| Metadata | `latestApplicationVersion`, `includesMultipleApplicationVersions`, `timeStampBegin`/`End`, `metaData` (device type, OS) | version attribution |

Reading the numbers:

- **CPU instructions beat CPU time for cross-device comparison** -
  `cumulativeCPUInstructions` is hardware- and frequency-independent, so it
  quantifies workload changes without clock-speed noise.
- **Launches vs resumes ratio is a health signal**: a well-behaved app
  resumes far more often than it cold-launches. Cold launches dominating
  means the app is being terminated too much (memory footprint, background
  task bugs) - check `applicationExitMetrics`.
- **Scroll hitches** (`animationMetrics.scrollHitchTimeRatio`, iOS 14+):
  hitch time divided by scroll time. Interpretation bands: under 5 ms/s
  users perceive smooth scrolling, 5-10 ms/s frames drop every couple of
  seconds, over 10 ms/s is a visibly bad scroll.
- **Hang rate is derivable**: total hang time over foreground time
  (e.g. 3 s of hangs in 30 min of use = 6 s/hour) gives a fleet-comparable
  responsiveness number; Organizer reports the same unit.

Handling rules learned in production:

- **Check `includesMultipleApplicationVersions`** and treat mixed-version
  payloads separately (or drop them) when comparing versions - the user
  updated mid-window and the numbers blend two builds.
- **Histograms, not raw samples.** Values arrive as `MXHistogram` buckets
  (`bucketStart`, `bucketEnd`, `bucketCount`) in `Measurement` units. When
  exporting to your own histogram system, re-bucket using bucket midpoints
  and convert units exactly once (see `production-monitoring.md` for the
  classic ms-vs-s corruption story).
- `averagePixelLuminance` and friends are `MXAverage` values;
  most others are cumulative counters over the window.
- Not every metric earns a dashboard. Cellular condition, for example, is
  data you can neither influence nor correlate with in-app behavior - export
  the metrics that answer questions you actually ask.
- Exporting through OpenTelemetry? Map by semantics: MetricKit's daily
  aggregates are not live state, so OTel gauges are the wrong target
  (stale "current" values); send value metrics as events with attributes
  and histograms as per-bucket records - see `production-monitoring.md`.

### MXDiagnosticPayload contents

| Diagnostic | Trigger | Notes |
|---|---|---|
| `MXCrashDiagnostic` | crash | signal, exception type/code, `terminationReason` ("Namespace SIGNAL, Code 0xb" style), `virtualMemoryRegionInfo` (vmmap-style neighborhood of the faulting address - distinguishes null deref from use-after-free), iOS 17+ `exceptionReason` (ObjC exception details) |
| `MXHangDiagnostic` | main thread unresponsive beyond threshold (seconds) | `hangDuration` + stack of the hang |
| `MXCPUExceptionDiagnostic` | sustained high CPU (background threads burning CPU over a sustained window) | `totalCPUTime`, `totalSampledTime` |
| `MXDiskWriteExceptionDiagnostic` | > ~1 GB logical writes per day | `totalBytesWritten` + attributed stack |
| `MXAppLaunchDiagnostic` (iOS 16+) | launch exceeding the system threshold | `launchDuration` + stack |

Every diagnostic carries a `callStackTree` - **unsymbolicated**: frames are
`binaryUUID` + `offsetIntoBinaryTextSegment` + `address`. Symbolication
happens off-device with your dSYMs (`symbolication.md`). Do not attempt
on-device symbolication; the dSYM is not on the device.

Diagnostics complement, not replace, a crash reporter: MetricKit gives you
Apple-measured hangs/disk/CPU/OOM context that crash SDKs cannot see, while
crash SDKs give real-time alerting and grouping (`third-party-sdks.md`).

### Custom metrics: mxSignpost and extended launch

```swift
let checkoutLog = MXMetricManager.makeLogHandle(category: "checkout")
mxSignpost(.begin, log: checkoutLog, name: "SubmitOrder")
mxSignpost(.end,   log: checkoutLog, name: "SubmitOrder")   // -> signpostMetrics histogram
mxSignpost(.event, log: checkoutLog, name: "CouponApplied") // -> count
```

Millisecond-scale overhead per emission (it snapshots process state) - use
for a handful of business-critical intervals, not blanket instrumentation.

`extendLaunchMeasurement(forTaskID:)` / `finishExtendedLaunchMeasurement`
(iOS 16+) extend the system's launch measurement past first draw to when
*your* UI is actually usable; results land in `histogrammedExtendedLaunch`.
Register the extension early in launch, and finish it exactly once.

## MetricManager (iOS 27+, Swift-native)

```swift
import MetricKit

let manager = MetricManager()   // keep it alive; or init(enabledStateReportingDomains:)

// Metrics - subscribe at app startup on a detached task / dedicated service
Task.detached(priority: .utility) {
    for await report in manager.metricReports {
        for entry in report.intervalEntries {
            for result in entry.values where result.metricGroup == .memory {
                if case .peakMemory(let metric) = result { process(metric.value) }
            }
        }
        upload(report)   // reports are Codable
    }
}

// Diagnostics
Task.detached(priority: .utility) {
    for await report in manager.diagnosticReports {
        switch report.result {
        case .crash(let crash): handle(crash.callStackTree, crash.terminationCategory)
        case .hang(let hang): handle(hang.callStackTree, hang.hangDuration)
        case .memoryException(let oom): handle(oom.callStackTree)   // new: OOM stacks
        case .cpuException, .diskWriteException, .appLaunch: break
        @unknown default: break
        }
    }
}
```

Structure: each `MetricReport` carries one full-day aggregated interval
entry plus smaller breakdown entries (typically a few hours each, present
only when they contain data); inside an entry, metrics are organized into
groups (`.cpu`, `.memory`, `.display`, `.gpu`, ...). Keep the
`MetricManager` instance alive - the streams stop delivering if it is
released - and start listening at launch to avoid data loss from delayed
subscription.

What is new and worth adopting:

- **`MetricResult`/`DiagnosticResult` enums** replace the payload-object
  zoo; values use `Measurement` and `Histogram` generics. New metrics
  include `hitchTime` (hitch ratio + totals) and `metalFrameRate` (games).
- **`DiagnosticResult.memoryException`** - a call stack when the app or an
  extension is terminated for exceeding its memory limit; the first time
  OOM kills come with evidence.
- **Crash diagnostics carry a `terminationCategory`** that states how the
  crash was accounted for in the exit metrics - abnormal-termination trends
  and individual diagnostics finally correlate directly.
- **`trackLaunchTask(id:)`** replaces `extendLaunchMeasurement`, closure-
  scoped and error-reporting (`maxCountExceeded`, `pastDeadline`, ...).
- **Environment** carries `isTestFlightApp`, `lowPowerModeEnabled`,
  `bundleIdentifier`, versions - filter TestFlight noise server-side.
- Reports are `Codable` (`MetricReport.encodingFormatKey` selects encoding
  shape) - the export pipeline is a `JSONEncoder` away.

### State-contextualized metrics (StateReporting framework)

Fleet-wide averages blend user flows ("scroll hitch rate 15 ms/s" across
all tabs). Reporting app states splits every metric and diagnostic by the
conditions it was collected under (tab A: 1 ms/s, tab B: 71 ms/s - now you
know where to optimize):

```swift
import StateReporting

// 1. A domain (reverse DNS) scopes one dimension of state; register it
//    when configuring MetricManager. One active state per domain;
//    use separate domains for independent dimensions (active tab vs
//    experiment arm) so metrics split by each.
// 2. Report transitions as the app enters states - a transition model,
//    no begin/end pairs; MetricKit tracks time-in-state.
// 3. Optional structured metadata via the @ReportableMetadata macro
//    (e.g. listSize, isSorted) further granularizes entries.
```

State-aware numbers arrive in `report.stateEntries` (empty until you report
states); set `MetricReport.encodingFormatKey` to `.byStateReportingDomain`
on the `JSONEncoder` to group exported JSON by domain. Rules: states are
stable, meaningful phases (not transient UI events); too many states makes
data uninterpretable and there are system caps on state counts; **validate
transitions with the Points of Interest instrument before shipping**.

Keep `MXMetricManager` for any target below iOS 27; both can coexist during
migration but do not double-upload the same day's data.

## Testing MetricKit

- **Device required.** Run from Xcode on a physical device and use
  Debug > Simulate MetricKit Payloads - it delivers a synthetic payload to
  your subscriber within seconds. This validates subscription, parsing, and
  upload plumbing only; the numbers are fake.
- Real payload timing cannot be forced. For end-to-end validation, TestFlight
  the build, use the app for a day, and verify the payload lands in your
  backend (filter by `isTestFlightApp` / TestFlight receipt where relevant).
- Log every received payload count + window via `Logger` so field issues in
  the pipeline itself are diagnosable.
- UI-test-driven perf suites that reinstall the app between runs will never
  see payloads (delivery requires the app to persist across the window).
