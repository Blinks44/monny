# APP-007: Native-only charging, design parity and copy review

- Updated: 2026-10-21
- Stage: awaiting_verification (native-only build 25 packaged; installed UI/platform acceptance open)
- Owner: user / app engineering; implementation ownership released for review
- Baseline: main abe3a80; clean at start
- Preserved experiment branch: experiments/discharge at abe3a80 (all source, tests, research and hardware receipts)
- Owned surfaces: app/helper removal, native setting bridge/controller, shared UI, all six translations, current contracts and release packaging

## Authorized outcome

Remove Discharge experiments from main, simplify the whole app, investigate direct macOS 26.4+ charge-limit access, implement feasible existing designs without editing Sketch, audit typography/spacing/battery presentation and all EN/RU/DE/FR/ES/zh-Hans copy. Do not build the website or invent unsupported hardware behavior.

## Acceptance

- [x] Preserve complete prior work on a named separate branch before deletion.
- [x] Main has no SMC writer, experimental charge commands, privileged helper or XPC if direct setting is supported.
- [x] Native setting reads/writes run serially off main; unknown APIs fail unavailable; no startup/wake replay.
- [x] Existing Sketch frames inspected live; changed app views reviewed in Light/Dark and all languages.
- [x] All retained interface text reviewed; loading explains collection, unavailable readings remain distinct.
- [x] Build/tests/signed candidate reviewed; open real hardware/platform/localization checks explicit.

## Direct-native investigation — 2026-10-21

An independently compiled ordinary-user probe calls the existing runtime-validated bridge without helper/root/private entitlements. Current-value setter succeeds and preserves endpoints. A distinct supported target setter also succeeds and reads back. Reasserting enable succeeds but resets the target on this runtime: the initial immediate endpoint comparison detects this, so a final ordinary-user target restore returns and reads back the original enabled/limit pair. No adapter isolation or helper install. Raw machine settings stay temporary. Controller must enable only when needed, before setting target, and verify the resulting pair. This confirms local access on the observed Apple silicon/macOS 27.0.1, not macOS 26.4 execution or guaranteed private API availability elsewhere.

The native setting is user-owned and persists after quit, as requested. macOS enforces it; no journal, session lease, restoration-on-quit or recurring charging policy is required for this preference contract. Errors re-read state and explain how to check System Settings. This supersedes the old temporary Monny-owned native session behavior in SPEC. Old helper is already removed by BAT-030; upgrading another installation must remove its old helper using the prior build before replacement.

## Design source

Live read-only Monny.sketch document 97DFF3F8-C639-4B3E-BA4D-979274B443DB, 2026-10-21. Popover Battery hero 328×178, gauge 288×72, 32-point white value, separate dotted target/label; footer 12-point medium, header 16-point bold. Existing native control standalone frames govern narrower functionality; other experiments remain deferred. Sketch source is not edited or saved. Screenshots are local evidence only.

## Next

User installs the native-only build 25, reviews Battery/popover/window/text, then tests one explicit native limit change/read-back and persistence. No helper installation; do not re-run adapter experiments. Installed signed UI access, macOS 26.4/other hardware, full VoiceOver and real notification delivery remain open. No automatic installation or publication.

## Final implementation and checks

Main removes the complete helper target/embed phases, all charging XPC/session/journal/lease code, mutable SMC path, eight adapter experiment commands, separate diagnostics, charge policy and their tests/scripts. Read-only SMC sensor code is retained in Readings; the existing small runtime-checked native bridge/model/decoder move into the app. No new dependency, root operation, helper install/removal or adapter isolation is added. The experiment branch is a complete Git snapshot, not a partial file copy. Historical BAT records are explicitly labelled as historical; current instructions/SPEC/PLAN/STATE no longer require the removed architecture.

ChargeLimitController plus NativeChargeLimitStore serialize reads/explicit writes, positively gate macOS 26.4/runtime/targets, avoid unnecessary enable and verify actual state. Failed writes re-read and show failure, never claim success or repeatedly overwrite system settings. Native toggle and stepped slider are shared by Settings, Battery and popover. Context menu disables the system limit or sets 100%; no disguised temporary override. Launch/activation/wake only read; quit leaves the preference with macOS. Real local ordinary-user probes above validate direct access; installed signed app operations remain a user check.

