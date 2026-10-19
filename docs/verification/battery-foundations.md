# Battery dashboard and policy foundations

- Date: 2026-10-19
- Revision: `main` at fd8ba18 plus uncommitted [BAT-001](../tasks/BAT-001-battery-foundations.md) files
- Environment: Apple M1 Max MacBook Pro, macOS 27.0.1, Xcode 27.1; Debug build
- Evidence: agent-observed live app/Sketch, injected policy tests and temporary offscreen AppKit rendering

## Build and behavior

`apps/monny/scripts/dev.sh build` passed. Final `apps/monny/scripts/dev.sh test` passed: 41 tests in 8 suites. The initial sandboxed build could not write Xcode/SwiftPM caches; the normal build succeeded with the tool's approved cache access. No compiler errors remained. Xcode emitted its AppIntents metadata warning; test-host logs also contain system autoShortcut connection warnings, without test failures.

The 13 new policy tests cover limit endpoints, exact sailing boundaries, default deadband, Hold, Discharge stopping without recharging, settings/mode changes, heat priority and two-degree hysteresis, very hot valid readings, missing/invalid temperature, invalid settings/level, unavailable capability, stale/future observations, disconnected power and re-enabling after release. These use injected values. They verify decisions only; there is no helper or hardware executor.

## Visual and localization checks

Inspected the live Monny.sketch Battery Light/Dark frames through MCP, without editing or saving Sketch. Live Russian Light inspection of the running app confirmed real battery facts and a filled chart, disabled controls and the off banner. It exposed missing visible switch labels and a duplicate slider label; both were fixed in the new page.

A temporary hosted test rendered the final page with a 620 pt content width (900 pt minimum window minus sidebar/margins) in all six language environments and Light/Dark, without changing user preferences. It used a fresh sampler and exercised collecting-history/unavailable-health states. The renders exposed truncated calibration captions in French/Spanish; wrapping labels and adaptive card height fixed them. Reviewed captures confirm visible switch labels, a single slider caption, wrapped calibration steps and a readable Russian Dark layout. Some repeated offscreen captures omit glyphs, so they do not establish complete per-language visual acceptance. The temporary harness was removed; captures/logs stay under temporary storage, outside Git.

Final interactive capture was blocked by ScreenCaptureKit error -3811 after rebuilding. Full final live verification in Light/Dark, all six languages, keyboard navigation and VoiceOver remains open. The no-battery route reuses the existing empty state but was not checked on battery-free hardware. No new performance or macOS 26 runtime measurement was made.

## Hardware boundary and next check

No helper installed, charging keys written, settings changed or charge modes activated. The policy is not connected to the sampler or any executor. Calibration/trips are disabled previews. Firmware compatibility is based on [source research](../research/battery-control.md), not a probe of this Mac.

Next: review the final Battery page live; independently implement signed helper registration, peer validation, version/capability handshake and restoration/lease lifecycle before requesting authorized hardware charge tests.
