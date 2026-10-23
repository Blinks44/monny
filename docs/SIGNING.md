# Build, release and signing backup

Run from this repository's root with full Xcode, `create-dmg` (`brew install create-dmg`) and a logged-in GUI session:

```sh
apps/monny/scripts/dev.sh build   # debugging
apps/monny/scripts/dev.sh test    # tests
apps/monny/scripts/release.sh     # signed DMG for installation/testing
```

Use **release.sh** for installed copies. It builds an arm64 Release, copies the app into `apps/monny/build/release/`, signs Sparkle's nested code and the app under Hardened Runtime, creates the branded DMG, checks signatures/image integrity, prints SHA-256 and writes the signed Sparkle `appcast.xml` beside the DMG. It never installs, publishes or creates keys; a missing update signing key stops packaging. `MONNY_SIGN_IDENTITY` overrides the pinned certificate.

## Release version and build

Open `apps/monny/monny.xcodeproj` → target **monny** → General → Identity:

- **Version** (`MARKETING_VERSION`): currently `1.0`; change for a user-visible release.
- **Build** (`CURRENT_PROJECT_VERSION`): read the current Debug/Release values in the project; agents increment it and run release.sh after every app change. Sparkle compares this number, so every published update needs a build larger than all earlier published ones.

Keep Debug/Release values consistent. The script reads Info.plist and automatically names `apps/monny/build/release/Monny-<Version>-<Build>.dmg`. It never increments versions or publishes.

## Signing key

Monny and Rebind use the **same existing Apple Development certificate and private key** in the login keychain. Both release scripts pin its public SHA-1 fingerprint:

`69D383553450694A1E9D78650B3FC6E69446BD4F`

Actual Apple Team ID: `GJ35NZKDRS`. The inspected certificate expires **2027-10-18**. Exact selection prevents accidentally using another certificate. A missing key or failed signature stops packaging; there is no automatic key creation, renewal, fallback or trust exception. Keep bundle identifiers unchanged. Replacing an expiring certificate is an explicit reviewed transition, not a reason to generate a new one on each build.

Apple Development is the distribution route until there is a paid Developer ID: the free team can issue it, and a stable signer keeps permissions across updates. Users allow the first launch through Privacy & Security → Open Anyway or `xattr -dr com.apple.quarantine` ([README](../README.md#install)). These DMGs are signed but not notarized; other-Mac installation and permission preservation remain unverified. Packaging a DMG does not turn a development certificate into a distribution certificate. Apple's [certificate purposes](https://developer.apple.com/help/account/certificates/certificates-overview/) distinguish these routes; [Developer ID distribution](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/) is not implemented here.

## Backup and macOS reinstall

Keep the current identity and its private key in an encrypted PKCS#12 backup outside the repository, with an off-device copy and its export password stored separately. A public certificate or signed app cannot recover the private key. Retired self-signed exports are not a backup of the current identity. Dated recovery evidence and its limits: [REL-001](tasks/REL-001-signing-workflow.md).

After reinstalling macOS, install Xcode/create-dmg, restore the repositories, import `AppleDevelopment.p12` into the login keychain using its export password, check its fingerprint/expiry and run the same release.sh. The certificate must include its private key in My Certificates. If missing/expired, stop and plan the identity transition; generating a same-named replacement does not restore it.

## Update signing key

Sparkle verifies every downloaded update with an **EdDSA (ed25519) key**, separate from the code-signing certificate. Monny's key was created once on 2026-10-21 with Sparkle's `generate_keys --account monny` and is stored in the login keychain under the account `monny` (Rebind's key uses the default account `ed25519`; the apps do not share it). The public key is `SUPublicEDKey` in `apps/monny/Info.plist`. `release.sh` signs through `generate_appcast --account monny`; macOS may ask once to allow keychain access.

The private key is exported to a private backup location outside the repository (owner-only); signing the build-34 DMG with that file verified against the keychain key. It is the plain private key: keep it in protected storage or an encrypted archive, never in Git, and keep an off-device copy. Losing it means installed copies can no longer accept updates and must be replaced by hand. Restore on a new Mac:

```sh
apps/monny/build/DerivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys --account monny -f /path/to/private-backup/monny_sparkle_ed25519.key
```

Never generate a new key once updates have been published.

## Publishing an update

The app reads `https://github.com/Blinks44/monny/releases/latest/download/appcast.xml`. For each stable release, tag `v<Version>` at the tested commit, create a GitHub release with that tag and attach the DMG and `appcast.xml` from `apps/monny/build/release/` unchanged (the appcast's download URL is `releases/download/v<Version>/<dmg>`). Drafts and pre-releases are not `latest`, so the app ignores them. Do not republish different bytes under the same version: raise the build and version. Builds before 34 have only the old manual check and must be replaced by hand once.

## Updating from a helper build

Builds up to 23 could install a charging helper. Remove it in that old app first; current Monny has no helper or migration code. Then quit and replace Monny. Clean-Mac installation and notarization remain open.
