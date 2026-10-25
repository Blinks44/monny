# Monny: current state

Updated **2026-10-25**. Main is a native monitor with the macOS 26.4+ system charge limit; no helper, XPC, SMC writes or Discharge. The retired experiment and its detailed records remain on **experiments/discharge** at `09595b5`.

## Implemented baseline

- macOS 26+ / Apple silicon, SwiftUI/AppKit, Swift 6 complete concurrency. Target/module `monny`, product `Monny.app`, bundle ID `blinks44.monny`. Hardened Runtime on, App Sandbox off. Six-language String Catalog (EN/RU/DE/FR/ES/zh-Hans).
- One shared sampler: CPU/memory/disk/network/process/battery, SMC temperatures/fans and NVMe health; history 1m–7d. Unsupported readings stay unavailable.
- Native charge limit: explicit 80–100% target with read-back; 100% disables it. Independent Optimized Battery Charging switch when readable. macOS keeps/enforces the preference after quit/sleep/restart; launch/wake only read. Monitoring remains available below macOS 26.4 with an information banner. Private runtime compatibility is a limitation, not a public API guarantee.
- Native onboarding, grouped processes, optional menu bar readings, global shortcut, login item, app language, power draw and local notifications are implemented. Sparkle updates/appcast are implemented. **1.0.0 (build 52) was published on 2026-10-24** as the latest GitHub release `v1.0.0`; versions and publishing follow [RELEASING](RELEASING.md), aligned with Rebind.
- Optional AI limits for Claude Code, Codex, Cursor, Grok and JetBrains AI: popover tab, window/history/forecast, per-tool switches and low-limit alert; off by default. Enabled checks use the tools' own sign-in every 2 minutes while visible, 5 minutes otherwise, with rate-limit cooldown. JetBrains reads local IDE XML/same-IDE logs only, keeps the source timestamp and shows monthly quota/top-ups separately (build 59; real quota comparison open). Claude/Codex accepted in build 44; other accounts/history checks remain open. Gemini unsupported. [APP-015](tasks/APP-015-ai-usage-limits.md) owns evidence.
- Website: landing/404, responsive Drawer, gallery, battery illustration, installation/FAQ and six-language Paraglide SSR/SEO; responsive WebP variants prepared by Vite. Saved Monny/Rebind export and interaction handoff is ready. Twelve tests, build and Worker packaging pass. Deployed 2026-10-24 at monny.moduix.dev with the 1.0.0 download, indexing and link preview. Rebind footer-link and copy revisions are pending deployment; final device/accessibility/translation checks remain in [WEB-001](tasks/WEB-001-landing-page.md).

