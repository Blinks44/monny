# Verification records

[STATE](../STATE.md) indexes active tasks and [SPEC](../SPEC.md) owns current requirements. Add one record per topic (for example `battery-fail-safe.md`) when real checks are performed.

- [Public-API readings](readings-public.md)
- [SMC temperatures and fans](sensors-smc.md)
- [NVMe SMART SSD health](ssd-smart.md)
- [Idle and dashboard cost](idle-cost.md)

Each record keeps the date, app revision, macOS version, Mac model and chip, settings, the commands or walkthrough, the observed result, the evidence source (agent-observed, tester report, injected test) and limits. Reading checks name the reference tool and tolerance (Activity Monitor, System Information, `powermetrics`). Screenshots stay local under [WORKFLOW](../WORKFLOW.md#repository-content-and-language); the written result must stand on its own.
