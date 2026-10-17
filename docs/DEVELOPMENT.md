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

Automatic signing; no development team or credentials are stored in the repository. Local builds without a team are signed to run locally. The battery helper will need a stable signature shared with the app so the helper can validate its client; the signing identity for releases is decided in the release task (Rebind uses one stable self-signed certificate outside notarization; Monny's helper approval flow may require a Developer ID, to be researched).

## Battery helper (planned)

The helper does not exist yet. When it does, this section owns: how to build and register it locally, how to approve it in System Settings → General → Login Items & Extensions, how to unregister it, and how to read its logs with `log stream --predicate 'subsystem == "blinks44.monny.helper"'`. Never leave a development helper installed with charging inhibited; uninstall restores macOS charging.

## Contribution workflow

Inspect the existing implementation and [current state](STATE.md) before choosing a slice. Read [engineering standards](ENGINEERING.md) for sampling, concurrency, helper security and localization. UI work follows [DESIGN](DESIGN.md) and the live Sketch frames. Build/test the affected behavior, record required runtime/hardware checks and preserve unrelated work. [WORKFLOW](WORKFLOW.md) describes task records and handoff.
