# Monny: development and local setup

Build commands, signing and local diagnostics for contributors. For the product overview, see the [root README](../README.md); agent startup/handoff is defined in [AGENTS](../AGENTS.md) and [WORKFLOW](WORKFLOW.md).

## Build and test

Use full Xcode with Swift 6.2+ and a macOS 26+ SDK. The app runs on macOS 26+. The last recorded environment (2026-10-17) used Xcode 27.1 (27A9275), Swift 6.4, macOS SDK 27 and macOS 27.0.1 on Apple silicon; macOS 26 runtime still needs testing.

Open `apps/monny/monny.xcodeproj`, select the shared **monny** scheme and Run (⌘R). Test (⌘U) runs the **monnyTests** target (Swift Testing, hosted in `Monny.app`).

```sh
apps/monny/scripts/dev.sh doctor
apps/monny/scripts/dev.sh build
apps/monny/scripts/dev.sh build-for-testing
apps/monny/scripts/dev.sh test
apps/monny/scripts/dev.sh release
apps/monny/scripts/dev.sh run
apps/monny/scripts/dev.sh resolve
```

The script respects `DEVELOPER_DIR` or a valid `xcode-select` selection, then falls back to `/Applications/Xcode.app/Contents/Developer`. It never modifies the system selection. For another Xcode installation:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer apps/monny/scripts/dev.sh build
```

Build output is under ignored `apps/monny/build/DerivedData/`. Do not run concurrent builds against the same DerivedData directory. Extra arguments are forwarded to `xcodebuild`, for example `apps/monny/scripts/dev.sh test -resultBundlePath build/Tests.xcresult` (use a fresh path each run).

## Project settings

- Target/scheme/module `monny`, product `Monny.app`, bundle ID `blinks44.monny`, tests `blinks44.monny.tests`.
- Swift 6, complete strict concurrency, `MainActor` default isolation, approachable concurrency, member import visibility.
- App Sandbox off, Hardened Runtime on, dead-code stripping; Release disables Xcode base-entitlement injection.
- String Catalog symbol generation; known regions en, ru, de, fr, es, zh-Hans.
- Files are file-system-synchronized: adding a Swift file under `apps/monny/monny/` or `apps/monny/monnyTests/` adds it to the target without editing the project.

## Signing

Automatic signing; no development team or credentials are stored in the repository. Default builds without a team use ad-hoc signatures and deliberately cannot register the helper. Apple-issued app/helper signatures require the Apple anchor, matching team, expected identifiers and no `com.apple.security.get-task-allow` entitlement. The experimental self-signed route requires the same exact leaf certificate and expected identifiers, also without the debugger entitlement; it is not a notarized distribution route.

Build a signed package with the existing identity in the user keychain:

```sh
apps/monny/scripts/release.sh
```

The release command never creates a signing key. It resolves the exact certificate name/fingerprint (default `Monny Local Signing`), builds arm64 Release through `dev.sh`, signs the app/helper and final versioned DMG, verifies signatures and prints SHA-256. Output: `apps/monny/build/release/`. `MONNY_SIGN_IDENTITY`, `MONNY_SIGN_KEYCHAIN` and `MONNY_PACKAGE_DIR` are optional overrides. Packaging is contained in this single script.

The original Monny identity is now in the user keychain. Verified encrypted backups for both apps are kept outside the repositories in `~/Documents/DeveloperSigning/`; save an off-device copy and keep the export password separately. The one-time import script has been retired. See [build, backup and macOS reinstall](SIGNING.md).

Native signed fixture checks cover the running verifier's identity, app/helper signer equality, wrong identifier/pin, ad-hoc/debuggable files and tampering. Passing these checks does not establish SMAppService installation on the local or another Mac. See [BAT-003](tasks/BAT-003-self-signed-helper.md) for the open runtime gates. Default ad-hoc builds still report Xcode disabling Hardened Runtime; verify actual flags on the separately signed artifact.

## Battery helper (status-only)

`dev.sh build|test|release` builds the `MonnyBatteryHelper` target as an app dependency and embeds it at `Monny.app/Contents/Library/HelperTools/MonnyBatteryHelper`, with `Contents/Library/LaunchDaemons/blinks44.monny.battery-helper.plist`. Shared protocol/signing sources live in `BatteryHelperShared/`; no package was added.

Registration is an explicit Install Battery Helper action in Battery/Settings. On an appropriately signed build, SMAppService requests approval in System Settings → General → Login Items & Extensions. The app refreshes status on return. Uninstall Helper asks for confirmation and, for an enabled service, requires a compatible authenticated non-controlling acknowledgement before unregistering. A pending unapproved registration can be cancelled without starting the daemon. No registration/removal was performed during BAT-002 development.

The current helper only reports version/state and prepares for removal; it cannot change charging. App/helper signatures and actual SMAppService registration, approval, same-team IPC and removal still need verification on the signed artifact. Incompatible-helper replacement is not implemented; do not bypass the failed handshake. Charge writes require lease/restoration and hardware acceptance first. Local logs: `log stream --predicate 'subsystem == "blinks44.monny.helper"'` (helper) or subsystem `blinks44.monny`, category `BatteryHelper` (app). See [BAT-002](tasks/BAT-002-helper-connection.md).

## Contribution workflow

Inspect the existing implementation and [current state](STATE.md) before choosing a slice. Read [engineering standards](ENGINEERING.md) for sampling, concurrency, helper security and localization. UI work follows [DESIGN](DESIGN.md) and the live Sketch frames. Build/test the affected behavior, record required runtime/hardware checks and preserve unrelated work. [WORKFLOW](WORKFLOW.md) describes task records and handoff.
