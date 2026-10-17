# Network Telemetry: Request-Level Observability in Production

Network failures are the production problem class you can least reproduce
at a desk: they depend on the user's carrier, location, Wi-Fi, and the
exact server cluster they hit. This file covers what to collect from real
users' requests - which errors to report, how to make the reports readable,
what `URLSessionTaskMetrics` reveals, and how to get aggregate network
statistics cheaply.

## Why lab testing undersells the field

- **Environments drift**: staging vs production, and within production,
  per-region clusters and canary pools can behave differently. "Works on
  my backend" says little about the cluster a given user landed on.
- **Interfering networks**: corporate/hotel Wi-Fi with captive portals or
  TLS-intercepting proxies (their own certificates) produces auth and
  certificate failures that never occur on your office network.
- **Mobile-specific realities**:
  - The radio channel changes mid-flow (cellular <-> Wi-Fi) and requests
    in flight die with it.
  - Cellular networks deliberately keep TCP connections alive across
    base-station handoffs, so a connection can sit open long after
    connectivity is actually gone - the socket looks healthy while
    nothing moves. Long-lived connections (websockets) need app-level
    heartbeats; socket liveness is not truth.
  - Bandwidth swings from broadband-class to near zero and back.
- Link conditioners and lab "bad network" emulation catch a lot, but the
  field is strictly worse. The conclusion: collect network telemetry from
  real users, not only from test rigs.
- **Reachability is advisory.** The API itself is documented as a hint,
  and its answer can diverge from what a request would actually do.
  Do not gate requests on reachability - attempt the request (especially
  on launch): if it fails you lost nothing, if it succeeds you have data.

## Error taxonomy: report, count, or drop

The core problem is signal-to-noise: benign transport errors are so
frequent that reporting each one buries the errors that mean a bug.

| Class | Examples | Handling |
|---|---|---|
| **Report** (non-fatal to crash SDK, all users) | response decode failures, post-decode validation failures (required field missing, impossible value), unexpected TLS/certificate errors | These should never happen in normal operation - each one is a client/server contract break or an environment problem worth a ticket |
| **Count** (aggregate rate only) | offline at request time, connection lost mid-request (channel switch), timeouts | Everyday mobile life; watch the *rate* per endpoint/release for spikes, do not file per-occurrence reports |
| **Drop** | cancellations you issued (`URLError.cancelled` from superseding a stale request) | Expected control flow, not an error |

Timeouts are the borderline case: worth a rate metric (they can indicate a
degrading backend), but individually they usually mean "slow network", and
at volume they drown everything else.

## Designing the non-fatal report

Crash SDKs group and title non-fatal errors by the error's domain and code.
Two consequences:

- **Never report the raw transport error.** Every `URLError` shares one
  domain, so hundreds of distinct problems collapse into a couple of
  dashboard rows distinguishable only by numeric code. gRPC-style
  transports are worse - a single domain and a generic status for
  everything.
- **Wrap in a custom error whose description is the dashboard title.**
  Put a human-readable problem statement where the SDK's grouping reads
  it, and carry the machine context in `userInfo`:

```swift
enum APIReport {
    static func decodeFailure(endpoint: String, status: Int,
                              underlying: Error) -> NSError {
        NSError(
            // becomes the issue title - readable, groups by problem
            domain: "Decode failed: \(endpoint)",
            code: status,
            userInfo: [
                "endpoint": endpoint,                       // template, not full URL
                "status": status,
                "underlying": String(describing: underlying),
                // compact, bounded state timeline - survives when SDK
                // breadcrumb logs get dropped at volume
                "lifecycle": LifecycleTimeline.shared.compact()
            ])
    }
}
```

- **Embed the critical breadcrumbs in `userInfo` yourself.** SDK
  breadcrumb logs are best-effort: at high non-fatal volume they may
  arrive empty, and a shared rolling buffer tends to contain everything
  *except* the lines about your problem. A compact app-state timeline
  (launch, foreground/background transitions, the last few network
  outcomes) fits in a bounded string of a few hundred bytes and always
  arrives with the report. Keep each value comfortably under the SDK's
  per-value limit (kilobyte scale).
- **Privacy**: never attach raw request or response objects, bodies, or
  full URLs with query parameters - auth headers, tokens, and user content
  end up in a third-party dashboard. Log endpoint *templates*
  (`/users/{id}/orders`), status codes, and byte counts. Review what a
  report contains on a test device before shipping the reporting code.
  See `third-party-sdks.md` for the SDK-boundary scrubbing rules.

## URLSessionTaskMetrics: the anatomy of a request

When an issue is reproducible only for some users, request phase timings
tell you *where* the time went without a proxy. Each
`URLSessionTaskMetrics` carries per-transaction (redirects and retries are
separate transactions) timestamps for:

1. **Queueing** - the task waits inside `URLSession` before work starts
   (`fetchStartDate` vs when you called `resume`).
2. **DNS** - `domainLookupStartDate`/`EndDate`.
3. **TCP connect** - `connectStartDate`/`EndDate`.
4. **TLS handshake** - `secureConnectionStartDate`/`EndDate`.
5. **Request send / response receive** - `requestStartDate` through
   `responseEndDate`.

Collection: implement `urlSession(_:task:didFinishCollecting:)` on the
task delegate. Alamofire exposes the same object as `response.metrics`,
which is more convenient than juggling a delegate alongside
completion-handler code.

