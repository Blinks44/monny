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

## Signing and packaging

Default developer builds are ad-hoc signed. Installed review candidates use the existing Apple Development identity with Hardened Runtime via `apps/monny/scripts/release.sh`; no helper is bundled or registered. The script builds arm64 Release, signs the app and DMG, checks signatures/image integrity and prints SHA-256. It never creates signing keys, installs the app or changes charging. See [SIGNING](SIGNING.md) for the existing backup/distribution limitations.

## Native charge limit

Main uses macOS's persistent system preference through a small runtime-checked PowerUI bridge. Monitoring supports macOS 26+; charge limit requires macOS 26.4+ and a compatible runtime. Native settings are read on startup/activation/wake; setters run only for explicit user actions, serially off main. Enabled/target read-back is mandatory. macOS owns enforcement after app quit; no helper/session/journal or adapter-isolation writes remain. The local ordinary-user probe validates access on macOS 27.0.1, not every supported Mac/OS.

The complete build-23 helper/Discharge implementation, engineering commands and tests are preserved on **experiments/discharge** at abe3a80. Historical BAT task/research evidence remains dated and does not describe current main. Do not invoke removed commands or resume experiments on main. Users of old builds must remove their helper using that old app before replacing it; the new app never silently uninstalls or edits recovery journals.

## Contribution checks

Read [STATE](STATE.md), [WORKFLOW](WORKFLOW.md) and affected contracts. Use dev.sh for build/test. Inspect live Sketch before visual changes, preserve source design, and render both appearances/all languages. Keep temporary snapshots, logs, raw machine data and probe binaries outside Git. Run meaningful injected native-setting tests; actual system-setting trials need bounded scope/read-back and truthful evidence. Research private runtime/SMC mechanisms before adding code; no blind library or toolchain migration.
