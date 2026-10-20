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

Build 10 adds explicit native charge-limit sessions, using only positively advertised supported values. Status/diagnostics never apply a target. The app keeps one authenticated owner connection, renews a 30-second lease every 10 seconds and does not enable control from saved preferences. The helper checkpoints original settings and attempts restoration on stop, disconnect, awake expiry, shutdown and restart. Build 12 retains the active native system limit across sleep; wake validates the existing setting and retains the original checkpoint for later restoration. System-limit changes/restoration are user-confirmed; physical and lifecycle behavior on the final helper remain open ([BAT-018](tasks/BAT-018-native-limit-interface.md)). Local logs: `log stream --predicate 'subsystem == "blinks44.monny.helper"'` (helper) or subsystem `blinks44.monny`, category `BatteryHelper` (app).

Build 12 preserves native limits across sleep with session revision 3, retaining build-11 expired-owner revocation while awake. Older helpers remain readable/removable but cannot enable new control in app 12. For an existing responding helper, turn control off and uninstall it explicitly in Monny before quitting and replacing the app with build 12 from the DMG. Launch the new app and install/approve its bundled helper. A copied app does not replace a running daemon. Older protocol-1 helpers remain readable/removable, but lack the native session flag and show an update hint. No automatic installation, global BTM reset or security-setting change is part of release.sh.

## Read-only charge diagnostics

Use the signed app, not an ad-hoc development build. Install/approve its bundled helper explicitly through Monny first. For a responding older helper, remove it through the old app before replacing the app, then install it from the new app; copying a DMG alone need not restart an already-running daemon. No installer or diagnostic script performs these actions automatically.

Run the installed executable directly (ordinary user, no sudo):

```sh
/Applications/Monny.app/Contents/MacOS/Monny --battery-diagnostics
```

It prints JSON to stdout and exits, with no menu bar UI, sampling, history writes, registration or charge writes. Only the authenticated helper performs the fixed six-key read and the native-limit getter query. SMC capability probes are cached per helper process; simultaneous requests share them. The native session backend reads the current setting for status/diagnostics so an old diagnostic snapshot cannot overwrite an active limit. Native snapshots are observations, not proof of physical enforcement. Metadata/readability is evidence only, never write support. Raw results stay local unless the user chooses to share them.

Machine error codes: `signingUnavailable` requires the signed package; `helperNotEnabled` requires explicit install/approval; `helperUpdateRequired` means the connected older helper lacks the required native-limit diagnostic flag; `connectionFailed`/`timedOut` leave capabilities unknown. No automatic retry or privilege escalation is attempted. Status/removal remain compatible with old protocol-1 helpers via additive optional fields; only a positive diagnostic feature flag permits the new selector. Replies remain limited to 4 KiB with exact key order and readable metadata/byte validation. Native replies validate the advertised sorted unique 80–100 range and configured limit; an unavailable API reports a typed reason without invented settings. Build 3 adds nativeChargeLimit/nativeLimitDiagnosticsAvailable optional fields; old status/removal clients still work.

The native-limit bridge checks the private system class and getter ABI before invocation; this diagnostic path does not invoke setter/disable selectors or edit preferences. Its synchronous getters run off the main actor. A client request times out after five seconds; this cannot forcibly cancel a private synchronous getter. The helper bounds work to one cached diagnostic task per process, so repeated clients cannot create more stuck reads. Build-3 installed-helper native reads are verified; macOS 26 native API acceptance remains open ([BAT-011](tasks/BAT-011-native-limit-diagnostics.md)).