```swift
final class MetricsRecorder: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let t = metrics.transactionMetrics.last else { return }
        Logger.networking.debug("""
            \(t.request.url?.path ?? "-", privacy: .public) \
            dns=\(Self.ms(t.domainLookupStartDate, t.domainLookupEndDate))ms \
            connect=\(Self.ms(t.connectStartDate, t.connectEndDate))ms \
            tls=\(Self.ms(t.secureConnectionStartDate, t.secureConnectionEndDate))ms \
            ttfb=\(Self.ms(t.requestEndDate, t.responseStartDate))ms \
            reused=\(t.isReusedConnection)
            """)
    }
    private static func ms(_ a: Date?, _ b: Date?) -> Int {
        guard let a, let b else { return 0 }
        return Int(b.timeIntervalSince(a) * 1000)
    }
}
```

Formatting gotcha: if you print the raw `Date` values, default formatting
shows whole seconds and every phase reads as zero. Network phases live in
milliseconds - format with sub-second precision (`HH:mm:ss.SSS`) or emit
computed millisecond durations as above.

### What the phases diagnose

- **Keep-alive health.** A reused connection reports
  `isReusedConnection == true` and empty DNS/connect/TLS phases. If every
  request pays a fresh DNS + TCP + TLS setup (often tens of milliseconds,
  sometimes more than the request itself), keep-alive is broken - either
  client-side (creating a new `URLSession` per request is the classic
  self-inflicted version) or a server/proxy dropping idle connections.
  Client-side metrics have settled more than one argument with a backend
  team certain their keep-alive configuration was fine.
- **Server processing time.** The gap between `requestEndDate` and
  `responseStartDate` is what the user actually waited on the backend
  plus its fronting infrastructure. Backends usually measure themselves
  from their app server inward; when the server says 30 ms and clients
  see hundreds, the difference lives in load balancers, auth layers, and
  security screening in front - and per-phase client data is the evidence
  that makes that conversation productive.
- **Latency physics.** Round trips scale with distance: single-digit
  milliseconds within a metro, tens across a continent, 100+ ms across
  the world - and connection setup costs multiple round trips. TLS 1.3,
  connection reuse, and CDN/edge termination all cut round trips; the
  metrics show whether those optimizations are actually in effect for
  real users.

Lab-side counterpart: the Instruments **Network template** visualizes the
same phases plus connection reuse and request parallelism per request with
zero code - use it to diagnose locally and to decide which numbers deserve
fleet-wide collection.

### Volume strategy

Full metrics for every request are too bulky to attach to mass reports.
Use two tiers:

- **Aggregate a few numbers fleet-wide**: phase durations and
  `isReusedConnection` rate as histograms/counters per endpoint template,
  through your telemetry pipeline (`production-monitoring.md` - an OTel
  histogram per phase maps directly).
- **Full dumps only on demand**: attach the recent request log to a
  user-initiated feedback/support flow (`oslogstore.md`), and in internal
  builds expose a share-sheet export so QA and teammates can forward a
  captured session through any channel.

## Aggregate network monitoring off the shelf

Firebase Performance Monitoring (and RUM SDKs generally) auto-instrument
`URLSession` and give you, per URL pattern: success rate over time,
response-time distribution with percentiles, request/response payload
sizes, and a breakdown of failing HTTP status codes - enough to spot "the
API started failing at 14:00 for the 2.3.1 release" without building
anything. Session timelines around a slow request (what else was in
flight, what ran before) also expose redundant and duplicate requests
worth deleting.

Costs and controls:

- Collection has runtime overhead and the SDK adds binary weight (about
  2 MB statically linked, before its dependencies). Wire the SDK's
  data-collection flag to a remote-config value so collection can be
  disabled in the field without a release - and re-enabled for an
  investigation.
- Percentile tables are only meaningful per endpoint *template*; verify
  the SDK's URL aggregation does not explode on path IDs.
- The vendor-neutral build-it route is OTel HTTP-client spans plus phase
  histograms - see `production-monitoring.md`.

## Wiring into the rest of the stack

- Persist request outcomes at `notice` (not `debug`) in a `networking`
  category so a support export (`oslogstore.md`) actually contains them.
- Carry one correlation ID per user flow into the request headers
  (`X-Request-ID`) and every related log line (`activity-tracing.md`) so
  client and server logs join.
- Time whole flows (UI action -> parsed model) with signposts
  (`signposts.md`); `URLSessionTaskMetrics` covers only the wire.
- MetricKit's daily network-transfer metrics track *volume* (cellular vs
  Wi-Fi bytes), not health - complementary, not overlapping
  (`metrickit.md`).

## Recipes

- Must-have, nearly free: non-fatal reports for contract-breaking errors
  (decode/validation) from all users, with readable custom errors.
- Cheap: an aggregate network monitor (Firebase Performance or OTel
  histograms) for per-endpoint success rate and latency distributions.
- Write logs to the persisted store, not just the console, so they can be
  retrieved from a device when it matters.
- Targeted, not mass: full `URLSessionTaskMetrics` dumps via feedback
  flows and internal-build exports.
- Everything remotely toggleable, and restrained by default: device disk
  is finite, collection SDKs have overhead, and over-collection has side
  effects users feel.
