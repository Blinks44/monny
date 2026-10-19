# BAT-001: Battery dashboard and charge policy foundations

- Updated: 2026-10-19
- Stage: awaiting_verification (final interactive visual check)
- Owner: unassigned
- Ownership checked: 2026-10-19, `main` at fd8ba18; released
- Owned surfaces: new `Battery/ChargePolicy.swift`, `Dashboard/BatteryPage.swift`, dashboard routing, new policy tests, related String Catalog entries, battery research and this task
- Requirements: SPEC §§4–5, phase 4 first slice
- Code baseline: `main` at fd8ba18; implementation and records uncommitted; existing STATE/PLAN/APP-004 corrections preserved

## Outcome and scope

Replace the Battery dashboard placeholder with real battery facts and history from the shared sampler. Establish a deterministic, software-tested policy for charge/hold/discharge, sailing and heat protection. Research helper installation, peer validation and firmware limits before adding any privileged writes.

This slice does not install a helper, write SMC keys or change charging. The policy is not connected to hardware; controls remain disabled and explain that macOS manages charging. Helper implementation, calibration, trip schedules and hardware acceptance follow separately.

## Acceptance

- [x] Battery page uses the live Sketch frame's card structure, real facts/history and honest unavailable values.
- [x] New copy is localized in all six languages; no unsupported feature appears active.
- [x] Policy covers limit boundaries, sailing, heat hysteresis, mode changes and fail-safe exits with deterministic tests.
- [x] Native APIs, maintained packages, licensing and firmware limitations researched and recorded.
- [x] Build/tests and final diff checked; runtime/design checks and hardware limits recorded.
- [ ] Final page reviewed interactively in Light/Dark and all six languages at minimum width.

## Sketch source

Monny.sketch inspected live through MCP on 2026-10-19 (Sketch 2026.3.1): `02 · Window`, `06 · Window · Battery` Light/Dark. The document index also identifies the popover helper-required states. No Sketch edits or save performed. Frame IDs are session-local; resolve by name.

## Implementation and verification

- Added `Battery/ChargePolicy.swift`, `Dashboard/BatteryPage.swift` and `monnyTests/ChargePolicyTests.swift`; routed Battery in `DashboardView`; added 22 String Catalog entries in six languages without changing existing entries.
- Policy is pure and dormant: no registration, XPC, SMC writes, timers or sampling added. Limits, manual modes, sailing, heat hysteresis, missing/stale/invalid input and capability changes are tested. Decisions do not prove hardware fail-safe behavior.
- Battery page reuses the sampler, KPIs and chart. Health/cycles/power have no invented history. No enforced-limit line, held-duration or calibration/trip history is shown. Lower details expose real capacities and temperature; the calibration card grows for translated labels at minimum width.
- `dev.sh build` passed; final `dev.sh test` passed (41 tests, 8 suites), 2026-10-19, M1 Max/macOS 27.0.1. Live Russian Light inspection and local offscreen renders are documented in [verification](../verification/battery-foundations.md). Full interactive verification remains open after ScreenCaptureKit failed.
- Mechanism and dependency decisions: [battery control research](../research/battery-control.md). No dependency added and no charging changes made.

## Review

The live screenshot exposed hidden switch labels and a duplicate slider label; fixed locally in the new page without changing shared controls. Narrow-layout rendering exposed truncated calibration captions; changed to wrapping text and an adaptive card height. Reviewed final policy against the existing sensor validity range, including very hot valid readings. Final diff/local links and translation placeholders checked; no temporary harness or images retained in Git.

## Open checks / dependency

Helper signing/approval, command acknowledgements, lease expiry and restoration across quit/crash/sleep/uninstall require a separate implementation and explicit hardware testing. Source research reports firmware gating even for root; a key being readable does not prove it writable. Adapter cycling is not a substitute for hold and will not be silently used.

## Next handoff

Engineering: the status-only helper/handshake now exists in [BAT-002](BAT-002-helper-connection.md). Continue with signed-artifact verification and command lease/restoration before connecting policy outputs to SMC writes.

User: review the Battery dashboard in the final build; the page is read-only and does not require helper installation.
