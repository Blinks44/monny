# Third-Party Observability SDKs

Sentry, Firebase Crashlytics, Datadog RUM, Bugsnag, Embrace, and friends.
This file is about deciding whether you need one, and integrating without
breaking the native stack.

## What they add over the native baseline

| Capability | Native (MetricKit + Organizer + unified logging) | Third-party |
|---|---|---|
| Crash stacks | next-launch delivery, symbolicate yourself, build your own grouping | real-time, server-symbolicated, grouped into issues, alerting, assignment |
| Coverage | all users (MetricKit) / opted-in (Organizer) | all users, plus session context |
| Hangs / OOM / disk / CPU | MetricKit diagnostics - Apple-measured, includes data SDKs cannot capture | ANR/hang detection, OOM heuristics (inference, not jetsam truth) |
| Context | none beyond payload metadata | breadcrumbs, user/session attributes, custom tags, release health |
| Network/RUM | build it yourself | request tracing, screen load waterfalls |
| Dashboards/alerts | build it yourself | included |
| Cost | free; your backend if you export | per-event/per-session pricing + SDK weight + privacy surface |

Rule of thumb: a small app with a working MetricKit-to-backend export may
need nothing else. Teams needing real-time crash triage, issue workflow, or
cross-platform (Android/web) parity buy an SDK. The two are complementary:
keep MetricKit flowing even with an SDK installed - exit reasons, Apple-
measured hangs, and disk-write diagnostics are data the SDKs do not see.

A third path exists: the open-source **KSCrash** is the in-process crash
capture engine several commercial SDKs build on. Pairing it with your own
upload endpoint and symbolication is the DIY route when data residency or
cost rules out vendors - and it counts as your one crash reporter under
the rule below.

## The one crash handler rule

Crash capture works by installing Mach exception handlers and signal
handlers. **Two crash SDKs in one process corrupt each other**: the last
installer wins, chaining is best-effort, and reports get lost or doubled.

- Pick exactly one in-process crash reporter.
- Audit transitive dependencies: analytics bundles sometimes embed crash
  reporting (historically, Firebase pulling Crashlytics) - disable the
  second one explicitly.
- Your own `signal(SIGSEGV, ...)` / `NSSetUncaughtExceptionHandler` counts
  as a crash reporter for this rule.
- MetricKit is exempt: it observes out-of-process and coexists with any SDK.
- Expect crash counts to differ between MetricKit, Organizer, and the SDK -
  different capture mechanisms, delivery timing, and opt-in populations.
  Trend each against itself; do not reconcile them to the decimal.

## Integration rules

- **Initialize first thing in `didFinishLaunching`/App init** - a crash
  before SDK init is invisible to it. Keep init synchronous and fast; every
  SDK on the launch path is on your launch metric.
- **Upload dSYMs from CI per shipped build** (see `symbolication.md`);
  fail the pipeline when upload fails, not silently.
- **Bridge unified logging as breadcrumbs, not as a replacement.** Keep
  `Logger` as the source of truth; forward `error`/`fault` (and selected
  `notice`) messages to the SDK as breadcrumbs/events via a fan-out handler
  (`logger-api.md`), applying your own redaction first - OS privacy
  redaction does not follow the message into the SDK.
- **Scrub PII at the SDK boundary**: configure beforeSend/scrubbing hooks,
  disable automatic capture you did not audit (network request bodies,
  view hierarchies, screenshots on crash).
- **Privacy manifests and disclosure**: the SDK's `PrivacyInfo.xcprivacy`
  plus your App Store privacy labels must cover what it collects (device
  IDs, crash data linked to users, IP-derived location). Review at every
  SDK major bump.
- **Sampling controls cost**: session/trace sampling for RUM-style SDKs is
  set at init - decide the rate deliberately, not at 1.0 by default.
  Consumer-scale apps commonly run traces and profiles at 1% or lower;
  crash and error capture stays at 100%.
- **Remote kill-switch for collection**: performance/RUM collection has
  runtime and battery cost. Wire the SDK's data-collection flag to a
  remote-config value so it can be disabled in the field without a
  release (and re-enabled for an investigation). What network
  auto-instrumentation buys you vs building it natively:
  `network-telemetry.md`.
- Gate SDK init behind consent where your jurisdiction/user base requires
  it, and have a no-op path so the app functions identically without it.

## Bridging pattern

```swift
struct CrashReporterBreadcrumbHandler: LogHandler {
    func log(level: OSLogType, message: String, category: String,
             file: String, line: Int) {
        guard level == .error || level == .fault else { return }
        // message must already be redacted - this leaves the OS privacy sandbox
        SDK.addBreadcrumb(category: category, message: message,
                          level: level == .fault ? .fatal : .error)
    }
}
```

And the reverse direction: attach your correlation/flow ID
(`activity-tracing.md`) as an SDK tag so a crash links back to the unified
log story around it.

## Assert in debug, report in production

For "the user should never get here" states, a plain `assertionFailure` is
a no-op in Release - the impossible state happens in the field and nobody
learns about it. The production-grade version asserts loudly in DEBUG and
reports a non-fatal in Release:

```swift
func reportedAssertionFailure(_ message: @autoclosure () -> String,
                              file: StaticString = #fileID,
                              line: UInt = #line) {
    #if DEBUG
    assertionFailure(message(), file: file, line: line)
    #else
    let text = message()
    Logger.app.fault("Invariant broken: \(text, privacy: .public)")
    SDK.captureNonFatal(title: "Invariant broken: \(text)",
                        context: ["location": "\(file):\(line)"])
    #endif
}
```

Developers and CI hit the hard stop; users keep a working app while the
dashboard collects how often "never" actually happens. Pair it with a
`fault`-level log so the local story (OSLogStore export, sysdiagnose)
records the same event the SDK saw.

## Evaluation checklist when asked "which SDK"

1. What does the team actually lack: alerting? grouping? Android parity?
   (If the answer is "dashboards for MetricKit data", consider exporting to
   Grafana instead - `production-monitoring.md`.)
2. SDK weight: binary size delta, launch-time init cost, background CPU.
3. Data residency and privacy-label impact.
4. Pricing model vs event volume (crash-only is cheap; full RUM is not).
5. Exit strategy: does instrumentation live behind your own facade so the
   SDK is swappable?
