# DES-006: Readable AI quota history

- Updated: 2026-11-09
- Stage: awaiting_verification
- Owner: unassigned for installed UI verification; native implementation ownership released
- Owned surfaces: Monny.sketch window AI history cards and interaction specimens; this record, DESIGN, SPEC, STATE and history
- Code baseline: main `11c1f38`; build 92 includes the build-91 Next resets fix and its evidence
- Requirements: SPEC §4; existing native history tooltip pattern

## Outcome

AI quota history now has no permanent reset labels or repeated reset rules. One bounded tooltip identifies the nearest stored point with service, historical period when known, local bucket timestamp and quota left. The history curves and next-resets card remain. Build 92 includes the earlier build-91 forecast-inset fix.

## Verification and handoff

Saved and reviewed live on 2026-11-09: **Monny.sketch → 02 · Window → 24 · AI history · Hover details · Light/Dark**. The boards own resting, middle-hover and right-edge specimens, reusable chart/tooltip symbols and the full interaction/data/accessibility notes. Existing AI window frames 19 and 21 in both appearances now omit static reset labels/rules. The 520 × 284 pt illustrative cards retain the existing visual tokens; tooltip placement stays inside the plot. Final MCP screenshots reviewed after saving: readable curves, one selected point/guide, nonoverlapping tooltip content, and edge placement in both appearances. No routine image exports.

Decision: remove permanent event annotations rather than moving their collision into multiple simultaneous tooltips. One nearest recorded sample gives the service, its historical period, local sample timestamp and quota left. Do not infer a reset event from a quota increase. Keyboard, coincident samples, missing history, localized wrapping and existing adaptive legends are specified in Sketch; native acceptance remains open.

## Native implementation — 2026-11-09

Live saved frame 24 reviewed again before implementation; no Sketch edits in this pass. Baseline `11c1f38` plus the preserved build-91 fix. The card uses `AIQuotaHistoryChart`; `AIQuotaHistory` owns testable point selection, historical period labels, keyboard traversal and tooltip placement. The nearest stored bucket is selected in screen coordinates without interpolation or inferred reset events. Historical metric identity supplies the period; unknown periods omit it. Removed the reset-detection/annotation loop and its extra y-axis headroom. A single recorded point is drawn as a dot.

Left/Right traverse buckets, Up/Down switch services at the closest recorded time, Escape/exit hides the tooltip; coincident points retain the current service on ties. VoiceOver has a named sample value, adjustable time traversal and localized next/previous service actions in all six languages. Selections resolve against current visible data, so pruned points and disabled services do not keep stale values. Tooltip size is measured and placement flips/clamps inside the plot; labels wrap. The card keeps 284 pt as a minimum with a 180 pt chart minimum, allowing adaptive legends to grow without squeezing the tooltip. No history storage, quota math, polling or dependency changes.

Verification on macOS 27.2/Xcode 27.2: `dev.sh format`, `dev.sh lint` and final `dev.sh test` pass, **192 tests in 23 suites**. Six new tests cover point/time fidelity across refills, nearest/coincident services, missing/invalid/out-of-plot data, keyboard bounds and service changes, historical periods, and all four tooltip corners. Initial compile checks caught a missing CoreGraphics import and actor-isolated access in the test fixture; both corrected before successful runs.

Temporary NSHostingView fixtures reviewed at native size: 48 states covering six languages, Light/Dark, resting/left-edge/near-zero/right-edge selection; eight full-card states with 0/1/3/21 tools at 420/520 pt. No overlapping reset text; tooltip text, dates, names and values remain inside the plot. Empty history keeps Collecting data. The 21-tool card grows to 425/391 pt at 420/520 pt widths and retains chart room. Dark appearance captured with the native drawing appearance. Axis locale behavior is unchanged. The temporary render harness was removed before the final 192-test run; screenshots remain local. Native fixture data does not verify real account readings or installed input routing.

Final `release.sh` passes app/nested-code/DMG signature checks, image verification and signed appcast generation. **Monny 1.6.0/build 92**, Apple Development signed, Hardened Runtime, not notarized: `apps/monny/build/release/Monny.dmg`, SHA-256 `af152cbc10c2e52fa5660447051d46ad23ceb09d29710b79603a157c90565d89`. No install or publication.

Next: install build 92 and check real-history hover, Tab/arrow/Escape routing and VoiceOver traversal, including coincident same-color services. Those installed checks remain open; underlying account/reset acceptance stays in APP-015.
