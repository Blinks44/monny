# DOC-001: Release documentation and Git hygiene

- Date: 2026-11-08
- Stage: done
- Owner: implementation session, released
- Baseline: main `b262d23` plus the pending APP-015 delivery-failure note
- Scope: current release/source documentation, website handoff and tracked-file hygiene; no app changes, deployment or release asset changes

Removed repeated candidate descriptions and superseded publication steps; kept pinned research sources, historical checksums and all open real-account/appearance/update checks. STATE/PLAN identify the published build and observed appcast 504 failure. Website records distinguish an already-live site from the unconfirmed deployment of its new source list. APP-015 owns delivery evidence; a shared GitHub failure remains an inference, not a confirmed incident.

Checked all 496 tracked entries for typical private-key/provider/GitHub/AWS credential patterns, personal home paths and credential/output filenames; none detected. This is a checkout pattern scan, not an exhaustive history/security audit. No tracked file matches ignore rules. Existing exclusions cover DMG/build output, local notes, website caches, per-user settings and signing exports. No ignore-rule changes or untracking were needed. Verification captures/logs remain outside Git.

Verification: local Markdown file links, affected anchors, final diff and `git diff --check`; Swift lint passes with app code unchanged. No build/test rerun needed for documentation-only work. Next: retry appcast delivery/installed update under APP-015; confirm website deployment under WEB-001. Those gates remain open.
