# Validation and realistic review

## Document review

Review affected local links/anchors, document-role consistency and skill metadata/resources/licenses. Use existing documentation tooling when available, and run `git diff --check` for a Git project. Check that the entry point reaches current state/contracts/tasks without depending on local backups or previous chats.

Compare facts about untracked, staged, tracked, committed, prepared and installed artifacts with observed version-control/filesystem state. After resolving a gate, update the affected live state/task/plan references so continuation does not select already completed setup work; preserve dated historical evidence. For staged delivery, the author records pending installation and the applying agent owns installed-file checks and final status reconciliation. Validate document responsibilities and continuation coverage, not a fixed number of files: combined contracts are appropriate when they preserve clear ownership and navigation.

Review publishability as part of completion: shared files use the chosen repository language, contain technical summaries instead of quoted replies, and omit raw chat/tool logs, personal absolute paths, real user data and temporary artifacts. Confirm that relevant ignore rules cover local-only material without hiding shared project context.

For Git projects, follow [repository hygiene](repository-hygiene.md): check representative excluded and kept paths with Git, inspect nested rules and tracked files matching exclusions, and preserve deliberate exceptions. Report unavailable Git checks rather than inventing results.

This instruction-only skill adds no checker scripts, runtime, packages, CI job or test framework. Use meaningful existing build/test checks for actual code/assets when required by the project; documentation-only setup does not need an application launch.

## Semantic audit

Check the process against actual artifacts and evidence:

- Does a new agent discover the intended entry point and reach all necessary current contracts without reading archives?
- Does AGENTS.md itself require no overengineering, simple readable solutions, priority for suitable maintained existing solutions, and minimal custom workarounds?
- Do current contracts and task handoffs describe the final state directly, with completed next steps removed and unique evidence/open checks preserved when redundant records are retired?
- Are implementation/capability claims consistent with source/artifacts and dated evidence? Are requirements and proposals separate?
- Can a reader identify the next actionable unfinished slice, owner/access needs and acceptance?
- Can another machine find the design source and code revision? Are session IDs lookup hints, not identity?
- Do design/copy states cover the bounded interaction and applicable responsive/accessibility/localization behavior?
- Do checks refer to the final artifact? Are failing/unrun/runtime/hardware checks still visible?
- Did migration preserve previous information and uncommitted work? Will another run avoid duplicates/reinstalls/status resets?
- Are public README claims honest and the installed skill set licensed, relevant and free of conflicting project rules?
- Was candidate discovery actually performed for the detected stack and upcoming work, with reviewed install/retain/skip decisions or a visible pending gap, even when setup changed only docs?
- Can an already-open chat adopt changed instructions without losing its task? Are root README, AGENTS and shared docs each populated with project-specific content rather than template placeholders?
- Are material setup questions grounded in an inspected gap, with usable choices and recommendations where appropriate? Are prior answers reused, assumptions explicit and dependent work still pending when a required answer is missing?
- Does the workflow fit the actual deliverable/toolchain even outside the example ecosystems? Are verification and contract handoffs appropriate without invented app/UI steps?
- Are ignore rules organized, relevant and narrow, with shared context, required inputs and safe examples still visible?
- Do verification screenshots stay local by default, with concise durable results and a specific purpose for any versioned image? Are shipped assets and required visual-test baselines preserved?
- Can the user simply continue development/design/the current task or name a feature, with role-aware selection and meaningful outcome reporting? Do handoffs resolve by name without asking for task/frame IDs or old transcripts?

Fix concrete findings; do not claim a perfect or certified process from document completeness alone.

When evaluating the skill, preserve first-pass findings and distinguish evaluator repairs from the original agent's output. Correct the affected project and make a narrow reusable skill change for a demonstrated instruction gap. Report which behavior was independently executed and which remains a written review; a repaired project alone is not proof that the original skill already prevented the error.

## Behavioral scenarios

Use the following to challenge the configured workflow. Distinguish a written scenario review from actual fresh-agent execution; report which was performed. If independent agent testing is authorized, use an isolated fixture and give only raw project artifacts, the skill and realistic request. Do not modify a live project during evaluation.

