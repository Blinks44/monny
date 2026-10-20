# BAT-018: Native charge-limit interface

- Updated: 2026-10-20
- Stage: awaiting_verification
- Owner: current app engineering chat
- Ownership checked: started on main 1dc16bd; refreshed checkout main cb9abff during completion. Existing work preserved; native UI/session changes remain uncommitted.
- Owned surfaces: additive native session IPC, bounded owner client, Battery controls/copy, build metadata, tests and relevant docs; scoped Sketch limit-only references
- Requirements: SPEC §5; fail-safe ownership and authenticated explicit installation; no automatic hardware writes

## Outcome

Expose native macOS limits only (advertised 80–100 values) through the existing Battery UI. A user explicitly enables control; original settings are restored on stop/disconnect/awake lease expiry/removal/shutdown. Ordinary sleep preserves an active native system limit and original checkpoint; wake validates without rewriting it. Existing transaction/journal handles partial failure and external changes. Hold/discharge/sailing/heat/trips/calibration remain disabled. No startup replay.

## Acceptance

- [x] Persistent authenticated owner connection, validated capability handshake, fixed 30-second lease renewed only during explicit control.
- [x] Old helper remains readable/removable; no new selector sent without advertisement.
- [x] UI commits supported values, shows acknowledged state/failure and restores on explicit stop/quit.
- [x] Runtime limits are explicit: process-restart recovery availability requires helper KeepAlive, but stalled synchronous API has no hard timing guarantee.
- [x] Meaningful ownership/lifecycle/IPC tests, build, six-language copy and signed DMG checks pass.
- [ ] Real control/lifecycle on final installed helper is verified separately; do not infer authorization from feature implementation.

## Source

Monny.sketch inspected and saved through live MCP on 2026-10-20. `02 · Window` now contains `16 · Battery · Native limit control · Light/Dark`: explicit switch, supported values, active 85% and original-setting restoration caption. Both final screenshots show unclipped copy and matching Light/Dark geometry using existing components/colors. Main future-mode frames remain unchanged. Native stepped-slider rendering is platform-provided in the app.

Saved source SHA-256: `6b722636fc8219c187a5bb88d4287302c78d9a63fb309fcd4a968251f3a7c9c6`.

## Implementation and software evidence — 2026-10-20

- App/helper build 10, marketing 1.0; additive protocol-1 capability fields retain old-helper status/removal compatibility. New commands require positive session advertisement. A persistent NSXPCConnection owns a server-issued token; fixed 30-second lease, 10-second renewal, 5-second request deadline, no automatic retry or launch replay. Identical renewals do not repeat setter writes.
- Existing journal/transaction preserves the first original setting across target changes, refuses foreign ownership and preserves external changes. Explicit stop/normal quit request acknowledgement. KeepAlive requests registered helper restart so startup recovery can run; synchronous API stalls and OS scheduling have no hard recovery deadline.
- Shared native controls appear in the Battery popover/dashboard. Six-language guidance explains native macOS-limit coexistence and original-setting restoration. Unsupported modes remain unavailable. Existing system settings need no preparatory change.
- `apps/monny/scripts/dev.sh test`: **174 tests in 21 suites pass**. New coverage includes real anonymous XPC ownership/renewal/disconnect/legacy capability/timeout, lifecycle restoration, external changes, failed restoration, invalid replies and fresh active diagnostics. Layout fixtures cover all six locales, the control and populated Battery tab at the fixed popover width/height. These are injected tests, not real charge enforcement or keyboard/VoiceOver acceptance.
- `apps/monny/scripts/release.sh`: final signed `apps/monny/build/release/Monny-1.0-10.dmg`, SHA-256 `6966671762316b55f63d6eaa63cb674e0f5d5bb103b4a5ec2ab2f8cf41c8e63b`. Existing shared Apple Development identity; no new certificate or package dependency. Release/signature fixtures pass expected signer, wrong identifier/pin, ad-hoc/debuggable code and tampering checks; strict image/app verification passes.
- Final DMG mounted read-only: build 10, root helper KeepAlive, Applications link and exact helper payload verified. Temporary mount removed. No app/helper installed, registration changed or hardware setting written during this implementation. Existing Text-concatenation deprecation warnings remain outside this bounded change.

## Open checks

User screenshot confirms enabled native-limit UI and Connected; the subsequent user check confirms system-limit changes/restoration. Exact installed artifact/helper metadata, sustained physical behavior and quit/sleep/crash/removal restoration remain hardware acceptance. The agent did not change hardware settings.

## Next action

