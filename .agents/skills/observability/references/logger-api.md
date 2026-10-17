# Logger API (and Legacy os_log)

## Setup pattern

`Logger` (iOS 14+ / macOS 11+, `import OSLog`) is the primary API. One
static logger per subsystem/category pair; subsystem = bundle identifier,
category = functional area:

```swift
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!

    static let networking = Logger(subsystem: subsystem, category: "networking")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let sync = Logger(subsystem: subsystem, category: "sync")
}

// Call sites
Logger.networking.info("Fetched \(recordings.count) recordings")
Logger.sync.error("Sync failed: \(error.localizedDescription, privacy: .public)")
```

Guidance:

- Categories should mirror how you will filter: one per feature area or
  module, not one per file and not one for the whole app. In a modular
  codebase, a category per module works well.
- Subsystems naturally follow **targets**: the app, each extension, and
  each shared framework get their own reverse-DNS subsystem
  (`com.example.app`, `com.example.app.share-extension`) so a Console
  filter can isolate which binary emitted what.
- `Logger` values are cheap, `Sendable`, and safe to share; still prefer
  `static let` over constructing per call in hot paths.
- `Logger(_ osLog: OSLog)` bridges an existing `OSLog` handle (useful with
  `MXMetricManager.makeLogHandle`).
- `Logger.disabled` is a null logger - useful to swap in for noisy
  subsystems, or via an environment flag.
- `logger.isEnabled(type: .debug)` lets you skip expensive setup work that
  exists only to produce a log message (rarely needed - interpolation itself
  is already lazy).

## Levels

Eight methods, five effective levels (see persistence table in
`fundamentals.md`):

| Method | OSLogType | Notes |
|---|---|---|
| `trace` / `debug` | `.debug` | Synonyms. Memory only |
| `info` | `.info` | Memory; persisted only during `log collect` |
| `notice` / `log` | `.default` | The persisted default |
| `warning` / `error` | `.error` | Synonyms. Persisted |
| `critical` / `fault` | `.fault` | Synonyms. Persisted + extra capture |

`log(level:_:)` takes an explicit `OSLogType` when the level is dynamic.

## Privacy

Interpolated **strings, objects, and custom types** are redacted by default -
on a device without a debugger they render as `<private>`. **Numeric scalars
and Booleans are visible by default.** Annotate explicitly:

```swift
logger.log("Paid with account \(accountNumber)")                  // <private>
logger.log("Ordered \(smoothieName, privacy: .public)")           // visible
logger.log("User \(userID, privacy: .private(mask: .hash))")      // stable hash
logger.log("Balance \(balance, privacy: .private)")               // hide a number
```

- `.private(mask: .hash)` prints a consistent hash per value: you can tell
  that two log lines concern the same user without learning who it is. Use it
  for identifiers you need to correlate.
- Annotate deliberately in both directions: mark genuinely harmless
  diagnostic values `.public` so production logs stay readable, and leave
  anything user-derived private. Blanket-`.public` "because <private> is
  annoying" is the classic leak.
- Redaction happens at read time in the OS store only. If you re-emit the
  formatted string to a file, analytics, or a crash SDK breadcrumb, you must
  redact yourself before emitting.

## Formatting

Formatting applies at render time (Console.app; the Xcode 15+ console
applies most of it too):

```swift
logger.debug("\(name, align: .left(columns: 12)) \(id)")          // columns
logger.debug("\(duration, format: .fixed(precision: 2))")         // 2 decimals
logger.debug("\(flags, format: .hex)")                             // hex int
logger.info("\(temperature, format: .fixed(precision: 1), privacy: .public)")
```

Formatting is free at emit time (applied when the message is rendered), so
format aggressively for readability. Column alignment makes multi-field
logs option-drag column-selectable in Xcode's console - paste straight into
Numbers to chart a quick investigation. Any `CustomStringConvertible` type
interpolates directly; conforming your own types is the cheap way to log
them.

Keep the format string itself static. Never pre-build the message:

