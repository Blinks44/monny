# BAT-008: Helper recovery and popover setup regressions

- Updated: 2026-10-19
- Stage: awaiting_verification
- Owner: unassigned; code/design checks complete
- Baseline: main 1dc16bd with preserved uncommitted BAT-005/007, UI and packaging work
- Owned surfaces: helper removal policy, shared actions/copy, popover panel event handling, build number, scoped Sketch references, tests and affected records

## Outcome

User reports registered helper without connection, failed removal, uncontained setup actions and popover closing during removal. Installed helper hash matches BAT-007 artifact. Read-only launchd/log/crash inspection identifies CODESIGNING 4 Launch Constraint Violation (AMFI c[5]p[1]m[1]e[0]), EX_CONFIG/spawn failed. Static app/helper signatures pass and signer is unchanged. This is an OS launch restriction before helper startup, not evidence of a missing keychain file or a Swift lifecycle crash.

## Acceptance

- [x] Explicit removal can unregister this status-only release when transport is unavailable; future charging backends still require restoration acknowledgement and invalid/mismatched replies remain blocked.
- [x] User confirms helper removal succeeds and the popover remains open. Separate Escape/outside-click and accessibility review remains open.
- [x] Shared action block follows live Sketch with a primary action and secondary removal control; six-language Light/Dark layout checked.
- [x] Tests and signed release pass; installed OS launch recovery is recorded separately from static checks.

## Limits

No automatic service install/removal, root shell, trust/SIP/Gatekeeper modification or global background-item reset. Do not advertise a build-number change or static signature success as proof of restored OS launch. User-owned runtime acceptance remains required.

## Implementation and evidence — 2026-10-19

Unreachable transport (connectionFailed/timedOut) now permits explicit SMAppService unregister only for the shipped notImplemented/non-writing contract. Injected operations default to acknowledgement-required. Invalid, mismatched, cancelled or restoration-failure replies never permit this exception; tests retain the stricter default and verify both transport recovery cases, rejected responses and failed system unregister. No manual launchctl/bootstrap/unload path was added. SPEC/ENGINEERING document this narrow status-only exception; any charging-capable contract must require restoration acknowledgement.

MenuBarPanel's local/global outside-click monitors now defer dismissal during helper confirmation/busy operations and attached/modal sheets. Escape and explicit status-item toggling remain unchanged. The confirmation state clears when its view disappears. This addresses clicks in an alert/system authorization being mistaken for outside dismissal; real confirmation/password interaction still needs runtime acceptance.

Popover setup actions are contained in a shared-style card with a status chip, full-width primary retry/install/allow button and separate confirmation-protected trash button. Bare removal links and native More-menu clicks are removed from the failed/pending states. Six-language connection copy explains registered-but-unresponsive status and explicit recovery. ImageRenderer produced all six Light/Dark variants at 328 pt content width; Russian Light and German Dark were directly inspected with no clipped action/heading. The temporary harness was removed. Keyboard/VoiceOver and real authorization remain open.

Live Monny.sketch (Sketch 2026.3.1), page 03, saved scoped recovery references: Light 5C86A697-2365-43EB-AEC1-2C693C077B0F and Dark EBC9CA9F-3A54-47C8-A49F-BAC68637FDF6. Existing button/banner/chip symbols and color variables reused; both final frames screenshot-reviewed. Pending-approval behavior annotations updated to the secondary trash action; no unrelated frames changed.

Permanent suite: **101 tests in 14 suites passed** via dev.sh test. Signed release.sh passed arm64 build, positive/negative native signing fixtures, strict app/helper/DMG signatures and hdiutil integrity. Artifact: apps/monny/build/release/Monny-1.0-2.dmg, SHA-256 **74f9c206ac137ac16e27b1c33169dbf42ebaeb00fe5edcd86929ad6ddc8a3175**. App/helper build settings incremented to 2 (marketing/protocol/helper wire versions unchanged). This removes repeated build-1 ambiguity; it is not proof that OS launch constraints are repaired. Signing identity is unchanged. No agent app installation, service removal/reinstall, reboot, trust/security change or charging write.

## OS launch finding and next action

Installed helper binary SHA-256 8f1d86dbcb9f88b69de8432b38f2b1eb2b1ff456585744998e67fb029878f303 matches the prior BAT-007 package. The service is registered/enabled, but launchd rejects launch; crash report records CODESIGNING 4, Launch Constraint Violation. amfid reports an unknown certificate chain for the self-signed helper; static verification succeeds. The observed immediate cause is OS launch policy before main, not missing files, deleted private-key storage, native sleep-hook failure or a proven XPC implementation fault. Raw logs/crash data remain outside Git.

[Apple DTS's matching failure discussion](https://developer.apple.com/forums/thread/799933) distinguishes embedded constraints from service-applied constraints and documents cases involving background-item state. It does not prove that this self-signed installation is supported or that a reboot fixes it. No custom launch constraints, global resetbtm, quarantine removal or trust exception added.

User subsequently supplied a successful installed-app diagnostic reply (BAT-007). This confirms a diagnostic-capable helper now responds; the previous launch block is no longer observed in that reply. Exact artifact hash/build, reboot/reinstall sequence and process uid were not independently captured. No causal claim that build-number increment/reboot fixed OS policy. User subsequently confirms helper removal succeeds and the popover stays open. This closes the reported removal/dismissal regressions; the exact authorization sequence was not separately described. Visual acceptance and keyboard/VoiceOver review remain open.

Next user check: review the corrected helper styling; no further removal test is needed for the reported regression. Engineering: native getter-only diagnostics are now verified in BAT-011. Recurring build-3 OS launch rejection is owned by BAT-003 and the [dated signing evidence](../verification/self-signed-helper.md#recurring-launch-rejection-on-build-3--2026-10-19); the earlier blank cdhash rendering does not establish an empty rule. Do not repeat the completed diagnostic as a prerequisite. Keep native lifecycle and clean-Mac distribution gates open.

Build-4 policy update: [BAT-016](BAT-016-manual-native-verification.md) adds explicit native writes, so live operations now always require a compatible restoration/non-controlling acknowledgement. The offline-removal exception above describes the earlier non-writing artifact and retained test fixtures, not the current writer-capable build.
