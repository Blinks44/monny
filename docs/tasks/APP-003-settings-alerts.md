# APP-003: Working Settings, alerts and app language

- Updated: 2026-10-21
- Stage: done
- Owner: unassigned
- Owned surfaces: `App/Alerts.swift`, `App/UpdateChecker.swift`, `App/Preferences.swift` (shortcut name, `AppLanguage`), `Dashboard/SettingsPage.swift`, `AppModel.start()`, `Sampler.onSample`, Settings frames in Monny.sketch (General section)
- Requirements: SPEC §2 (badge, global shortcut), §7 (General, Menu bar, Notifications, About); phase 3
- Code baseline: `main`, committed in 4a69d9d

## Outcome and scope

Settings controls that do not depend on the battery helper now work: notifications for heat, low battery and memory pressure, the menu bar attention badge, a changeable global shortcut, the update check, and a new app language picker (user request 2026-10-18). Battery notifications (charge limit, calibration), helper status and Uninstall Helper wait for battery control (phase 4).

## Acceptance

- [x] Alerts fire once per episode and re-arm when the condition clears: hot = thermal state Serious/Critical (as the CPU chip), low battery = on battery below 20 %, memory pressure = Warning or Critical (re-arms at Normal). Notifications follow the Settings toggles; permission is asked the first time one is due.
- [x] Badge shows for hot or Critical memory pressure and respects Show alert badge.
- [x] Global shortcut (default ⌥⌘M) recorded in Settings; the menu item and popover footer show the current shortcut.
- [x] Check for Updates queries the latest GitHub release on request only; states idle / checking / up to date / available (Download… opens the release page) / failed (offline variant), as in Sketch frames 08, 12, 13.
- [x] Language: System or one of the six languages, stored as `AppleLanguages` in Monny's domain; a Restart row appears when the choice differs from the running language. Language row added to all eight Settings frames in Sketch.
- [x] User: the global shortcut opens the dashboard from another app (user-reported, 2026-10-18).
- [ ] User: a notification appears (for example with Battery below 20% on, or under heavy load).

## Sketch source

Monny.sketch, page `02 · Window`, Settings frames 08/12/13/14 Light/Dark: General gained a Language row (popup "System"), Menu bar and About moved down 44 pt. Saved 2026-10-18. The Restart row is not drawn; it reuses the row pattern with a Tinted button.

## Implementation and verification

- Dependency: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) 1.17.0 (MIT, maintained, Swift 6, Carbon hot keys without Accessibility permission, own recorder and six of our languages). Decision in [research](../research/README.md#other-dependencies).
- Update check: plain GitHub Releases API with `URLSession` (Sparkle installs updates, which SPEC rules out). 404 (nothing published) counts as up to date. Superseded 2026-10-21 by Sparkle ([APP-012](APP-012-sparkle-updates.md)); `UpdateChecker.swift` was removed.
- Language change applies after a restart: Restart waits for the current process to exit, then reopens the bundle, so history is saved before the new instance loads it.
- Differences from Sketch: the shortcut is the package's recorder field instead of a popup button; Privacy has no Read policy link until a policy page exists; About subtitle says "You're up to date" without "checked today".
- Tests: `AlertTests` (heat episodes, low battery only on battery power, pressure re-arm, version comparison). `dev.sh test`: 25 tests pass. `dev.sh build` passes.
- Agent check of the running Debug build on the M1 Max (macOS 27.0.1): Settings in Russian and English fit; Check for Updates showed up to date (API returned 404); switching the stored language showed the Restart row, Restart relaunched Monny (new process, history saved) in the chosen language. Popup menus cannot be opened in background control, so the picker itself was exercised by writing the same default. Language reset to System afterwards.
- Not checked by the agent: delivered notifications (the hot state cannot be forced safely). The user reported that the global shortcut works.

## User acceptance — 2026-10-21

User, build 37 on the M1 Max (macOS 27.0.1): enabled notifications arrive.

## Next handoff

None.
