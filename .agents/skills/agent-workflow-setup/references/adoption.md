# Adopting an existing or new project

## Inventory and reconciliation

Capture the available version-control baseline/status and preserve unrelated changes. Inspect manifests, source/assets/data, toolchains, target environments, verification/build scripts, CI, dependency lockfiles and repository ignore rules. Read existing AGENTS/override/nested instruction files and any client-specific entry points. Note which instructions actually load in each agent environment; a file's existence is not proof of discovery. If Git is absent, follow the established version-control mechanism; do not initialize Git or migrate repositories implicitly.

Identify where product intent, current work, decisions and design live today. A maintained issue tracker can own tasks: use links and a short local index rather than copying a second backlog. Offline access must be explicit; note the date of any cached tracker snapshot. Existing `ARCHITECTURE.md`, `CONTRIBUTING.md` or `ROADMAP.md` can fulfill the corresponding role without renaming them.

Reconcile proposed docs with code/assets and recent relevant changes. For each ambiguous fact use evidence, or label it unverified. An unchecked old task may already have partial code; a screenshot may be only a proposal. Do not mark all legacy tasks complete or infer approval from a mockup. Preserve user requirements separately from withdrawn or superseded decisions.

Before restructuring large documents, preserve useful information through existing Git history or a local migration backup. Migrate current facts and decisions into their owners. Do not create a committed copy of a raw session log; publish only sanitized technical history when it is useful, with corrected links and an explicit historical notice. An archive is evidence, never part of routine startup. Avoid deleting files with unknown callers. Do not commit, reset or publish simply to facilitate migration.

## Guided initialization and material questions

Setup is a guided conversation when necessary, not a fixed intake form. Start with the request, established answers and repository inventory. Distinguish observed facts, decisions already made, reversible implementation choices and material unknowns. Inspect relevant sources before asking; do not ask the user to supply facts the repository can establish, such as its language, commands, existing task names or documented design source.

Ask when the missing answer changes product scope, target environment, the authoritative source, client integration, compatibility, or a migration that could discard useful information. A request to configure the workflow does not choose a product or stack for an empty directory. A detected stack or recent edit does not settle contradictory product requirements. Explain the specific conflict and ask which current requirement/source should govern it.

Useful decision areas, only when unresolved:

| Missing decision | Question to resolve | Independent work that can proceed |
| --- | --- | --- |
| Empty project with no product intent | What should the project deliver, and where will it run? Offer plausible directions only if the request supports them. | Inventory the directory and existing instructions; prepare only justified repository hygiene. Do not invent SPEC, commands or a default stack. |
| Agent clients or working roles | Which clients and disciplines need to use the shared context? | Reuse existing document roles and inspect available integrations. Do not claim discovery or install client adapters without evidence. |
| Competing requirements, trackers or design sources | Which source is current and authoritative for this conflicting outcome? Describe the concrete discrepancy. | Preserve both sources and configure unaffected areas; avoid creating a second backlog or selecting an arbitrary latest file. |
| Unclear compatibility or migration boundary | Which existing behavior, supported environments or conventions must remain compatible? | Inspect consumers, tests and Git history; retain current contracts while isolating proposed changes. |

Use concise questions in the user's language, grouped by the decision that blocks the next step. Ask the smallest useful batch, usually one to three questions. For a real choice, offer a few distinct options, a recommendation grounded in observed needs and the practical consequence of each; allow a free-text answer. Avoid asking approval for routine file organization, record IDs or checks already authorized. Use an available user-input tool when suitable, otherwise ask directly in conversation. The workflow must also work in clients without interactive question tools.

If an answer is required, keep dependent changes pending; silence or elapsed time is not a decision. Continue useful independent work and persist the exact missing decision plus its effect before handing off. For low-impact reversible choices, use the established convention or state a reasonable assumption and proceed; do not label it user-approved. Reuse prior answers rather than repeating intake after a restart or audit. If the user delegates a choice, make a supported recommendation within that delegation and record why.

Record resolved technical decisions in the existing requirements, entry point, task or decision record that owns them. Record only consequential defaults and remaining questions; do not add a separate questionnaire file or store personal answers/chat transcripts. Unresolved product direction stays unresolved, and setup completion claims identify the usable scope and pending configuration. Once the user answers, reconcile those records and resume the same setup task rather than creating a new workflow.

## Scale the structure to the project

- Small project: concise AGENTS, public README, current state and requirements/plan may be sufficient; design/task detail can be sections rather than directories.
- Multi-session UI app: add a design contract and task handoff records; keep the engineering guide separate when rules are substantial.
- Backend/library: use API/schema/compatibility contracts and relevant data migration/operation/release evidence; do not manufacture a visual design pipeline.
- Monorepo: root context covers shared product/contracts; module instructions cover local commands and boundaries. Use stable task links and shared API/schema versions for dependent frontend/backend work. Avoid a single mandatory map of every service.

These examples are not eligibility limits. For any other domain, identify the deliverable, authoritative editable inputs, consumers, execution/target environment and meaningful acceptance evidence. Firmware may use board/toolchain/simulator/hardware gates; data work may use schema/data provenance and reproducibility; infrastructure may use configuration/environment/plan/rollout contracts; games may use engine scenes/assets and runtime checks. Preserve the project's terminology and required artifacts. Create visual-design docs only for an actual visual/design contract, and choose skills from real tools rather than a fixed list of ecosystems.

