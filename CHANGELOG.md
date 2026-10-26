# Changelog

Notable changes to Monny. Versions follow the app version shown in **Settings → About**.

## 1.1.1: 2026-10-26

- Added AI limits for ClinePass, Codebuff, Amp, Augment and Nous Portal using the tools’ existing sign-in.
- Added vendor logos for all supported AI tools.
- Fixed the AI history legend layout when many tools are enabled.
- Service requests that carry sign-in credentials now refuse redirects.

## 1.1.0: 2026-10-25

- Processes: search by app or process name, and Quit or Force Quit an app or process from its context menu, with confirmation for Force Quit.
- Battery: a power panel showing what the Mac uses, how much goes into charging and the adapter's rating, or the draw and time left on battery. Overview shows the Mac's power draw next to the battery level.
- AI limits for JetBrains AI (monthly quota and top-up credits, read from local IDE files) and GitHub Copilot (premium requests, chat and completions, using the GitHub CLI sign-in).
- A low AI limit no longer notifies again when the service adjusts its reset time.
- Corrected and refined wording in all six languages.

## 1.0.0: 2026-10-24

First public release. Requires a Mac with Apple silicon and macOS 26 or later.

- Menu bar popover with Overview, Battery and Processes tabs, a global shortcut (⌥⌘M) and optional readings next to the icon.
- Dashboard window with Overview, CPU, Memory, Disk, Network, Battery and Sensors pages and history from 1 minute to 7 days.
- Battery charge limit from 80 to 100% using the built-in macOS setting (macOS 26.4 and later), plus the Optimized Battery Charging switch.
- Temperatures, fan speeds, SSD health and power draw where the Mac reports them; anything the Mac does not expose is shown as unavailable.
- Notifications for a reached charge limit, a hot Mac, low battery, high memory pressure and an app that keeps the CPU busy.
- Optional AI limits for Claude Code, Codex, Cursor and Grok, off by default.
- Automatic updates through Sparkle.
- English, Russian, German, French, Spanish and Simplified Chinese.

The app is signed but not notarized; see [Install](README.md#install) for the one-time first-launch step.