The native Battery hero and dotted target replace the small wrong gauge. Header/footer typography, 16-point window content insets, y=20 toolbar, wrapping settings columns and readable collecting-state explanations follow the inspected source. Native setting controls are implemented; advanced cards from unchanged Sketch remain visibly disabled with availability help, not fake automation. Charge-limit notification now requires measured adapter/not-charging state and level at least the actual enabled target; it fires once per episode, with no estimated threshold or setter loop. Non-battery review also guards process CPU/energy/I/O deltas against recycled PID/reset-counter underflow instead of reporting huge wrapped rates.

Reviewed all **276 retained catalog entries** in EN/RU/DE/FR/ES/zh-Hans, removed obsolete helper/experimental copy, completed new strings and corrected unnatural terms (memory reservation, SSD state, process headings, collecting states and system-preference persistence). Six-language coverage and format argument types are checked, including preserved plural forms. Names/units still follow locale/region; language selection applies after restart as before. Translations are reviewed engineering copy, not a claim of independent native-speaker acceptance.

Final **dev.sh test: 34 tests in 9 suites pass**, including injected native setting order/idempotence/disabling/invalid target/unavailable/failure cases, notification episode/rearm and retained reading/history/alert/sensor/bundle tests. Interface review generates **252** local renders: eight pages at 900/1040 widths × six languages × two appearances, three popover tabs × six × two, the populated Battery fixture × six × two, and the older-OS availability notice × six × two. Popover control-height assertions pass. Visual review covers the Battery gauge, settings/long text, all eight page types and footer; small-width KPI labels may still use standard truncation, with full accessibility text. No full interaction/VoiceOver claim follows from snapshots. An early ideal-size assertion falsely treated responsive NSHostingView.fittingSize as fixed-window overflow; it was replaced by actual constrained renders and the Battery height check. Render windows are reused to avoid a test-harness live-window warning.

Live GUI inspection of the current executable through computer-use timed out twice (-10005); no unsupported GUI mechanism or old screenshot substituted for final live acceptance. Earlier visible app data belonged to the previous process and is not final-artifact evidence. Actual installed UI/keyboard/VoiceOver review remains open. Xcode emits non-fatal Shortcuts service and Charts anchor diagnostics during offscreen rendering; no app crash/test failure is observed.

At the initial build-24 cleanup, production app/helper source reduced from **10,645 to 6,387 physical lines** (4,258 fewer, including comments/blanks). Tests/process fixtures reduced from **5,730 to 430** (5,300 fewer); the old tests remain with the old implementation on experiments/discharge. Removed tests do not establish current platform acceptance; retained/new tests match the native-only contract.

## Older macOS availability

Below macOS 26.4, NativeLimitControls replaces the slider/toggle with the existing informational Banner: charge limits require macOS 26.4, update the system to use this feature, and battery monitoring remains available. The same view serves the Battery page, popover and Settings. All six localizations are provided. An injected availability flag renders the older-OS branch at 328 points in Light/Dark; twelve notice renders fit within 260 points and representative RU/DE renders are reviewed. This simulates interface availability on the current OS; execution on macOS 26.0–26.3 remains open. No charging operations are run for this check.

## Signed native-only candidate

`apps/monny/build/release/Monny-1.0-25.dmg`, SHA-256 `fa48166eb5aeff7b8d0613671e215c4e9efdfa8f58afcfafc8151bda2df0cfa0`. Existing Apple Development signer and Hardened Runtime retained; signed, not notarized. Release build, strict app/DMG signatures and image checksum pass. Separate read-only mount review confirms build 25/bundle identity, exact signed staging app binary, all six localized resources, Applications link and **no HelperTools/LaunchDaemons**. The six packaged localizations include the new availability message. Python’s .strings encoding parser failed on the first resource inspection; the system plutil reader verified all resources successfully. Package review performs no settings mutation or installed-app replacement. Xcode leaves empty old embed directories in incremental output; packaging rejects any contents and removes only empty directories before signing. No bypass of a surviving helper binary.

Shell syntax, affected documentation file links, Git whitespace, source/output visibility and branch preservation checked. At the user’s request, the final app source and records are saved together in one main-branch commit. No push or Sketch save; all previous experiment work remains reachable at the named branch.
