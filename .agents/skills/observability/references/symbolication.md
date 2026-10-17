# Symbolication: dSYMs, atos, and MetricKit Stacks

A stack trace without symbols is a list of numbers. Symbolication maps
addresses back to function names and lines using the dSYM produced for that
exact binary.

## dSYM fundamentals

- Every Release build with `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym`
  produces one dSYM bundle per binary (app + each framework/app extension).
- The **UUID is the contract**: a dSYM symbolicates only the binary with the
  matching UUID. Check both sides:

```bash
dwarfdump --uuid MyApp.app/MyApp
dwarfdump --uuid MyApp.app.dSYM
```

- Archive dSYMs for every build you ship. Xcode archives (.xcarchive) keep
  them under `dSYMs/`; store the xcarchive or export the dSYMs to wherever
  your symbolication happens. A crash from a build whose dSYMs were lost is
  permanently unreadable.
- Spotlight indexing is how Xcode/Organizer find local dSYMs; keeping the
  .xcarchive on the machine that opens crash logs is usually enough for
  Xcode's own symbolication.
- SDK/SwiftPM binary dependencies ship their own dSYMs (or not - vendor
  frames stay unsymbolicated).

## Symbolicating an .ips crash report

Easiest paths first:

1. **Xcode**: drag the .ips into Devices & Simulators > View Device Logs, or
   open via Organizer - Xcode symbolicates automatically when dSYMs are
   findable locally.
2. **CrashSymbolicator.py** (ships with Xcode):

```bash
find /Applications/Xcode.app -name CrashSymbolicator.py
python3 CrashSymbolicator.py -d MyApp.app.dSYM -o symbolicated.ips crash.ips
```

3. **atos** for spot-checking single frames:

```bash
atos -arch arm64 -i \
     -o MyApp.app.dSYM/Contents/Resources/DWARF/MyApp \
     -l 0x100e34000 \
     0x100e4b2f0 0x100e4d104
```

`-l` is the binary's **load address** in that process instance - in an .ips
report it is the image's base in `usedImages`. **Always pass `-i`**: it
expands inlined functions, and release-mode inlining otherwise makes whole
call chains vanish from the output (the classic "atos shows only main"
mystery).

4. **LLDB crashlog import** - loads a crash log as if the app had just
   crashed under the debugger, with disassembly available for
   compiler-generated frames:

```
(lldb) command script import lldb.macosx.crashlog
(lldb) crashlog ~/Desktop/MyApp.crash
```

Requires the crash log, the app binary, and the matching dSYM all on the
Mac (Spotlight finds the latter two) - one more reason to keep xcarchives.