User confirms system-limit changes/restoration and the build-11 handoff. The current user-authorized build-12 revision changes native sleep behavior: replace the app/helper, enable a supported limit, sleep/wake and verify the same limit and enabled state remain, then switch control off or quit and verify the original system setting returns. Earlier sleep-restoration instructions are superseded for native limits.

Sustained physical behavior, final helper metadata/restart, forced app/helper exit, uninstall restoration, keyboard/VoiceOver, all-language full-app review and macOS 26 remain open. No global BTM reset or system-security change is part of the handoff.


## User-supplied active-state observation — 2026-10-20

A supplied screenshot shows the native-control switch enabled, selected target 80%, active-limit banner, helper Connected and adapter/non-charging status while the current level is above the target. This confirms the visible active state after the user enabled control; it does not independently identify the installed binary/helper, prove that Monny caused non-charging (the earlier configuration already showed it), establish sustained enforcement or verify restoration. Forced discharge is not implemented by this native-limit backend. The subsequent user report confirms working system-setting changes/restoration; physical enforcement and lifecycle gates remain.


## Follow-up ownership and user verification — 2026-10-20

User confirms working native limit changes in System Settings after the explicit off/restore instructions. This is user acceptance of setting control/restoration, not independent artifact identification or sustained physical/lifecycle evidence. Current engineering owns a bounded follow-up: app-side wake/status recovery and end-to-end app coordinator tests using the existing anonymous XPC fixture. No helper installation, charging changes, sleep or process termination on the user's Mac is authorized by this continuation. Hardware acceptance remains open.


## Build-11 follow-up — 2026-10-20

- Expiry now permanently revokes the native owner token before attempting restoration; command admission rechecks validity after checking the deadline. A queued renewal cannot reactivate control, including after restoration failure/recovery. A new explicit session can still apply a target.
- App wake requests fresh status. Failed renewal closes the old owner and performs one read without cancelling that read, registering a helper or replaying a target. Fresh safe status clears an obsolete error; restorationRequired retains the error and blocks activation. Failed status while owning control closes that connection rather than leaving an active banner.
- Native session revision 2 is an additive capability requirement. A build-10 helper remains readable/removable, but build 11 shows the existing update hint and disables activation until its helper is replaced. Wire/helper version 1/1.0 remains compatible for removal; no automatic installation or global BTM reset.
- `dev.sh test`: **178 tests in 21 suites pass**. App-coordinator tests exercise stop, sleep/wake, expiry, external settings and removal over real anonymous Foundation XPC. A new regression initially exposed expired-owner replay; after the fix, the real ten-second renewal reaches fresh non-controlling state with no extra writes. Additional tests cover restoration-error visibility, expired-token rejection after failed recovery and legacy revision read/removal compatibility. Operations use injected settings only; this does not verify physical sleep, quit or charging.
- Visual design and Sketch source unchanged in this follow-up. No new dependencies, translations or signing identities. Release artifact evidence follows below.


### Final build-11 artifact

`release.sh` completes with the existing shared Apple Development identity. Signed native fixtures (expected signer, wrong identifier/pin, ad-hoc/debuggable code and tampering), strict app/DMG signatures and image integrity pass. Final image mounted read-only: build 11, root/KeepAlive configuration, exact helper payload and Applications link pass; unmounted and temporary directory removed. Artifact: `apps/monny/build/release/Monny-1.0-11.dmg`, SHA-256 `eca6e99a55a8202242d653695efcafebcf5a62c8216a7b9331ededab4cfc2055`. The interrupted final mount check was not executed when automatic approval review was unavailable; it has now completed successfully. No Git commit or additional Sketch save performed; no installed app/helper, charging setting or system-security state changed by the agent.

Next user action: switch control off, remove the responding old helper through Monny, quit, install app 11 from the DMG and explicitly install/approve its helper. Check limit activation/off, then quit/relaunch and sleep/wake restoration. Exact physical/lifecycle acceptance remains open.


### User acceptance after build-11 handoff — 2026-10-20

User reports the updated flow works after the build-11 update and quit/restoration instructions. Record this as positive user acceptance of that handoff; no separate binary metadata or per-step measurements were supplied. Sleep/wake, forced process exit, helper restart, sustained physical enforcement, other hardware and macOS 26 remain unverified. Next: user-owned sleep/wake check with an explicitly enabled limit, verifying original settings restore and Monny does not silently resume control on wake.


## Native sleep preservation revision — 2026-10-20

User explicitly changes the sleep contract: keep the selected native macOS limit and enabled UI across ordinary sleep/wake. Current engineering owns executor/IPC timeout/renewal behavior, tests, build metadata and affected docs. No visual redesign, real sleep, helper installation or charging mutation is authorized. Preserve explicit stop/quit/removal/disconnect/crash restoration and expired-owner rejection while awake. This supersedes earlier sleep-restoration acceptance for native limits; injected SMC modes still restore before sleep. Research Apple and OpenDente before implementation.


