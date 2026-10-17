---
name: agent-workflow-setup
description: Set up, migrate, or audit durable agent workflows for development projects of any language, platform or discipline. Adapt project instructions, public documentation, current state, handoffs, relevant skills and Git ignore rules to the actual project. Use for configuring the workflow itself, rather than ordinary implementation under an existing workflow.
license: MIT
metadata:
  version: "1.4.0"
---

# Agent Workflow Setup

Configure a project so a fresh development or design agent can identify what exists, select an authorized next step, verify its work and leave a usable handoff. Derive the workflow from its actual artifacts, tools, collaborators and delivery needs. Languages, platforms and examples in the references are not a supported-project allowlist; unfamiliar domains still use this process. Do not copy the originating application's stack, visuals, paths or product requirements.

## Inspect before configuring

Read [adoption](references/adoption.md) for setup, migration or audit. Inspect existing instructions (including nested/override files), public docs, source/assets/data, manifests/toolchains, verification configuration, task tracker, version control and design/engineering sources. Establish project intent, domain-specific constraints, usable tools and evidence. Separate requirements, implementation, observed verification and unknowns. Use applicable checks such as tests, builds, simulations, data validation or artifact inspection; do not invent app commands or UI requirements for other domains.

Preserve existing user/contributor work and useful conventions. Adopt equivalent existing documents instead of creating competing sources of truth. For a new project, ask only for product/platform decisions needed to proceed; do not invent a stack or finished feature set from an empty directory. Report inaccessible code/design sources and continue independent setup.

## Clarify decisions that inspection cannot resolve

