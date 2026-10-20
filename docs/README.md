# Monny documentation

The [root README](../README.md) is the public project overview: what Monny does, availability, technology and building. Keep detailed development status, operational notes and agent instructions here.

| Document | Purpose |
| --- | --- |
| [SIGNING](SIGNING.md) | Three build/test/release commands, encrypted key backups and macOS reinstall |
| [DEVELOPMENT](DEVELOPMENT.md) | Build/test commands, toolchain, signing and the helper's local setup |
| [SPEC](SPEC.md) | Required product behavior and acceptance |
| [PLAN](PLAN.md) | Roadmap and remaining phase gates |
| [DESIGN](DESIGN.md) | Visual direction and current Sketch source/readiness |
| [ENGINEERING](ENGINEERING.md) | Platform, sampling/concurrency, helper security, localization and dependency conventions |
| [verification](verification/README.md) | Software/native/hardware checks with dated results |
| [research](research/README.md) | Current mechanism decisions and dependency/license references |

For agents and multi-session contribution, start with [AGENTS](../AGENTS.md) and [STATE](STATE.md), then the relevant [task](tasks/README.md). [WORKFLOW](WORKFLOW.md) defines ownership, fresh context, design/code handoff and completion updates. [History](history/README.md) records dated technical outcomes, which may contain superseded decisions.

Live readings and their comparison limits are indexed in [STATE](STATE.md) and [verification](verification/README.md). The Battery page is read-only; policy and helper software checks do not establish hardware charge control.

Reusable setup: [Agent Workflow Setup](../.agents/skills/agent-workflow-setup/README.md) is a self-contained MIT skill for configuring this pattern in other projects. Its license covers only that folder.

Update the root README when the public feature set, supported platform or basic setup changes. Keep scoped test results, task owners and agent prompts in their owning documents. Raw chat/tool transcripts and verbatim replies stay out of shared documentation.

Maintain the affected topic during ordinary work: replace stale current claims/next actions, link to evidence and preserve unique decisions/open checks before retiring a record. See [record lifecycle](WORKFLOW.md#incremental-documentation-maintenance).
