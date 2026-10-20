# Verification records

[STATE](../STATE.md) indexes active tasks and [SPEC](../SPEC.md) owns current requirements. Add one record per topic (for example `battery-fail-safe.md`) when real checks are performed.

- [Public-API readings](readings-public.md)
- [SMC temperatures and fans](sensors-smc.md)
- [NVMe SMART SSD health](ssd-smart.md)
- [Idle and dashboard cost](idle-cost.md)
- [Battery dashboard and policy foundations](battery-foundations.md)
- [Bundled helper and authenticated connection](helper-connection.md); [new session/lifecycle software checks and runtime gates](../tasks/BAT-005-helper-lifecycle.md)
- [Self-signed helper artifact](self-signed-helper.md)
- [Isolated native registration comparison](helper-registration-probe.md) (minimal Apple Development daemon launched as root; cleanup verified)
- [Battery design parity and macOS charging guidance](battery-design-parity.md)

Each record keeps the date, app revision, macOS version, Mac model and chip, settings, the commands or walkthrough, the observed result, the evidence source (agent-observed, tester report, injected test) and limits. Reading checks name the reference tool and tolerance (Activity Monitor, System Information, `powermetrics`). Screenshots stay local under [WORKFLOW](../WORKFLOW.md#repository-content-and-language); the written result must stand on its own.

Build-4 explicit native verification: [BAT-016](../tasks/BAT-016-manual-native-verification.md) owns the signed artifact, 158-test/software evidence and pending user-authorized temporary-target/rollback check. No actual native setting write is verified.
