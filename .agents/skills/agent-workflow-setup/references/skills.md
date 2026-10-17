# Selecting and installing project skills

## Inventory before searching

Inspect skills already discoverable in the environment and project, including names/descriptions, folder/source, versions, licenses and actual relevant instructions. Retain compatible reviewed skills. Avoid copying a global skill into the repo merely to increase the count; project-local portability may justify it if licensing permits and that is the user's intent.

Include instructions shipped with the detected dependencies/toolchain when available. Reviewed version-locked resources can be routed from the entry point instead of vendored again; document their installation prerequisite and verify referenced paths. A scaffold flag or package containing skills does not establish agent discovery. Fill actual missing resources selectively, and record compatibility overrides when upstream guidance conflicts with the observed project.

Derive candidates from the detected stack and real gaps, not the project name. Read the candidate contents, relevant references and scripts before deciding to install it. Do not execute scripts merely to inspect them.

During setup, assess skills for the project's upcoming development/design work as well as this session's edits. A documentation-only setup session still needs candidate discovery for the detected project. Start with maintained primary sources relevant to its real tools and deliverables; do not invent a source catalog for unfamiliar domains. Reuse an already documented candidate review when its inspected revision and project fit remain current. If research is unavailable, record that gap as pending rather than claiming no useful skills exist.

The following examples are non-exhaustive. For unfamiliar domains, derive needs from actual languages, artifact formats, tools and verification gates; research relevant sources or retain general guidance when no suitable reviewed skill exists. Missing ecosystem-specific skills do not prevent useful workflow setup.

| Detected need | Useful skill areas, subject to review |
| --- | --- |
| SwiftUI Apple app | SwiftUI, Swift concurrency, Swift Testing, applicable design/accessibility; AppKit or UIKit only where used |
| Web frontend | Actual framework, design system, browser verification, accessibility and user-facing copy |
| API/backend | Actual language/framework, schema/data migration, meaningful tests and API compatibility |
| Full-stack/monorepo | Shared contracts plus each active module's skills; avoid duplicate overlapping guidance |
| Library/CLI | Actual language, compatibility/public API, testing and relevant interface copy |
| Firmware, games, data or infrastructure | Detected toolchain/engine/data formats/providers, reproducibility, target/runtime verification and relevant engineering contracts |

For Swift/Apple discovery, the [Swift Agent Skills directory](https://github.com/twostraws/swift-agent-skills) is a useful index. It links independent source repositories; it is not a bundle to install wholesale or an endorsement. Revisit actual upstream sources at setup time. Other ecosystems need their own maintained, relevant sources rather than a prefilled list of unverified skill names.

## Review and select

Check origin/revision, license and redistribution conditions, maintained status, supported framework/platform/toolchain, instruction scope, scripts/tool/network requirements and contradictory rules. Prefer a small complementary set. A security or performance audit skill is useful when those tasks exist, not automatically a prerequisite for every change.

Leave a compact selection record identifying candidates actually inspected, source/revision/license, decision and project-specific reason. A manifest section or setup-task table can own it; no separate backlog is required. Distinguish a skipped reviewed candidate from an unreviewed suggestion or unavailable source. Valid outcomes include retaining adequate existing guidance, installing a complementary skill, skipping a duplicate/conflicting/mismatched candidate, or recording an access/license gap. No minimum installation count applies, but omitting additions needs an evidence-based reason; absence of feature edits today is insufficient. For a separate backend repository, review frontend integration needs here without automatically installing backend implementation skills.

Resolve platform conflicts explicitly in project instructions (for example, macOS availability/callback rules over generic iOS/async advice). Do not import unrelated delegation mandates, deployment policies, navigation scaffolds or typography preferences. If adapting redistributable third-party material, preserve notices and record the adaptation; do not silently remove required attribution.

If access is unavailable, retain existing reviewed skills and mark new candidate review/install as pending. Never call a skill “reviewed” from its catalog title alone, pin a guessed revision, or claim an installation that did not occur. Setup can still complete the useful context structure while clearly recording this gap.

## Install, verify and maintain

When project-local skill installation is part of the authorized setup, copy only the reviewed skill and necessary resources/licenses to the client-supported location. For Codex, repository `.agents/skills/<name>/` is supported; confirm current docs if that behavior matters in the target environment. Prefer an available installer when it supports the requested project-local destination. An installer that changes global directories is not automatically a suitable substitute.

Do not overwrite an existing skill, flatten subfolders, execute downloaded install hooks or copy the upstream repository's own AGENTS/config/plugin packaging. Stage downloads first, inspect them and install deliberately. Agent Skill metadata does not authorize its executable helpers or external tool mutations.

Record a compact provenance register, such as `.agents/skills/manifest.json`, preserving the project's existing schema:

```json
{
  "skills": [
    {
      "name": "skill-name",
      "repository": "source repository URL",
      "source_path": "upstream skill folder",
      "revision": "actual inspected commit or released version",
      "license": "verified license identifier",
      "reviewed_on": "actual review date",
      "normalization": "what was copied/adapted and why"
    }
  ]
}
```

Locally authored skills can use origin/version/license/scope instead of an upstream commit. Do not pretend an unpublished local version is pinned upstream. No mandatory checksum framework: add digests only when they serve a concrete verification need.

Verify installed frontmatter/resources/license files and unique names. Inspect names in global/project locations: duplicate names are not a merge/override mechanism in Codex. Explain how to invoke and observe discovery; detection timing depends on the client. If a skill does not appear, refresh/restart the supported client before claiming availability.

Updates are a deliberate re-review of changed contents/licenses/compatibility, with recorded version and local adaptations preserved. Do not auto-update every invocation or install language-package dependencies as part of skill selection.

Official references (checked 2026-10-10): [Codex local skill discovery and distribution](https://learn.chatgpt.com/docs/build-skills), [AGENTS discovery and overrides](https://learn.chatgpt.com/docs/agent-configuration/agents-md). Other agent clients may need a thin adapter pointing to the same canonical context; do not assume Codex conventions apply to all tools.
