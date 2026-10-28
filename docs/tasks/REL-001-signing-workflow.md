# REL-001: Persistent signing and installation verification

- Updated: 2026-10-23
- Stage: awaiting_verification
- Owner: unassigned
- Scope: current release pipeline, signing recovery and clean-Mac installation
- Implementation: `apps/monny/scripts/release.sh`; operational instructions in [SIGNING](../SIGNING.md)

## Current outcome

The release command selects the pinned existing Apple Development identity, builds arm64, signs Sparkle's nested code and the app/DMG, verifies signatures/image integrity and produces the appcast in `apps/monny/build/release/`. Missing/ambiguous signing identities fail; no automatic key generation, signer fallback or cross-repository dependency. Main has no helper. Apple Development signing is not notarization or clean-Mac acceptance.

## Retained verification

- 2026-10-19: encrypted backups of the former self-signed identities were imported into isolated temporary keychains, fingerprint-matched and used to sign a test executable. Those identities were subsequently retired; this is not proof of restoring the current certificate.
- 2026-10-20, build 9: ordinary release command passed arm64 build, strict app/DMG signatures and image integrity. Read-only mounted and extracted copies retained readable/traversable permissions, Hardened Runtime and expected identity/version. Exact identity, missing, substring and ambiguous-selector fixtures passed. Historical helper fixtures belong to the experiment branch.
- 2026-10-20: current Apple Development PKCS#12 export was nonempty, owner-only and rejected an empty password. This establishes encrypted file creation, not an independently observed restore/signing test.
- SIGNING records a 2026-10-21 user report of current-identity restore and off-device backup in the related project. No Monny-specific clean second-Mac verification was captured; keep that distinction.
- Later native-only packaging, including build 50, passed; [current candidate evidence](../history/2026-10.md#2026-10-23-align-menu-commands-with-rebind). No new packaging or key access during this cleanup.

## Open checks and next action

Verify installation and launch from a downloaded DMG on a clean second Mac. Confirm recovery/signing with the current identity and availability of an off-device encrypted backup with its password stored separately. The separate Sparkle key backup was reported off-device on 2026-10-24; in-app updates between published builds were accepted on 2026-10-25 and 2026-10-26.

Legacy keychain migration, retired credentials and intermediate packages are no longer startup instructions. They require no further action on main. Do not reset trust, permissions or background services to bypass a failure.
