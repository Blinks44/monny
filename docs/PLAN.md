# Monny: roadmap

Updated 2026-10-25. [STATE](STATE.md) indexes implementation and open work; [SPEC](SPEC.md) owns behavior. Builds and fixture tests do not establish hardware acceptance.

## Current slice

Complete the native monitor's remaining compatibility/release checks and AI-limit account/history verification. Website design transfer/style corrections and the reviewed Monny/Rebind Sketch export handoff are ready; final interaction/device/translation and release acceptance continues independently. Select a bounded slice from STATE; do not reimplement accepted features.

## App phases

1. Monitoring and history are implemented. Finish independent sensor comparisons and accumulated-history chart/hover review ([CORE-002](tasks/CORE-002-temperatures-fans.md), [CORE-003](tasks/CORE-003-history.md)).
2. Native charging is implemented: 80–100% slider (100% disables the limit), independent Optimized Battery Charging switch, explicit writes with read-back, persistent macOS preference. Verify the private runtime on macOS 26.4–26.x ([APP-007](tasks/APP-007-native-simplification-design-parity.md), [APP-014](tasks/APP-014-limit-slider-optimized-charging.md)).
3. Copy review and six-language native text-fit fixtures are ready in build 58 ([copy review](tasks/APP-016-copy-localization-review.md)); finish installed localization acceptance and AI limits on the remaining accounts/history ([DES-002](tasks/DES-002-native-onboarding-next-features.md), [APP-015](tasks/APP-015-ai-usage-limits.md)).
4. Finish clean-Mac installation and signing/update backup checks; publish only when requested ([REL-001](tasks/REL-001-signing-workflow.md)). Sparkle 1.0.0 → 1.1.0 update accepted 2026-10-25 ([APP-012](tasks/APP-012-sparkle-updates.md)).
5. Review the implemented `Monny.sketch → 05 · Website` transfer in an active browser at desktop/390 px, finish accessibility/translation acceptance; deployed 2026-10-24 with the 1.0.0 download and indexing ([WEB-001](tasks/WEB-001-landing-page.md)).

## Next features

The pre-release additions are implemented: grouped processes ([APP-008](tasks/APP-008-grouped-processes-keyboard-idle-cost.md)), menu bar readings ([APP-010](tasks/APP-010-menu-bar-readings.md)), sustained-load alert ([APP-011](tasks/APP-011-busy-app-alert.md)), native onboarding ([APP-009](tasks/APP-009-native-onboarding.md)), power draw ([APP-013](tasks/APP-013-power-draw.md)) and Sparkle ([APP-012](tasks/APP-012-sparkle-updates.md)). Their build-37 user acceptance is dated evidence, not acceptance of later changes.

Next release ([DES-004](tasks/DES-004-power-search-quit-ai-tools.md), design accepted 2026-10-25): Overview/Battery UI reported good in builds 53–55; specific charging/accessibility checks remain open. Process search reported working in build 56; Quit/Force Quit implemented in build 57 with 82 passing tests and reported working by the user; detailed runtime/accessibility checks remain open. JetBrains AI is implemented in build 59 from local IDE quota data, awaiting comparison with a real IDE quota. Next when requested: Windsurf or another researched AI candidate that works from its own local sign-in.

Opt-in AI limits are implemented for Claude Code, Codex, Cursor, Grok, local-only JetBrains AI and GitHub Copilot (build 61, existing GitHub CLI sign-in). Remaining real-account/history checks belong to [APP-015](tasks/APP-015-ai-usage-limits.md); Gemini is unsupported under the current credential/privacy contract.

After release, Discharge may be researched again. Helper/SMC-write work is preserved on **experiments/discharge** at `09595b5`; main excludes it. A mechanism, safety and distribution decision is required before code on main. Sailing, heat-driven charging, calibration and trips are deferred; GPU load, battery health trends and widgets are not planned.

## Release gates

- Accepted 2026-10-21: installed charge-limit change on M1 Max/macOS 27.0.1; informal reading comparisons; six languages; build-37 keyboard/VoiceOver/contrast/motion, notifications and pre-release additions. macOS 26 was reported working, minor version unknown; this does not close 26.4–26.x charging acceptance.
- Measured: background 0.0%, dashboard 2.9% (build 29); popover about 2% (user, build 37). Conditions and limits: [idle cost](verification/idle-cost.md).
- Published 2026-10-24: 1.0.0 (build 52) on GitHub Releases and the website.
- Open: clean-Mac DMG installation, signing-identity recovery and off-device backup (update-key backup reported 2026-10-24); later feature-specific checks indexed in STATE. Apple Development candidates are signed but not notarized. Developer ID/notarization is not implemented.
