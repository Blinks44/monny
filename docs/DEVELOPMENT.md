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

Default developer builds are ad-hoc signed. Installed review candidates use the existing Apple Development identity with Hardened Runtime via `apps/monny/scripts/release.sh`. The script builds arm64 Release, signs the app and DMG, checks signatures/image integrity and prints SHA-256. See [SIGNING](SIGNING.md) for the existing backup/distribution limitations.

## Native charge limit

`Battery/NativeChargeLimitBridge.m` calls the private `PowerUISmartChargeClient` (macOS 26.4+) as the ordinary user, after checking every method signature at runtime; a mismatch reads as unavailable. `ChargeLimitStore` makes the calls off the main actor one at a time and confirms each change by reading it back. Launch, wake and opening a view only read. macOS enforces the limit and keeps it after Monny quits. Verified on macOS 27.0.1 only.

The helper/Discharge implementation and its tests are on **experiments/discharge** (09595b5).

## Contribution checks

Read [STATE](STATE.md), [WORKFLOW](WORKFLOW.md) and affected contracts. Use dev.sh for build/test. Inspect live Sketch before visual changes, preserve source design, and render both appearances/all languages. Keep temporary snapshots, logs, raw machine data and probe binaries outside Git. Run the injected charge-limit tests; a real system-setting change is a manual check. Research private runtime/SMC mechanisms before adding code; no blind library or toolchain migration.
