# Repository hygiene and Git ignore rules

Create or improve `.gitignore` during workflow setup for a Git project. Derive rules from the repository, not a universal catalog. A well-organized file is a reviewed contract about which artifacts belong in version control.

## Inspect before editing

Inspect existing root/nested ignore files and their comments/exceptions, tracked and untracked paths, manifests, build/verification commands, CI, output directories, editor/tool configuration and agent-client storage conventions. Check `.gitattributes` or artifact-management conventions when they affect generated, large or binary files. Read configuration structure and filenames without printing credentials or private data.

Classify representative artifacts as shared inputs/contracts/evidence, reproducible generated output, machine-specific state or private/local material. A generated artifact may intentionally be distributed or required for bootstrapping; do not hide it merely because its extension looks generated. Preserve deliberate vendoring, lockfile, fixture and release policies. For unfamiliar tools, inspect their configuration or authoritative documentation rather than guessing paths.

## Organize relevant sections

Use short English headings and explain non-obvious rules. Include only categories that apply:

- Build/generated output: actual intermediate/product directories, dependency caches, tool-generated files.
- Verification output: transient test bundles, coverage/profiling output, logs and screenshots/exports stay local by default; version concise results and required baseline fixtures.
- Editor/OS state: per-user workspace/session files and applicable OS metadata. Preserve shared settings/schemes/extensions configurations when the project uses them.
- Local configuration/private data: identified developer overrides, credentials, user data or environment files; retain sanitized example configuration and schema files.
- Local agent material: raw transcripts/tool dumps, scratch work, migration backups and workstation access hints in a dedicated narrow location. Reuse an existing location, or establish one when useful.
- Required shared files: document the policy for instructions, project skills and licenses/provenance, STATE/tasks/technical evidence, source/design inputs, manifests/lockfiles and shared configuration.

Comments do not enforce inclusion. Prefer exclusions narrow enough to avoid required inputs; use tested exceptions only when necessary. Do not add every possible language/tool pattern or gratuitous `!` rules. Do not ignore entire `.agents/`, `.codex/` or other client directories by name: inspect their contents and separate shared configuration/skills from local session state. Never ignore shared context because it was written by an agent.

For visual checks, inspect the actual artifact without routinely exporting or retaining an image. Put any temporary screenshots in the project's narrowly ignored local output location. Commit an image only when its purpose is concrete: a requested deliverable, shipped asset, baseline consumed by a visual test, or specific defect evidence that a concise written result cannot adequately preserve. Record that purpose in the owning task/evidence note; “visual verification” alone is insufficient. Reports must preserve the tested artifact/environment, observed result and limits without depending on access to local screenshots. Existing images are not automatically deleted or untracked when adopting this policy.

## Preserve Git semantics

Keep rule order and nested overrides meaningful: the last applicable matching pattern decides. A root-anchored `/build/` differs from `build/` at any depth. Directory exclusions need a trailing slash. A negated child cannot be re-included while its parent directory remains excluded; either narrow the exclusion or explicitly keep the parent traversable first.

Avoid broad extension rules such as `*.json`, `*.md`, `*.png`, `*.log` or `*.lock` when they can hide configuration, docs, assets, fixtures or lockfiles. Ignore private/environment artifacts at their actual paths, with safe examples preserved. Ignore rules prevent accidental addition of untracked files; they are not a secret scanner or access-control mechanism.

Repository `.gitignore` holds shared project policy. Respect existing personal/global excludes without changing global Git settings. User-specific extras can use an established local convention or `.git/info/exclude` when explicitly in scope; do not depend on them for exclusions that every clone needs. If Git is absent, use the established VCS mechanism or record that hygiene remains pending; do not initialize Git implicitly.

## Validate with Git, not visual inspection alone

Use the project's installed Git and representative paths; they need not exist to test matching:

```sh
git check-ignore -v --no-index --stdin
git ls-files --cached --ignored --exclude-standard
git status --short --untracked-files=all
git diff --check
```

Supply both paths that should be excluded and paths that must remain visible to `check-ignore`. `--no-index` also evaluates rules for already tracked paths. Inspect the matching rule and its source, including nested/global excludes; a printed negation means inclusion. An exit status of 1 can mean no path was ignored and is expected for a keep-only sample. Choose a few samples for each changed section and the actual source, docs, shared skills/configuration, lockfiles and important fixtures/assets. Validate negation/parent rules when used.

Use `ls-files` to identify tracked files that still match exclusions. Review each result against the project's deliberate tracked-artifact policy. Do not automatically run `git rm --cached`, delete files, rewrite history or change tracked status as part of setup; record a concrete finding and handle any authorized cleanup separately. Report paths/categories without exposing private contents. Existing tracked private material is not repaired by adding an ignore rule.

Finish with the adopted sections, meaningful exclusions and kept shared inputs, checks actually performed and any unresolved tracked-file or discovery conflict. Repeated setup preserves justified rules and avoids duplicate sections. No generator script, package or CI checker is required.

Primary references: [Git ignore syntax and precedence](https://git-scm.com/docs/gitignore), [check-ignore](https://git-scm.com/docs/git-check-ignore), [ls-files](https://git-scm.com/docs/git-ls-files), reviewed 2026-10-10. Confirm relevant tool-specific conventions when adopting another project.
