# APP-007: Native-only charging, simplification and production review

- Updated: 2026-10-21
- Stage: awaiting_verification (installed UI, real charge-limit change and older-macOS checks open)
- Owner: app engineering; released for user review
- Baseline: main 6d30be2; experiment preserved on `experiments/discharge` at abe3a80

## Outcome

Main is a native monitor plus the macOS 26.4+ system charge limit. No privileged helper, XPC, SMC writes, Discharge, sailing, heat protection, calibration or trips; their code and records are on `experiments/discharge`.

## Charge limit

- `Battery/NativeChargeLimitBridge.m` loads `PowerUI.framework`, checks every `PowerUISmartChargeClient` method signature once and fails unavailable on any mismatch. Three C calls: read, set limit, enable/disable.
- `ChargeLimitStore` (actor) validates the reply (`ChargeLimit.isValid`), writes only for explicit user actions, enables before setting the target (enabling resets the target on macOS 27), and succeeds only on matching read-back. `ChargeLimitController` exposes the state to the popover, Battery page, Settings and the status-item menu.
- Launch, popover open, app activation, wake and opening a view only read. macOS enforces the limit and keeps it after quit.
- Below macOS 26.4 the controls are replaced by an information banner (six languages).
- Ordinary-user read, distinct target write/read-back and restore of the original pair verified locally on M1 Max, macOS 27.0.1 (2026-10-21, standalone probe). Not verified: the installed app changing the setting, macOS 26.4–26.x execution, other Macs.

## Production review — 2026-10-21

Reviewed the 2026-10-18…21 work. Fixed and simplified:

- Battery health (`system_profiler`, ~1 s) ran on the main actor: with approachable concurrency a `nonisolated async` function inherits the caller's actor. Marked `@concurrent`.
- "Charge limit reached" could repeat while plugged in, because macOS lets the level drift a percent below the limit. It now re-arms only on unplug or a limit change.
- Charge-limit layer: five types/files and a twice-validating bridge reduced to one bridge, one model, one actor and one controller. Unknown state no longer shows "requires macOS 26.4" while the first read is pending.
- SMC reader back to the plain read API; the diagnostic inspection/Codable types were only used by the removed helper.
- Removed disabled placeholder cards (sailing, heat, calibration, trips), the disabled "Calibration finished" notification, their preferences and 17 unused strings. Battery notifications are hidden on a Mac without a battery. "Set Limit to 100%" is disabled when it is already 100% or unsupported.
- Removed the popover keep-open hook for the old helper authorization, the custom `BatteryCardRow` layout (an `HStack` with `fixedSize` does the same) and `InterfaceReviewTests` (wrote 252 PNGs to /tmp per test run; no meaningful assertions).
- `release.sh`: embedded Python with helper checks replaced by a short bash script with the same steps.
- Docs: retired BAT-*, APP-005/006 and helper verification records (on `experiments/discharge`); README, SECURITY, CONTRIBUTING, SIGNING, DEVELOPMENT, SPEC and DESIGN no longer describe a helper.

Checks: `dev.sh test` passes, 33 tests in 8 suites (new: reply validation, no repeated limit alert while plugged in). Sketch (live, document 97DFF3F8…, read-only): popover Battery hero matches `02 · Popover · Battery`; the shared control now follows `16 · Battery · Native limit control` with the switch above the target. Window Battery differs only by design: deferred cards removed and the existing Details card kept. `release.sh`: `Monny-1.0-27.dmg`, SHA-256 `0fa64f68c9803dc18bcec4700f0ba4ed2717effb903c9795c025a8bd8456b456`, app/DMG signatures and hdiutil verify pass.

Sketch MCP note: the server can run while its tools are missing from an agent session (they load at session start). It still answers plain HTTP JSON-RPC at the address shown by `claude mcp list`.

## Pre-release review — 2026-10-21

Reviewed all app code (about 7,200 lines) and the six-language String Catalog on main 7fe24b0.

- Bugs fixed: `NativeLimitControls` re-syncs after every change, so a failed change no longer leaves the slider on an unconfirmed target when the setting did not change; an unavailable limit on macOS 26.4+ says "Charge limit isn’t available on this Mac" instead of "requires macOS 26.4"; the status item clears its accessibility value when readings are turned off; the charge-limit notification body states the level instead of repeating the title; Wi-Fi signal "Fair" has its own key (`signal.fair`), because the thermal state's "Fair" is a different word in other languages; the memory pressure subtitle no longer says "how efficiently macOS manages memory" (the opposite meaning) in any language.
- Simplified: removed unused `CollectingHistoryCard`, the unused Banner warning/danger kinds, Chip info kind, large primary button and destructive tinted button; one `ThermalStateText.text(for:)`; `Duration / .seconds(1)` instead of manual component math; four stale strings.
- Copy: Russian strings rewritten where they read as literal translations (download/upload, throughput, router, cached files, onboarding, busy-app body, thermal "Fair"/"Critical"), German "Wired" and the confirmation error; load average detail reads "1 min · 5 min: …".
- Checks: `dev.sh test` 41 tests in 9 suites pass (new: charge-limit notification body); no compiler warnings in app sources; every catalog key has all six languages. `release.sh`: `Monny-1.0-37.dmg`, SHA-256 `440566f3771683a7c9b86750e9053b3c266478c3e2b31c8d362d013019cba652`; app/DMG signatures and hdiutil verify pass. Not checked: rendered wrapping of the changed strings in all languages.

## User acceptance — 2026-10-21

User installed build 27: the app works, and changing the limit in Monny changes it in System Settings › Battery. Scope: user's MacBook (M1 Max, macOS 27.0.1).

## Next

Charge-limit change from the installed app is accepted. Build 37 with its copy, accessibility and notifications accepted by the user (2026-10-21). Open: charge limit on macOS 26.4–26.x.
