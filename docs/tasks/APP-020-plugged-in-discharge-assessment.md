# APP-020: Plugged-in discharge assessment

- Updated: 2026-11-16
- Stage: planned
- Owner: assessment session complete; implementation unassigned
- Owned surfaces: this task, discharge research and affected planning indices; no app/Sketch ownership
- Requirements: feasibility comparison only; SPEC §5 and main's no-isolation/no-helper boundaries unchanged
- Code baseline: main `c25bea9`, 1.7.0/build 94; earlier APP-019 documentation changes preserved

## Outcome and scope

Assessed one manual discharge to 20% while connected to a charger/monitor, followed by ordinary charging. No sailing mode or recurring automation. [Research](../research/plugged-in-discharge.md) records health evidence, historical branch findings, current dependency leads, risks and acceptance gates.

Recommendation: do not position twice-weekly discharge as battery care; use the existing native charge limit for constant desk power. Discharge is narrower than fan-control research and has historical Monny groundwork, but its closed-lid/monitor requirement and reliable restoration are unresolved. An optional one-off discharge to the existing limit (e.g. 80%) is a different, potentially useful proposal for user review; not accepted scope.

## Design status

Inspected live Monny.sketch popover frame 30 Battery charging/sleep entry Light on 2026-11-16, matching current BatteryTab. If pursued, the action belongs with Battery controls; no navigation redesign is necessary. No drawing, exact copy handoff or Sketch edit/save. Required future states include available/unsupported, active, cancellation/restoration and unconfirmed failure; no claim that a restored adapter guarantees immediate charging.

## Verification and limits

Read current source/contracts, historical experiments/discharge AdapterVerificationOperations and BAT-027/028/030 records without switching branches, and primary Apple/upstream documentation. Existing short hardware evidence is historical; sustained target discharge is unverified. No executable, service, charging mutation, runtime test or build run for this documentation-only assessment. Reviewed local links and git diff --check.

## Next handoff

Review product value and choose whether to investigate further. Before any implementation/hardware trial, define endpoint semantics and monitor/clamshell acceptance; inspect native macOS 27 capability read-only first if selected, and separately authorize any physical experiment. Keep existing native behavior and firmware/platform limits explicit.
