# CORE-003: History for the 1m–7d ranges

- Updated: 2026-10-18
- Stage: implementing
- Owner: unassigned
- Owned surfaces: `Readings/History.swift`, `Readings/Sampler.swift` cadence, `monnyApp.swift` load/save, `Sparkline` component
- Requirements: SPEC §4 (history, "Collecting history"), research [history decision](../research/README.md#history-storage-decision); phase 3
- Code baseline: `main`; store committed after e1b21b1

## Outcome and scope

Readings are kept for the 1m, 1h, 24h and 7d ranges and the 24h/7d tiers survive a restart, so charts can be built on them. First consumer: the network sparkline in the popover Overview card.

## Acceptance

- [x] Four tiers: 1 s buckets over 60 s, 10 s over 1 h, 1 min over 24 h, 10 min over 7 d; averages per bucket, unavailable readings not stored, gaps kept.
- [x] Sampler reads every 10 s while nothing is visible (no process enumeration), at the user's rate while visible.
- [x] 24h/7d saved as a binary plist in `~/Library/Application Support/blinks44.monny/History.plist` every 5 minutes and at quit, loaded off the main actor at launch.
- [x] Popover network sparkline from the 1m tier; fewer than two points draw nothing.
- [ ] Dashboard charts and sparklines on the tiers, with the "Collecting history" state (next).
- [ ] Background cost measured over a few minutes with the popover closed.

## Implementation and verification

- Tests: bucketing average, span trimming, sleep gaps, unavailable values, plist round trip (`HistoryTests`, 5 tests). `dev.sh test`: 21 tests pass.
- Quit via AppleScript after 25 s wrote `History.plist` (622 bytes); `plutil -p` showed the pending 1-minute bucket with sums and counts for all 12 metrics.

## Next handoff

Engineering: build the dashboard charts (Overview KPI sparklines, CPU load and temperature, 24 h battery level) on `History` with the "Collecting history" state from Sketch, then measure idle cost.
