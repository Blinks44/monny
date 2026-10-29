# APP-016: macOS 15 support and release notes in the update window

- Updated: 2026-10-29
- Stage: awaiting_verification
- Owner: unassigned
- Ownership checked: 2026-10-29, released
- Owned surfaces: deployment target, onboarding layout and `PrimaryButtonStyle(isLarge:)`, `DashboardView` toolbar, process list `ForEach`, `scripts/release.sh` appcast notes, platform statements in README/SPEC/ENGINEERING/DEVELOPMENT/AGENTS/website
- Requirements: SPEC header (platform), §7 updates
- Code baseline: main `af68534`, released as `v1.3.0` (build 74) on 2026-10-29

## Outcome and scope

User decision 2026-10-29: Monny runs on macOS 15+ (Apple silicon only, unchanged). The native charge limit still needs macOS 26.4+; earlier versions keep the existing monitor-only Battery banner. Sparkle's update window shows the release notes.

## Implementation and verification

- A deployment-target-15 build reported only two macOS 26 APIs: `EnumeratedSequence` as `RandomAccessCollection` in `ForEach` (now `Array(...)`) and `sharedBackgroundVisibility` (now behind `#available(macOS 26, *)`). Sparkle 2.10 and KeyboardShortcuts support macOS 15; all 38 literal SF Symbol names exist in macOS 15 (system `name_availability.plist`). Window/popover blur is `NSVisualEffectView`, not Liquid Glass.
- `release.sh` embeds `docs/releases/<Version>.md` without its title and install section as Markdown (`generate_appcast --embed-release-notes`); a missing notes file fails the release. Notes are English only.
- 2026-10-29, macOS 27.0.1: `dev.sh test` passed 148 tests in 19 suites; `release.sh` built Monny 1.3.0 build 73, `LSMinimumSystemVersion` 15.0, appcast `minimumSystemVersion` 15.0 with an embedded `sparkle:format="markdown"` description. Build 73 DMG SHA-256 `3ed485873f747e265173c5c2c331a5ee306a96a71f6c31e9895a5654191c5d16` (superseded).
- Build 74, onboarding spacing (user report 2026-10-29: the Ready button almost touched the settings card). The fixed 532 pt Ready height was shorter than its content (card ended about 6 pt below the button row's top). Now a 16 pt minimum gap before the buttons, Sketch frame `03` insets (Ready 40 pt top and 24 pt bottom, other steps 52/30) and a minimum instead of a fixed height, so longer translations make the window taller; primary buttons use `Button/Large Primary` (40 pt, 24 pt insets). Off-repo renders of Welcome/Ready in EN/RU/DE: gap kept, Ready 533/549/546 pt content height. 148 tests pass. Repackaged after the final release-notes edit: DMG SHA-256 `7884804bdf6883f41c3473d6d31e8677d2b1be101292095cd3ad685b335d5ebb`. Website `pnpm check` (12 tests) and `pnpm build` pass with the macOS 15 copy.

## Open checks / dependency

- [x] 2026-10-29, user-reported: installed build 74 on macOS 15.6 (Apple silicon VM, Russian) works, including onboarding Ready spacing, popover, dashboard Overview/Memory/Disk and window chrome. The VM has no battery or real sensors, so temperatures/SSD health show unavailable, as expected; sensors and charge limit on macOS 15 hardware are not covered.
- [ ] Update window shows the notes when updating from 1.2.1 (after publication).
- [x] Website copy (macOS 15+) deployed by the user 2026-10-29.

## Next handoff

Update an installed 1.2.1 through Check for Updates and confirm the notes appear.