| Request / raw fixture | Expected observable result |
| --- | --- |
| Empty directory; request to configure an agent workflow without a product goal | Asks the needed outcome/target question; completes useful inspection/hygiene without invented stack, SPEC or development commands |
| Existing repository with clear intent, clients and maintained contracts | Uses evidence and established conventions; no mandatory questionnaire or repeated request for known facts |
| Two current trackers/design sources conflict on a requirement | Identifies the concrete conflict and asks which source governs it; preserves both and continues unaffected setup |
| Required target/product decision receives no answer | Dependent changes remain pending, exact dependency is saved, independent work is completed; silence does not become approval |
| Setup interrupted after a material decision was recorded | Reuses the decision, reconciles partial artifacts and resumes the same task; no repeated intake or reset |
| “Set up this new SwiftUI app”; manifests and a few views | Detected Apple target; useful reviewed skills only; real build commands; no invented completed design/features |
| “Configure this existing web repo”; CONTRIBUTING/ADR/task tracker, dirty files | Reuses owning docs; preserves dirty files and old evidence; no duplicate backlog or macOS rules |
| “Set up backend agent work”; API/schema tests, no UI | API/data contract and relevant checks; no invented Sketch/design screen tree |
| “Continue the project”; old open task but partly implemented code | Reconciles diff/current source, retains existing code, chooses actionable acceptance or next bounded slice |
| High-priority item needs unavailable hardware | Retains that gate, moves independent authorized work forward; no mocked hardware-complete claim |
| Design document unavailable or later than implementation | Records missing access or revision discrepancy; no claim of design parity or invented latest source |
| Interrupted session with unsaved task status | Reads actual partial artifacts, distinguishes incomplete work/checks; no destructive restart |
| Two chats overlap a catalog/shared component | Recognizes advisory owner limits, coordinates or chooses independent surface; no silent takeover |
| Network unavailable for candidate skills | No guessed source/revision/review claims; useful docs created and install gap recorded |
| Invoke setup again on unchanged project | No duplicate IDs/files/backlogs or repeated installs; improves only demonstrated gaps |
| Task contains ten follow-ups and a final next step already implemented | Reconciles the active handoff against artifacts, condenses superseded detail and retains unique decisions and unverified acceptance |
| Specification has a chain of contradictory dated overrides | Writes the current requirement directly, routes dated implementation evidence to its owner and preserves acceptance limits |
| Cleanup finds an old hardware report with an unresolved safety check | Keeps the evidence and routes the open check; age or a passing build does not justify deleting it |
| Informal success report with unknown build/conditions | Neutral scoped reported result, unknown fields retained, no quoted reply or broader verification/approval claim |
| Workflow updated while a feature chat is open | Re-reads changed instructions/current records, reconciles actual edits, preserves task/ownership and continues without rerunning setup |
| Unfamiliar firmware/game/data/engineering project | Inspects real inputs/tools/target and derives contracts/checks; no rejection based on an ecosystem list or invented UI workflow |
| Existing ignore rules include required nested fixtures or shared agent files | Repairs only demonstrated rule conflicts, tests excluded and kept paths, preserves intentional tracked artifacts; no automatic untracking |
| Local agent logs/private overrides alongside shared skills/config examples | Excludes actual local paths narrowly; shared instructions/tasks/skills and safe examples stay visible; no whole-client-directory exclusion |
| Native/browser/design visual review alongside shipped images and visual-test baselines | Reviews the actual artifact; temporary screenshots stay local, concise results stay versioned, required assets/baselines remain visible; any extra versioned image has a specific documented purpose |
| Project has no Git repository | Adapts established VCS conventions or records pending Git hygiene; no implicit Git initialization or claimed Git checks |
| “Continue the design”; top global priority is a hardware regression | Chooses the actionable design prerequisite, preserves hardware gate and role; no request for a task ID |
| “Continue the task”; this chat has partial implementation | Resumes that outcome after reconciling actual edits; no switch to an unrelated top-priority task or destructive restart |
| “Let's add [feature]”; related feature partly exists | Matches/reuses the outcome, retains work, derives bounded acceptance; asks only about material behavior ambiguity |
| “Continue development”; design has saved initial frames and missing states | Uses a genuinely ready bounded handoff or independent engineering; no whole-flow readiness claim or forced role switch |
| “Implement the prepared permissions flow”; no ID in request | Finds the named handoff, refreshes sources/version and implements its ready scope; records gaps without requiring user lookup |
| First role-compatible item blocked and no independent work available | Reports the precise missing access/receiving role and open acceptance; no invented busywork or recreated completed asset |
| Finish a design slice then start a fresh code chat | Saved name/version/scope/next-role handoff and plain-language final report let the user give a short request without relaying metadata |
| Equivalent request in another language, with a tool/language qualifier | Selects by intended action/outcome and context, not literal wording; distinguishes design inspection from editing and respects module/tool constraints without installing or migrating implicitly |
| Documentation-only setup of an unfamiliar starter with just the setup skill installed | Researches relevant candidates for actual upcoming work; records reviewed choices or access gaps and installs a justified subset when authorized, without a mandatory count |
| Prepared workflow is applied; state/task/roadmap disagree about installation | Verifies installed artifacts, reconciles the affected live references and retains historical checks; completed setup is not proposed again as the next product task |

Task completion and release readiness are separate. For shipping, use the project's real supported-platform, compatibility, meaningful tests, rendered UX and operational/distribution gates. Setting up this skill does not certify the resulting application or prove all agent-client behaviors.
