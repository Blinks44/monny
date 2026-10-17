# Production Monitoring: Pipelines, Aggregation, and Not Fooling Yourself

Collecting signals is the easy half. This file covers turning MetricKit
payloads and custom events into dashboards that detect regressions instead of
manufacturing them.

## Lab vs field

| | Perf lab (device farm, XCTest metrics, CI) | Field telemetry (MetricKit, own events) |
|---|---|---|
| Stability | High - same devices, same scenario | Noisy - every device, thermal state, competing apps |
| Latency | Per-commit; bisect regressions automatically | Days - release, adoption, accumulation |
| Representativeness | Only the configs you built | The actual fleet |
| A/B experiments | No | Yes - compare cohorts within one version |

Use both: the lab catches regressions before release (XCTest `measure` with
baselines, per-commit runs, statistical comparison across N runs - discard
the first warm-up runs, the device heats up); the field validates that lab
wins are real and catches what the lab cannot model. Comparing *versions* in
the field is biased - stragglers on the old version are not a random sample.
Prefer within-version cohort comparison or phased-release comparison.

Lab specifics that pay off immediately: every new XCTest UI-test target
ships a free launch-time test (`XCTApplicationLaunchMetric`); `measure`
blocks accept memory/CPU/storage/clock/signpost metrics for cheap A/B
comparisons of two implementations; run performance tests **without the
debugger attached and with sanitizers off** (both distort numbers, and the
watchdog is disabled under the debugger); baseline on the oldest supported
hardware. In Instruments 27, Run Comparisons diff two traces node-by-node
(filter both runs to the same os_signpost interval first) to verify a fix
with data instead of vibes.

## The pipeline Apple already runs: the Power and Performance API

Before building anything, know what App Store Connect gives you for free.
The Organizer's metrics, insights, and diagnostics are all available
programmatically (App Store Connect API, JWT-authenticated GET requests):

