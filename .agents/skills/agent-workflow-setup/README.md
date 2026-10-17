# Agent Workflow Setup

A reusable Agent Skill for setting up or reviewing project context for development and design agents in new or existing projects. It adapts to any language, platform or engineering domain from the project's actual artifacts and tools. Apps, services, libraries, games, firmware, data/ML and infrastructure are examples, not a limit on its scope.

It teaches an agent to inspect the repository, preserve existing work, select relevant reviewed skills, maintain a public README, establish current state/requirements/contracts/task handoffs, adapt `.gitignore` and verify the resulting workflow. Visual design documents apply when needed. It does not require every project to use the same filenames or install a catalog of skills.

Generated AGENTS.md instructions explicitly prioritize simple, correct and readable solutions, no overengineering, suitable maintained libraries/system APIs before custom implementations, and minimal workarounds. Ordinary task completion includes maintaining the affected documentation: current contracts and next steps stay current, while unique evidence and unresolved checks survive cleanup.

## Use

Copy this **whole folder**, including references, metadata and LICENSE, into the target repository at `.agents/skills/agent-workflow-setup/` for Codex. Avoid nesting another copy inside it. Other Agent Skill clients need their supported skill location/discovery mechanism. Skill/tool discovery is separate from access to the project's design editor or task tracker.

Example prompt:

> Use $agent-workflow-setup to configure an agent workflow for this project. Detect its domain, tools, artifacts and existing conventions; preserve existing work, adapt documentation and Git ignore rules, install relevant reviewed project-local skills where needed, and make it possible for a new agent to continue from current records. Complete and verify the setup.

For an audit/update, specify that mode and existing constraints. For a brand-new project, give the project goal and intended environment when known. If consequential decisions remain unclear, the agent first inspects available evidence, then asks focused questions with options and recommendations. It continues independent setup, keeps dependent changes pending and records the resolved decisions without storing a questionnaire or chat transcript. Existing conventions and prior answers avoid repeated intake.

After setup, requests use ordinary language: ask to continue work in the relevant discipline or describe the feature you want. Wording is flexible; examples illustrate intent rather than defining commands or keywords. The agent follows the project entry point, resolves the role and matching task from intended action/outcome and context, checks actual artifacts and saves its result/next step. Tool/language qualifiers identify applicable sources/modules, not permission for a stack migration. Task IDs, filenames and previous-chat summaries are optional. Final reports explain readiness, open checks and what this role or the receiving role does next. A short request such as “Implement the prepared permissions flow” resolves its saved handoff.

Tell already-open chats once to re-read updated project instructions and continue their task. Both roles need access to current project records and their working artifacts; setup does not create shared chat memory. Rerun this skill for a workflow audit or migration, not every feature request.

Repository documentation and skill content use English by default. You can communicate with the agent in any language. Setup produces commit-ready technical records; raw transcripts, quoted replies, personal paths and local user data stay out of shared docs. Localized product content is preserved.

Git rules are organized into relevant, commented sections derived from actual build/tools/output paths. Shared context stays versioned; generated output and local agent material are excluded narrowly. Existing rules/exceptions are preserved and checked, including already tracked files. See [repository hygiene](references/repository-hygiene.md).

Verification screenshots and exports stay local by default; Git keeps concise technical results. Images are retained only for a specific documented purpose, such as a requested deliverable, shipped asset, required visual-test baseline or defect evidence that a written result cannot adequately preserve. Agents with direct access to the editable design source inspect it rather than receiving routine PNG copies or a duplicated visual manual.

## Checks and distribution

This is an instruction-only skill: no scripts, runtime or package dependencies. See [validation](references/validation.md) for document and scenario review using existing project tools. Setup includes candidate-skill research for upcoming project work even when it changes only documentation; additions depend on reviewed fit, not a fixed count. Document roles may be combined for a small project. Installed completion must agree across the affected current records.

Version **1.4.0**. Publish this folder independently; it has no dependency on Rebind files or other bundled skills. Its [MIT license](LICENSE) covers this folder only, not the host project or separately installed third-party skills. No external skills are redistributed here. For marketplace distribution, follow the current [Codex plugin guidance](https://learn.chatgpt.com/docs/build-skills#distribute-skills-with-plugins); no plugin/server is necessary for local repository use.
