# Monny: current state

Updated **2026-11-08**. **1.6.0/build 90 is published** as the latest [GitHub release](https://github.com/Blinks44/monny/releases/tag/v1.6.0) (nine browser-free AI sources): 186 tests and lint pass; signed DMG and appcast uploaded ([evidence](tasks/APP-015-ai-usage-limits.md#160-publication--2026-11-08)). Apple Development signed, not notarized, minimum macOS 15. Main uses the native macOS charge limit without a helper or SMC writes; retired Discharge work remains on **experiments/discharge** at `09595b5`.

Tooling: tests and packaging use temporary Library/Caches directories removed afterwards; `dev.sh clean` clears persistent build products ([DEVELOPMENT](DEVELOPMENT.md#build-and-test)). Since 2026-11-05 `dev.sh format`/`lint` run the Xcode-bundled swift-format; the formatting-only build 88 is local and unpublished ([history](history/2026-11.md#2026-11-05-swift-formatting-agent-permissions-and-website-skill-pointer)).

## Implemented baseline

- macOS 15+ / Apple silicon (charge limit 26.4+), SwiftUI/AppKit, Swift 6 complete concurrency. Target/module `monny`, product `Monny.app`, bundle ID `blinks44.monny`. Hardened Runtime on, App Sandbox off. Six-language String Catalog (EN/RU/DE/FR/ES/zh-Hans).
- One shared sampler: CPU/memory/disk/network/process/battery, SMC temperatures/fans and NVMe health; history 1m–7d. Unsupported readings stay unavailable.
- Native charge limit: explicit 80–100% target with read-back; 100% disables it. Independent Optimized Battery Charging switch when readable. macOS keeps/enforces the preference after quit/sleep/restart; launch/wake only read. Below macOS 26.4 monitoring stays available with an information banner. Private runtime compatibility is a limitation, not a public API guarantee.
- Processes: search by name, PID or local port, single-PID details, Quit/Force Quit…, sort pop-up, Needs attention ([DES-005](tasks/DES-005-process-port-search.md)); per-app network rates and daily traffic (1.4.0).
- Native onboarding, grouped processes, optional menu bar readings, global shortcut, login item, app language, power draw, local notifications and Sparkle updates/appcast. Publishing follows [RELEASING](RELEASING.md).
- Optional AI limits for Claude Code, Codex, Cursor, Grok, JetBrains AI, GitHub Copilot, ClinePass, Codebuff, Amp, Augment, Nous Portal and Kimi Code; off by default, 2-minute visible/5-minute background checks, history and low-limit alerts. Tools reuse their own saved sign-in (JetBrains reads local IDE quota; Amp/Augment use bounded usage-only CLI commands). 1.6.0/build 90 adds OpenCode Go, Kilo, Kiro, Alibaba Token Plan/Coding Plan, cached Windsurf, CodeRabbit counts, work-account Gemini CLI and Hugging Face ZeroGPU; real-account verification is open. [APP-015](tasks/APP-015-ai-usage-limits.md) owns sources/evidence.
- Website: landing/404, gallery, product demo sections, installation/FAQ, six-language Paraglide SSR/SEO, live at monny.moduix.dev with indexing and link preview. Download buttons use the permanent `releases/latest/download/Monny.dmg` link ([WEB-001](tasks/WEB-001-landing-page.md), [WEB-002](tasks/WEB-002-website-refresh.md)).

Browser-free AI expansion is published ([source decision](research/ai-usage-candidates-2026-11.md#implementation-decision-and-result--2026-11-08)). Website source changes are committed; the user owns deployment, whose completion is not confirmed.

## Work and open checks

| Outcome | Stage | Next step |
| --- | --- | --- |
| [AI limits](tasks/APP-015-ai-usage-limits.md) | awaiting_verification | Nine new browser-free sources need real-account agreement; Kimi availability accepted on build 86; detailed quota/reset/expiry open. ClinePass/Codebuff and Amp/Augment/Nous need real-account comparison; multi-poll/new-period, other accounts/history/expiry/429 and service-mark gates remain. |
| [Sensor and layout regressions](tasks/APP-018-sensor-and-layout-regressions.md) | awaiting_verification | Fixes shipped in 1.5.0; compare temperatures/core layout on the reporter's Mac. |
| [Process network rates and daily traffic](tasks/APP-017-process-network.md) | awaiting_verification | Checked on macOS 27.2 including VPN; check macOS 15/26 when hardware is available. |
| [Native charging / production review](tasks/APP-007-native-simplification-design-parity.md) | awaiting_verification | Verify charge control on macOS 26.4–26.x; installed M1 Max/macOS 27.0.1 behavior accepted. |
| [Fan-control feasibility](tasks/APP-019-fan-control-feasibility.md) | planned | Research ready; quieter curves need a separate product/service decision. No app feature, helper or fan writes. |
| [Website](tasks/WEB-001-landing-page.md) | awaiting_verification | Desktop/phone accepted 2026-10-26. Keyboard/VoiceOver, reduced-motion and fluent translation checks remain. Shared shell with Rebind: SPEC §10. |
| [Website refresh: product demos](tasks/WEB-002-website-refresh.md) | awaiting_verification | Deployed 2026-10-28; desktop/phone, keyboard/VoiceOver, Reduce Motion and translation review open. |
| [Power draw, process search/quit, more AI tools](tasks/DES-004-power-search-quit-ai-tools.md) | awaiting_verification | Power/process UI and translations accepted 2026-10-26; APP-015 owns remaining AI account checks. |
| [Onboarding and Settings design](tasks/DES-002-native-onboarding-next-features.md) | awaiting_verification | Long-language check of the Settings frame revision. |
| [Signing/install](tasks/REL-001-signing-workflow.md) | awaiting_verification | Clean second-Mac installation; identity recovery and off-device signing-identity backup. |

Also open: the 2026-11-08 installed-update failure coincides with HTTP 504 from public appcast delivery; [release evidence](tasks/APP-015-ai-usage-limits.md#160-publication--2026-11-08) owns the incident and retry check. Earlier update acceptance into 1.5.0 is also unconfirmed; native-speaker and deployed-site review of the 2026-10-28 copy revision.

Known coverage limits: fanless/later-chip Macs, no-battery or below-26.4 onboarding, macOS 26 icon/special states, tinted-wallpaper menu bar, and sensors/charge banner on real macOS 15 hardware (only a VM was checked). Revisit with an actual issue or suitable device. Users of helper builds (≤23) must remove the helper in the old app before replacement.

## Acceptance record

- 2026-10-26: available-device monitoring/history and the current interface/translations accepted ([verification](verification/README.md)); no independent source comparison, assistive-technology audit or hardware matrix is claimed.
- 2026-10-21: installed charge-limit change (build 27, M1 Max/macOS 27.0.1), informal reading comparisons, six languages, build-37 onboarding, alerts, keyboard/VoiceOver/contrast/motion and real notifications. macOS 26 reported working, minor version unknown. Performance: [idle cost](verification/idle-cost.md).
- Release-by-release acceptance and publication evidence: [history](history/README.md).

[PLAN](PLAN.md) owns sequencing; task records own detailed evidence. Discharge, sailing, heat-driven control, calibration and trips are deferred. Claude Code uses native AGENTS loading and `.claude/skills`.
