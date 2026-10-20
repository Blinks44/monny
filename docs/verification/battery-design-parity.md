# Battery design parity and macOS charging guidance

Date: 2026-10-19. Baseline: main at fd8ba18 plus uncommitted BAT-001–003 and APP-005 work. Agent-observed on the existing Apple silicon development Mac, macOS 27.0.1 / Xcode 27.1 / SDK 27. Scope: Battery page and its charging guidance, not a new whole-app acceptance. Task: [APP-005](../tasks/APP-005-battery-design-parity.md).

## Design and implementation

Inspected live Monny.sketch Battery Light/Dark and onboarding helper sources. Charging rows now include saved sailing/heat explanations, separators and the Sketch slider preview. The slider remains non-interactive and exposes a disabled accessible slider. Calibration has connecting lines, no-history text, a localized one-hour rest, a power reminder and primary-action styling. Trips shows disabled day/time selectors and an honest unscheduled state. No fabricated previous calibration, next departure, charging sessions or historical sensor data was added.

A two-column Layout measures content at the actual widths, keeps the 244 pt side column and aligns paired card heights. Card heights grow for long translations; calibration's footer stacks when needed. Existing helper-unavailable banner/actions and real-reading details remain intentional differences from the enabled-control Sketch fixture. The chart shows real recorded levels; charging/on-battery bands and held-at-limit summaries remain absent because the history does not store those states.

Added the information entry in both Sketch Charging cards and standalone `15 · Battery · macOS charging guidance · Light/Dark` frames. Both guidance frames were screenshot-reviewed and saved through Sketch's public API (save callback succeeded). Current document ID after save: `081DE730-41FB-4F91-AE15-49CB1E42DF8D`; frame IDs: Light `049F116B-F4C5-4C58-85E5-C6540D4285DF`, Dark `4BBCE899-DAD5-4182-9451-D36EF4FFCF1E`. Resolve IDs live on resume. No raster exports versioned.

## Checks actually performed

- Temporary native ImageRenderer harness rendered six languages, Light/Dark and content widths 620/776 pt; guidance rendered in all six languages. Inspected representative final captures across every language, including Russian/French expansion and Dark. Captures stay under `/tmp/monny-battery-polish/`. The harness was removed before final tests; no snapshot test mirroring implementation was retained.
- Live rebuilt Debug app inspected through CUA: Russian Battery titles, disabled controls, sailing/heat accessibility hints, calibration/trip structure and guidance popup. CUA captures only the app window, so the popover outside its bounds is cropped; the complete guidance was checked in native offscreen captures and the accessibility tree. This is not a full VoiceOver/keyboard audit or final user acceptance.
- The original legacy settings URL opened General. Replaced it with `x-apple.systempreferences:com.apple.Battery-Settings.extension`; clicking the corrected action in the rebuilt app visibly selected Battery in System Settings. No system charging setting changed.
- Final full `dev.sh test`: 63 tests in 11 suites passed (`/tmp/monny-battery-polish-test.log`). After the URL-only correction, `dev.sh build` and final arm64 Release packaging passed. Native signed fixture checks and DMG integrity checks passed again. No helper installed, registered or removed by the agent.
- Added 17 manual String Catalog entries in EN/RU/DE/FR/ES/zh-Hans; Xcode also extracted new entries. Existing charging-status translation remains unchanged; the controls card uses a separate noun key to avoid “Charging” being translated as a live status.

## Review artifact and remaining acceptance

Separate review package: `apps/monny/build/DesignReview/Monny-SelfSigned.dmg`, SHA-256 `576f203732ce83d0f5968709edc0272aaec2cc9be07c1f87a76ab20ce16d5602`. It uses the same persistent local certificate and status-only helper. The original BAT-003 package is unchanged (SHA-256 `4f13345f923ff7b36cca86a91e15c55d38c9d561f14c2c19bf0ae2b45aa7fc2e`). Neither package is notarized or proven installable with its daemon on a clean Mac.

Next: user reviews Battery in the review build and owns helper installation. Full keyboard/VoiceOver, Increase Contrast, macOS 26 runtime, signed daemon lifecycle and clean-machine distribution remain open. Future charging-backend coexistence must be verified before enabling control; the guidance is preparation, not proof that macOS settings were detected or that disabling them is required for monitoring.

## Generated artifact maintenance — 2026-10-19

The dated review package described above was removed as superseded generated output during [BAT-004](../tasks/BAT-004-charge-command-safety.md). Historical checks/hashes are retained. Use the latest signed status-only apps/monny/build/release/Monny-1.0-1.dmg for new checks; current artifact evidence is in BAT-004. This cleanup does not close any visual, helper installation or hardware acceptance.
