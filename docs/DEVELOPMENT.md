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

The release command never creates a signing key. It resolves the exact certificate name/fingerprint (default: the pinned shared Apple Development fingerprint; see SIGNING), builds arm64 Release through `dev.sh`, signs the app/helper and final versioned DMG, verifies signatures and prints SHA-256. Output: `apps/monny/build/release/`. `MONNY_SIGN_IDENTITY` and `MONNY_SIGN_KEYCHAIN` are optional overrides; there is one output directory, with no signer-specific package path. Packaging is contained in this single script. Install the build-time tool once with `brew install create-dmg` (MIT, also used by Rebind). The command requires a GUI session to configure Finder and does not silently fall back to an unstyled image. `scripts/dmg/background.tiff` is the shipping Retina artwork exported from the saved Sketch DMG background; regeneration/source and visual checks are in [REL-002](tasks/REL-002-branded-dmg.md).

The original Monny identity is now in the user keychain. Verified encrypted backups for both apps are kept outside the repositories in `~/Documents/DeveloperSigning/`; save an off-device copy and keep the export password separately. The one-time import script has been retired. See [build, backup and macOS reinstall](SIGNING.md).

Native signed fixture checks cover the running verifier's identity, app/helper signer equality, wrong identifier/pin, ad-hoc/debuggable files and tampering. Passing these checks does not establish SMAppService installation on the local or another Mac. See [BAT-003](tasks/BAT-003-self-signed-helper.md) for the open runtime gates. Default ad-hoc builds still report Xcode disabling Hardened Runtime; verify actual flags on the separately signed artifact.

## Battery helper and explicit verification

`dev.sh build|test|release` builds the `MonnyBatteryHelper` target as an app dependency and embeds it at `Monny.app/Contents/Library/HelperTools/MonnyBatteryHelper`, with `Contents/Library/LaunchDaemons/blinks44.monny.battery-helper.plist`. Shared protocol/signing sources live in `BatteryHelperShared/`; no package was added.

Registration is an explicit Install Battery Helper action in Battery/Settings. On an appropriately signed build, SMAppService requests approval in System Settings → General → Login Items & Extensions. The app refreshes status on return. Uninstall Helper asks for confirmation and requires a compatible authenticated non-controlling acknowledgement before unregistering. Build 4 can change native settings through explicit verification, so transport failures/timeouts cannot bypass this acknowledgement; malformed/mismatched replies remain blocked. A pending unapproved registration can be cancelled without starting the daemon. No registration/removal was performed during BAT-002 development.

The current helper reports version/state, prepares for removal and supports read-only diagnostics plus the explicit manual native-setting verification below. Ordinary status/diagnostics never apply a target. Local status-only registration/approval/restart/removal is user-confirmed; installed diagnostics succeed, but new lifecycle hooks, runtime negative-peer and clean-Mac checks remain open, and self-signed launch is intermittently OS-blocked. Incompatible-helper replacement is not implemented; do not bypass the failed handshake. Normal product controls stay disabled pending hardware acceptance. Local logs: `log stream --predicate 'subsystem == "blinks44.monny.helper"'` (helper) or subsystem `blinks44.monny`, category `BatteryHelper` (app). See [BAT-002](tasks/BAT-002-helper-connection.md).

## Read-only charge diagnostics

Use the signed app, not an ad-hoc development build. Install/approve its bundled helper explicitly through Monny first. For a responding older helper, remove it through the old app before replacing the app, then install it from the new app; copying a DMG alone need not restart an already-running daemon. No installer or diagnostic script performs these actions automatically.

Run the installed executable directly (ordinary user, no sudo):

```sh
/Applications/Monny.app/Contents/MacOS/Monny --battery-diagnostics
```

It prints JSON to stdout and exits, with no menu bar UI, sampling, history writes, registration or charge writes. Only the authenticated helper performs the fixed six-key read and the native-limit getter query. One snapshot is cached for that helper process's lifetime; simultaneous requests share it. Status checks never probe. Native getter snapshots are diagnostic observations, not a live setting subscription or proof of enforcement. Metadata/readability is evidence only, never write support. Raw results stay local unless the user chooses to share them.

