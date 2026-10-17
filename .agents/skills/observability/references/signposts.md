# Signposts: OSSignposter, Instruments, and Field Histograms

Signposts measure durations and mark moments using the same
subsystem/category machinery as logging. They are the bridge between your
code and Instruments' timeline - and, via MetricKit, between your code and
production histograms.

## OSSignposter (iOS 15+ / macOS 12+)

```swift
import OSLog

private static let signposter = OSSignposter(
    subsystem: Bundle.main.bundleIdentifier!, category: "networking")
```

Also: `OSSignposter(logger:)` reuses a Logger's subsystem/category,
`OSSignposter(subsystem:category: .pointsOfInterest)` targets the dedicated
Points of Interest instrument track, and `OSSignposter.disabled` is the null
object for gating.

### Intervals

```swift
func fetchRecordings() async throws -> [Recording] {
    let id = Self.signposter.makeSignpostID()
    let state = Self.signposter.beginInterval("FetchRecordings", id: id,
                                              "\(query, privacy: .public)")
    defer { Self.signposter.endInterval("FetchRecordings", state) }

    let (data, _) = try await session.data(for: request)
    Self.signposter.emitEvent("Fetch complete", id: id)   // point-in-time marker
    return try decode(data)
}
```

Rules:

- **One ID per operation instance.** `makeSignpostID()` disambiguates
  concurrent runs of the same-named interval; without distinct IDs,
  overlapping begin/end pairs get cross-matched in Instruments.
  `makeSignpostID(from: object)` derives a stable ID from an object identity
  - it needs a **reference type** (the object representing the work: the
  request, the operation, the cell's model box). Casting a value type
  `as AnyObject` boxes it on the fly; do that only with a deliberate,
  consistent key, not ad hoc per call site.
- **End on every exit path, with the outcome in the end message.** A begin
  whose operation can succeed, fail, or be cancelled needs an explicit end
  in each branch ("finished", "error: ...", "cancelled") - Instruments then
  aggregates durations per outcome, and cancellations become countable
  instead of invisible.
- **Begin and end must use the same name string**, and the `state` returned
  by `beginInterval` must be passed to `endInterval`. The state object
  carries the ID and enforces pairing with runtime assertions in debug
  builds. Exactly one begin and one end per interval.
- State may cross threads and `await`s - intervals spanning async work are
  fine (that is the point). Ending twice or discarding the state without
  ending is a bug.
- For a synchronous block, `withIntervalSignpost(_:id:around:)` wraps
  begin/end around a closure. It is not `async` - for async work use manual
  begin/end with `defer`.
- `beginAnimationInterval` (iOS 16+) marks animation intervals that the
  Animation Hitches instrument understands - use it around scripted
  animations you want hitch-attributed.
- Attach messages sparingly; the same privacy rules as logging apply to
  interpolated values.

### Legacy os_signpost (iOS 12-14 targets)

```swift
let log = OSLog(subsystem: subsystem, category: "networking")
let spid = OSSignpostID(log: log)
os_signpost(.begin, log: log, name: "Fetch", signpostID: spid, "%{public}s", url.absoluteString)
os_signpost(.end,   log: log, name: "Fetch", signpostID: spid, "%d items", count)
os_signpost(.event, log: log, name: "CacheHit", signpostID: spid)
```

Same rules: shared name, shared ID, `.begin`/`.end`/`.event`. Migrate to
`OSSignposter` when the target allows. Begin and end calls may live in
different functions, objects, or files - only the (log handle, name, ID)
triple must match, which is what lets you bracket async work wherever its
entry and exit points actually are.

## Metadata that Instruments can aggregate

Signpost messages are format strings, and Instruments computes statistics
over their arguments - use begin/end messages as data, not decoration:

- **Outcome as the end message**: end an interval with "cancelled" vs
  "finished with size %d" and the os_signpost summary breaks durations down
  per outcome (cancelled downloads averaging far shorter than completed
  ones is the expected shape).
- **Attach distinguishing metadata to at least one side**: begins and ends
  with no message all lump together in the aggregation table, leaving only
  per-instance timeline clicks to tell 20 identical intervals apart.
- **Engineering types**: annotate an argument as
  `"finished, size %{xcode:size-in-bytes}d"` and Instruments treats it as a
  byte size - the metadata-statistics view then sums/averages it ("80 MB
  downloaded this session"). Other engineering types exist for durations,
  bandwidth, etc. (Instruments > Help > Instruments Developer Help).

## Instruments integration

- Profile with the **os_signpost** instrument (Blank template, add from the
  library, or it is included in several templates). Each subsystem/category
  gets a row; intervals render as bars, events as ticks; the detail table
  aggregates count/min/max/avg duration per category > name > begin/end
  message.
- The **Points of Interest** track picks up signposts emitted on a
  `.pointsOfInterest` category - use it for coarse app milestones (launch
  phases, screen transitions) that give every other instrument context. It
  is included in the Time Profiler template by default, doubles as the
  navigation aid for filtering a trace to one operation (right-click an
  interval > filter), and is how you validate iOS 27 StateReporting
  transitions before shipping. A classic milestone set for launch work:
  will/didFinishLaunching, viewDidLoad, viewWillAppear, viewDidAppear,
  first-content-cell-displayed - the gaps between events localize where
  time-to-first-content goes (storyboard load, layout, first fetch).
- **Counts diagnose bugs, not just durations.** The interval count and the
  number in flight at once (scrub the timeline) expose work that should not
  exist - e.g. far more load intervals than visible cells means the table
  is prefetching phantom rows, and a burst of "cancelled" ends right after
  launch means requests are started and immediately torn down. Signposts
  routinely surface over-fetching that no duration statistic would show.
- **Recording mode matters at high volume**: Instruments' default immediate
  mode streams every signpost live, bypassing the OS buffering that makes
  signposts cheap. Emitting thousands per second (game engines), switch to
  windowed recording (hold the record button > Recording Options > Last N
  seconds) so the OS buffers and Instruments collects at the end.
- **Run Comparisons (Instruments 27)** diff two traces; filtering both runs
  to the same signpost interval is what makes the before/after comparison
  apples-to-apples.
- **Traces are scriptable and exportable via `xctrace`**
  (`xctrace record --template 'Time Profiler' --launch MyApp`, plus
  `export`, `import`, `symbolicate`, `list`): capture on CI without the
  GUI, export instrument tables as XML, re-symbolicate a trace with dSYMs.
  For hand-off to another tool (or an AI agent), the GUI route is: signpost
  detail view > List: Intervals > copy, and for the call tree select the
  root and Deep Copy with "Separate by Thread" + "Hide System Libraries"
  applied - both paste as plain text.
- Signposts are near-zero cost when no one is recording; **keep them in
  release builds** - profiling release builds is exactly when you need them.
  If a signpost is truly high-frequency, gate it:

```swift
static let signposter: OSSignposter = ProcessInfo.processInfo
    .environment["SIGNPOSTS_VERBOSE"] != nil
    ? OSSignposter(subsystem: subsystem, category: "verbose")
    : .disabled
```

  Both scheme knobs work for this: environment variables read via
  `ProcessInfo.processInfo.environment` (process-scoped, cannot leak into
  production), and `-Name value` launch arguments, which surface through
  `UserDefaults` - handy when the same toggle should also be settable from
  a debug menu.

- For very complex domains, a custom Instruments package (an Xcode
  Instruments Package project producing an .instrpkg - an XML definition of
  table schemas over your signpost data, optional CLIPS modelers, and
  custom graphs/details) reshapes signpost data into team-shareable
  domain-specific views; a useful one can be ~100 lines of XML. Worth it
  only once the standard os_signpost instrument view demonstrably does not
  scale to your data.
- Instrumentation-only expensive work (building a debug description just
  for a signpost message) can be gated on `signposter.isEnabled` / the
  legacy `OSLog.signpostsEnabled` so it costs nothing when nobody records.

## XCTest performance metrics

`XCTOSSignpostMetric` measures a signposted region inside a performance test,
turning an instrumented interval into a CI-regression gate:

```swift
func testFetchPerformance() {
    measure(metrics: [XCTOSSignpostMetric(subsystem: "com.example.app",
                                          category: "networking",
                                          name: "FetchRecordings")]) {
        // exercise the code path that emits the interval
    }
}
```

`XCTApplicationLaunchMetric`, `XCTClockMetric`, `XCTCPUMetric`,
`XCTMemoryMetric`, `XCTStorageMetric` complement it; `measure` records
baselines in the xcbaseline file so regressions fail the test.

## Field histograms: mxSignpost

`mxSignpost` (MetricKit) wraps `os_signpost` and additionally snapshots
process state so the system can aggregate your intervals into
`MXSignpostMetric` histograms delivered with the daily payload:

```swift
import MetricKit

let checkoutLog = MXMetricManager.makeLogHandle(category: "checkout")

mxSignpost(.begin, log: checkoutLog, name: "SubmitOrder")
// ... work ...
mxSignpost(.end, log: checkoutLog, name: "SubmitOrder")   // histogram of durations
mxSignpost(.event, log: checkoutLog, name: "CouponApplied") // count
```

- Overhead is higher than plain os_signpost (state capture, roughly
  millisecond scale). Instrument the handful of business-critical intervals,
  not all thousand signposts.
- Begin/end pairs produce duration histograms in the payload; events produce
  counts. Read them from `MXMetricPayload.signpostMetrics`.
- On iOS 27's new API the equivalent is `MetricManager.logHandle(category:)`
  and the `signpostInterval` metric result - see `metrickit.md`.

## DTrace: tracing code you cannot instrument (macOS + simulator)

Signposts require owning the code; DTrace attaches probes to *any* running
process without rebuilding anything - it is the machinery under parts of
Instruments. Constraints up front: **requires SIP disabled** and `sudo`,
and it does **not run on iOS devices** - simulator processes and macOS
apps only. That makes it a dev-machine investigation tool, never a
production one.

A probe is `provider:module:function:name` plus an optional
`/ predicate /` and `{ action }`:

```bash
# every ObjC method of classes matching a pattern, in one process
sudo dtrace -n 'objc$target:MyStore*::entry' -p $(pgrep -x MyApp)

# stack trace whenever a specific selector runs (? wildcards one char, so
# it matches the ':' in the selector)
sudo dtrace -n 'objc$target:MyStore:-refresh?:entry { ustack(); }' -p $(pgrep -x MyApp)

# count calls per class instead of streaming them: aggregations print on Ctrl-C
sudo dtrace -n 'objc$target:::entry { @[probemod] = count(); }' -p $(pgrep -x MyApp)

# which files does this process open? (syscall provider + copyinstr)
sudo dtrace -n 'syscall::open*:entry /pid == $target/ { printf("%s", copyinstr(arg0)); }' -p $(pgrep -x MyApp)
```

Grammar notes: the `objc` provider maps module = class, function =
`-`/`+` method, name = `entry`/`return`; the `pid` provider probes any C
or Swift function in any loaded module; `$target` binds to the `-p` PID.
Predicates (e.g. `/ arg0 == 0x... /`) gate the action - with `objc`
probes, `arg0` is the receiver, so a predicate on it traces one specific
instance. Two safety rules: **dry-run wide patterns with `-l`** (lists the
matched probes without running them - an unfiltered `objc$target:::` can
match hundreds of thousands) and keep destructive actions (`-w`,
`stop()`, `system()`) out of anything you did not write yourself.

When to reach for it over signposts/Instruments: counting or stack-tracing
calls in system frameworks or third-party binaries, watching syscalls
(file opens, spawns) without a File Activity trace, or answering "who
calls this?" in a process you cannot rebuild.

## Choosing the mechanism

```
See it in Instruments while profiling        -> OSSignposter
Milestones visible across all instruments    -> OSSignposter on .pointsOfInterest
Duration distribution from production        -> mxSignpost histogram
Guard against regression in CI               -> XCTOSSignpostMetric over the same signpost
A one-off timestamped message                -> you probably still want a signpost
Trace code you cannot rebuild (dev machine)  -> DTrace probes
```