| Resource | Returns |
|---|---|
| `perfPowerMetrics` for an app ID | aggregated metrics (battery, launch, hang rate, memory, disk writes) for the ~8 most recent versions, p50 and p90 per device class, **plus smart insights** - auto-flagged regressions with a summary string and the impacted devices/percentiles |
| `perfPowerMetrics` for a build ID | the same metrics for one specific version |
| `diagnosticSignatures` for a build ID | top diagnostic signatures (disk writes, hangs), each with a normalized `weight` (relative importance) and a logs URL |
| `diagnosticLogs` for a signature ID | anonymized per-device logs with call stack trees (same JSON shape as MetricKit's `callStackTree`) |

Wire these into the alerting pipeline you already have; the insights feed
alone is a serviceable regression detector (a regression is flagged when a
metric trends up and the latest version exceeds the recent-version
average). Caveats: opted-in users only, ~a-day lag, aggregates only - it
complements rather than replaces a MetricKit export when you need all
users, custom dimensions, or same-day data.

## Pipeline shape

```
App (MetricKit subscriber + custom events)
  -> serialize (jsonRepresentation() / Codable reports)
  -> batch + upload (background URLSession, retry, 30-60s debounce or N-event cap)
  -> ingestion (your API / Telegraf-style agent / OTLP collector)
  -> time-series store (VictoriaMetrics / Prometheus-compatible / ClickHouse)
  -> dashboards + alerts (Grafana)
```

## OpenTelemetry as the custom pipeline

Before inventing a wire format, consider **opentelemetry-swift**
(github.com/open-telemetry/opentelemetry-swift, SPM): the vendor-neutral
standard whose OTLP output any backend ingests (Grafana Cloud, Datadog,
Honeycomb, a self-hosted collector). Products to link: `OpenTelemetryApi`,
`OpenTelemetrySdk`, the OTLP HTTP exporter targets, and
`OpenTelemetryConcurrency`.

Setup is three provider registrations at startup, each wrapping an OTLP
exporter pointed at `<endpoint>/v1/metrics`, `/v1/traces`, or `/v1/logs`
with an auth header (`OtlpConfiguration(headers:)`; Grafana Cloud uses
`Authorization: Basic <token>`). Attach a **resource** to each provider
(the `ResourceExtension` product's default resources auto-populate app,
device, and OS identity) - telemetry without resource attributes arrives
at the backend with no service name, and nothing can be filtered or
grouped:

- **Metrics**: `registerMeterProvider` with a `PeriodicMetricReader`
  (interval = your upload cadence). Instruments via
  `meterBuilder(name:)` then `gaugeBuilder` / `counterBuilder` /
  `histogramBuilder(...).setExplicitBucketBoundariesAdvice(...)`.
- **Traces**: `registerTracerProvider` with a span processor
  (`SimpleSpanProcessor` to start; batch in production). Spans via
  `tracerProvider.get(instrumentationName:instrumentationVersion:)`,
  `spanBuilder(spanName:).setParent(...).startSpan()`, `setAttribute`,
  `span.status`, `end()`.
- **Logs/events**: `loggerProvider.loggerBuilder(...)`;
  `logRecordBuilder().setBody(...)` for logs,
  `eventBuilder(name:).setData([String: AttributeValue])` for structured
  events; `setSpanContext(span.context)` links either to a span so the
  backend can show "logs for this span".

Semantics that decide correctness (misuse produces wrong dashboards, not
errors):

- **Gauge** = last-value state, sampled continuously while the app runs.
  App-level quantities only (memory footprint, active-session flag); a
  screen-scoped gauge keeps reporting its stale last value after the
  screen closes, and zeroing it lies differently.
- **Counter** = monotonic accumulator; dashboards graph its **rate of
  change**, not the total.
- **Histogram** = distribution with explicit bucket boundaries you choose;
  backends render repeated submissions as a heatmap of the distribution's
  change over time. Boundaries make or break legibility (same rules as
  the bucket guidance above).
- **Span hierarchy** beats flat spans: child spans (`setParent`) turn
  interleaved multi-user timelines into per-operation trees - name the
  parent per user flow, children per stage, attributes for inputs/counts
  that explain duration variance.

Context propagation and API design:

- A `@TaskLocal` current-span (the same mechanism as the correlation-ID
  pattern in `activity-tracing.md`) parents child spans across `await`s
  without threading span parameters through every API. Better: link
  `OpenTelemetryConcurrency` and call
  `registerDefaultConcurrencyContextManager()` - span context then flows
  through Swift Concurrency automatically.
- Expose tracing to the team as a `withSpan("name") { span in ... }`
  closure (the swift-distributed-tracing shape): the wrapper owns
  `defer { span.end() }`, catches errors to set `span.status = .error` and
  attach an error log before rethrowing, stamps `#function`/`#fileID`/
  `#line` as attributes, and parents from the task-local. Hand-managed
  begin/end spans get leaked by early `guard` returns; the closure shape
  makes that impossible.
- **Cost is volume times fleet size.** Gate every emit behind a comparable
  verbosity-level enum checked at the facade (`guard level >= threshold`),
  with `withSpan` degrading to running the closure span-less. Drive the
  level from a remote flag so an investigation can raise verbosity for a
  cohort without a release.
- **PII discipline doubles here**: auto-instrumented network spans that
  capture headers or bodies ship auth tokens and profile data to a
  third-party store every engineer can query. GDPR counts indirect
  identifiers (user IDs) as personal data. Strip at the facade, same rule
  as `logger-api.md`'s redaction boundary.

When exporting **MetricKit payloads through OTel**, map types by their
semantics, not their names: daily aggregates of past sessions are not live
state, so a gauge is the wrong target (it would freeze yesterday's value as
"current") - send value metrics as **events with attributes**; and MetricKit
histograms carry absolute daily bucket counts while OTel histograms are
rate-of-change instruments - export them as **per-bucket records** (bucket
label + count) and reassemble the heatmap server-side.

Design rules:

- **Tag every point** with app version, build, OS version, device class, and
  the metric name. Version is the dimension every investigation slices by.
- **Stamp exported points with the payload's window** (`timeStampBegin`/
  `End`), not ingest time - a MetricKit payload describes the previous
  day, and upload-time stamping shifts every chart by a day (more for
  users who launch infrequently), blurring incident timing.
- **User/device identifiers are your choice, not MetricKit's** - payloads
  are anonymous; attach your own IDs at upload time if (and only if) your
  privacy policy covers it.
- **Histograms travel as buckets.** MetricKit gives bucketed histograms;
  ship bucket boundaries + counts, not decoded per-user values. When
  re-bucketing into your own scheme, use bucket midpoints and accept the
  quantization.
- **Choose bucket layouts per metric.** Sub-second UI metrics need fine
  buckets around 50-500 ms; launch metrics need coverage out to 10+ s.
  One-size buckets waste resolution where it matters and storage where it
  does not (every bucket set materializes a series in the store).
- **Convert units exactly once, at a named boundary.** MetricKit delivers
  `Measurement` values (typically seconds); ingestion systems often expect
  ms. The classic failure: exporting Apple's already-in-buckets values
  through a transform that assumed seconds and multiplied by 1000 - a week of
  dashboards 1000x off before the release cycle exposed it. Assert units in
  tests on the export path.

## Launch metrics without self-deception

- **Prefer MetricKit's `histogrammedTimeToFirstDraw`** over hand-measured
  "process start to didFinishLaunching":
  - Since iOS 15, **prewarming** starts processes long before the tap;
    process-start-based measurements show minutes-or-hours launches. Detect
    prewarmed launches via the `ActivePrewarm` environment variable and
    bucket them separately if you must self-measure; MetricKit already
    separates them (`histogrammedOptimizedTimeToFirstDraw`).
  - Clamping self-measured outliers ("ignore >10s") hides the users who
    actually regressed.