**Published:** `Monny-1.0.0-52.dmg` with `SHA256SUMS.txt` and `appcast.xml` on [GitHub Releases](https://github.com/Blinks44/monny/releases/tag/v1.0.0), Apple Development signed, not notarized. The live latest appcast lists build 52 and the downloaded DMG matches its checksum. [Evidence](history/2026-10.md#2026-10-24-first-release-published).

## Work and open checks

| Outcome | Stage | Next step |
| --- | --- | --- |
| [Native charging / production review](tasks/APP-007-native-simplification-design-parity.md) | awaiting_verification | Verify charge control on macOS 26.4–26.x; installed M1 Max/macOS 27.0.1 behavior accepted. |
| [Temperature/fan sensors](tasks/CORE-002-temperatures-fans.md) | awaiting_verification | Compare against an independent tool; spinning/fanless and later-chip hardware remain unverified. |
| [History and dashboard](tasks/CORE-003-history.md) | awaiting_verification | Review accumulated chart/hover behavior; retain source/load/SMART checks in task evidence. |
| [Sparkle updates](tasks/APP-012-sparkle-updates.md) | awaiting_verification | Publish the next release, then update 1.0.0 to it on an installed copy. Off-device update-key backup reported by the user on 2026-10-24. |
| [App/site copy review](tasks/APP-016-copy-localization-review.md) | awaiting_verification | Build 58: corrected six-language copy, saved Sketch, 96 native fixtures, signed DMG ready. Finish installed copy and all-language website/device acceptance. |
| [AI limits](tasks/APP-015-ai-usage-limits.md) | awaiting_verification | Real Cursor/Grok/model/credit/API-key accounts; multi-day history, expiry, alerts and long-session 429 behavior. Check mark usage before release. |
| [Website](tasks/WEB-001-landing-page.md) | awaiting_verification | Desktop and 390 px Drawer/menu review passed; finish physical-phone/all-section, keyboard/VoiceOver, reduced motion, translation and release/deployment gates. Saved Sketch export handoff is ready. |
| [Power draw, process search/quit, more AI tools](tasks/DES-004-power-search-quit-ai-tools.md) | awaiting_verification | Overview/Battery/search/process actions reported working in builds 54–57. Detailed panel/confirmation/error lifetime and accessibility checks remain open. JetBrains AI build 59: compare monthly quota/reset/top-ups with the IDE; real charging checks remain open. Remaining AI candidates are next when requested. |
| [Signing/install](tasks/REL-001-signing-workflow.md) | awaiting_verification | Clean second-Mac installation; current identity recovery and off-device signing-identity backup. |

Installed follow-ups: build-50 context-menu/Sparkle-window interaction and VoiceOver; Overview-card navigation (build 28); pressed/optimistic-switch behavior from builds 40–41 ([APP-014](tasks/APP-014-limit-slider-optimized-charging.md)). Those interactions were not separately accepted in their records; review them on the current candidate. Platform review also retains no-battery/below-26.4 onboarding ([APP-009](tasks/APP-009-native-onboarding.md)), macOS-26 Dock/Finder icon appearance ([DES-001](tasks/DES-001-missing-states.md)) and charging-flow/minimum-width Russian text ([APP-013](tasks/APP-013-power-draw.md)). Users of helper builds (≤23) must remove the helper in the old app before replacement.

## Acceptance and continuation

2026-10-25 JetBrains AI: build 59 implements local-only quota reading, same-IDE freshness, monthly/top-up separation, Settings/history/alerts and missing/stale states. All 100 permanent tests passed; 72 localized native popover fixtures and two five-tool dashboard layouts reviewed. Real IDE quota/reset/top-up comparison and installed accessibility remain open. [Evidence](tasks/DES-004-power-search-quit-ai-tools.md#jetbrains-ai-implementation--2026-10-25).

2026-10-25 copy review: build 58 passes 101 tests and signed DMG packaging; website checks/12 tests/dry-run and seven HTTP smoke tests pass. That candidate preserves the then-in-progress JetBrains work. The finished JetBrains slice is build 59 under DES-004; the reviewed copy is preserved. [Evidence/artifact](tasks/APP-016-copy-localization-review.md).

2026-10-25 next-release UI: Overview/Battery/search UI reported working in builds 53–56; specific hardware/accessibility checks remain open. Build 57 adds explicit Quit/Force Quit with confirmation, protected targets, launch-identity validation and shared-sampler refresh. All 82 tests passed, including the previously stalled search regressions and signals to test-owned children. User reports build-57 process actions work; Mac/OS and individual scenarios were not restated. Detailed runtime/accessibility checks remain open. [Evidence and next slice](tasks/DES-004-power-search-quit-ai-tools.md#process-actions-implementation--2026-10-25).

2026-10-25 website sitemap review: live XML parses with six canonical URLs and complete reciprocal language alternatives; all seven production HTTP smoke tests pass. No implementation change required. [Evidence and limits](tasks/WEB-001-landing-page.md#production-sitemap-review--2026-10-25).

2026-10-21 user acceptance: installed charge-limit change (build 27, M1 Max/macOS 27.0.1), informal reading comparisons and six languages; build-37 onboarding, readings, busy-app alert, battery power, keyboard/VoiceOver/contrast/motion and real notifications. macOS 26 worked per user report, minor version unknown. These checks do not automatically accept later changes. Performance evidence: [idle cost](verification/idle-cost.md).

[PLAN](PLAN.md) owns sequencing; task records own detailed evidence/open acceptance. Signed DMGs are not notarized. Clean-Mac installation, key recovery and first published Sparkle update remain separate release checks. Discharge/sailing/heat-driven control/calibration/trips are deferred.

Repository cleanup: [DOC-001](tasks/DOC-001-repository-cleanup.md). Historical commit references may predate the 2026-10-22 attribution rewrite. Claude Code uses native AGENTS loading and `.claude/skills`; current instructions are in AGENTS, not the history journal.
