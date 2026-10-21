# APP-009: Native onboarding

- Updated: 2026-10-21
- Stage: done
- Owner: unassigned (released 2026-10-21)
- Owned surfaces: `App/Onboarding.swift`, onboarding scene and launch policy in `monnyApp.swift`, onboarding strings in `Localizable.xcstrings`
- Requirements: [SPEC](../SPEC.md#6-onboarding) §6; [PLAN](../PLAN.md) phase 4 onboarding gate
- Code baseline: main at 037d588 plus uncommitted onboarding; build 30, layout fix in build 31

## Outcome and scope

On first launch Monny opens a 600 × 540 window with Welcome, Charge limit and Ready from Sketch frames `01`/`07`, `12` and `03`/`08` (page `03 · Flows & System`). Charge limit appears only when the native limit was read (a Mac with a battery on macOS 26.4+); otherwise there are two steps. Welcome swaps the charge-limit item for “Sensors and history” on a Mac without a battery.

- Use 80% Limit enables the native limit at 80% through the shared `ChargeLimitController` (explicit gesture, read back); on failure the step stays and shows the existing “Couldn’t confirm the charge limit” line. Not Now skips.
- Ready: Launch Monny at login (on, registered only when Open Monny is pressed) and Check for updates automatically (on), stored as Sparkle's `SUEnableAutomaticChecks` so Sparkle will not ask again. The body shows the current global shortcut. Open Monny closes the window and opens the popover.
- `hasCompletedOnboarding` is set when the window closes by any route, so onboarding never returns after it was seen. Existing users see it once after updating to build 30.

## Implementation and verification

- Agent-observed on the M1 Max, macOS 27.0.1, Debug build: the window opens in front at first launch (regular activation policy until it closes) and not after the flag is set. Light/Dark renders of all three steps through a temporary `ImageRenderer` test (removed) match the Sketch layout and copy; the renderer cannot draw the window blur, the live window can.
- 31 new strings in all six languages; existing “Charge limit” and failure strings reused.
- `dev.sh test`: 37 tests in 9 suites pass. Signed `Monny-1.0-30.dmg` built.
- User-reported on build 30 (2026-10-21): onboarding works; the window had an empty strip at the bottom and the Ready rows were cramped when a subtitle wrapped. Build 31: content sits below the hidden 32 pt title bar so the window is 540 pt (agent-observed), rows grow with their text, and the Russian login subtitle is shorter.

## Open checks / dependency

- User: confirm the build 31 layout fix. Use 80% Limit, the login switch and Open Monny were reported working on build 30. Check the other five languages for wrapping.
- The updates switch drives Sparkle's own preference since build 34 ([APP-012](APP-012-sparkle-updates.md)).
- Not tested on a Mac without a battery or on macOS below 26.4 (two-step flow).

## User acceptance — 2026-10-21

User, build 37: onboarding walkthrough and its copy accepted.

## Next handoff

None.
