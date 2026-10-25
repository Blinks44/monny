<p align="center">
  <img src="docs/images/app-icon.png" alt="Monny app icon" width="128" height="128">
</p>

<h1 align="center">Monny</h1>

<p align="center">
  See what your Mac is doing, and keep its battery healthy while it stays plugged in.<br>
  Free, open source, native on macOS 26+.
</p>

A native macOS menu bar utility for resource monitoring and battery charge control. A click on the menu bar icon shows CPU, memory, disk, network, cores and battery at a glance; a dashboard window adds history charts, top processes and temperature sensors. Battery controls use the built-in macOS charge limit where available; macOS manages charging.

**Status:** version 1.0.0. Download it from [GitHub Releases](https://github.com/Blinks44/monny/releases/latest); what changed in each version is in the [changelog](CHANGELOG.md).

## Repository layout

| Path | Contents |
| --- | --- |
| `apps/monny/` | The macOS app: Xcode project, sources, tests and the `scripts/dev.sh` build script |
| `apps/website/` | The public landing page: TanStack Start/React 19 on Vite with moduix, Paraglide in six languages, Cloudflare Workers ([README](apps/website/README.md)) |
| `docs/` | Specification, design notes, roadmap, current state and verification records |
| `AGENTS.md`, `.agents/`, `.claude/` | Instructions and skills for coding and design agents |

## Features

- **Menu bar popover** with Overview, Battery and Processes tabs, refreshed every few seconds, and a global shortcut (⌥⌘M by default).
- **Dashboard window** with Overview, CPU, Memory, Disk, Network, Battery and Sensors pages and 1 minute to 7 day history.
- **Battery charge limit** from 80 to 100% on macOS 26.4 and later. Monny changes the same setting as System Settings, so macOS keeps enforcing it after Monny quits. No privileged helper.
- **Notifications** for a reached charge limit, a hot Mac, low battery, high memory pressure and an app that keeps the CPU busy.
- **AI limits (optional, off by default):** how much of your Claude Code, Codex, Cursor, Grok, JetBrains AI and GitHub Copilot subscription limits is left, read with each tool's own sign-in on this Mac.
- English, Russian, German, French, Spanish and Simplified Chinese.

Readings never leave the Mac: no account, analytics or telemetry. The only network requests are update checks and, when AI limits are turned on, the limit checks with Anthropic, OpenAI, Cursor, xAI and GitHub (JetBrains AI is read from local IDE files). The [specification](docs/SPEC.md) lists the full scope and acceptance.

## Requirements

- A Mac with **Apple silicon** running macOS **26 or later**. Intel Macs are not supported. Charge limits need a Mac with a battery, macOS 26.4+ and a compatible native runtime.
- Full Xcode with a **Swift 6.2+ compiler** and a **macOS 26+ SDK** to build from source.

## Build and run

From the repository directory:

```sh
apps/monny/scripts/dev.sh doctor
apps/monny/scripts/dev.sh run
```

`doctor` reports the selected toolchain and project targets. `run` builds Debug and opens `Monny.app`. The script selects full Xcode per process without changing your system's `xcode-select` setting. Alternatively, open `apps/monny/monny.xcodeproj` in Xcode, select the **monny** scheme and run with **⌘R**. See the [development guide](docs/DEVELOPMENT.md) for tests, Release builds and signing.

## Install

Monny is distributed as a DMG on [GitHub Releases](https://github.com/Blinks44/monny/releases), outside the Mac App Store: system monitoring needs App Sandbox off.

1. Download the latest `Monny-<version>-<build>.dmg`, open it and drag **Monny** to **Applications**.
2. Open Monny from Applications.

Monny is signed, but not yet notarized by Apple: that needs a paid Apple Developer ID, which the project does not have yet. So on first launch macOS says it cannot verify the app. Allow it once in either way:

- **System Settings:** try to open Monny, close the message, then go to **System Settings → Privacy & Security**, scroll to Security and click **Open Anyway** next to Monny. Confirm with your password.
- **Terminal:** remove the download quarantine flag, then open Monny as usual:

  ```sh
  xattr -dr com.apple.quarantine /Applications/Monny.app
  ```

This is needed once per downloaded version. Updates keep the same signature, so permissions such as notifications and launch at login stay granted. After the first install Monny checks for updates itself (Sparkle); you can also use **Check for Updates** in the menu bar icon's right-click menu.

## Technology

| Area | Stack |
| --- | --- |
| Language and UI | Swift 6 language mode, SwiftUI, Swift Charts, AppKit for the menu bar item |
| Readings | Mach host statistics, IOKit, SMC sensors, `ProcessInfo` and power-source APIs ([research](docs/research/README.md)) |
| Battery control | The macOS 26.4+ system charge limit, changed as the ordinary user |
| Localization | String Catalogs |
| Tests | Swift Testing with an Xcode-hosted test target |
| Design | Sketch, SF Symbols |

## Documentation

- [Development guide](docs/DEVELOPMENT.md): build, tests and signing. [Releasing](docs/RELEASING.md): versions and publishing on GitHub.
- [Specification](docs/SPEC.md) and [roadmap](docs/PLAN.md): product requirements and remaining work.
- [Documentation index](docs/README.md): design, engineering conventions, verification and contributor/agent workflow.
- [Contributing](CONTRIBUTING.md), [security policy](SECURITY.md), [code of conduct](CODE_OF_CONDUCT.md) and [changelog](CHANGELOG.md).

## Acknowledgements

- [CodexBar](https://github.com/steipete/CodexBar) by Peter Steinberger and its contributors (MIT): its documentation showed where supported tools keep their sign-in or quota data and which endpoints report their plan limits, including Copilot through the existing GitHub CLI account. Monny copies no code from it ([research](docs/research/ai-usage-limits.md)).
- Claude, OpenAI/Codex, Cursor and Grok marks are trademarks of their owners and only identify those services; SVGs from [thesvg.org](https://thesvg.org/) ([sources](docs/research/ai-usage-limits.md#service-marks)).
- [Stats](https://github.com/exelban/stats) by Serhiy Mytrovtsiy (MIT): SMC key names for temperatures and fans ([research](docs/research/README.md#temperatures-and-fans-smc)).
- [Sparkle](https://sparkle-project.org) (MIT) for updates and [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus (MIT) for the global shortcut; [create-dmg](https://github.com/create-dmg/create-dmg) (MIT) builds the installer.

## License

Monny is released under the [MIT License](LICENSE).
