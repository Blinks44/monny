# DES-007: AI recovery notifications, charging diagnosis and sleep battery report

- Updated: 2026-11-09
- Stage: awaiting_verification
- Owner: current Codex chat; implementation complete, installed acceptance open
- Ownership checked: main `c0e3f29`; scoped uncommitted app/docs changes
- Requirements: SPEC §4, §7; design source in DESIGN
- Code baseline: main `c0e3f29` plus this task's uncommitted changes, build 93

## Outcome and scope

Designed first in Monny.sketch, then implemented the three selected features. Other brainstorming proposals remain deferred. No installation, publication, charging setting change or new dependency.

- AI limit restored: separate off-by-default checkbox in Notifications. An exhausted quota must be observed while enabled, followed by a newer fresh available reading from the same authenticated HTTP session. One alert per episode, grouped by tool; periods and remaining quotas are named and clicking opens AI usage. Initial/stale readings, timers, opt-out, hidden source, sign-out/expired session, changed session or plan do not trigger recovery. An in-memory SHA-256 context is excluded from persisted AIUsage. Polling remains unchanged.
- Charging diagnosis: Battery dashboard guidance distinguishes charging, measured discharge on adapter, reached native limit, unknown not-charging cause, waiting for fresh power, and unavailable. Reuses measured battery flow and native limit readback. Popover report link is independent of native-limit support. No invented cable fault, wall-power measurement or system pause reason.
- Sleep report: paired workspace events and recent shared gauge readings, with a post-wake gauge timestamp. Wait 60–120 seconds; missing readings stay unavailable. Last sleep and inline recent intervals show elapsed wall time and percentage-point change. At most 100 completed reports over seven days persist; pending intervals do not survive restart. No wake requests, assertions, logs or new sleeping timers.

## Sketch source and review

Monny.sketch saved and reviewed live on 2026-11-09. Page 01 frame 30 owns popover navigation; page 02 frames 25–29 own state boards, expanded Battery content, Settings and recent intervals; page 03 frames 14–15 own recovery behavior and native notification specimens. Light/Dark use existing tokens/symbols plus reusable Insight/Status card sources. Frame 27 is expanded scroll content, not a taller default app window. Final screenshots confirm readable states, entry links and nonoverlapping source notes. Save callback reported success; document identity refreshed after saving.

Native differences: cards grow with content rather than keeping the 184 pt specimen height. Recent intervals use DisclosureGroup and wrapping summaries instead of a fixed table. Native formatting is locale-aware; report readings remain distinct from estimates.

## Verification

On macOS 27.2 / Xcode 27.2: `dev.sh format` and `dev.sh lint` pass. Final `dev.sh test` passes **201 permanent tests in 25 suites**. Nine added tests cover measured discharge priority, missing readings, paired/fresh sleep endpoints, charge gains, persistence/restart/retention, one-shot recovery, stale/reset/account changes, opt-out/unknown session and exclusion of session context from saved data. Earlier test compilation exposed a Swift Testing mutating-expression macro issue; evaluated the result before #require and reran successfully.

A temporary native render fixture passed separately (202 tests including the fixture), then was removed before the final test run. Captured 12 Light/Dark cards with six locale environments. Russian app-bundle copy, native Light/Dark geometry and locale-driven view labels/number formatting were inspected; this is not six separate app-language launches. Transparent Dark captures required an opaque backdrop for meaningful visual review. No source Theme changes. Full installed six-language/VoiceOver/keyboard acceptance remains open.

`release.sh` succeeds: **Monny 1.6.0/build 93**, arm64, Apple Development signed, Hardened Runtime, not notarized or published. Script verifies app/nested signatures, DMG integrity/signature and produces the signed Sparkle appcast. Artifact: `apps/monny/build/release/Monny.dmg`; SHA-256 `11339dafa08c25912887c7d4237dfb35bb71fe39096bb067bd42366eeb149ac3`. The app's Info.plist reports build 93; independent shasum agrees with SHA256SUMS.txt. A final lint and diff check pass after packaging. Local documentation link targets resolve.

## Limits and next verification

Recovery is currently available through the shared authenticated HTTP usage decoder. Local/CLI-only quota sources (JetBrains, Amp, Augment, Alibaba and cached/count-only sources) lack continuity evidence and do not send recovery alerts. Token rotation conservatively cancels the pending episode. Existing quota display/history is preserved. Full account/reset agreement and real notification routing/permissions/Focus remain open.

Sleep reports measure net endpoint change, not continuous sleep, wake reasons or a responsible process. Intermediate charging cannot be ruled out from two battery endpoints. Verify one real unplugged sleep/wake interval and missing/plugged endpoints; compare against system battery readings. No real sleep was forced for this task.

Next: install build 93, enable AI limit restored, confirm a real exhausted-to-available event, then check Battery after an unplugged overnight sleep and an adapter reconnect. Check both appearances, keyboard/VoiceOver and all six app languages. Runtime acceptance remains open until those observations are supplied.

## 1.7.0 publication preparation — 2026-11-09

Publication authorized. Source/package version advances to 1.7.0/build 94, above the shared build-93 review DMG. Release includes the previously unpushed AI-history hover and forecast fixes. Short release notes are in releases/1.7.0.md; real account/hardware acceptance remains open. Release candidate lint and all 201 tests in 25 suites pass on macOS 27.2/Xcode 27.2. Packaging and publication evidence follow here.
