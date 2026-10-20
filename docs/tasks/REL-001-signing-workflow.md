# REL-001: Consistent persistent signing workflow

- Updated: 2026-10-20
- Stage: awaiting_verification (current key backup and runtime update checks)
- Owner: app engineering; implementation complete, verification handoff
- Ownership: main at fd8ba18 plus prior uncommitted battery/UI work; scripts and signing documentation only
- Scope: align Monny/Rebind release entry points and exact identity selection; preserve existing keys and app-specific security checks

## Outcome

Both repositories now pin the same existing Apple Development certificate (public fingerprint 69D383553450694A1E9D78650B3FC6E69446BD4F) for installed local test candidates. One release.sh builds/copies/signs/verifies a branded DMG in build/release; no automatic key generation, signer fallback, ZIP fallback, signer-specific output or cross-repository dependency. Existing self-signed keys/backups remain intact; historical results below describe that earlier workflow, superseded for current candidates. Current-key backup and same-signer installed-update checks remain open. Apple Development is not notarized customer distribution acceptance.

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

Export the current Apple Development identity with its private key as encrypted AppleDevelopment.p12, verify restore/signing and retain an off-device copy/password separately. Existing Monny.p12/Rebind.p12 are the previous self-signed identities. User can update installed Apple Development build 8 to build 9 and check helper reconnection; no helper deletion, signer change or BTM reset is part of that update. See [SIGNING](../SIGNING.md).

## Follow-up: script inventory and first Rebind identity

Folded the former prepare-self-signed.py implementation into release.sh and removed the redundant launcher target. Monny now has four scripts (dev, release, native helper-signing checks, one-time legacy import); Rebind has two plus its required DMG background artwork. The one-time importer was subsequently retired after successful migration; helper checks remain release security acceptance.

The final merged Monny script passed exact/self-signed/missing/ambiguous/substring selector fixtures, shell/Python syntax, arm64 Release, signed helper fixtures and strict app/DMG/hdiutil verification. Its rebuilt SigningReview/Monny-1.0-1.dmg SHA-256 is 2e0b2889929b038ab4f5ecd7cd8e4e7e3c041dd31c132594f1882b39d0855a01. Same original certificate retained. Full tests were not rerun for packaging-only changes.

## Verified backups and final default release — 2026-10-19

Exported only the exact Monny and Rebind identities into encrypted .p12 files outside both repositories in Documents/DeveloperSigning. Export password was supplied through a hidden local dialog; no password is stored in Git, logs or that backup folder. Each backup was imported into an isolated temporary keychain, matched its original certificate fingerprint, signed a copied test executable and passed signature verification. Temporary keychains were removed. Monny's original certificate/private key was imported into the default user keychain; no identity rotation or trust modification occurred. The original ignored keychain was retained temporarily and has now been removed during the final cleanup below.

Final ordinary release.sh (no overrides) passed arm64 Release, native helper-signature fixtures, strict app/DMG signature and hdiutil checks. Artifact: apps/monny/build/release/Monny-1.0-1.dmg; SHA-256 2505ea104e0d1db9563bca81f442a05a52c6af00138bc78f9c9b9268801a8c5d. A first packaging attempt failed at hdiutil after successful signing; error reporting was improved and the complete rerun passed. No app behavior changed; existing full app tests were not rerun for packaging-only changes.

Both repositories now have short app-specific SIGNING guides with the same build/test/release/reinstall commands. Removed the completed one-time importer and its stale error-message reference. Monny has dev.sh, release.sh and required verify-helper-signing.sh; Rebind keeps dev.sh, release.sh and its DMG artwork. No permanent backup tooling added. Shell/Python syntax, selector fixtures, documentation links and git diff --check passed. No helper installation, permission change or publication.

## Retired local keychain cleanup — 2026-10-19

Removed apps/monny/.local-signing and its obsolete keychain/password files at the user's explicit cleanup request. Reconfirmed the exact Monny identity in the user keychain, both existing encrypted .p12 exports and that the keychain search list only references the login keychain. Current release scripts have no dependency on the removed directory. Prior isolated backup restore/signing checks remain the evidence for export recovery; they were not rerun or represented as an off-device backup. The narrow ignore rule remains as protection against accidentally reintroducing legacy credentials. Updated current guidance and git diff --check passed; no app build is required for this local-secret/documentation cleanup. User still needs an off-device copy and separately stored export password.


## Shared development signing alignment — 2026-10-20

User explicitly requests one release/install workflow for Monny and Rebind after Monny's local recovery. Owner: current app engineering task; scope is release.sh, build numbers and signing/release documentation. Preserve unrelated edits, app code, design and all existing private keys. Both scripts now pin the same existing Apple Development certificate, use readable public bundle modes and build/release as their only packaging directory. No signing fallback or key creation, extra config file, shared cross-repository dependency, helper installation or permission reset. Monny keeps its native helper security fixtures. Rebind changes signer for the first time, so its existing self-signed installation is not a same-signer update test. Build/package verification is recorded below; Apple Development remains a local test route, not notarization or verified customer distribution.


## Unified default pipeline verified — 2026-10-20

Ordinary apps/monny/scripts/release.sh, with no identity/output overrides, succeeds using the pinned existing certificate. Artifact apps/monny/build/release/Monny-1.0-9.dmg; SHA-256 **3e2497a94a9b745f3b0432489ac784db3bfcff602df2395f20531d4e947e9e70**. Release build, strict app/DMG signatures and image integrity pass. Independently mounted read-only and ditto-extracted copies retain readable/traversable public modes, valid strict signatures, Hardened Runtime, actual Team ID and expected version/build. Exact-name/fingerprint/missing/substring/ambiguous selector fixtures and shell/Python syntax pass. No new app logic tests: only packaging/signing and build metadata changed; earlier app test results remain dated evidence. No key export or new key, publication, trust change, global permission reset or input/charging command.

Monny's signed positive/negative native helper fixtures also pass. Installed working build 8/helper are untouched. Temporary build/apple-development is removed after moving the exact verified build-8 DMG into build/release for rollback; superseded ignored local packages are removed, hashes/history preserved. Current candidate build 9 is not installed and does not close the pending same-identity update check.


## Current shared identity backup exported — 2026-10-20

User explicitly requests a backup beside the previous exports. Keychain Access My Certificates selects the existing Apple Development identity associated with its private key and exports PKCS#12 to Documents/DeveloperSigning/AppleDevelopment.p12. The resulting file is nonempty (3334 bytes); OpenSSL's empty-password MAC check is rejected. File permissions are restricted to 0600, containing directory remains 0700. No export password is entered/read/stored by the agent, no plaintext key or new identity is created. Old Monny.p12/Rebind.p12 remain unchanged. A second export reaches an existing-file warning and is cancelled, avoiding replacement. Folder README distinguishes current/shared from historical identities and contains no passwords.

This verifies local file creation and rejection of an empty password, not full restore or private-key signing. No password is available to perform that test and it is not requested in chat. User retains the password separately, copies the backup off-device and can perform an isolated restore/signing check later. No application build/runtime/permission changes accompany the backup. No private material or local backup is added to Git.
