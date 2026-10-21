# Monny: shared development workflow

Updated 2026-10-17. [AGENTS](../AGENTS.md) is the entry point for code and design work. This workflow defines durable context, ownership and completion; it does not authorize new agents, messages, helper installation, charging changes on a real Mac or publication.

## Document responsibilities

| Source | Owns / read when |
| --- | --- |
| AGENTS + STATE | Boundaries and current task index; every start/resume |
| Root README / DEVELOPMENT | Public overview / detailed build, signing and local setup |
| SPEC | Current requirements and acceptance; product orientation or affected contracts |
| DESIGN + live Sketch | Direction, source locator/readiness / current visual states, components, copy and annotations; UI work |
| ENGINEERING | Sampling, Swift/concurrency, helper security, storage and skill conventions; app code |
| PLAN | Priorities and remaining release gates; selecting a slice |
| tasks | One outcome's current scope, owner, implementation, evidence and next action |
| research | Mechanism choices (sensors, SMC, helper, updates), sources, maintenance and licensing |
| verification | Dated results and reproducible walkthroughs; relevant acceptance |
| history | Short dated outcomes and rationale; optional historical lookup |

Link to the owning record instead of copying its full content. Requirements, screenshots, old checkboxes and test counts do not establish current implementation or hardware support. Inspect actual artifacts when records disagree.

## Start, resume and establish freshness

1. Read AGENTS and STATE from the current checkout. Read this workflow on first use or when changed; refresh relevant sections after compaction or a dependent handoff.
2. Inspect branch/HEAD, `git status --short`, relevant history/diff and the affected implementation/task. Preserve unrelated and uncommitted work. Locate the relevant SPEC section and PLAN priority.
3. For UI, resolve Monny.sketch from DESIGN. Load the Sketch MCP guides, refresh document IDs and inspect applicable frames, symbols, color variables and screenshots. An old export is not the current design.
4. Establish a bounded outcome, owner, surfaces and required checks. Reuse a matching task; use [TEMPLATE](tasks/TEMPLATE.md) for substantial new work. A tiny isolated fix needs only concise evidence/history.
5. Explain the selected outcome, existing result and next action briefly, then complete authorized work. Ask only about material missing behavior/access.

Already-open chats adopt changed instructions by re-reading them and reconciling their existing task/diff. They do not restart work or rerun setup merely to refresh context. A new chat is optional; before a handoff save enough context for another agent to continue without the old transcript.

### Short requests and role-aware task selection

Interpret intent in the user's language and established scope. “Continue the task” resumes this chat's outcome; “continue design” stays in design. A fresh unqualified Monny development request defaults to app implementation. Tool/language mentions identify applicable sources, not a new role or permission to migrate/install tools. Resolve task IDs, contracts and source locations yourself.

A named feature takes precedence over default priorities. Inspect related partial work, reuse its record and derive observable acceptance. Otherwise select the highest-priority actionable slice for this role from PLAN: foundations and core readings before screens that display them, ready design handoffs for code; missing states for design.

If hardware/access/ownership blocks that slice (for example a Mac without a battery, an uninstalled helper or a missing sensor), retain the gate and advance independent work within the authorized role. If none exists, state the exact missing input and next responsible role. Ask one focused question only for a material unresolved choice. Do not recreate completed work or treat “continue” as permission to exhaust the roadmap. A saved next step does not authorize external actions.

### Interrupted sessions and uncertain records

Before an interruption, save the verified artifact, unfinished edits, failed/pending checks, ownership and next action. After an abrupt interruption, inspect the actual diff; do not assume the last note was saved or discard partial implementation because its task still says `planned`.

## Task status and capability status are different

Stages: `planned`, `in_design`, `ready_for_implementation`, `implementing`, `awaiting_verification`, `done`, `blocked`, `cancelled`. Skip inapplicable stages. `blocked` identifies a concrete dependency and how to unblock it.

Record design, implementation and verification separately. `done` requires the task's bounded acceptance on an identified final artifact. Keep `awaiting_verification` when required runtime/hardware acceptance remains open. Capability labels follow [SPEC](SPEC.md#capability-labels); release readiness requires PLAN's gates. Builds and injected sample data do not prove real readings or charging behavior. Record user acceptance only when supplied, limited to its actual scope.

## Code + design loop

The task owns outcome/acceptance. Inspect the actual app/capability limits and live Sketch before design or implementation. Cover applicable empty, loading, unavailable-sensor, helper-missing, on-battery, charging, hot, error and disabled states without advertising unsupported behavior.

For design work, save a self-contained Sketch source with reusable symbols, states, copy and annotations; review it live. The repository needs source/date, ready scope, limits and next step. The implementation agent inspects that source directly, reuses shared sampling/state and records justified native differences. Do not mirror component inventories or routinely export PNGs.

