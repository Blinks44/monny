# App and website copy review

- Updated: 2026-10-26
- Stage: done (native copy/interface accepted by the user, 2026-10-26; website follow-up owned by WEB-001)
- Owner: unassigned; copy review ownership released
- Ownership: user paused the parallel JetBrains implementation while this review finished. Catalog/build number are available to the receiving agent again.
- Owned surfaces: app String Catalog, charging guidance, six website catalogs, refreshed AI preview, matching English Monny.sketch text and build number.
- Requirements: SPEC §§3–8, 10; six supported languages and accurate current capabilities.
- Baseline: started on main `fbc5f1b` with existing build-57 power/process work, subsequently committed independently as `bd2930e`. Preserved the parallel, uncommitted JetBrains AI implementation throughout; build 58 includes that work and does not establish its runtime acceptance.

## Delivered

Reviewed all 400 baseline app keys and all six website catalogs (EN/RU/DE/FR/ES/zh-Hans), including dynamic messages, plural branches, errors, notifications, onboarding and installation. Corrected 66 existing app keys (134 localized entries against the starting catalog), added six translations of the macOS occasional-full-charge explanation, and revised 165 website entries. The final catalog also retains seven keys added by the parallel JetBrains work.

- Preserve **Mac** in Latin script. Russian uses consistent charge-limit, memory, power, session and quota language; removes literal “window” and “sign-in expired” calques. German uses informal address consistently on the website and app. Corrected other-language grammar, reset wording and short labels.
- Explain API-key subscription readings as unavailable in Monny, rather than claiming API keys have no limits. Pace forecasts are conditional estimates. Privacy wording distinguishes system readings from enabled service queries.
- Replace the obsolete claim that Monny cannot change Optimized Battery Charging. Explain that macOS can occasionally charge to 100% for accurate battery estimates. Website installation now describes the published DMG, and the first-launch notice explains notarization without an inaccurate “paid Developer ID” claim or opaque Russian transliterations.
- Preserve source lookup keys, placeholders, plural rules and app behavior. One added charging-guidance paragraph is the only production Swift edit owned by this review.

## Saved design

Saved **Monny.sketch**, 2026-10-25. Live MCP screenshots reviewed the changed AI popover/window states, onboarding, charging guidance, website battery/AI/privacy/installation/FAQ and Implementation notes. Removed obsolete instructions to disable macOS charging before using Monny. Mobile battery copy gained room above the illustration; expanded status badges retain their pause icon without overlapping text. Refreshed the two website AI screenshot placements and `apps/website/src/assets/product/ai-limits.png` from the named 2x transparent export Frame, retaining 2320×1600 dimensions.

The first save used the percent-encoded document path twice and failed; a single save with the decoded existing path succeeded. Final save verified directly in the on-disk Sketch archive: document `8510303C-CB56-455D-BA86-F32634419712`, both image placements reference the refreshed image. No Rebind edits.

## Verification

On macOS 27.0.1, build **58** in both Debug and Release:

- All app translation format signatures match their keys; every key covers RU/DE/FR/ES/zh-Hans, with English key fallback where intended. Website message keys and substitution parameters preserved. `git diff --check` passes.
- Temporary native render review: eight surfaces × six languages × Light/Dark = **96 fixtures** (Overview, Battery charging/on-battery, charging guidance, AI low/API-key/expired states, onboarding, Settings, process no-match). Reviewed the rendered contact sheets. Fixed French power-caption/5-hour-label truncation, Russian process-sort expansion and the Russian update-button/version wrap; rerendered successfully. Numeric units in these per-view locale fixtures retain the host formatting locale; they establish text fit, not six separate system-locale acceptance runs. The review harness was removed to local temporary storage.
- `apps/monny/scripts/dev.sh test` passed **101 tests in 15 suites** on the final source. This includes the parallel agent's `JetBrainsRenderReview.swift`; its optional-appearance unwrap was corrected so the checkout compiles. Their render file and JetBrains implementation/tests remain in place for continuation. A preceding run including this review's harness passed 102 tests. Initial failures were sandbox cache access, the then-unfinished FoundationXML import, and temporary render-harness compilation; all resolved before the final pass.
- `apps/monny/scripts/release.sh` passed: signed app, nested Sparkle code, DMG integrity and signed appcast. `apps/monny/build/release/Monny-1.0.0-58.dmg`; SHA-256 **58bead4c363689c2e085ad9581f6f1bb518a987fb3b387d4902a7919d49a64ca**. Apple Development signed, not notarized. No installation, publication or charge-setting mutation.
- Website `pnpm check` passed formatting/lint/types and 12 tests; final `pnpm deploy:dry-run` rebuilt and packaged the Worker without uploading. Seven production-preview HTTP smoke tests passed for all six localized landing/404 responses, SEO, crawler files and immutable assets. Existing upstream CSS/sourcemap/chunk-size warnings remain.
- Chrome showed the revised Russian desktop and 390×844 hero with complete copy. Later Chrome capture returned empty page surfaces despite correct HTTP responses; Safari capture/input also failed to show the navigated page. Repeated all-language/all-section browser pixel acceptance is therefore **not claimed**. Live Sketch desktop/mobile text and native fixtures were reviewed; website physical-phone, all-language visual and VoiceOver checks remain under WEB-001. No native-speaker acceptance is invented.

## Terminology references

[Apple Russian Mac/battery terminology](https://support.apple.com/ru-ru/102397), [memory terminology](https://support.apple.com/ru-ru/guide/activity-monitor/view-memory-usage-actmntr1004/mac), [macOS charge-limit behavior](https://support.apple.com/en-us/102338), [Developer ID and notarization](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/).

## Current acceptance and handoff — 2026-10-26

The user accepted the current installed interface and translations. Version/model/OS and individual assistive-technology scenarios were not restated; this is broad user acceptance, not a newly observed six-language/native-speaker or VoiceOver audit. No further native copy review is required without a reported issue. Website physical-device, browser/translation/accessibility acceptance stays with [WEB-001](WEB-001-landing-page.md). New provider copy introduced after this acceptance requires its own verification in APP-015.
