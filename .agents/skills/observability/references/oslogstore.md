# OSLogStore: Reading Your Own Logs at Runtime

`OSLogStore` (iOS 15+ / macOS 10.15+, `import OSLog`) reads entries back out
of the unified log store from inside the app - the foundation of "Send Logs
to Support" features and in-app debug consoles.

## Scope and limits (read these first)

- **iOS: your process only.** `OSLogStore(scope: .currentProcessIdentifier)`
  is the only scope; it returns entries logged by the current process instance
  plus what the store retained from earlier runs under normal persistence
  rules. macOS additionally offers `OSLogStore.local()` (whole machine,
  requires admin rights) and `init(url:)` for `.logarchive` files.
- **App extensions are separate processes**, so the main app cannot read a
  widget/keyboard/share extension's entries, and vice versa - each process
  sees only its own. If a support export must include extension logs,
  either run the same exporter inside each extension (writing into a shared
  App Group container for the app to attach), or accept the gap. At
  development time, a device `.logarchive` (`log-cli-and-console.md`) is
  the way to see all processes together.
- **Persistence rules apply.** `debug` never appears; `info` almost never
  (only if a `log collect` happened to be running). A support exporter
  retrieves the `notice`/`error`/`fault` record - write your essential logs
  accordingly.
- **Rotation applies.** Old entries are purged by the system; do not promise
  "logs since install".
- **It can be slow.** Enumerating a large store takes seconds. Always fetch
  on a background task, never on the main thread, and bound the range with a
  position.

## The system store vs rolling your own

Do not build a parallel log database (SwiftData/SQLite/file) just to show
or export logs - the OS already persists `Logger` messages, and
`OSLogStore` is the read API over that store. Double-writing costs the
lazy-interpolation performance and privacy redaction that make `Logger`
cheap and safe. A custom store is justified only when you need something
the system store refuses to give: a guaranteed retention window
independent of system rotation, structured custom fields you want to
query, or one place that aggregates logs across the app and its
extensions (an App Group file each process appends to). If you do both,
write through one facade (`logger-api.md`) so every message still reaches
unified logging.

If you do build a file trail, three implementation rules: cap the buffer
by **bytes**, not entry count (entries vary wildly in size, and a byte cap
is what actually bounds disk and memory); **debounce** disk writes (a
write per event turns the trail into an I/O tax - buffer in memory and
flush after a few quiet seconds); and filter high-frequency events
(per-scroll, per-frame) before recording, or they evict the history you
kept the trail for.

## Fetch recipe

```swift
import OSLog

func exportRecentLogs(hours: Double = 24) async throws -> String {
    let store = try OSLogStore(scope: .currentProcessIdentifier)
    let position = store.position(date: Date().addingTimeInterval(-hours * 3600))
    let subsystem = Bundle.main.bundleIdentifier!

    let lines = try store.getEntries(at: position)
        .compactMap { $0 as? OSLogEntryLog }
        .filter { $0.subsystem == subsystem }
        .map { entry in
            "\(entry.date.formatted(.iso8601)) [\(entry.category)] " +
            "\(levelName(entry.level)) \(entry.composedMessage)"
        }
    return lines.joined(separator: "\n")
}

private func levelName(_ level: OSLogEntryLog.Level) -> String {
    switch level {
    case .debug: "DEBUG"
    case .info: "INFO"
    case .notice: "NOTICE"
    case .error: "ERROR"
    case .fault: "FAULT"
    case .undefined: "UNDEFINED"
    @unknown default: "UNKNOWN"
    }
}
```

Notes:

- `getEntries(with:at:matching:)` accepts an `NSPredicate`, but filtering
  behavior has been inconsistent across OS releases; filtering in Swift after
  `compactMap` is the dependable route.
- Positions: `position(date:)`, `position(timeIntervalSinceLatestBoot:)`,
  `position(timeIntervalSinceEnd:)`. Starting from the store's beginning is
  the slow path - always pass a position.
- Entry subclasses beyond `OSLogEntryLog`: `OSLogEntryActivity`,
  `OSLogEntrySignpost` - a support exporter usually wants only the log kind.
- Entries include `process`, `sender` (library), `subsystem`, `category`,
  `date`, `composedMessage`. Interpolated values you logged as private are
  visible **to your own process** here - your exporter must not undo the
  privacy story by uploading what the OS redacted from everyone else. Filter
  or re-redact before the data leaves the device, and gate the export behind
  explicit user action.

## Support-export design

1. User taps "Share Logs" (never upload silently - App Review and GDPR both
   care).
2. Fetch on a background task with a bounded window (24-72h), filtered to
   your subsystem.
3. Write to a file in `FileManager.default.temporaryDirectory`, present a
   share sheet (or attach to your support ticket API).
4. Include app version, build, OS version, device model, and locale in a
   header - the metadata that every support thread asks for next.
5. Consider also attaching recent MetricKit diagnostic summaries (see
   `metrickit.md`) for crash context.

Before hand-rolling this, evaluate the open-source **Diagnostics**
package (iOS/iPadOS/macOS) - an established implementation of exactly
this feature: session logs plus
system info (OS/app version, device, storage) assembled by
`DiagnosticsReporter.create()` into an HTML report with built-in filtering
(errors-only toggle for support staff) for email attachment, or
`.create(format: .json)` for piping into a ticket system. It supports
custom "smart insights" (a protocol over the log lines, with built-ins
like update-available and low-storage checks), and v7 embeds structured
JSON in the report specifically so AI agents can parse it cheaply. The
build-vs-adopt line: Diagnostics owns the report format and sharing UX;
you still decide what gets logged and the redaction policy.

## In-app debug console

Same fetch, rendered in a hidden debug screen (shake gesture / build-config
gated). Refresh on pull rather than polling; the store is not a live stream.
Build the filter UI's facets (category chips, level picker) from the
distinct categories and levels present in the fetched entries rather than a
hardcoded list - it stays correct as the app's categories evolve.
For live tailing during development, `log stream` in a terminal beats
anything you can build in-app.
