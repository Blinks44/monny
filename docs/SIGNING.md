# Build, release and signing backup

Run from this repository's root with full Xcode installed:

```sh
apps/monny/scripts/dev.sh build   # local development
apps/monny/scripts/dev.sh test    # tests
apps/monny/scripts/release.sh     # signed package
```

The release package is in `apps/monny/build/release/` (DMG). The script checks signatures and prints SHA-256. It does not publish or install anything. Development builds are for local work; use release.sh for distribution.

## Signing key

`Monny Local Signing` is the permanent certificate AND private key in your user/login keychain. The release command finds it automatically. Missing or ambiguous keys stop the release; the script never creates a new key. Do not replace it with a new certificate bearing the same name.

Expected certificate fingerprint: `B42AD07994F6A1FC1EAE792F53D26E685C5DD31A` (public identifier, not a password).

## Backup and macOS reinstall

The backup location for both apps is `~/Documents/DeveloperSigning/`: `Monny.p12` and `Rebind.p12`. Each encrypted file contains that app's certificate and private key. Use the export password entered in the local backup dialog; it is not the login password. Keep that password in your password manager.

**A copy on this Mac alone does not survive erasing the disk.** Before reinstalling macOS, copy both .p12 files to a private off-device backup and keep the password separately. Never put private keys/passwords in Git, an app or its distribution DMG.

On a new/reinstalled Mac:

1. Install Xcode and restore the repositories.
2. Open each .p12 and import it into the login keychain using its export password. The certificate must have a private key underneath it in Keychain Access.
3. Run the same release.sh command. Approve expected codesign access locally if requested. A login-keychain access prompt normally uses that keychain's password.

A signed app/DMG cannot recover a lost private key. If a backup is lost, inaccessible or expired, stop and plan an explicit identity migration.

## Advanced use

`MONNY_SIGN_IDENTITY` selects an exact certificate name or fingerprint; `MONNY_SIGN_KEYCHAIN` selects an existing unlocked keychain. Ordinary builds need neither. To make another backup later, export this certificate **with its private key** as password-protected .p12 from Keychain Access; a public .cer is insufficient.

This is self-signing, not Apple Developer ID or notarization; Gatekeeper approval may still be required. Signature checks do not establish clean-Mac installation acceptance.

Monny additionally runs native helper-signature checks during release. The helper remains status-only; installation on a recipient Mac is unverified. The original key is now in the user keychain; both encrypted .p12 backups passed restore/signing checks. Retain the old ignored .local-signing folder until you have made an off-device backup. The one-time migration script has been removed.

Scripts kept: dev.sh (build/test), release.sh (signed package), verify-helper-signing.sh (required helper security checks).
