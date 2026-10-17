# Anti-Patterns

Common mistakes in logging and telemetry code, with fixes. Ordered roughly by
how often LLM-generated code contains them.

## Logging

### 1. `print` / `NSLog` as the logging mechanism

`print` goes to stdout: invisible without a debugger, never persisted, no
metadata, no filtering. `NSLog` is synchronous and slow.

```swift
// Before
print("Fetched \(items.count) items")

// After
Logger.networking.info("Fetched \(items.count) items")
```

### 2. String-taking wrapper defeats lazy interpolation

```swift
// Before - describe(payload) executes on EVERY call, logging enabled or not
func appLog(_ s: String) { Logger.app.debug("\(s)") }
appLog("payload: \(describe(payload))")

// After - direct Logger use; interpolation evaluates only if captured
Logger.app.debug("payload: \(describe(payload))")
// (if a facade is required, take @autoclosure () -> String)
```

The wrapper also collapses the whole message into one interpolated value,
losing per-value privacy annotations.

### 3. Pre-building messages by concatenation

```swift
// Before - privacy annotations impossible, eager evaluation
let msg = "User " + user.email + " logged in from " + ip
logger.info("\(msg)")

// After
logger.info("User \(user.email, privacy: .private(mask: .hash)) logged in from \(ip, privacy: .private)")
```

### 4. PII marked `.public` (or blanket-public "because <private> is annoying")

```swift
// Before
logger.info("Login for \(email, privacy: .public), token \(token, privacy: .public)")

// After - correlate without revealing; never log secrets at all
logger.info("Login for \(email, privacy: .private(mask: .hash))")
```

Persisted messages are readable by anyone with the device. Tokens, passwords,
and auth headers should not be logged even privately.

### 5. Expecting `debug`/`info` to be there later

`debug` is never persisted; `info` only during a live `log collect`. A
support flow reading OSLogStore, or a sysdiagnose, will not contain them.

```swift
// Before - "why is the support log empty?"
logger.debug("Sync finished with \(count) changes")

// After - essential troubleshooting record persists
logger.notice("Sync finished with \(count) changes")
```

### 6. `error`/`fault` for expected conditions

Cache misses, cancelled tasks, user typos are not errors. `fault` captures
extra process state (expensive) and pollutes the signal support filters by.
Reserve `error` for real failures the app handles, `fault` for bugs.

### 7. One category for the whole app

`category: "app"` makes Console filtering useless. One category per
functional area/module; subsystem = bundle ID.

### 8. Logging in per-frame or tight-loop paths

Even unified logging has per-call cost. A message per scroll tick or per cell
render floods the store and evicts the history you needed. Use a signpost
interval (aggregatable) or delete it.

### 9. Re-emitting formatted log strings to files/SDKs without redaction

OS privacy redaction protects the OS store only. A fan-out handler that
writes the rendered message to a file or crash-SDK breadcrumb ships the
private values. Redact before the message leaves the process.

## Signposts and measurement

### 10. Timestamped log lines instead of signposts

```swift
// Before
let start = Date()
let result = try await load()
logger.info("load took \(Date().timeIntervalSince(start))")

// After - visible in Instruments, aggregatable, pairs with MetricKit
let id = signposter.makeSignpostID()
let state = signposter.beginInterval("Load", id: id)
defer { signposter.endInterval("Load", state) }
let result = try await load()
```

### 11. Shared/missing signpost IDs for concurrent operations

Concurrent intervals with the same name and no distinct ID cross-match their
begin/end pairs in Instruments. `makeSignpostID()` per operation instance.

### 12. Signposts stripped from release builds

`#if DEBUG` around signposts makes release-build profiling (the build that
has the real optimizations) blind. Signposts are near-free when not
recorded - keep them; gate only genuinely high-frequency ones behind
`OSSignposter.disabled`.

### 13. Blanket mxSignpost conversion

`mxSignpost` snapshots process state per emission (millisecond scale).
Converting every os_signpost to mxSignpost measurably slows the app. Pick
the few business-critical intervals for field histograms.

### 14. Benchmarking with a log stream or immediate-mode Instruments attached

Live streaming (Console.app, `log stream`, Xcode console) adds an IPC to
every log call, and Instruments' default immediate mode does the same to
every signpost - both bypass the buffering that makes emission cheap.
Numbers measured that way overstate logging cost. Benchmark detached; for
signpost-heavy apps record in windowed ("last N seconds") mode.

## MetricKit

### 15. Testing on the simulator

MetricKit delivers nothing on simulators. Physical device + Xcode's
Debug > Simulate MetricKit Payloads for plumbing; TestFlight + a day of
patience for real payloads.

### 16. Late or conditional subscription

