# DOC-001: Repository and documentation cleanup

- Updated: 2026-10-23
- Stage: done
- Owner: unassigned; documentation maintenance released
- Baseline: main `713defe`, initially clean; cleanup is uncommitted

## Outcome

Condensed STATE, PLAN, history, signing and AI task handoffs; removed superseded experiment implementation journals from main while retaining mechanism/licensing decisions and the experiment-branch locator. Reconciled completed shell/onboarding/notification/design next steps with dated acceptance. Preserved outstanding hardware/account/history/install/update/localization checks in their owning records and STATE.

Removed live account quota values, personal storage/battery/SSD snapshots and upstream workstation paths. Comparison methods/tolerances/results, platform context, required assets, source, licenses, lockfiles and skills remain. Added a narrow ignore rule for `monny_sparkle_ed25519.key` and clarified pre-commit content review in WORKFLOW. Retained existing reviewed skills/provenance; no installs or upstream refresh were required for this cleanup.

Current experiment branch is `09595b5`; older `abe3a80` references predate the attribution rewrite. Verified experiment task/research files directly before replacing current source locators. Historical IDs remain labelled historical rather than inventing replacement commits.

## Verification — 2026-10-23

- Repository-owned Markdown: 275 local links/anchors checked; none missing. Skill manifest JSON valid; STATE under 8 KiB.
- Current tracked content: 345 regular files scanned for private-key headers, selected provider-token formats and personal absolute home paths; no remaining pattern matches. Tracked-file inventory contains no credential exports, raw logs or session transcripts. This is a bounded content review, not an exhaustive secret audit or a scan of historical blobs.
- Seven generated/local/credential path samples are ignored; eleven required instructions, task/config/lockfile/source/asset samples remain visible. No tracked files conflict with ignore rules. No blanket agent-directory/image/key exclusion or automatic untracking.
- Final `git diff --check` passed. No app/website code, Sketch, signing keys, local artifacts, commits or remote refs changed. No app tests/build/release needed for this documentation-only work; earlier results remain dated evidence.

## Limits and next step

Old document contents remain in previous Git commits and the experiment branch; working-tree cleanup does not erase them. No private-key/token leak was found by the current-content patterns, and no history rewrite was performed. Nothing was committed or published.

Next: review and commit this scoped cleanup. Product work continues from STATE; clean-Mac, native compatibility, account/history and update checks remain open.
