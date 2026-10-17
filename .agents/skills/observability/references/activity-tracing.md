# Activity Tracing and Log Correlation

The problem: a user action fans out across subsystems (UI -> service ->
network -> parser), and each layer logs independently. When something fails,
you need every log line belonging to *that* flow, not the category soup of
three concurrent flows.

## os_activity (the system mechanism)

Activities are the unified logging system's built-in correlation: an activity
is created for a scope of work, log messages emitted within the scope are
tagged with its ID (transitively, across GCD dispatch), and Console.app can
group by activity. UIKit/AppKit create an activity for each user event
automatically.

How the grouping behaves (Console.app > Activities view):

- Log messages emitted while an activity scope is active roll up under that
  activity instead of interleaving in the flat stream - the payoff is
  reading a multi-stage concurrent flow (a sync pipeline: fetch, decode,
  diff, persist) as a tree rather than shuffled lines.
- Activities created inside an active scope become **children** of it by
  default (they inherit `OS_ACTIVITY_CURRENT` as parent); messages logged in
  the parent scope but outside any child appear at the parent level. Pass
  the `detached` flag to force a new top-level activity instead.
- A scope bounds attribution: after `os_activity_scope_leave` (or the
  wrapper's `scope.leave()` / end of the applied block), subsequent logs no
  longer attach to the activity. Leaving early is how you stop attributing
  a long tail of unrelated work.

Reality check for Swift:

- There is **no supported Swift-native API**. `os.activity` exposes only the
  C interface, and the canonical Swift wrapper (used by community samples)
  builds `OS_ACTIVITY_CURRENT`/`OS_ACTIVITY_NONE` via `dlsym` and calls
  `_os_activity_create` / `os_activity_apply` / `os_activity_scope_enter`
  directly. It works, but it is underscore-API territory.
- Activity context follows GCD queues **and XPC calls** (cross-process
  correlation is the one thing only activities give you) but **does not
  propagate through Swift Concurrency** (`Task {}`, `async let`). In an
  async/await codebase, activities silently lose the flows you most wanted
  correlated.
- Debugger tie-in: LLDB's `thread info` prints the current thread's
  activity - a quick way to check what flow a paused thread belongs to.
- `os_activity_label_useraction` labels the system-generated activity for
  the current UI event - callable once, early in an IBAction/gesture handler;
  handy for making Console traces readable on macOS/UIKit codebases.

Verdict: use activities when (a) targeting Objective-C or GCD-structured
Swift, and (b) Console-side grouping is genuinely the debugging workflow.
Minimal wrapper for that case:

```swift
import os.activity

// Objective-C style, GCD-propagating scope:
let activity = _os_activity_create(#dsohandle, "SyncFlow",
                                   OS_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT)
var state = os_activity_scope_state_s()
os_activity_scope_enter(activity, &state)
defer { os_activity_scope_leave(&state) }
// every log emitted here is tagged with the activity
```

## Correlation IDs (the portable mechanism)

For modern Swift codebases, an explicit correlation ID carried through the
flow is simpler, async-safe, and survives export to any backend:

```swift
struct FlowID: Sendable, CustomStringConvertible {
    let raw = UUID().uuidString.prefix(8)
    var description: String { String(raw) }
}

// Thread through the flow explicitly, or via TaskLocal:
enum FlowContext {
    @TaskLocal static var id: FlowID? = nil
}

func startSync() async {
    await FlowContext.$id.withValue(FlowID()) {
        await performSync()
    }
}

func log(_ logger: Logger, _ message: String) {
    logger.info("[\(FlowContext.id.map(String.init(describing:)) ?? "-", privacy: .public)] \(message, privacy: .public)")
}
```

- `@TaskLocal` propagates through structured concurrency (child tasks,
  `async let`, task groups) - exactly where os_activity drops the ball. It
  does not cross into detached tasks unless passed explicitly (usually the
  correct semantics).
- The same mechanism is how OpenTelemetry parents spans across `await`s
  (its `OpenTelemetryConcurrency` module ships a task-local context
  manager) - if the app grows into full distributed tracing, the
  correlation-ID pattern upgrades to OTel spans without changing shape.
  See `production-monitoring.md`.
- Prefix the ID in the message (short, `.public`) so Console/`log`
  searches and your backend can both group by it.
- The same ID belongs in outgoing request headers (`X-Request-ID`) so
  client logs join server logs.

## Activities vs signposts vs correlation IDs

```
Group related LOG LINES for debugging        -> correlation ID (Swift Concurrency)
                                                or os_activity (ObjC/GCD)
MEASURE the flow's duration and stages       -> OSSignposter interval, same ID
                                                across begin/event/end
Both                                          -> both, sharing one generated ID
```

Do not use activities to time anything (they carry no duration semantics in
Instruments), and do not use signpost IDs as log correlation (they do not tag
Logger messages). The two systems share subsystem/category but answer
different questions.