```swift
// Before - subscribed when the debug screen opens; pastPayloads empty,
// days of payloads never delivered
if showDiagnostics { MXMetricManager.shared.add(subscriber) }

// After - unconditional, on every launch, in App init
MXMetricManager.shared.add(MetricsSubscriber.shared)
```

### 17. UI work in the subscriber callback

`didReceive` arrives on a background queue. Touching UI there crashes or
warns; heavy synchronous processing delays delivery. Persist/forward, hop to
the main actor only for display.

### 18. Unit confusion when exporting histograms

MetricKit values are `Measurement`s (typically seconds); ingestion often
expects ms. Multiplying already-converted values by 1000 (or not converting
at all) corrupts dashboards silently. Convert once, at a named boundary,
with a unit test asserting the conversion.

### 19. Comparing versions across mixed-version payloads

`includesMultipleApplicationVersions == true` means the window blends two
builds. Segment or drop those payloads when doing per-version analysis; and
remember users lingering on the old version are not a random sample.

## Launch measurement

### 20. Self-measured launch from process start, post-iOS 15

Prewarming starts the process minutes before the tap: process-start-based
measurement produces absurd outliers, and clamping them (">10s = discard")
hides genuinely slow users. Check `ProcessInfo.processInfo.environment["ActivePrewarm"]`
or prefer MetricKit's launch histograms which already separate prewarmed
launches.

### 21. Monitoring only p95 (or only averages)

p95 misses regressions in the middle of the distribution; averages are
dominated by tails. Watch p50 + p95 + mean, or a bounded 0-100 score index
(`production-monitoring.md`).

## Crashes and memory

### 22. Two crash reporters

Two SDKs (or an SDK plus your own signal handlers) corrupt each other's
reports - last installer wins. One in-process crash reporter, ever;
MetricKit coexists because it is out-of-process.

### 23. Waiting for OOM crash reports

Jetsam kills leave no crash report. Track `MXAppExitMetric` memory exit
reasons (and `memoryException` diagnostics on iOS 27); infer via
clean-shutdown flags if needed pre-27.

### 24. Freeing compressed memory on memory warning

Eagerly iterating big collections to "free memory" on
`didReceiveMemoryWarning` forces decompression of compressed pages, spiking
footprint at the worst moment. Change policy instead: cap `NSCache`, stop
prefetching, drop regenerable data by releasing references (not by walking
them).

### 25. Shipping without archiving/uploading dSYMs

Unsymbolicated production stacks are permanent if the dSYMs for that exact
build (UUID-matched) are lost. Archive per release; upload from CI to
wherever symbolication happens; fail loudly on upload errors. Related:
symbolicating with `atos` but without `-i` silently drops inlined frames -
release-build stacks look shallower than the real call chain.

### 26. Testing watchdog behavior in the simulator or under the debugger

The launch watchdog is disabled in both. An app that takes 25 s to launch
passes every desk test and then gets `0x8badf00d`-killed (and App Review
rejected) in the field. Test launch standalone on the oldest supported
device.

### 27. Treating the Crashes Organizer as the full termination picture

OS terminations (watchdog, thermal, code-signature kills) do not reliably
appear there, OOMs never do, and Organizer only covers opted-in users. Read
the Terminations pane and `MXAppExitMetric` alongside the crash list before
declaring a release stable.

## Process

### 28. Optimizing production problems from local guesses

If it only reproduces in the field, the first release adds the
metric/diagnostic that would prove the hypothesis; the second fixes it.
Shipping a speculative fix with no measurement burns a release cycle to
learn nothing.

### 29. Swallowed errors

```swift
// Before
catch { }

// After - every error path leaves a record
catch {
    Logger.sync.error("Snapshot upload failed: \(error.localizedDescription, privacy: .public)")
}
```

### 30. Blocking the main thread on OSLogStore

Enumerating the store takes seconds on long histories. Fetch on a background
task, bounded by `position(date:)`.

### 31. Uploading logs without user action

Silently exfiltrating the log store is an App Review and GDPR problem, and
OSLogStore contains values the OS redacts from everyone else. Export must be
user-initiated, scoped to your subsystem, and re-redacted.

## Network telemetry

### 32. Reporting every transport error as a non-fatal

Offline at request time, connection lost on a Wi-Fi/cellular switch, and
cancellations of superseded requests are everyday mobile life. Reported
individually they bury the decode/validation failures that actually mean a
bug - and at volume they can also starve the SDK's breadcrumb attachment.
Count the benign classes as aggregate rates; report only the classes that
should never happen (`network-telemetry.md`).

### 33. The raw transport error as the report identity

Crash SDKs group and title non-fatals by error domain and code. Every
`URLError` shares one domain, so hundreds of distinct problems collapse
into a couple of indistinguishable dashboard rows (gRPC-style transports
are worse: one domain, one generic status). Wrap in a custom error whose
readable description becomes the issue title and whose `userInfo` carries
the endpoint template, status, and a compact state timeline.