See [BAT-007](tasks/BAT-007-helper-read-only-diagnostics.md) for the original SMC diagnostic evidence; [SIGNING](SIGNING.md#release-version-and-build) explains release version/build settings.

A writer-capable helper that cannot acknowledge restoration stays registered. Repeated reinstall/reboot is not a verified repair for launch-policy rejection; see [launch evidence and signing limits](verification/self-signed-helper.md#recurring-launch-rejection-on-build-3--2026-10-19). No global background-item reset or security exception is part of the workflow.

## Read-only adapter diagnostics (build 13)

The signed build-13 app/helper adds an independent opt-in command:

```sh
/Applications/Monny.app/Contents/MacOS/Monny --adapter-diagnostics
```

Use the same explicit signed-app/helper update and approval procedure above. This command never registers/replaces a helper or changes charging. It first checks `adapterDiagnosticsAvailable` through the old authenticated status selector; an older helper returns `helperUpdateRequired` before any new selector is sent. Ordinary status and `--battery-diagnostics` keep their previous behavior and exact six-key SMC payload.

The new `readAdapterDiagnostics` selector takes no keys/values/paths and reads exactly CHIE/CH0I/CH0J off the main actor, once per helper process. Concurrent calls share the result. The helper revalidates the session and lifecycle after the read; the client retains its five-second timeout and 4 KiB reply bound. JSON includes `adapterDiagnostics`, typed unavailable outcomes and unverified control support. Neither metadata nor successful bytes establish write access, physical adapter isolation or complete Discharge-to-limit behavior. A stuck synchronous read cannot be forcibly cancelled; one cached task bounds work. The released build-13 artifact has no adapter writer; later unbound preparation is described below.

Full software/anonymous-XPC checks pass in [BAT-021](tasks/BAT-021-adapter-diagnostics.md). Installed signed-helper read outcomes are user-confirmed in BAT-021; write access, wrong-peer runtime and all existing physical/crash/restart gates remain open. Keep raw diagnostic output local.

## Read-only adapter-power diagnostics (build 14)

This command reads IOPowerSources and a fixed projection of AppleSmartBattery directly as the ordinary user. No helper/signing handshake or helper update is needed. Run the packaged candidate directly from the repository root, without installing it:

```sh
apps/monny/build/release/Monny.app/Contents/MacOS/Monny --adapter-power-diagnostics
```

It prints one sanitized JSON snapshot and exits. No SMC connection, XPC, native-limit getter/setter, registration, sampler/history, UI or network work is started. App-model construction is lazy and all diagnostic launch/activation/termination paths bypass it. Normal UI startup still constructs and starts the same shared sampler.

`physicalAdapterSupport` stays `unverified`. Source selection, ExternalConnected, AppleRawExternalConnected, charging flags, and adapter-dictionary shape are observations, not physical cable or write-support grants. Missing/invalid Boolean fields differ from false. The public adapter query's nil result stays unavailable because it can mean absence or error. Acquisition time does not prove driver-telemetry freshness. Exit 0 means the report was emitted; unavailable fields are still unknown.

Use [BAT-023's connected/unplugged/reconnected check](tasks/BAT-023-adapter-power-observation.md#user-check) with the lid open. Keep outputs local unless intentionally sharing. This baseline does not prove behavior during CHIE isolation or close hardware recovery gates.

## Adapter engineering verification

Build 15 introduced `--verify-adapter-isolation` with a positive revision-1 capability handshake. Full verification still requires independent physical cable evidence, battery-source observation, restored CHIE byte, fresh return-to-adapter evidence and unchanged native settings. **Build 16 continues to advertise adapterVerificationAvailable=false**; Discharge stays disabled.

Build 16 adds the separate zero-argument `--verify-adapter-byte-pulse` command. It first authenticates a status reply and requires adapterBytePulseAvailable=true and adapterBytePulseVersion=1; old/disabled helpers refuse before the selector. No automatic registration, retry or fallback. The helper admits only known CHIE=0 with the reviewed metadata, no active native owner, fresh adapter-source/native readings, battery ≥30%, positive raw external flag and known open lid. One fixed 0→8→0 cycle checkpoints first, captures one candidate reading and restores immediately without dwell/polling. No native getter runs while isolated and no native setter runs at all. The report always says unverified; a byte round trip establishes no physical support. Unknown flags remain unknown.

The executor opens the fixed secure adapter journal and recovers before native startup/listener activation. Partial failures restore or retain recovery intent and block new control/removal acknowledgement. A three-second software budget/watchdog cannot interrupt a synchronous stalled system call; helper restart availability is user-confirmed only for native recovery, not CHIE. The user must approve the concrete hardware experiment before anyone runs the valid pulse command. See [BAT-025](tasks/BAT-025-adapter-byte-pulse.md) for the candidate and exact scope. Read-only power/adapter diagnostics remain separate.

## Bounded byte-source observation (build 17)

`--observe-adapter-byte` is a separate explicit engineering command with exact zero extra arguments and its own positively advertised revision-1 handshake. It uses one isolation attempt, at most eight reads over a two-second observation window and the existing three-second checkpoint/watchdog budget. No repeated toggles, native setting changes or private native getter while isolated. Ownership remains reserved across awaits; lifecycle events recover independently of source flags. Synchronous I/O can outlast the software budget.

The bounded report separates byte rollback and observed battery source; zero exit also requires actual return-to-adapter-source evidence and unchanged native endpoints. Unknown/missing return evidence produces nonzero and never retries. Full adapter verification and Discharge remain disabled. [BAT-026](tasks/BAT-026-bounded-adapter-observation.md) owns the concrete new hardware scope; do not reuse the consumed no-dwell pulse authorization or run the valid command without new explicit authorization. Prefer a direct adapter and disconnected USB-C display, with lid open. [Upstream evidence](research/opendente-aldente-chie.md) explains this distinction.

Build 18 requires observation revision 2 and adds a separate read-only source-return window after confirmed CHIE=0/journal clearance: at most two seconds/eight readings, with no setter or lease extension. The original owner reservation remains across awaits; lifecycle interruption terminates the read. Return status and count are explicit; absent/stale/changed-native data cannot become success. The CLI uses a seven-second response timeout. Revision-1 helpers refuse before the selector; update explicitly before testing. No new hardware invocation is authorized by this software change.

## Adapter helper restart experiment (build 19)

`--verify-adapter-restart` requires the separately advertised revision-1 capability and zero extra arguments. It deliberately leaves a known-eight checkpoint and exits only the helper process without cleanup, then reads status from a different instance until the bounded polling limit. Startup receipt must prove pending-eight-to-zero recovery, native preservation and actual adapter power. This is not the normal observation command and must not be automatically retried. Helper restart may be throttled; the old in-process watchdog is gone after exit. [BAT-027](tasks/BAT-027-adapter-restart-recovery.md) owns the concrete authorization/fallback and acceptance. Do not run the valid command as part of routine package verification.

The unprivileged `scripts/verify-adapter-recovery.sh` fixture checks only injected file-backed effects across actual subprocess exit/reconstruction. It never registers a helper or opens AppleSMC. Hosted tests inject the terminating callback. Neither establishes real adapter restart recovery.

## Lifecycle evidence (build 20)

Authenticated --battery-diagnostics/--adapter-diagnostics now include lifecycleDiagnostics/version 1 tied to helperInstance. Counts and last outcomes distinguish sleep/wake/removal preparation, no pending adapter recovery, restored adapter, preserved native session and failure. No lifecycle-simulation selector or automatic OS sleep is added. Compare the same helper instance before/after ordinary user-owned sleep with Monny native control off and CHIE=0; [BAT-028](tasks/BAT-028-adapter-lifecycle-evidence.md) owns this read-only integration check. Passing it does not validate active CHIE restoration during sleep/removal.

## Active adapter sleep experiment (build 22)

`--verify-adapter-sleep` is a separately advertised revision-1 engineering command. It retains one authenticated session through typed known-eight preparation and a single ordinary console-user IOPMSleepSystem request. Build 22 first arms workspace sleep/wake observation, waits up to 60 awake seconds for a paired event, then begins the separate 15-second/30-read authenticated post-wake check. Transition/DarkWake no longer consumes that latter budget; absent events still fail closed. A compatible revision-1 build-21 helper is sufficient. The helper remains charge-only and keeps the original three-second non-renewable watchdog. Failed requests cancel/close rather than replay. On user wake, success requires the same helper, paired counters, adapterRestored at sleep, no failed wake, preserved native settings and adapter source. Timer rollback before sleep is inconclusive. See [BAT-029](tasks/BAT-029-active-adapter-sleep.md) for explicit authorization and manual-wake/fallback instructions; never run it during package review. No root shell, sleep assertion or wake schedule is part of the test.

## Active adapter removal experiment (build 23)

`--verify-adapter-removal` requires a positively advertised revision-1 build-23 helper and separate authorization for one preparation plus actual helper removal. It retains the authenticated owner during fixed known-eight preparation, requires the existing same-instance removal acknowledgement to restore zero/preserve native settings, then calls ordinary async SMAppService.unregister once. Registration, direct unprivileged CHIE=0 and adapter source are checked afterward without XPC or automatic reinstall. A timer-first restoration or failed/malformed acknowledgement cannot authorize removal. Native preservation in the report is measured before unregister. See [BAT-030](tasks/BAT-030-active-adapter-removal.md) for preconditions, bounded checks and fallback. Never execute the valid command during package review.

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