Machine error codes: `signingUnavailable` requires the signed package; `helperNotEnabled` requires explicit install/approval; `helperUpdateRequired` means the connected older helper lacks the required native-limit diagnostic flag; `connectionFailed`/`timedOut` leave capabilities unknown. No automatic retry or privilege escalation is attempted. Status/removal remain compatible with old protocol-1 helpers via additive optional fields; only a positive diagnostic feature flag permits the new selector. Replies remain limited to 4 KiB with exact key order and readable metadata/byte validation. Native replies validate the advertised sorted unique 80–100 range and configured limit; an unavailable API reports a typed reason without invented settings. Build 3 adds nativeChargeLimit/nativeLimitDiagnosticsAvailable optional fields; old status/removal clients still work.

The native-limit bridge checks the private system class and getter ABI before invocation; this diagnostic path does not invoke setter/disable selectors or edit preferences. Its synchronous getters run off the main actor. A client request times out after five seconds; this cannot forcibly cancel a private synchronous getter. The helper bounds work to one cached diagnostic task per process, so repeated clients cannot create more stuck reads. Build-3 installed-helper native reads are verified; macOS 26 native API acceptance remains open ([BAT-011](tasks/BAT-011-native-limit-diagnostics.md)).

See [BAT-007](tasks/BAT-007-helper-read-only-diagnostics.md) for the original SMC diagnostic evidence; [SIGNING](SIGNING.md#release-version-and-build) explains release version/build settings.

A writer-capable helper that cannot acknowledge restoration stays registered. Repeated reinstall/reboot is not a verified repair for launch-policy rejection; see [launch evidence and signing limits](verification/self-signed-helper.md#recurring-launch-rejection-on-build-3--2026-10-19). No global background-item reset or security exception is part of the workflow.

## Manual native-limit verification (build 4, not hardware-verified)

Install the signed app and explicitly replace/approve its helper through Monny. Quit Monny before copying a DMG update; an old daemon can continue running, so confirm the new feature handshake rather than infer replacement from the app version. This does not install, invoke or authorize a test automatically. The helper prepares its fixed root-owned journal at startup and recovers an unfinished setting before serving connections.

With explicit authorization for a temporary **80%** target and restoration of the freshly captured original enabled/limit pair, quit the normal app and run as the ordinary user:

```sh
/Applications/Monny.app/Contents/MacOS/Monny --verify-native-limit 80
```

This command **can change settings**. It calls the authenticated helper once, applies/read-backs the target and immediately attempts original restoration; there is no dwell/hold timer. JSON records target/before/applied/after/outcome. Only restored produces exit 0. failedRestored means the attempt failed but original read-back matched; externalChange means a different observed setting was preserved, not restored; restorationRequired explicitly means recovery is unconfirmed and helper removal remains blocked. unavailable means the API/target/fresh reading could not establish the check. A timeout/disconnect never triggers an automatic retry; do not repeat an uncertain write. Keep JSON local unless intentionally sharing it.

The server validates the session/target and rejects competing active control. The client first checks nativeVerificationAvailable; helperUpdateRequired means the old daemon needs explicit replacement, not a retry of the write. A valid new selector is never sent to a legacy helper. No native range above/below actual advertised values is assumed. Five-second leases/client timeouts cannot interrupt a stalled private API, and a killed/OS-blocked helper cannot restore until it runs again. No physical charging, macOS 26 or clean-Mac claim follows from software fixtures. Current evidence: [BAT-016](tasks/BAT-016-manual-native-verification.md).

## Contribution workflow

Inspect the existing implementation and [current state](STATE.md) before choosing a slice. Read [engineering standards](ENGINEERING.md) for sampling, concurrency, helper security and localization. UI work follows [DESIGN](DESIGN.md) and the live Sketch frames. Build/test the affected behavior, record required runtime/hardware checks and preserve unrelated work. [WORKFLOW](WORKFLOW.md) describes task records and handoff.

One helper executor owns native sessions, checkpoint recovery, bounded leases and sleep/wake/graceful-termination hooks. Those event handlers still require real runtime acceptance in [BAT-005](tasks/BAT-005-helper-lifecycle.md); earlier status-only confirmations do not validate the new writer or recovery. A DMG replacement alone does not prove the running daemon loaded the new executable.