- Measure **stages**, not just the endpoint: first frame (TTID), full
  content (TTFD - the moment your primary content is on screen; pick the
  dominant element and instrument its first render), plus initialization
  phases as signposts. The endpoint tells you *that* it regressed; stages
  tell you *where*.
- Distinguish cold / warm / resume; MetricKit separates resume
  (`histogrammedApplicationResumeTime`).
- Filter or separately track **first launch after install/update** - cold
  caches make it structurally slower.
- Web-vitals equivalents worth self-instrumenting when launch UX is a KPI:
  - **First input delay**: first gesture after launch -> next frame
    (`CADisplayLink`) - hang metrics average over the whole session and
    miss launch-adjacent jank.
  - **Time to interactive**: first moment the main run loop has gone ~3s
    without a >50-100 ms stall.

## Aggregation: means, percentiles, and score indexes

- **p50 + p90/p95 + mean together.** Percentiles alone miss mid-distribution
  shifts (a p95 watcher never sees the 2s-to-4s users while p95 sits at 10s);
  means alone are wrecked by heavy tails.
- For an executive-level "is the app getting faster" number, map each metric
  onto a **0-100 score** via fixed control points (e.g. 500 ms -> 95 pts,
  1000 ms -> 85, 3500 ms -> 50, log-normal-ish curve, linear interpolation
  between points), then weight scores into one index. Properties that make
  this worth the setup: bounded (outliers cannot dominate), sensitive across
  the whole distribution, comparable across metrics, and stable enough that
  a 1-point move means something (roughly a 10% real improvement in the
  underlying metric). Weights come from scenario frequency - a flow half
  your users hit daily outweighs a settings screen.
- Alert on the index and per-metric p50/p95 deltas per release; investigate
  with the stage metrics.
- Reference bands for the UX metrics Apple publishes: scroll hitch rate
  under 5 ms/s reads as smooth, 5-10 ms/s is borderline, over 10 ms/s is a
  visibly bad scroll; hang rate is expressed in seconds of unresponsiveness
  per hour of use, with hangs counted from 250 ms (severe from 500 ms).
  Ideal hang rate is zero; trend it per release.

## SLIs and alert hygiene

- Frame each key flow as a **success-rate SLI with an explicit target**
  ("image loads succeed >= 98%", "sync completes >= 99.5%") alongside the
  latency percentiles - availability and latency regress independently,
  and a success-rate target is a number product and engineering can agree
  on before the incident.
- Dampen alerts so one noisy datapoint never pages: evaluate on the
  median of several evaluation points, and require the condition to hold
  through a pending window before firing (ok -> pending -> firing). Tune
  the window to the metric's cadence - MetricKit data arrives daily,
  request-level success rates move by the minute.
- Enrich client-aggregated events with the dimensions incidents actually
  split on (app version, OS version, network type, region) - an alert
  that cannot be sliced is an alert that cannot be diagnosed.

## Experiments on performance

- To prove a perf metric matters to the business, run a **slowdown
  experiment**: inject controlled delay for a small cohort and measure
  retention/engagement deltas (a classic result: ~10% launch slowdown
  costing ~1% of engaged users). Implement the delay as CPU-bound work, not
  a timer, so it scales with device speed like real regressions do.
- The same cohort mechanics validate optimizations: ship the optimization
  flag-gated to 50% and compare within-version.
- Stability metrics are the go/no-go guard for any technical rollout
  (refactor behind a flag, new networking stack): watch crash and hang
  rate per cohort before product metrics, and roll to an internal ring
  (employees/dogfood) first - it converts the worst bugs into internal
  feedback instead of user-facing incidents.
- A cohort that shipped with a bug is contaminated: users on old app
  versions re-enter it with the bug even after a fix ships. Stop the
  experiment, fix, and relaunch under a fresh experiment key rather than
  resuming the same one - otherwise the measured effect blends buggy and
  fixed exposures.

## Operational checklist

- Payload receipt is itself monitored (count of MetricKit payloads ingested
  per day per version) - a silent subscriber regression otherwise looks like
  the app getting infinitely fast.
- Uploads batch and survive offline (background URLSession or a durable
  queue); losing telemetry from exactly the crashing sessions is the
  classic bias.
- TestFlight/internal builds are excluded or tagged (`isTestFlightApp` on
  iOS 27 reports; your own build-config tag before that).
- Dashboards annotate release rollouts; every incident review starts with
  "which version and when did adoption cross 50%".
- Retention: keep raw payload JSON for a few weeks (re-derivation after
  pipeline bugs), aggregates long-term.
