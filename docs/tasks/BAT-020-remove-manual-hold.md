# BAT-020: Remove separate Hold-at-current-level mode

- Updated: 2026-10-20
- Stage: done (app policy, requirements and saved Sketch aligned)
- Owner: unassigned; app/design ownership released
- Baseline: main cb9abff plus preserved uncommitted native-limit/helper/UI/research work
- Owned surfaces: ChargePolicy/tests, Settings limit choices, obsolete Hold catalog entry, scoped Sketch charging components, SPEC and state/design/research records
- Requirements: user product decision; SPEC §5

## Outcome

Selectable modes are Charge and Discharge. Automatic holding at the chosen limit, Discharge endpoint and heat protection remain internal policy actions. Remove the distinct request to freeze charging immediately at the current arbitrary percentage. Native 80–100% control and its crash/helper-restart verification remain unchanged.

## Changes and verification

Removed unused app-policy Mode.hold and Reason.manualHold; retained Action.hold and the helper's internal inhibition operation. Updated the existing Discharge episode test without removing its at-limit or return-to-Charge coverage. Removed the unused six-language Hold button catalog entry. Current Battery UI has no separate mode button, so no SwiftUI layout edit is needed.

Follow-up authorized and completed 2026-10-20: removed all 17 Hold mode references in live Monny.sketch, including hidden no-battery source layers and Foundations. Two equal mode tiles/segments remain. Updated all 13 reusable limit cards to 80/85/90/95/100 and six window/calibration slider minimums to 80%, with matching knob/fill positions. Cleaned old native-reference tick names/duplicates. Preserved history axes, actual state-of-charge values and calibration discharge thresholds. Reviewed every changed component with MCP screenshots and complete Light/Dark Battery screens; fixed the selected Charge icon and Dark subtitle using existing source layers and OnAccent variable. Saved Monny.sketch through the public API; no exported PNGs or source copies in Git.

SPEC and app-policy accepted limit range are now 0.8...1; the current native UI already restricts selection to the helper's advertised 80/85/90/95/100 values. Endpoint and invalid-setting tests updated. Settings now offers only 80/85/90/95/100 and replaces an out-of-range legacy preference with 80% when opened; it never starts control. Full dev.sh test after the design/range/adapter follow-up: **187 tests in 22 suites pass**, including retained limit/Discharge/heat behavior. The earlier 13-test run below remains dated evidence of the manual-mode removal.

The initial manual-mode removal check passed **13 policy tests** on 2026-10-20; its sandboxed invocation failed on Xcode/SPM cache access before an approved rerun passed. The final build-13 Settings/range follow-up rebuild passed **19 tests in two affected suites**. Existing App Intents metadata/service warnings did not fail these runs. Signed build-13 release/package evidence is in BAT-021. Catalog JSON, scoped links and git diff --check pass. No installed-helper update, real charging/lifecycle test or Git commit.

Review: manual mode/reason/button copy are removed and product limit selection starts at 80%; automatic holding, sailing, heat pause, Discharge episode and helper internal inhibition remain. No persisted Mode or IPC migration is needed: the removed app-side enum is not Codable or wired to a live helper.

## Next action

Engineering: [BAT-021](BAT-021-adapter-diagnostics.md) implements separate authenticated read-only adapter diagnostics; installed read-only evidence is accepted; next prepare bounded adapter recovery/coexistence software. Design cleanup is saved and screenshot-reviewed; no remaining Hold/range design handoff. Real crash/helper-restart, sustained charging and broader platform checks remain owned by BAT-018/BAT-005.
