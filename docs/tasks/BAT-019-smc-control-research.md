# BAT-019: Establish SMC options below 80%, Hold and Discharge

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: done (bounded research; no hardware capability enabled)
- Owner: unassigned; research ownership released
- Ownership checked: main cb9abff; existing uncommitted native-limit/helper/UI work preserved
- Owned surfaces: this task, scoped battery research, STATE/PLAN and history records; no production code or design edits
- Requirements: SPEC §5; phase 4

## Outcome and scope

Determine which SMC mechanisms could meet the existing below-80%, run-on-adapter Hold and plugged-in Discharge contracts. Separate published mechanisms from locally observed read access and verified writes. Preserve the build-12 native backend and its remaining crash/helper-restart acceptance. Research and a fixed-key unprivileged read-only probe are authorized; helper installation, charging writes and crash tests are outside this slice.

## Acceptance

- [x] Compare native, legacy inhibition, firmware limits and adapter isolation against all three behaviors.
- [x] Review ready solutions, licensing, maintenance and coexistence/restoration limits.
- [x] Record bounded local read evidence without claiming write support.
- [x] Save the implementation decision, next action and unchanged hardware gates.

## Implementation and verification

Completed [mechanism comparison, pinned source review and local read evidence](../research/smc-charge-control.md). Reused the existing read-only SMC adapter without production edits. Fixed nine-key temporary Swift 6 probe compiled; sandbox could not open AppleSMC, then approved unprivileged execution outside the sandbox returned CHIE readable (hex_, one byte), four SMC-132 failures and four IOKit-not-privileged failures. No raw values recorded, writes/helper calls, installation or crash tests. No new app artifact, app build or behavioral-test rerun; existing 180 tests/build-12 evidence is unchanged.

Decision: retain native 80–100% control. No reviewed backend establishes below-80% Charge or arbitrary Hold on this Mac; CHIE-only adapter isolation cannot complete Discharge-then-Hold. New BSD/MIT candidates do not resolve those gaps. No dependency, copied code or Sketch edit.

Product update: below-80% charge limits and separate manual Hold are subsequently removed in [BAT-020](BAT-020-remove-manual-hold.md). The automatic at-limit/Discharge endpoint inhibition requirements and research limitations remain.

## Open checks / next handoff

The separately advertised read-only CHIE/CH0I/CH0J helper diagnostic is implemented in [BAT-021](BAT-021-adapter-diagnostics.md), preserving the fixed legacy six-key reply and status/removal compatibility. Installed read-only evidence is now accepted in BAT-021; next prepare bounded recovery/coexistence software before any adapter write. No writable IPC or mode activation follows from read access. The research record specifies the later writer/recovery prerequisites. BAT-018/BAT-005 still own open real crash/helper-restart, sustained physical and broader platform acceptance; none closed here.

## Review

Reviewed results against SPEC §5 without weakening Charge/Hold/Discharge behavior. Scoped records and local links checked; git diff --check passed. Baseline main cb9abff plus existing uncommitted app/helper/UI changes retained. No Git commit or distribution artifact produced.
