# APP-021: Weekly history and chart focus

- Updated: 2026-11-23
- Stage: awaiting_verification
- Owner: unassigned for installed verification
- Baseline: main `3edefd5`; published source `394bd5e`
- Scope: dashboard history axes/lines, sparklines, AI chart focus and companion [AI marks](APP-015-ai-usage-limits.md#complete-ai-branding--2026-11-23)

Weekly time axes show weekdays; samples retain clock times in summaries and tooltips. Missing buckets break a chart series instead of drawing through sleep or quit gaps. Weekly full-size plots and sparklines use linear interpolation. The history tier keeps bucket dates chronological, merges matching timestamps while preserving metrics across clock corrections, and normalizes old archives at load. The on-disk format is compatible. AI history follows the existing keyboard-visible focus policy while retaining hover, arrow keys, Escape and VoiceOver actions.

Evidence: live Overview/CPU and AI chart reference frames inspected in Sketch. Chronological order and six gaps were observed in the local week archive. Native renders reproduced interpolation across those gaps; the reporter's exact backwards strokes were not reproduced from that archive. Final SwiftUI CPU/Battery fixtures with a corrected timestamp and multi-hour gaps showed separated segments and weekday-only Russian ticks. Format, lint and 214 tests passed on macOS 27.2.1/Xcode 27.2, including three new history regression tests for gaps/isolated points, clock correction and legacy archives.

`release.sh` produced `apps/monny/build/release/Monny.dmg` (1.8.1/build 102), verified bundle and DMG signatures and image integrity, and generated the signed appcast. SHA-256 `b135ded9ecbf72be9b462818d0e95f8000d15a0bedac81962f06c76e542b1c2f`. Local Apple Development signed package, not notarized or published.

## 1.8.2 publication

Published [v1.8.2/build 103](https://github.com/Blinks44/monny/releases/tag/v1.8.2) from `394bd5e`. Lint and all 214 tests passed. The first packaging attempt stopped on Finder error `-10006`; the standard retry completed with strict app/DMG signature and image integrity checks. A temporary copy from the mounted DMG launched successfully. The Sparkle Ed25519 signature verifies against the app's public key. GitHub's latest endpoint returned v1.8.2, and the public appcast, checksum and DMG matched the local files byte for byte. DMG SHA-256 `d1542a8d25b00687b57e798fbb3b4ec0026ce15f9270d504a0cf5f6877ec95f7`.

Next: check Sparkle update from an installed earlier build, compare the reporter's seven-day charts and confirm that mouse hover/click has no focus outline, Tab shows the outline, arrows inspect history, Escape clears the selected sample and VoiceOver can traverse buckets and services.
