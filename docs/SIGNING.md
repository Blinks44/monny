# Build, release and signing backup

Run from this repository's root with full Xcode, `create-dmg` (`brew install create-dmg`) and a logged-in GUI session:

```sh
apps/monny/scripts/dev.sh build   # debugging
apps/monny/scripts/dev.sh test    # tests
apps/monny/scripts/release.sh     # signed DMG for installation/testing
```

Use **release.sh** for installed copies. It builds an arm64 Release, copies the app into `apps/monny/build/release/`, signs it under Hardened Runtime, creates the branded DMG, checks signatures/image integrity and prints SHA-256. It never installs, publishes or creates keys. `MONNY_SIGN_IDENTITY` overrides the pinned certificate.

## Release version and build

Open `apps/monny/monny.xcodeproj` → target **monny** → General → Identity:

- **Version** (`MARKETING_VERSION`): currently `1.0`; change for a user-visible release.
- **Build** (`CURRENT_PROJECT_VERSION`): currently `27`; agents increment it and run release.sh after every app change.

Keep Debug/Release values consistent. The script reads Info.plist and automatically names `apps/monny/build/release/Monny-1.0-27.dmg`. It never increments versions or publishes.

## Signing key

Monny and Rebind use the **same existing Apple Development certificate and private key** in the login keychain. Both release scripts pin its public SHA-1 fingerprint:

`69D383553450694A1E9D78650B3FC6E69446BD4F`

Actual Apple Team ID: `GJ35NZKDRS`. The inspected certificate expires **2027-10-18**. Exact selection prevents accidentally using another certificate. A missing key or failed signature stops packaging; there is no automatic key creation, renewal, fallback or trust exception. Keep bundle identifiers unchanged. Replacing an expiring certificate is an explicit reviewed transition, not a reason to generate a new one on each build.

Apple Development is the distribution route until there is a paid Developer ID: the free team can issue it, and a stable signer keeps permissions across updates. Users allow the first launch through Privacy & Security → Open Anyway or `xattr -dr com.apple.quarantine` ([README](../README.md#install)). These DMGs are signed but not notarized; other-Mac installation and permission preservation remain unverified. Packaging a DMG does not turn a development certificate into a distribution certificate. Apple's [certificate purposes](https://developer.apple.com/help/account/certificates/certificates-overview/) distinguish these routes; [Developer ID distribution](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/) is not implemented here.

## Backup and macOS reinstall

The old encrypted `Monny.p12` and `Rebind.p12` backups in `~/Documents/DeveloperSigning/` contain the **previous self-signed identities**, not this Apple Development private key. Keep them for old builds; do not delete or overwrite them.

The current Apple Development identity has been exported through Keychain Access → My Certificates to encrypted `AppleDevelopment.p12` in that folder (2026-10-20), for both apps. The file is nonempty, rejects an empty-password MAC check and is owner-readable only. Full restore/private-key signing verification remains open. Store its export password in your password manager, separately from the file, and keep an off-device copy. A public .cer or app/DMG cannot recover the private key. No signing folders, keys or passwords belong in Git.

After reinstalling macOS, install Xcode/create-dmg, restore the repositories, import `AppleDevelopment.p12` into the login keychain using its export password, check its fingerprint/expiry and run the same release.sh. The certificate must include its private key in My Certificates. If missing/expired, stop and plan the identity transition; generating a same-named replacement does not restore it.

## Updating from a helper build

Builds up to 23 could install a charging helper. Remove it in that old app first; current Monny has no helper or migration code. Then quit and replace Monny. Clean-Mac installation and notarization remain open.