### Build-12 implementation and software verification

- Native session revision 3 requires the new sleep contract before app activation; builds 10/11 remain readable/removable. App/helper build 12, marketing 1.0; wire/helper versions unchanged for removal compatibility.
- Before native sleep, check the awake lease, keep the authenticated owner and journal, cancel the expiry task and clear its suspended deadline. The existing setting remains untouched. Repeated power notifications are idempotent. Status observers can read the preserved session before helper wake handling, so app/helper notification order cannot falsely close the owner. Other connections cannot take ownership; a same-target renewal racing sleep only reads, while target changes are refused.
- Wake validates the existing limit, retains the original checkpoint and rearms the same owner's 30-second lease without setters. Changed settings are preserved and control stops. Unknown reads/recovery failure block control. Awake expired tokens remain revoked. Stop/quit/disconnect/removal/shutdown/restart continue restoring original settings or preserving external changes.
- Native RPC/one-shot request deadlines and owner renewal use SuspendingClock; executor instants also exclude system sleep. Direct injected hardware modes keep pre-sleep restoration. No power assertion or background polling added.
- `dev.sh test`: **180 tests in 21 suites pass**. New sleep tests verify no setting/journal writes, same-owner continuity, delayed old expiry, duplicate notifications, observer admission, foreign/changed-target refusal and original restoration after stop. Parameterized cases cover sleep-time disconnect/removal/shutdown, external settings, unavailable wake read/recovery, journal restart and post-wake expiry. App-coordinator/anonymous-XPC test retains the enabled state before and after wake, then restores on explicit stop. Legacy session revisions 0/1/2 remain readable/removable but cannot start revision-3 control.
- These are injected software/IPC checks, not a claim about real sleeping hardware or XPC survival. Sleep/wake preservation and subsequent stop/quit restoration on the final installed candidate remain open. No app/helper installed, real power transition triggered or charging setting changed by the agent. No new dependency, copied GPL source, visual change or Sketch save in this revision.

### Final build-12 artifact

`release.sh` completes: signed `apps/monny/build/release/Monny-1.0-12.dmg`, SHA-256 `cc9348446e71ce91ea10d0fcd60e39ec3c77a3a9411140d2edd8bcd5b5540799`. Existing shared Apple Development signer; runtime/peer-signing negative fixtures, strict app/DMG signatures and image integrity pass. Final read-only mount verifies build 12, exact helper payload, root/KeepAlive configuration and Applications link; temporary mount/directory removed. Existing Text-concatenation deprecation warnings remain. No installed-app/helper update, real sleep or charging write was performed. No Git commit or Sketch save in this follow-up.

Next user action: switch control off and uninstall the responding helper, quit Monny, replace the app from build-12 DMG, launch and install/approve its helper. Enable a supported limit and sleep/wake: the same target and enabled UI should remain if the original connection/settings survive. Then stop or quit and verify the original macOS setting returns. Disconnection, changed external settings or failed recovery may correctly stop control; do not claim guaranteed persistence through those events. Final real sleep/physical acceptance remains open.


### User-confirmed build-12 sleep/wake — 2026-10-20

After the build-12 handoff, the user reports the new build works as intended, including after sleep. This accepts native-limit preservation across ordinary sleep/wake in the user's local setup. The app previously identifies an M1 Max in the supplied UI; exact installed binary/helper metadata, sleep duration and power conditions were not independently collected. Do not infer forced app/helper crash recovery, restart, prolonged physical enforcement, other hardware or macOS 26 acceptance. The task remains awaiting_verification for those remaining gates. The separate [SMC investigation](BAT-019-smc-control-research.md) is complete: no verified below-80%/Hold backend, and CHIE-only isolation cannot complete Discharge-then-Hold. The separate read-only adapter diagnostic is implemented in [BAT-021](BAT-021-adapter-diagnostics.md); installed-helper adapter reads are accepted there, while real crash/helper-restart acceptance remains open. Do not change charging hardware without explicit authorization.

### Build-15 helper reappearance and endpoint evidence — 2026-10-20

[BAT-024](BAT-024-adapter-verification-ipc.md#user-reported-helper-restart--2026-10-20) records user-confirmed temporary-target activation, helper reappearance in approximately 4–5 seconds after force-quit, and restoration of the original native pair with control stopped. This accepts bounded native helper restart/journal rollback; forced-app-exit, sustained physical enforcement, other rollback cases and CHIE gates remain open. No repeat crash is requested.