5. **xctrace symbolicate** - re-symbolicates an Instruments `.trace` file
   after the fact with dSYMs, for traces captured on machines that lacked
   the symbols (CI boxes, testers' Macs).

## How symbolication actually works (for debugging the process itself)

Runtime addresses differ from on-disk addresses by the **ASLR slide**:
`slide = load address - linker address` (linker address from
`otool -l` on the binary's `__TEXT` `LC_SEGMENT_64`; load address from the
crash log's Binary Images list or `vmmap` on a live process). File address =
runtime address minus slide. UUIDs + file addresses identify code
independent of the slide, which is why they are the keys into debug info.

Debug information comes in three tiers; what your stack looks like tells
you which tier the tool found:

| Tier | Contains | Symptom when it is all you have |
|---|---|---|
| Function starts (`LC_FUNCTION_STARTS`, in the binary) | addresses only | frames like `<binary> + 264`, no names |
| nlist symbol table (in the binary; stripped in Release per Strip Style) | names for linking-visible functions | function names but **no file/line**; local/static functions missing |
| DWARF (in the dSYM) | everything: files, lines, **inlined frames**, parameters | full detail - the goal |

Consequences: the strip build settings (`Strip Linked Product`,
`Strip Style`, `Strip Swift Symbols`) decide what remains in the shipped
binary, and only the dSYM restores full fidelity afterwards. Mixed
name-and-address stacks mean some frames came from the symbol table and the
stripped ones fell back to function starts.

Related facts that explain otherwise-confusing stacks:

- **`___lldb_unnamed_symbol<N>$$<module>` frames** are LLDB's synthetic
  names for functions it can locate (via function starts) but cannot name -
  the tell that the module's symbol table was stripped and no dSYM was
  found. (Scriptable check: an `SBSymbol` reports `synthetic == True`.)
- **Objective-C method names survive stripping** - the runtime needs
  selector and class metadata to dispatch, so `objc_copyClassNamesForImage`
  + `class_copyMethodList` can rebuild a name-per-address map even for a
  fully stripped binary. This is why stripped ObjC frames are recoverable
  without dSYMs (and why ObjC symbol names are never secret from reverse
  engineers); stripped Swift and C symbols genuinely need the dSYM.
- **Swift names are mangled** in symbol tables and raw `nm` output: stable
  ABI symbols start with `$s`, with module/type/member lengths and
  one-to-two-letter role suffixes encoded in the name. `atos` demangles for
  you; for raw dumps pipe through `xcrun swift-demangle`, or inside LLDB
  use `language swift demangle <mangled>`.
- **System dylibs are not files on disk** on modern macOS/iOS - they exist
  only inside the dyld shared cache (which is also why `image list` paths
  for OS frameworks point at files that do not exist, and why `nm`/`atos`
  cannot open them). OS-frame symbolication therefore depends on LLDB's
  understanding of the cache and Xcode's per-OS-version symbol caches, not
  on the paths a crash log prints.

## Symbolicating MetricKit call stack trees

MetricKit diagnostics arrive as JSON `callStackTree` structures, always
unsymbolicated. Per frame: `binaryUUID`, `binaryName`, `address`,
`offsetIntoBinaryTextSegment`, plus `subFrames` (and `sampleCount` for
sampled diagnostics like hangs). Tree-level fields a parser needs:
`callStackPerThread` (true = one stack per thread, crash-style; false =
aggregated sample tree, hang/CPU-style) and per-stack `threadAttributed`
(marks the thread the diagnostic blames - the crashing thread). Recipe:

1. Group frames by `binaryUUID`; locate the dSYM whose `dwarfdump --uuid`
   matches. Frames whose UUID matches no dSYM you own are OS frames - Apple's
   system symbols are resolved by Xcode's symbol cache, or left as-is.
2. Recover the load address: `loadAddress = address - offsetIntoBinaryTextSegment`
   (every frame of one binary yields the same value - a good sanity check).
3. Feed atos:

```bash
atos -arch arm64 -i -o MyApp.dSYM/Contents/Resources/DWARF/MyApp \
     -l <loadAddress> <address1> <address2> ...
```

Shortcut: `atos --offset` treats its inputs as offsets into the binary, so
a single MetricKit frame resolves without the load-address step - convert
`offsetIntoBinaryTextSegment` to hex and run
`atos -arch arm64 -i -o <dSYM binary> --offset 0x<hex>`.

Automate this server-side where the diagnostics land; symbolication cannot
happen on the user's device (no dSYM there) and should not happen in the app.
The iOS 27 `CallStackTree` type exposes the same data typed
(`CallStackFrame.binaryUUID`, `.offsetIntoBinaryTextSegment`,
`binaryName(from:)`), changing the parsing, not the math.

For hang/CPU diagnostics, `sampleCount` weights frames (how often the sampler
caught the thread there) - sort by it before reading.

## Third-party SDK symbol upload

Crash SDKs symbolicate server-side and need the dSYMs uploaded per build:

- Crashlytics: `upload-symbols` run-script phase (warns in-console when
  builds lack symbols).
- Sentry: `sentry-cli debug-files upload` (build phase or CI step after
  archiving).
- Datadog: `datadog-ci dsyms upload`.

Rules: upload from CI after the archive step (not from dev machines), fail
the pipeline loudly if upload fails, and remember that re-building from the
same commit produces a **different UUID** - upload the dSYMs of the artifact
you actually shipped.

**Apple's server-side symbolication**: uploading your app to App Store
Connect *with symbols* (the "Include app symbols" option) lets Apple
symbolicate Organizer crash/hang/disk-write reports server-side and enables
click-through from a stack frame to the source line in Xcode. What is
extracted is limited to function names, source file paths, and line
numbers.

## Locating and verifying dSYMs

```bash
symbols -uuid MyApp.app/MyApp                 # UUID of a binary or dSYM
mdfind "com_apple_xcode_dsym_uuids == <UUID>" # Spotlight-search dSYMs by UUID
dwarfdump --verify MyApp.dSYM                 # validate the DWARF itself
(lldb) add-dsym /path/to/MyApp.dSYM           # hand LLDB a dSYM explicitly
```

How LLDB/Xcode *find* dSYMs is configurable - the `com.apple.DebugSymbols`
defaults domain drives the lookup, which is how teams wire a **symbol
server** so every machine symbolicates any shipped build:

- `DBGShellCommands` - a script invoked with a UUID that returns a plist
  pointing at the dSYM (and optionally source paths). Point it at a script
  that queries your build-artifact store and Xcode/LLDB resolve symbols
  for any UUID on demand.
- `DBGFileMappedPaths` - a directory of UUID-structured symlinks to dSYMs;
  the filesystem-only alternative to a script.
- `DBGSearchPaths` / `DBGSpotlightPaths` - explicit search directories and
  Spotlight scoping.

A dSYM can also carry a per-UUID plist in `Contents/Resources/` with
`DBGSymbolRichExecutable` (path to the unstripped binary) and
`DBGSourcePathRemapping` - the supported way to make jump-to-source work
when builds happen on CI under different source roots.

DWARF is capped at 4 GB per binary - a project that big needs splitting
into components with their own dSYMs. For Instruments symbolication of
local builds, the app must be properly code-signed with the
`get-task-allow` entitlement (Xcode's Profile action sets this; check
`codesign -d --entitlements -` if names are mysteriously missing). Always
pass `-arch` to `atos`/`symbols`/`otool`/`dwarfdump` for universal
binaries.

## LLDB spot checks

When correlating a stack with a locally built binary:

```
(lldb) image list -b                         # loaded modules, brief
(lldb) image list MyApp                      # UUID + load address + path
(lldb) image lookup -a 0x100e4b2f0           # what is at this address
(lldb) image lookup -n functionName          # reverse: where is this symbol
(lldb) image lookup -rn 'SessionStore' MyKit # regex search, scoped to module
(lldb) image dump symtab MyKit -s address    # in-memory nm equivalent
```

Useful for verifying "does this dSYM really contain that symbol" before
blaming the pipeline. `image lookup -a` is also the quick way to check a
single suspect address from any tool's output against the live process,
and `image dump symtab` works even for shared-cache libraries that `nm`
cannot open as files.

## Failure modes checklist

- Frames show raw addresses -> dSYM missing or UUID mismatch (rebuilt
  binary, wrong build in the store).
- Frames show wrong-looking symbols -> UUID mismatch symbolicated anyway
  (forced `-l` with the wrong load address, or wrong arch slice - check
  `-arch`).
- Only app frames missing, OS frames fine -> your dSYM absent; system
  symbols came from Xcode's cache.
- MetricKit frames symbolizing to nonsense -> load address not derived per
  binary (`address - offset`), or frames from an app extension attributed to
  the app binary.
- Function names present but no file/line -> symbol-table-only
  symbolication; the dSYM was not found (check UUID with `mdfind`).
- Whole expected call chains absent from atos output -> inlining; re-run
  with `-i`.
