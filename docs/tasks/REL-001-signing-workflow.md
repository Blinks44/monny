# REL-001: Consistent persistent signing workflow

- Updated: 2026-10-19
- Stage: awaiting_verification (off-device backup)
- Owner: unassigned; released
- Ownership: main at fd8ba18 plus prior uncommitted battery/UI work; scripts and signing documentation only
- Scope: align Monny/Rebind release entry points and exact identity selection; preserve existing keys and app-specific security checks

## Outcome

Each project exposes `apps/<app>/scripts/release.sh`, uses an existing identity in the macOS keychain, stops if missing/ambiguous, signs the app and DMG, and records a SHA-256. Certificate creation is never part of a release. Separate identities remain separate. A one-time import preserves Monny's original identity without rotating it; the original directory is retained until migration and a user-held backup are verified. No helper installation, system trust modification, publication or app permission changes.

## Acceptance

- [x] Monny uses the original key from the default keychain; signed fixtures and release package pass.
- [x] Rebind exact identity lookup and optional explicit keychain align with Monny without touching app code.
- [x] Missing/ambiguous identity stops before building; self-signed identities are not filtered by system trust.
- [x] Backup/reinstall/build instructions and verification limitations recorded in both projects.

## Verification — 2026-10-19

- Existing-key release passed through `release.sh` using the original local keychain and separate `build/SigningReview/` output. Artifact: `Monny-1.0-1.dmg`; SHA-256 `3bb0b26a11bc31a0f37f7687bffd8f676f9f4c7215fd060dc3ea51ca4fdbaf33`. Arm64 Release build, signed native helper fixtures, strict app/DMG signature checks and hdiutil verification passed. The original signer was preserved.
- Python syntax, shell syntax and both repositories' `git diff --check` passed. Both selectors passed exact-name, self-signed, missing, ambiguous and substring-rejection fixtures; real missing-identity invocations failed before building. Packaging-only changes; no new app test run.
- Default-keychain migration did not finish: macOS export authorization remained pending. The agent stopped its own waiting export; no import occurred and original files were retained. The importer now times out after 120 seconds rather than waiting indefinitely.
- Initial Rebind lookup found no identity. The user subsequently confirmed no prior releases; the first Rebind Release identity was created in the default user keychain, without trust changes. Temporary private-key files were removed after import; its signed app/DMG and hdiutil verification passed. Artifact: Rebind-1.0-1.dmg, SHA-256 de4736423a5dad77370602fa87822d475d77127e0366f53f931eec69b8f827b2.

## Next action

User copies Documents/DeveloperSigning/Monny.p12 and Rebind.p12 to a private off-device backup and keeps the export password separately. Both isolated restore/signing checks are complete, as is Monny default-keychain migration. No further setup commands are needed. See [short build/reinstall guide](../SIGNING.md). Helper installation and clean-Mac acceptance remain owned by BAT-003.

## Follow-up: script inventory and first Rebind identity

Folded the former prepare-self-signed.py implementation into release.sh and removed the redundant launcher target. Monny now has four scripts (dev, release, native helper-signing checks, one-time legacy import); Rebind has two plus its required DMG background artwork. The one-time importer was subsequently retired after successful migration; helper checks remain release security acceptance.

The final merged Monny script passed exact/self-signed/missing/ambiguous/substring selector fixtures, shell/Python syntax, arm64 Release, signed helper fixtures and strict app/DMG/hdiutil verification. Its rebuilt SigningReview/Monny-1.0-1.dmg SHA-256 is 2e0b2889929b038ab4f5ecd7cd8e4e7e3c041dd31c132594f1882b39d0855a01. Same original certificate retained. Full tests were not rerun for packaging-only changes.

## Verified backups and final default release — 2026-10-19

Exported only the exact Monny and Rebind identities into encrypted .p12 files outside both repositories in Documents/DeveloperSigning. Export password was supplied through a hidden local dialog; no password is stored in Git, logs or that backup folder. Each backup was imported into an isolated temporary keychain, matched its original certificate fingerprint, signed a copied test executable and passed signature verification. Temporary keychains were removed. Monny's original certificate/private key was imported into the default user keychain; no identity rotation or trust modification occurred. The original ignored keychain remains a safety copy pending an off-device backup.

Final ordinary release.sh (no overrides) passed arm64 Release, native helper-signature fixtures, strict app/DMG signature and hdiutil checks. Artifact: apps/monny/build/release/Monny-1.0-1.dmg; SHA-256 2505ea104e0d1db9563bca81f442a05a52c6af00138bc78f9c9b9268801a8c5d. A first packaging attempt failed at hdiutil after successful signing; error reporting was improved and the complete rerun passed. No app behavior changed; existing full app tests were not rerun for packaging-only changes.

Both repositories now have short app-specific SIGNING guides with the same build/test/release/reinstall commands. Removed the completed one-time importer and its stale error-message reference. Monny has dev.sh, release.sh and required verify-helper-signing.sh; Rebind keeps dev.sh, release.sh and its DMG artwork. No permanent backup tooling added. Shell/Python syntax, selector fixtures, documentation links and git diff --check passed. No helper installation, permission change or publication.
