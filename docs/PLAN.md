# Monny: roadmap

Updated 2026-10-28. [STATE](STATE.md) indexes implementation and open work; [SPEC](SPEC.md) owns behavior. Builds and fixture tests do not establish hardware acceptance.

## Current slice

Complete the native monitor's remaining compatibility/release checks and AI-limit account/history verification. Website design transfer/style corrections and the reviewed Monny/Rebind Sketch export handoff are ready; deployed desktop/phone review and the in-app update to 1.1.1 were accepted by the user on 2026-10-26. Specific accessibility/translation and remaining compatibility/account checks continue independently. Select a bounded slice from STATE; do not reimplement accepted features.

## App phases

1. Monitoring and history are implemented and accepted by the user on 2026-10-26 within available-device coverage. No further review is required without a concrete regression; untested hardware remains a support limitation ([verification](verification/README.md)).
2. Native charging is implemented: 80–100% slider (100% disables the limit), independent Optimized Battery Charging switch, explicit writes with read-back, persistent macOS preference. Verify the private runtime on macOS 26.4–26.x ([APP-007](tasks/APP-007-native-simplification-design-parity.md)).
3. Current app interface/translations accepted 2026-10-26; ClinePass/Codebuff added in build 64 and Amp/Augment/Nous in build 65; verify the remaining accounts/history ([DES-002](tasks/DES-002-native-onboarding-next-features.md), [APP-015](tasks/APP-015-ai-usage-limits.md)).
4. Finish clean-Mac installation and signing/update backup checks; publish only when requested ([REL-001](tasks/REL-001-signing-workflow.md)). Sparkle 1.0.0 → 1.1.0 update accepted 2026-10-25; in-app update to 1.1.1 accepted 2026-10-26; 1.1.1 → 1.2.0 not yet confirmed.
5. Deployed website accepted on desktop and phone on 2026-10-26, including AI badges and the permanent latest-download link. Only specific accessibility/translation checks remain ([WEB-001](tasks/WEB-001-landing-page.md)).

## Next features

Process search by name, PID or port, the compact sort pop-up and Needs attention are accepted and released in 1.2.0 ([DES-005](tasks/DES-005-process-port-search.md)).

The pre-release additions (grouped processes, menu bar readings, sustained-load alert, native onboarding, power draw and Sparkle updates) are implemented. Their build-37 user acceptance is dated evidence in [history](history/2026-10.md), not acceptance of later changes.

Power UI, process search and Quit/Force Quit ([DES-004](tasks/DES-004-power-search-quit-ai-tools.md)) are implemented and the current interface/translations were accepted 2026-10-26. JetBrains AI and Copilot matched their real sources in installed 1.1.0. Simple additional AI tools are authorized: ClinePass/Codebuff are implemented in build 64 and Amp/Augment/Nous in build 65, awaiting real-account agreement. Build 66 adds authentic vendor marks; the deployed website has six-language badges/selection rationale accepted on desktop and phone; remaining candidates need their own source decision. Existing-hardware acceptance does not establish every charging/accessibility edge case or Mac configuration.

Opt-in AI limits are implemented for Claude Code, Codex, Cursor, Grok, local-only JetBrains AI, GitHub Copilot (build 61, existing GitHub CLI sign-in), ClinePass/Codebuff (build 64, own CLI sessions), Amp/Augment (bounded own CLI usage commands) and Nous Portal (Hermes session, build 65). Remaining real-account/history checks belong to [APP-015](tasks/APP-015-ai-usage-limits.md); Gemini is unsupported under the current credential/privacy contract.

After release, Discharge may be researched again. Helper/SMC-write work is preserved on **experiments/discharge** at `09595b5`; main excludes it. A mechanism, safety and distribution decision is required before code on main. Sailing, heat-driven charging, calibration and trips are deferred; GPU load, battery health trends and widgets are not planned.

## Release gates

- Accepted 2026-10-21: installed charge-limit change on M1 Max/macOS 27.0.1; informal reading comparisons; six languages; build-37 keyboard/VoiceOver/contrast/motion, notifications and pre-release additions. macOS 26 was reported working, minor version unknown; this does not close 26.4–26.x charging acceptance.
- Measured: background 0.0%, dashboard 2.9% (build 29); popover about 2% (user, build 37). Conditions and limits: [idle cost](verification/idle-cost.md).
- Published 2026-10-24: 1.0.0 (build 52) on GitHub Releases and the website. Latest app release: 1.2.0 (build 69), 2026-10-28; public DMG/appcast verified. The user accepted the in-app update to 1.1.1 and the deployed desktop/phone website on 2026-10-26.
- Open: clean-Mac DMG installation, signing-identity recovery and off-device backup (update-key backup reported 2026-10-24); later feature-specific checks indexed in STATE. Apple Development candidates are signed but not notarized. Developer ID/notarization is not implemented.
