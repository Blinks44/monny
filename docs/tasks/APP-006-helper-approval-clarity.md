# APP-006: Clear helper approval step

- Updated: 2026-10-19
- Stage: awaiting_verification (user setup UX)
- Owner: unassigned; released
- Baseline: main 1dc16bd plus preserved BAT-004/REL-002 work
- Scope: shared helper setup actions/copy, six translations, scoped Sketch source corrections

## Outcome

User reports local helper installation succeeded but password prompts and several secondary links made approval unclear. Do not count this as verified IPC, restart or removal. Make approval the single primary action; explain where to enable Monny and that macOS can ask again for a password. Refresh on app activation already exists. Keep removal in its confirmation menu during approval, away from the main path; no automatic registration/system-settings navigation or permission changes.

## Checks

Build/test, updated Sketch source and six-language/native layout review. Actual repeated setup UX remains user acceptance; the agent does not reinstall/remove the user's helper.

## Implementation and verification — 2026-10-19

Pending approval now shows one primary Allow in macOS action. Retry and confirmed uninstall are in a native More menu during this step; connected-state removal remains available. All six languages explain enabling Monny in Login Items & Extensions, returning to the app, and possible repeated authentication. Existing app-activation refresh is preserved. No auto-install, approval bypass, polling or helper-protocol change.

Corrected the misleading single-password promise in both onboarding Light/Dark Sketch frames. Saved standalone Light/Dark approval references on Flows & System (5C68E498-6CDF-4B2C-85AF-65BFFF879678 / 882EC50D-07D3-4467-BFBE-D3EEEEEA3792), screenshot-reviewed alongside updated onboarding. Full dev.sh test: 75 tests pass. A temporary injected-state ImageRenderer harness rendered all six languages in Light/Dark at 340 pt width; representative images confirm wrapping and primary button fit. Native Menu cannot be rendered by ImageRenderer (placeholder), so interactive menu/focus/VoiceOver acceptance remains open; harness removed afterward. Release and packaging pass, final artifact/hash owned by REL-002. No reinstall/removal of the user's helper was performed.

User reports local installation and the background approval sequence completed; Connected after DMG update is now user-confirmed with a screenshot; exact running artifact/version is not independently captured. This does not close status IPC/reconnect/restart/removal or clean-Mac gates. BAT-008 supersedes the secondary More-menu/removal-link presentation with a confirmation-protected trash control and popover interaction protection. Next: user verifies the new recovery/approval flow; do not require uninstall just to repeat cosmetic verification.
