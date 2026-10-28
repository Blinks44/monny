# WEB-002: Website refresh: show what Monny can do

- Updated: 2026-10-28
- Stage: awaiting_verification (deployed; manual checks open)
- Owner: current design/website chat (Claude Code)
- Ownership checked: main `b07c30a` at start; another chat meanwhile committed and released DES-005 (main `56782b2`, 1.2.0). Pre-existing uncommitted SPEC/DESIGN/WEB-001 edits were not this task's and were left as found.
- Owned surfaces: `Monny.sketch → 05 · Website` landing frames, notes and the `99 · Archive` page; `apps/website/` landing sections, navigation and messages; this record.
- Requirements: [SPEC §10](../SPEC.md#10-public-website) website family; user request 2026-10-28, following Rebind's WEB-002

## Outcome and scope

The site predated much of the app and its middle was generic (a six-card metric grid, four icon-tile privacy cards, centered heading rhythm). Everything between the hero and installation now shows the real mechanisms with small demos; the shared shell from SPEC §10 is unchanged.

Audit 2026-10-28 (SPEC, app sources, live Sketch, website code) found missing: optional menu bar readings, alert dot and right-click menu; power draw with the adapter split; grouped processes, search, Quit/Force Quit; the six notifications and the once-per-episode rule; sampling cadence; unavailable-not-zero sensors and thermal states; AI pace mark, Running low, Limit reached and stale readings; limit persistence. While the design was drawn, 1.2.0 shipped PID/port search and Needs attention, so the Processes section was updated to show them.

User decisions 2026-10-28: section order approved; desktop approved; old frames archived; then mobile and code.

Exclusions: no invented numbers, ratings or testimonials (every demo is labelled example values); motion only for the sampling timeline, off under Reduce Motion; no native app change.

## Acceptance

- [x] Desktop design approved by the user (2026-10-28).
- [x] Old desktop/mobile landings moved to `99 · Archive`; no prototype links pointed at them.
- [x] Mobile landing and the Port 3002 demo state; refresh notes cover interaction and motion.
- [x] Implementation and six-language copy; automated checks below.
- [x] Monny.sketch saved by the user (2026-10-28).
- [x] Deployed by the user (2026-10-28); live HTML on `/`, `/ru/`, `/de/` contains the new section anchors. First impression reported fine; no specific browser or device stated.
- [ ] Manual checks on the deployed site: desktop and phone, keyboard/VoiceOver on chip groups, Reduce Motion, translations by fluent readers.

## Sketch source

Page `05 · Website`: `Web · Landing · Desktop` (x 0, 1440 × 10033) and `Web · Landing · Mobile` (x 1540, 390 × 12421); `State · Processes demo · Port 3002 (desktop)` (x 6400); `Website · Refresh notes (WEB-002)` (x 7940). Page `99 · Archive`: `Archived · Web · Landing · Desktop/Mobile (before WEB-002, 2026-10-28)`. Header, Drawer, 404 and footer links say Menu bar instead of Features.

Order: shared header and hero; compact dashboard tabs (880 px screenshot); Menu bar; Readings; Processes; Battery; Notifications; AI limits; compact Privacy; shared Install, FAQ, final card and footer. Text column 480 and demo card 640 alternate sides; eyebrow color follows the section metric. Mobile stacks text, demo, then extras at 350 px.

Facts checked against sources: refresh options and the 10 s background cadence (`Sampler.swift`), notification defaults (`SettingsPage.swift`), thermal chip colors (`OverviewTab.swift`), energy shown as approximate watts (`ProcessList.swift`), Needs attention rule and port wording (SPEC §3, DES-005), AI cadence and states (SPEC §3), tool sources ([research](../research/ai-usage-limits.md)). App interface strings reuse the app's String Catalog translations.

## Implementation · 2026-10-28

`features/landing/feature-section` holds the shared section layout, cards, labels, result rows and chips (moduix ToggleGroup: `ChoiceChips` single-select, `ToggleChips` multi-select). Sections: `menu-bar-section` (toggles add or remove readings in the strip; menu anchored under the icon), `readings-section` (30-second timelines; a cover slides off over 30 s only under `prefers-reduced-motion: no-preference`), `processes-section` (Top apps / Port 3002 chips), `battery-section` (existing `BatteryDemo`, Charging / On battery power card, persistence card), `notifications-section`, `ai-section`, `privacy-section`. `feature-grid` and obsolete messages were removed. Numbers use `Intl` with the page locale; times use a fixed 24-hour cycle so server and browser render the same text. Navigation, footer and 404 link to `#menu-bar`; the smoke test checks the new section headings and anchors.

Verification: `pnpm check` (format, lint, types, 12 tests), production build, 7 Worker smoke tests on all six locales and `deploy:dry-run` pass. Headless Chrome captures of the production preview at 1440 px (EN, RU) and 390 px through an iframe (EN, DE) were reviewed; fixed after review: heading tracking, chart label overlapping the line, whole-percent busy value, wrapping of the long German busy line. User report the same day: the app icon in the notification banner stretched to the text height (flex default `stretch`); it now keeps 38 × 38. Not checked: real devices/Safari, keyboard/VoiceOver, live Reduce Motion, native-speaker review.

## Next handoff

Review the live site on desktop and phone, including the Processes section, keyboard/VoiceOver on the chip groups, Reduce Motion and translations.
