# Retrieving Logs: Console.app, the log CLI, Profiles, sysdiagnose

The store is binary; these are the readers. (In-app reading: `oslogstore.md`.)

## Console.app

1. Select the device or simulator in the Devices sidebar, press Start
   Streaming.
2. Filter: type in the search field and choose what the term matches
   (Subsystem, Category, Process, Message). Right-clicking a log line offers
   "Show subsystem" style quick filters.
3. `debug` and `info` messages are hidden by default - enable via
   Action > Include Info Messages / Include Debug Messages. **These toggles
   change the system's live capture mode** (visible in
   `sudo log config --status` flipping to a live-stream mode) - Console is
   not a passive viewer, so what you see with it open differs from what the
   store keeps when it is closed.
4. Reading the stream: message-type dots are light gray (info), dark gray
   (debug), yellow (error), red (fault); a "Volatile" tag means the message
   lives in memory only and will never reach the persisted store.
5. Save configured filters as named saved searches in the toolbar - one per
   subsystem/feature is the practical setup for debugging on colleagues' or
   testers' machines.

Console streams live; it does not browse the past. For history use
`log show`/`log collect` or a sysdiagnose.

## The log CLI (macOS; targets Mac, simulators via the sim's own store, and devices for collect)

```bash
# Live stream, like Console but greppable
log stream --level debug --predicate 'subsystem == "com.example.app"'

# Historical query from the local store
log show --last 2h --predicate 'subsystem == "com.example.app" AND messageType >= error'

# Info/debug in the output (if they were captured)
log show --info --debug --last 30m --predicate '...'

# Snapshot the store into a portable archive
sudo log collect --last 1d --output ~/Desktop/app.logarchive
log collect --device --last 1h --output ~/Desktop/device.logarchive  # attached iOS device

# Open any .logarchive in Console.app or query it:
log show ~/Desktop/device.logarchive --predicate '...'
```

Predicate syntax is `NSPredicate` over fields: `subsystem`, `category`,
`process`, `processID`, `messageType` (`debug|info|default|error|fault`),
`eventMessage`, `composedMessage`. Common recipes:

```bash
--predicate 'subsystem == "com.example.app" AND category == "networking"'
--predicate 'process == "MyApp" AND composedMessage CONTAINS[c] "timeout"'
--predicate 'messageType == fault'
```

`log stream` on a booted simulator: `xcrun simctl spawn booted log stream
--predicate '...'`. The simulator also has a sysdiagnose counterpart:
`xcrun simctl diagnose` dumps a full diagnostic archive of the simulator
session (system + simulator logs, environment plists). Like a device
sysdiagnose it contains personal information (accounts, paths, network
details) - keep it local.

Team tip: check the team's standard filter into the repo as a one-line
script (`scripts/tail-logs.sh` wrapping `log stream --level debug
--predicate 'subsystem == "..."'`) - unlike Console saved searches, it is
shareable, reviewable, and identical on every machine.

## Scripted capture workflows (agent-assisted debugging)

When an AI agent or a script drives the debug loop, ad-hoc streaming into a
foreground terminal does not fit: capture has to run in a long-lived
background session, write to files, and be summarizable afterwards. A
three-tier setup that works well in practice - each tier a start/stop pair
writing timestamped files under `logs/`:

### Tier 1: simulator stream-to-file (fastest loop)

```bash
#!/bin/bash
# scripts/capture-sim-logs.sh - attach to the booted simulator
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
UDID=$(xcrun simctl list devices | grep "(Booted)" \
    | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' \
    | head -1)
[ -z "$UDID" ] && { echo "No booted simulator"; exit 1; }

xcrun simctl spawn "$UDID" log stream --level=debug \
    --predicate 'subsystem == "com.example.app"' \
    2>&1 | tee "logs/sim-${TIMESTAMP}.log"
```

- Attaches to the already-booted simulator without relaunching the app.
- Captures `Logger` output including `debug` (visible live even though it
  never persists); does **not** capture `print`.
- Run it in a long-lived background shell; Ctrl-C stops the stream and the
  file survives. Analyze the newest capture
  (`ls -t logs/sim-*.log | head -1`): grep `error|fault`, a category tag,
  or tail it.

### Tier 2: device console launch (stdout on real hardware)

```bash
xcrun devicectl device process launch --console --terminate-existing \
    --device <device-udid> \
    --environment-variables '{"ENABLE_PRINT_LOGS": "1"}' \
    com.example.app 2>&1 | tee "logs/device-$(date +%Y%m%d-%H%M%S).log"
```

