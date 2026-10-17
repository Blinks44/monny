# Fundamentals: The Observability Model on Apple Platforms

## The three pillars, mapped to Apple frameworks

| Pillar | Apple mechanism | Scope |
|---|---|---|
| **Logs** | Unified logging (`Logger`, `os_log`), viewed via Console.app / `log` CLI / Xcode / `OSLogStore` | Discrete events with metadata, on-device |
| **Traces** | Signposts (`OSSignposter`) + activities (`os_activity`), viewed in Instruments | Durations and correlation, mostly local profiling |
| **Metrics** | MetricKit (`MXMetricPayload`, `MXDiagnosticPayload`), Xcode Organizer | Daily aggregates + diagnostic stacks from the production fleet |

Crash reporting sits across pillars: the OS writes `.ips` reports, MetricKit
delivers crash/hang/OOM diagnostics into the app, Organizer aggregates
opted-in users, and third-party SDKs add real-time grouping and alerting.

The key mental shift from server-side observability: there is no live query
against production. Signals are either persisted on the user's device (logs),
delivered to your app in batches (MetricKit), aggregated by Apple (Organizer),
or shipped by you to your own backend. Design each emission knowing which of
those paths it will take - a `debug` log and a Grafana dashboard are different
products with different code.

## Unified logging architecture

Available since iOS 10 / macOS 10.12; supersedes ASL and Syslog. Properties
that drive every design decision:

- **Binary, deferred-formatting store.** Messages are recorded in a compressed
  binary format (`.tracev3` files under `/var/db/diagnostics` on macOS);
  formatting into text happens at read time. This is why logging is cheap and
  why you cannot just `cat` a log file - you need Console.app, the `log` tool,
  or `OSLogStore`.
- **Memory first, disk maybe.** All messages land in an in-memory ring buffer.
  Only levels configured to persist get compressed and written to the on-disk
  store, which is rotated: old messages are purged when the store exceeds its
  size limit. There is no infinite retention - if a bug takes a week to
  manifest, day-one logs are likely gone.
- **Centralized and system-wide.** Your messages interleave with every other
  process. Subsystem + category are the only handles that make yours findable.
- **Static format strings + typed interpolation.** The compiler splits an
  `OSLogMessage` into a static string (stored once) and typed arguments
  (stored per event). This enables both the performance and the privacy model.

## Levels and persistence (the table that decides everything)

| Level | Persisted to disk | Cost | Meant for |
|---|---|---|---|
| `debug` / `trace` | Never | Lowest (memory only, dropped unless captured live) | Development-only detail |
| `info` | Only while a `log collect` is running, or when snapshotted around an `error`/`fault` | Low | Helpful but non-essential context |
| `notice` (default) | Yes, until store rotation | Medium | Essential troubleshooting record |
| `error` | Yes, longer retention than notice | Higher | Failures the app handles |
| `fault` / `critical` | Yes, longer retention than notice | Highest (captures extra state, from related processes too) | Bugs: broken invariants |

Consequences:

- Retention is typically a few days and depends on device storage; `error`
  and `fault` land in separate files with longer retention than `notice`.
- An `error`/`fault` also captures surrounding in-memory `info` context -
  one more reason info-level breadcrumbs before a potential failure are
  worth emitting even though they normally evaporate.

- Anything support must be able to pull from a user's device later must be
  `notice` or above. `debug`/`info` are effectively invisible in production.
- `error` and `fault` are more expensive precisely because they do more
  (fault additionally records information about the process chain). Do not
  use them for expected, frequent conditions.
- The defaults can be overridden per subsystem while debugging (`log config`,
  logging profiles) - see `log-cli-and-console.md`. Never rely on overrides
  being present on user devices.

## Who can see what

| Context | debug | info | notice/error/fault | Interpolated private values |
|---|---|---|---|---|
| Xcode debugger attached | yes | yes | yes | visible |
| Console.app streaming a device | if enabled via Action menu | if enabled | yes | `<private>` unless annotated public |
| Later, from the on-device store (`log collect`, OSLogStore, sysdiagnose) | no | only if collect was running | yes | `<private>` |
| App Store user, no tooling | messages persist on their device; anyone with the device + a Mac can read them | | | redaction is the only protection |

Three conclusions:

1. **Persisted logs are semi-public.** Anyone with physical access to the
   device and its passcode can collect and read them. Treat every `.public`
   annotation as printing the value where the device's owner - or whoever
   ends up with the device - can read it.
2. **Redaction only protects interpolated values in the OS store.** The moment
   you also write the formatted message to your own file or a third-party SDK,
   the OS privacy machinery no longer applies - your code is responsible.
3. **Live streaming changes the cost model.** While Console.app or
   `log stream` is attached, every log call pays an IPC to the observer,
   bypassing the buffering that makes logging cheap. Never benchmark or
   profile with a log stream attached.

## What production observability you get for free

Without adding any SDK:

- **Unified logging**: persisted notice+ messages retrievable via sysdiagnose
  or an in-app OSLogStore exporter.
- **MetricKit**: daily metric payloads (launch, hang, CPU, memory, disk,
  network, battery) and diagnostic payloads (crash, hang, CPU exception,
  disk-write exception, launch, memory) delivered into the app on device.
- **Xcode Organizer**: crashes, hangs, disk writes, energy, launch time,
  feedback - but only from users who opted in to Share With App Developers,
  aggregated per version, delayed by ~1 day.
- **App Store Connect / TestFlight crash feedback**.

Third-party SDKs and custom pipelines earn their keep with real-time
delivery, alerting, grouping, session/user context, and cross-platform
dashboards - not with data that the native stack lacks entirely. Establish
the native baseline first, then justify the SDK. See `third-party-sdks.md`.

## The five habits of an observable codebase

1. **Every error path logs.** A caught-and-swallowed error is the single most
   common reason a production bug is undiagnosable.
2. **Boundaries log their inputs.** Network responses, file loads, IPC,
   user-initiated actions - the places where reality enters the program.
3. **State transitions log.** Login state, sync state, playback state; the
   sequence reconstructs the story.
4. **Durations are signposted, not logged.** Timers in log messages cannot be
   aggregated; signposts flow into Instruments and MetricKit histograms.
5. **The fleet is instrumented before it is optimized.** When a problem only
   happens in production, the first ship adds the metric that would prove the
   hypothesis; the second ship fixes it.
