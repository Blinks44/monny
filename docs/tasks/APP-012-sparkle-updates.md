# APP-012: Automatic updates with Sparkle

- Updated: 2026-10-21
- Stage: awaiting_verification
- Owner: unassigned (released 2026-10-21)
- Owned surfaces: `App/AppUpdater.swift`, `apps/monny/Info.plist`, Sparkle package in the Xcode project, About rows in `Dashboard/SettingsPage.swift`, updates switch in `App/Onboarding.swift`, appcast and nested signing in `scripts/release.sh`
- Requirements: [SPEC](../SPEC.md#7-settings) §7 About, §8 network; [PLAN](../PLAN.md#release-gates); [SIGNING](../SIGNING.md#update-signing-key)
- Code baseline: main at 037d588 plus uncommitted APP-009 to APP-011; build 34

## Outcome and scope

Sparkle 2.10.0 replaces the GitHub Releases API check, set up as in Rebind (user request 2026-10-21). Settings › About: Check for Updates (Sparkle's standard windows and alerts) and “Check for updates automatically”, which is Sparkle's own preference and is shared with the onboarding Ready switch. `SUEnableAutomaticChecks` is on in Info.plist, so Sparkle does not ask separately. No system profile is sent. Monny's own EdDSA key; `release.sh` writes an appcast for the GitHub release of the same version.

## Implementation and verification

- `AppUpdater` wraps `SPUStandardUpdaterController` (not started in tests); a user-driver delegate brings scheduled update windows forward, since Monny has no Dock icon without its window. The custom update states and their seven strings were removed.
- Key generated with `generate_keys --account monny`, exported to the private signing folder and described in its README; signing the DMG with the exported file verifies against the keychain key.
- `release.sh` build 34: Sparkle's XPC services, Autoupdate, Updater.app and framework signed inside out with the app's identity; `codesign --verify --strict --deep` passes; `Info.plist` carries the feed URL and public key; `appcast.xml` lists only build 34 with a valid EdDSA signature and the `releases/download/v1.0/Monny-1.0-34.dmg` URL. The signed Release app launches under Hardened Runtime (agent-observed, then the installed copy restored).
- `dev.sh test`: 38 tests in 9 suites pass (the version comparison test went with `UpdateChecker`).

## Open checks / dependency

- Nothing is published yet, so Check for Updates shows Sparkle's error alert until the first release carries `appcast.xml`.
- End-to-end update: publish two builds, install the older and confirm Sparkle offers, verifies, installs and relaunches the newer with settings and history kept. Same-signer behavior without notarization is unverified.
- User reported an off-device copy of `monny_sparkle_ed25519.key` on 2026-10-24.

## Next handoff

When publication is authorized, follow [SIGNING](../RELEASING.md), then verify an update between two published releases and confirm the separate update-key backup. Current power draw and Settings design are already implemented; no further feature implementation is pending in this task.