- `--console` streams the process's **stdout/stderr** - which is where
  `print` goes and where unified-log messages do not appear. To see
  structured messages in this stream, have the logging facade
  (`logger-api.md`) additionally mirror each message to `print` **only
  when the launch environment sets the flag** (read the `ProcessInfo`
  environment once into a static bool). Shipping builds never set the
  variable, so the mirror is dead code in production and the
  no-`print`-in-committed-code rule stays intact.
- `--terminate-existing` guarantees a clean relaunch under the console.
- The tier for device-only bugs that need a live stream without sudo.

### Tier 3: timestamped device archive (everything, including extensions)

1. Before reproducing, record the window start (pad a couple of minutes
   early) and the device UDID:
   `date '+%Y-%m-%d %H:%M:%S' > .log-start-time`;
   UDID from `xcrun xctrace list devices`.
2. Reproduce the issue on the device.
3. Collect and pre-filter:

```bash
sudo log collect --device-udid <udid> \
    --start "$(cat .log-start-time)" --output logs/device.logarchive
log show logs/device.logarchive \
    --predicate 'subsystem == "com.example.app"' \
    --info --style compact > logs/device-filtered.txt
```

- **Requires interactive sudo** - an agent should hand this command to the
  user to run, not attempt it itself.
- The only tier that captures **every process**, including app extensions
  (keyboard, share, widget) that a console attach cannot reach - the tier
  for bugs that live in an extension.
- The `.logarchive` reopens in Console.app for interactive digging; the
  `--style compact` text export is the greppable artifact.
- Bounding with `--start` keeps collection time and archive size sane.

Conventions that keep the loop reliable: one timestamped file per capture
session (never overwrite), newest-file lookup for analysis, keep raw
captures after summarizing, and check the scripts into the repo so every
machine and agent session captures identically.

## Changing capture behavior while debugging (macOS)

```bash
sudo log config --mode "level:debug" --subsystem com.example.app
sudo log config --mode "level:debug,persist:info" --subsystem com.example.app  # both knobs in one mode string
sudo log config --status --subsystem com.example.app
sudo log config --reset --subsystem com.example.app                 # back to defaults
xcrun simctl spawn booted log config --status                       # same controls for a simulator
```

Notes: `level:` controls what is captured, `persist:` controls what reaches
disk - independent knobs, combinable in one `--mode` string. Private data
is system-wide, not per subsystem: the historical toggle was
`sudo log config --mode "private_data:on"`, but modern macOS removed it -
the supported route is a logging configuration profile with
`Enable-Private-Data` (and on managed devices, Apple's profiles). Remember
to `--reset` when done.

Or install a logging configuration profile at
`/Library/Preferences/Logging/Subsystems/com.example.app.plist` with
`DEFAULT-OPTIONS` and per-category dictionaries containing a `Level` dict
(`Enable`: `Default|Info|Debug`, `Persist`: same values or `Inherit`).
Categories inherit from the subsystem, subsystems from the system.

On iOS, per-subsystem debug capture requires an Apple-provided logging
profile (from the Bug Reporting profiles page); you cannot `log config` a
device. Design production logging assuming default persistence rules.

## sysdiagnose (deep system issues, user devices)

A sysdiagnose captures the entire unified log store plus system state - the
heavyweight option when a user hits something you cannot reproduce:

- iPhone/iPad: hold both volume buttons + side button ~1.5s (a short vibration
  confirms), wait up to 10 minutes, retrieve under
  Settings > Privacy & Security > Analytics & Improvements > Analytics Data,
  or sync via Finder. AirDrop the `sysdiagnose_...tar.gz` file.
- The archive contains `system_logs.logarchive` - open in Console.app or
  query with `log show`.
- Only `notice`+ messages from your app will be present. If your support
  workflow depends on sysdiagnose, your essential logs must be `notice`+.

For app-level support flows, an in-app OSLogStore exporter (see
`oslogstore.md`) is friendlier than teaching users the button chord.

## Xcode console (15+)

The debug console renders unified log metadata: a metadata-options button
picks which fields display under each message (type, library, subsystem,
category); selecting a log and pressing space quick-looks all metadata
including the emitting function; errors and faults get yellow/red
backgrounds; tokenized filters (with autocomplete, or right-click a log >
hide/show similar) cut the noise; hovering a line offers jump-to-source.
`print` output appears as plain stdout with none of that metadata - one
more reason `print` has no place in committed code.