Check rendered behavior against the same source revision; perform hardware/charging checks only when required and authorized. Later code or design changes invalidate affected earlier evidence. A Sketch save and a Git commit are separate operations.

## Concurrent work and synchronization

- Claim one owner per shared file/section and Sketch source in the task and STATE. Record scope, time/baseline and release/transfer; identifiers are advisory, not atomic locks.
- Prefer independent surfaces (a metric reader, a screen, the helper). Shared tokens, the sampler and the helper protocol need explicit impact ownership. Re-read shared records immediately before editing and merge only your changes.
- Both roles need project records and relevant artifacts. If a client cannot read the repository, provide the startup/handoff and establish who persists its result. Shared files do not create shared chat memory.
- Separate worktrees/clones need an explicit shared coordination location and normal Git integration. Record real baselines/implementation commits or uncommitted files; never reset or auto-commit unrelated work for synchronization.
- Sketch needs its own saved version/backup. Refresh both source and code before dependent work; session IDs are lookup hints.

## Repository content and language

Shared documentation, instructions, comments and skills use English; conversation follows the user's language. Preserve product translations and intentional Unicode fixtures.

Keep stable contracts, current state/tasks, significant decisions and concise reproducible verification. Report date, known build/OS/Mac model/settings, observed result, evidence source and limits. Distinguish agent observation, tester report and injected tests. Unknown conditions remain unknown; a vague confirmation does not close broad acceptance.

Keep transcripts, quoted replies, personal absolute paths, real machine data (process lists, serial numbers), migration backups and temporary logs out of commits. Use portable source names/access instructions. Screenshots/exports stay in temporary storage outside the repository by default; written results must remain useful without them. Version an image only for a documented deliverable, shipped asset, required visual-test baseline or defect evidence that text cannot preserve.

The commented `.gitignore` owns actual Xcode/SPM/editor/local-output exclusions. For new paths, inspect nested rules, test ignored and kept samples with `git check-ignore -v --no-index`, and inspect `git ls-files --cached --ignored --exclude-standard`. Keep shared context, source/design inputs and lockfiles visible. Do not blanket-ignore client directories or image extensions; do not auto-untrack files. See the skill's [hygiene reference](../.agents/skills/agent-workflow-setup/references/repository-hygiene.md).

## Incremental documentation maintenance

Ordinary completion includes maintaining the affected topic. Replace superseded requirements/current claims and completed next steps directly; do not append a chain of overrides. Keep task summaries focused on current scope, evidence links and open acceptance. History receives the short outcome/reason, not another session transcript.

Remove completed tasks from STATE's active table. Retain records owning unique decisions/evidence or a useful handoff. Retire a redundant record only after durable facts and every open check have an identified owner; repair incoming links/anchors in the same change. Old evidence is not disposable merely because it is old or the build passes.

Keep STATE roughly 1–2 pages (preferably under 8 KiB), PLAN a short roadmap and startup free of mandatory archives. Broader moves/merges/deletions require a scoped cleanup task. Do not introduce a new archive hierarchy or bookkeeping framework without a concrete need.

## Verification and completion contract

Before the final answer or interruption handoff:

1. Update the affected task/evidence with the final deliverables, real revision or baseline plus uncommitted files, actual checks/failures, limits and one next action per applicable role. Keep historical tests dated; a document edit is not a rerun.
2. Update STATE's affected facts/rows and concise recent outcomes. Update SPEC for changed requirements, DESIGN for direction/source/readiness, PLAN for priorities/gates and research for mechanism decisions. Touch only relevant records.
3. Add a short dated history entry for substantive work, linking detailed evidence. Apply incremental maintenance above so current handoffs describe the final result.
4. Review the final diff against acceptance and affected design states. After app changes, increment the build number, run tests and `release.sh` so the user receives a signed DMG ([AGENTS §4](../AGENTS.md#4-finish-or-hand-off)). Keep unresolved runtime/hardware/accessibility/localization gates explicit.
5. Report the meaningful outcome, what is ready/open and the next action/role. A receiving-role request such as “Verify the charge limit on a MacBook” must resolve from saved records without IDs or the old chat.

### Documentation review

Check affected facts against artifacts/evidence, current task/STATE/PLAN consistency, incoming local links/anchors and `git diff --check`. Docs-only work does not require an app launch, helper installation, a new checker, runtime, CI job or test framework.

## Requests the user can give

Ordinary requests such as “continue development”, “continue the design”, “continue the task”, “add [behavior]” or “implement the popover overview” use the selection rules above. IDs, source coordinates and old-chat summaries are optional. On workflow changes tell existing chats once to read updated instructions and continue their existing task.

## Reusing the workflow elsewhere

The reusable [Agent Workflow Setup](../.agents/skills/agent-workflow-setup/README.md) adapts document responsibilities and checks to another project's actual domain and tools. Use it for setup/audit/migration; ordinary product work follows AGENTS and relevant skills.