```swift
// WRONG - defeats privacy, lazy evaluation, and static-string storage
let message = "User " + user.email + " logged in"
logger.info("\(message)")

// RIGHT
logger.info("User \(user.email, privacy: .private(mask: .hash)) logged in")
```

## Performance model (why wrappers go wrong)

`Logger` methods take an `OSLogMessage` built by a compiler-generated string
interpolation. The arguments are evaluated **only if the message will actually
be captured**. A disabled `debug` log costs nanoseconds and never touches the
interpolated expressions.

A wrapper that accepts `String` destroys this:

```swift
// WRONG - `describe(payload)` runs on every call, even when debug is off
func appLog(_ message: String) { Logger.app.debug("\(message)") }
appLog("payload: \(describe(payload))")
```

If you need an abstraction (multi-destination, module tagging), either expose
the category loggers directly, or take an autoclosure:

```swift
func appLog(_ message: @autoclosure () -> String,
            level: OSLogType = .debug) {
    guard Logger.app.isEnabled(type: level) else { return }
    Logger.app.log(level: level, "\(message())")
}
```

Note that even the autoclosure variant loses per-value privacy annotations -
the whole rendered string becomes one interpolated (private-by-default)
value. For most apps, direct `Logger` use per category is the better design.

## Multi-destination facade

When logs must fan out (unified logging + file for support export + analytics
breadcrumbs), keep unified logging as one handler among several rather than
abandoning it:

```swift
protocol LogHandler: Sendable {
    func log(level: OSLogType, message: String, category: String,
             file: String, line: Int)
}

struct OSLogHandler: LogHandler {
    // one OSLog/Logger per category, map levels 1:1
}
struct BreadcrumbHandler: LogHandler {
    // forward >= error to the crash SDK as breadcrumbs; skip debug entirely
}
```

Rules for facades:

- Map levels faithfully (`critical -> .fault`, `warning -> .error`,
  `info -> .info`, `debug -> .debug`); do not invent levels the store cannot
  express.
- Filter at the handler (a server handler that drops `debug`), not by
  pre-rendering different strings per destination.
- Capture `#fileID`, `#line`, `#function` as default arguments in the facade
  if you want call-site info; unified logging records the emitting subsystem
  but not your source location.
- Redact before the message leaves the process. The facade is exactly the
  place where OS-level privacy protection ends.

## Legacy os_log (iOS 10-13 targets, Objective-C)

```swift
import os

private let log = OSLog(subsystem: "com.example.app", category: "networking")

os_log("Fetched %d recordings", log: log, type: .info, count)
os_log("Getting %{public}s", log: log, type: .info, url.absoluteString)
os_log("Token %{private}s", log: log, .debug, token)  // private is default for %s/%@
```

- The format string parameter is a `StaticString`: a `let message = ...`
  variable or Swift string interpolation will not compile there - values go
  in as format arguments, which is exactly what enables the privacy and
  deferred-formatting machinery.
- Format specifiers: `%d`/`%i`, `%f`, `%s` (C string), `%@` (object),
  modifiers `%{public}...` / `%{private}...`. Scalars default public,
  strings/objects default private - same model as Logger.
- From Swift, use `%@` for strings and objects: `%s` expects a C string and
  historically misbehaves with Swift `String` arguments even though the
  documentation lists it.
- Built-in value decoders render raw scalars readably at display time:
  `%{time_t}d` (dates), `%{errno}d` (POSIX error names),
  `%{uuid_t}.16P`, `%{bool}d`, and friends - prefer them over
  pre-formatting values in code.
- `OSLog(subsystem:category:)` handles are the unit of filtering; the special
  category `OSLog.Category.pointsOfInterest` feeds the Instruments POI track.
- When touching legacy call sites, migrate the file to `Logger` unless the
  deployment target forbids it; do not mix both styles in one file.

## Objective-C

Use `os_log`/`os_log_with_type` with an `os_log_t` from `os_log_create`.
The same level, privacy, and static-format rules apply.