Use [guided initialization](references/adoption.md#guided-initialization-and-material-questions) when project intent, clients, source ownership or conflicting conventions remain materially unclear. Resolve facts from artifacts first; ask about consequential choices with a recommendation and tradeoffs. Reuse answers and existing authorization, keep questions small, and continue independent setup while awaiting a reply. Do not turn initialization into a mandatory questionnaire or silently settle a blocking product decision.

Persist agreed decisions, evidence-based defaults and unresolved dependencies in their existing owning records. Keep dependent configuration pending until the required answer arrives; complete and verify everything else within scope.

## Build the smallest complete context system

Use [document contracts](references/documents.md) to adapt these responsibilities:

- `AGENTS.md`: short entry point, role-aware short-request handling, contextual reading rules, exact development commands, boundaries, verification and completion rules.
- Root `README.md`: public project introduction, availability, requirements, setup/use, technologies, operation and links.
- Current state: implemented baseline, recent meaningful changes, open tasks, blockers and one concrete next action.
- Product requirements and plan: required outcomes/acceptance versus remaining priorities; no chronological session dump.
- Design contract, when applicable: direction, accessible states, canonical design source/components, versioned design-to-code handoff.
- Task/evidence records: bounded acceptance, advisory ownership, final artifact/revision, checks, review, unresolved work and next step.
- Engineering/developer guidance, decisions and history: only where the project's actual complexity warrants them.

Map roles to paths in the entry point. Keep routine startup small; route deeper documents by task. State files are read from disk, not shared chat memory. Scope specialized instructions to their module when useful. Do not make every small change update every document or read the whole repository.

Every generated or updated `AGENTS.md` must explicitly require no overengineering, the simplest correct and readable solution, and priority for a suitable maintained library, system API or add-on that already solves the problem. Minimize custom patches and workarounds; fix the cause or document the real limitation. Evaluate fit, maintenance and licensing before adoption; add custom machinery only when existing solutions do not satisfy the need. Include these requirements in the entry point itself, not only in this skill or a linked guide.

Configure incremental context maintenance as part of ordinary task completion: replace superseded current claims and next steps, link to the owning evidence, and trim redundant detail in the affected topic. Keep requirements current rather than appending a chain of overrides. Preserve unique decisions, dated evidence and open acceptance before retiring a record; check incoming links. Follow the [record lifecycle](references/documents.md#incremental-maintenance-and-record-lifecycle), keeping broader reorganizations scoped to explicit cleanup work.

All shared files created by setup must be suitable for committing. Use English for repository documentation, instructions, comments and skill content unless the project explicitly chooses another language; conversational replies follow the user's preference. Keep localized product resources and purposeful Unicode fixtures multilingual. Record technical outcomes rather than verbatim user replies or chat/tool transcripts. The repository-content boundary and reported-result format are defined in [document contracts](references/documents.md).

## Adapt repository hygiene

When Git is used or requested, read [repository hygiene](references/repository-hygiene.md) and create or improve `.gitignore` as part of setup. Inspect the project's tools, actual output paths, nested rules and tracked files first. Organize relevant rules into commented sections; explain non-obvious exclusions and preserve required exceptions. Keep shared instructions, skills, state, tasks and concise technical verification results versioned. Verification screenshots and exports stay in narrowly ignored local storage by default; retain images in Git only for a specific documented purpose, such as a requested deliverable, shipped asset, required visual-test baseline or defect evidence that a written result cannot adequately preserve. A visual check does not require an export or a committed image. Validate both excluded paths and representative files that must remain visible. Do not paste a universal multi-stack template, untrack files automatically or change global ignore settings.

## Select skills and tools deliberately

Read [skill selection](references/skills.md) during setup and relevant audits. Inventory existing skills and research candidates for the detected stack, deliverables and near-term work, even when this session changes only documentation. Review actual contents, sources, licenses and executable behavior; record install/retain/skip decisions or an explicit discovery/access gap. Install a useful subset into the authorized project-local location, pin provenance and preserve licenses. Zero additions is valid after this review, not a substitute for it. Avoid duplicate skills, entire plugin bundles and blind catalog installs.

Tool integrations and skills are separate: a design skill does not grant Sketch/Figma access, and an installed skill is not necessarily loaded by every agent client. Verify each client's discovery convention and document any thin adapter/explicit entry prompt. Do not change global settings or credentials as a side effect of project setup.

## Establish the operating loop

Encode these outcomes in the project workflow, using its language and conventions:

1. Start/resume: resolve the role/current outcome from the request and established chat scope; read entry point and current state, inspect actual artifacts/diff and affected contracts before claiming a feature is absent. Already-open chats re-read changed instructions from disk and reconcile their current task; they do not restart it or rerun setup merely to refresh context.
2. Scope/claim: reuse the task, choose bounded acceptance and checks; identify ownership and shared surfaces. Owner fields are advisory, not atomic locks. Coordinate overlaps or use independent surfaces; separate worktrees still need a shared coordination point.
3. Contract → implementation: when relevant, identify saved design/engineering/API/data contract version and stable source IDs, behavior/components/states; record justified implementation differences. Refresh sources before dependent work. Contract/design readiness, implementation and verification remain separate; skip visual handoffs when the project has no UI.
4. Verify/review: check changed behavior and relevant visual/accessibility/localization/security/platform constraints. Review the final diff against acceptance. Mock tests and successful compilation do not prove runtime/hardware acceptance.
5. Finish/interruption: persist actual checks/failures, limits, changed contracts/state and one actionable next step before the final handoff when possible. After an abrupt interruption, reconcile the diff; do not assume the last record was saved.

Interpret routine requests by intended action/outcome and established context in the user's language. Examples are illustrations, not required wording or keyword commands. Tool/language mentions constrain the relevant source/implementation; they do not define a role by themselves or authorize tool installation/stack migration. Encode [role-aware selection](references/adoption.md#short-requests-and-role-aware-continuation) in project instructions. Resolve task IDs/paths yourself by meaning, title, requirements and artifacts; do not make the user locate a record or reconstruct the previous chat. Resume the current compatible task, or select the highest-priority actionable slice for the requested role. A named feature selects that outcome; derive bounded acceptance, reuse existing work and ask only about material missing behavior.

If the first slice needs unavailable hardware/access or another role's unfinished handoff, retain that dependency and advance independent useful work within the same role/scope. Explain a genuine block with the exact missing input and next responsible role. Short requests authorize the bounded requested work, including design edits when design is requested; workflow setup alone does not. Saved next steps do not authorize deployment, messages, new agents or other external actions.

`done` means the bounded task's acceptance is met on the identified final artifact. Subsequent changes invalidate affected evidence. Product release readiness is a separate gate involving the project's actual compatibility, testing, delivery and operational requirements.

## Validate and deliver

Use [validation](references/validation.md) to review a fresh-chat continuation, interrupted migration, design handoff and unavailable-tool scenario. Review affected links and facts, use the project's existing checks, and run `git diff --check` when Git is available. Fix actionable failures, reconcile completed gates in their current owning records and record checks actually performed on the installed outcome. A staged transfer remains pending until the applying agent completes those checks. Do not add a runtime, custom validator, CI job or test framework solely for workflow documentation.

Provide concrete changed files, adopted document roles, installed/retained/skipped skills with reasons, ignore-rule decisions and checks, remaining access/verification limits, and short prompts for the next development/design chat. Complete authorized setup; do not stop with a file list or proposal. Leave no generated placeholder contracts presented as complete.

Configure ordinary agents to report meaningful outcome names, what is ready/open, and the next step for their role or the receiving role. Persist that handoff before finishing; when a transfer is needed, provide a short natural-language request that resolves from shared records without an ID. Users should not need to remind agents to save context or browse task files to discover the next stage.