Names in this skill are examples, not mandatory filenames. Record the chosen mapping once and reuse it. Separate required behavior from discovered implementation and keep public claims no stronger than evidence permits.

For Git projects, adapt ignore rules during setup using [repository hygiene](repository-hygiene.md). A reusable workflow must preserve the inputs needed to reproduce work while excluding actual generated/local material.

## Safe, repeatable adoption

On a second invocation, inspect the existing mapping and improve only demonstrated gaps. Do not reset state/backlog, generate new task IDs for the same outcome, reinstall identical skills or create another archive without changed content. Preserve dates/results of prior verification; only update them after actual checks. Refresh pins deliberately, not whenever a skill is used.

Record an unknown next step as a proposed bounded action, not as a feature requirement invented by setup. If product direction is missing, complete the repository inventory and ask the necessary product question while retaining useful setup work.

Configure local docs/skills within the requested scope. Setup is not permission to edit a live design document, execute application actions, connect accounts, install global tooling, change secrets, deploy, create/message agents, or run package-provided scripts. Use existing authorizations for actions genuinely requested; avoid new ceremonial approvals.

## Short requests and role-aware continuation

Configure the entry point so natural-language requests to resume work, continue a discipline or add a feature work without task IDs, filenames, copied specifications or setup invocation. Interpret intended action/outcome and established context in the user's language; examples are illustrative, not an exact-phrase/keyword routing table. Documentation/tracker navigation, ID selection and record maintenance belong to the agent.

Tool and language qualifiers identify the relevant source, module or implementation constraints. Determine whether the user intends design edits, implementation, inspection or another action before using them to choose work. Access to a design tool does not make every task a design task, and a language mention does not authorize rewriting other modules or migrating the stack. Preserve explicit role/tool constraints and ask only when the meaningful outcome remains ambiguous.

Resolve the latest requested role/outcome first, then this chat's established task/role. A task-specific continuation preserves that task; a fresh role-specific continuation selects the highest-priority actionable slice for that role from current records and actual artifacts. Design prioritizes missing states/contracts that unblock implementation; implementation prioritizes core issues/checks and ready bounded handoffs. Filter by role and real dependencies before applying global priority. Do not send a designer to a hardware gate or let an implementer assume all parts of a partially saved design are ready. Use the project's established default for an unqualified fresh request; document that default when useful. Ask one focused human-readable question only if competing interpretations materially affect scope and cannot be resolved.

A named feature takes precedence over the default next item. Match existing outcome names/requirements/artifacts, retain partial work, derive observable acceptance from the request and current contracts, and proceed within the role. Create a task only when useful. Missing feature behavior or product choices may need clarification; bookkeeping and discovery do not. Dedicated agents change role only when authorized by the user's request or established scope.

Before work, explain the selected outcome, existing result and next action briefly. After the bounded outcome/check/handoff, report what is ready, what is open and the next action with its responsible role. Persist the same information in the task/current-state record. Prefer meaningful names over IDs in conversation; optional links help inspection. On transfer, provide a request such as “Implement the prepared permissions flow” that the receiver can resolve from shared records. Do not require the user to relay frame IDs/versions; the durable handoff owns them.

If hardware/access, ownership or another role's work blocks the first item, retain the gate and select independent useful work within the requested role. If none exists, state the exact missing input/receiving role; do not invent work, recreate completed artifacts or silently claim readiness. Stop after the selected bounded slice rather than treating “continue” as permission to exhaust the entire roadmap. Short role requests authorize normal scoped work, including editing the established design when design is requested; setup and saved next steps alone do not authorize external actions or agent messaging.

## Design source options

Use the project's established source: live Sketch/Figma, repo-native components/tokens, or another named artifact. An accessible authoritative export can be used if it is explicitly the current design contract; label its version and limits. Do not insist on an external editor for a code-native UI, or invent a current visual source when the live document is inaccessible. Record proposed exploration separately from an accepted implementation contract.

Handoff evidence identifies the authoritative source, saved version/revision where available, ready scope and access to applicable states, behavior/copy and annotations. When the receiving agent can inspect that source directly, do not duplicate its frame/component inventory or routinely export screenshots. Local machine absolute paths need a portable share/access instruction for other machines. Re-resolve session-specific document IDs instead of treating them as permanent identity.

Before implementing a changed design, reconcile affected code/capabilities and preserve real state/data behavior. After implementation, check the rendered interface against the same design revision and record justified platform differences. Later design revisions do not automatically change the native app.

## Multi-agent access

Both coding and design agents need the entry point, state and affected task. If one client cannot read the repository, supply a compact handoff and establish who writes its outcome back; do not claim automatic synchronization. For separate clones/worktrees, record code revisions and intended integration; for design outside Git, record saved design version separately.

Give the user a prompt to refresh already-open chats after setup: re-read updated instructions/current records, reconcile actual edits and continue their authorized task. Do not assume those chats reload instructions automatically or require a new chat for every small edit. Subsequent product work follows the entry point; setup is used again for a workflow audit or migration.

Owner records include time/revision, scope and transfer/release. They are a coordination aid: two writers can race. Existing active overlap requires coordination, a single shared task board, or independent work. Do not create agents as part of setup unless explicitly authorized.
