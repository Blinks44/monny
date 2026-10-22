# APP-014: Charge limit slider and Optimized Battery Charging switch

- Updated: 2026-10-22
- Stage: done
- Owner: unassigned (released after build 39)
- Owned surfaces: `Battery/ChargeLimitController.swift`, `Battery/NativeLimitControls.swift`, `Battery/NativeChargeLimitBridge.*`, right-click menu, Sketch frames `16 · Battery · Native limit control`, `17 · Window · Settings · Native`, `05 · System · Menu bar & notifications` (Light/Dark)
- Requirements: SPEC §2 (right-click menu), §5; release candidate
- Code baseline: main 0636518 plus uncommitted build 39 changes

## Outcome and scope

User-reported bug: turning the limit off made macOS report 100%, the slider followed, and turning the switch back on tried to write an enabled 100% limit, which never read back and showed “Couldn’t confirm the charge limit”. User decision 2026-10-22: follow System Settings. One slider, 100% means no limit; the former switch now controls Optimized Battery Charging. The duplicate “Set Limit to 100%” menu item is removed.

## Acceptance

- [x] Slider: 100% turns the limit off, a lower target turns it on and sets it; enabled 100% is never written (unit tests).
- [x] Optimized switch writes only on change and requires read-back; hidden when unreadable (unit tests).
- [x] Sketch frames updated and saved; SPEC/DESIGN/research updated.
- [x] On this Mac (user-reported, build 38, macOS 27): slider targets including 100% update System Settings › Battery; turning Optimized Battery Charging off shows in System Settings after its Battery sheet is reopened (an open sheet does not refresh).
- [x] The switch animates when macOS confirms the change (build 39).

## Sketch source

Monny.sketch saved 2026-10-22: frame 16 shows the slider card first, then the Optimized Battery Charging switch, with a note that 100% means no limit; frame 17 Settings › Battery card has the same two rows; the right-click menu lists only Turn Off Charge Limit. Popover Battery frames still show the helper-era layout; the app keeps using frame 16 inside its card.

## Implementation and verification

`ChargeLimitStore.set(target:)` replaces `set(limit:enabled:)`; `ChargeLimit.target` reports 100 while the limit is off and `isValid` requires 100 as the last target. The bridge reads/writes Optimized Battery Charging with its own signature check. The value label shows “No limit” at 100%. New strings in six languages; retired “Use charge limit” and “Set Limit to 100%”.

`scripts/dev.sh test`: 44 tests in 9 suites pass (2026-10-22). `scripts/release.sh`: `apps/monny/build/release/Monny-1.0-38.dmg`, SHA-256 `5a0c37d9e978cad25a828edbcea41499d338556025ca1dd629ee607c020df705`, signed Apple Development, not notarized. A read-only PowerUI probe confirmed the Optimized getter; the agent's own write probe was blocked by the session permission policy, and the user then confirmed both writes through the app. Build 39 animates the Optimized switch when the confirmed value arrives (it previously jumped, since the value changes after the async write): 44 tests pass, `Monny-1.0-39.dmg`, SHA-256 `2c273600dc8886395a38586e6a9f0770695152db663b072c28eac841c3876106`.

Build 40 (same uncommitted change set) replaces `.buttonStyle(.plain)`, which dims on press, with `StaticButtonStyle` and makes push/popup buttons darken with `State/Pressed` instead of fading (user request; DESIGN rule). 44 tests pass; `Monny-1.0-40.dmg`, SHA-256 `9c6170ff3973dc3d2bfbef5fddc9a2768e44b659d18832f5fcdc436ab38ece2b`. Pressed look not yet seen by the user.

Build 41: the charge-limit controls no longer use `.disabled` while a write runs (it dimmed the switch to 45 % and made it flash); busy now only blocks pointer input, and the Optimized switch moves at once to the chosen position, then settles on the read-back value with an animation. 44 tests pass; `Monny-1.0-41.dmg`, SHA-256 `3b05227d3ae09f099a914d75af36f02ec0979212e82655ec358323c2e10a29f3`.

## Next handoff

Commit with the release candidate when the user asks.
