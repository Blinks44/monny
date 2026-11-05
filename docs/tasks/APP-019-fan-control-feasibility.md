# APP-019: Quieter fan control feasibility

- Updated: 2026-11-04
- Stage: planned
- Owner: unassigned; research handoff available
- Baseline: main `05b9323`, Monny 1.5.0/build 87
- Scope: feasibility only; no app/Sketch/system mutations authorized
- Contracts: SPEC §1 non-goals, AGENTS §3, ENGINEERING platform/readings boundaries

## Outcome

The user asks whether Monny could reduce fan noise by changing when fans accelerate. Existing products establish feasibility on supported Apple silicon models. Monny currently monitors fans only. The proposed temperature curve and failure-recovery/service requirements are recorded in [research](../research/fan-control.md); no implementation or safety guarantee is claimed.

## Evidence and open decision

Reviewed current source and primary product/upstream references on 2026-11-04. No SMC writes, root command, helper installation, dependency or hardware experiment. Existing monitoring and the prior fan-visibility clarification are preserved. Documentation-only link/diff review is sufficient; previous app tests are not reruns for this proposal.

Current SPEC explicitly excludes fan control. A decision to expand product scope and accept a privileged service is needed before implementation, followed by mechanism verification on named model/OS pairs and a live Sketch handoff. No generic fan-controller code should be copied into the read-only sampler.

Next: decide whether to pursue a scoped prototype for quieter fan control; keep System as the default and define restoration/thermal acceptance before any real write test.
