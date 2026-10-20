# Self-signed helper artifact verification

Date: 2026-10-19. Baseline: main at fd8ba18 plus uncommitted BAT-001–003 work. Agent-observed software verification on the existing Apple silicon development Mac, macOS 27.0.1 / Xcode 27.1 / SDK 27; no macOS 26 or second-Mac claim. Task: [BAT-003](../tasks/BAT-003-self-signed-helper.md).

## Observed results

- Final `apps/monny/scripts/dev.sh test`: 63 tests in 11 suites passed, including Apple/pin requirement parsing, malformed input, lifecycle and existing anonymous XPC tests. These tests do not register a service. Local log: `/tmp/monny-self-sign-test.log`.
- `apps/monny/scripts/prepare-self-signed.py`: arm64 Release build succeeded; app/helper signed with one persistent local self-signed certificate, no Team ID. `codesign -d --verbose=4` reports `flags=0x10000(runtime)` for both thin arm64 executables. No library-validation exception, debugging entitlement, system trust import or quarantine removal added.
- `verify-helper-signing.sh`: the temporary signed unprivileged executable derives its own runtime identity; app/helper signatures match it. Native Security requirements reject the wrong peer identifier and a different pin. Ad-hoc and debugger-entitled copies are rejected; changing a signed executable byte is rejected. The daemon itself was not executed by this harness. These are native signature tests, not privileged IPC or registration tests.
- An initial tampering fixture changed the x86_64 slice of a universal helper while default validation checked only native arm64. Final static validation checks all architectures with strict bundle validation; packaging builds arm64 only. The final tampering check passes.
- `codesign --verify --strict --deep`, `hdiutil verify`, shell/Python syntax checks and `git diff --check` passed. The DMG contains the signed app plus the Applications shortcut; signing state is outside staging in ignored `.local-signing/`. Source scripts/task records remain visible to Git.
- Repeated preparation reuses the dedicated keychain rather than regenerating it; exported DER certificates before/after the final repeat are byte-identical (`cmp` exit 0). Keychain search-list restoration is in a `finally` block; no trust settings are changed. Private key/password remain local and are not logged or versioned.

Final artifact: `apps/monny/build/SelfSigned/Monny-SelfSigned.dmg`, SHA-256 `4f13345f923ff7b36cca86a91e15c55d38c9d561f14c2c19bf0ae2b45aa7fc2e`. This identifies the local test artifact, not a published release. Repackaging can change the DMG hash while preserving the certificate.

## Open acceptance

No app/helper was installed or service registered/removed. Charging remains with macOS. Local explicit SMAppService registration, administrator approval, positive authenticated status IPC, restart/reconnect and removal remain unverified. Also test actual IPC rejection with a separately signed client, beyond static pin rejection. Finally download this DMG on a clean Mac without developer credentials/signing identity and record Gatekeeper approval and full service lifecycle. Keep system security enabled; do not infer distribution support from local fixture success.

Next action: authorize installation of the prepared status-only helper, then execute the local lifecycle checklist from [BAT-003](../tasks/BAT-003-self-signed-helper.md). Lease/restoration remains required before any future hardware write interface.

## Generated artifact maintenance — 2026-10-19

The dated review package described above was removed as superseded generated output during [BAT-004](../tasks/BAT-004-charge-command-safety.md). Historical checks/hashes are retained. Use the latest signed status-only apps/monny/build/release/Monny-1.0-1.dmg for new checks; current artifact evidence is in BAT-004. This cleanup does not close any visual, helper installation or hardware acceptance.

## User-reported installed connection — 2026-10-19

After reporting local installation/approval, the user updated the app through the DMG and supplied a screenshot of the connected-helper explanation. User explicitly reports Connected. Existing app logic only exposes this state after a validated status reply; this supports local positive IPC after app replacement. Exact installed artifact hash/version is not independently captured. No agent installation/removal performed. Full quit/reopen, Mac restart, wrong-signer runtime IPC, removal/reinstallation and clean-Mac distribution checks remain open; hardware control remains unavailable. Current next steps are owned by BAT-003.

## User-reported local lifecycle — 2026-10-19

User confirms Connected after fully quitting/reopening Monny and restarting macOS. User also confirms explicit removal changes status to Not installed, followed by reinstallation/approval returning Connected. This closes the basic local status-only lifecycle walkthrough. Exact installed hash/OS version were not independently recaptured; no process/crash trace is claimed. Runtime wrong-signer rejection, clean-Mac distribution and all hardware charge-control acceptance remain open. No agent service changes or new tests were performed for this documentation update.

## Observed launch-policy failure on updated helper — 2026-10-19

Read-only agent inspection of the installed BAT-007 helper matches its packaged binary hash and unchanged certificate. Static app/helper validation passes, but launchd reports spawn failure with EX_CONFIG. Crash report records CODESIGNING 4 Launch Constraint Violation; AMFI enforces a service-applied constraint before startup and reports the self-signed chain as unknown. Earlier user-confirmed status-only lifecycle applies to an older, unidentified artifact and does not establish reliable updated-helper launch. No agent service/security changes were made. [BAT-008](../tasks/BAT-008-helper-recovery-ui.md) owns build-2 removal/UI fixes and the user-owned reboot/reinstall check; distribution/clean-Mac gates remain open.


## Recurring launch rejection on build 3 — 2026-10-19

User reports eventual success only after several attempts. Read-only logs establish enabled registration at 23:06:06 followed immediately by taskgated-helper's no-eligible-provisioning-profile message and enforcing AMFI Launch Constraint Violation c[5]p[1]m[1]e[0]. launchd kills xpcproxy before the helper's main and removes the failed service. Later activation attempts cannot find the service. An explicit unregister at 23:06:46 and register at 23:06:49 precede a successful launch. These are local log times, not claims that every user attempt was individually traced.

Installed build 3/helper SHA-256 e312af751c2cf54e8dd3564453427630223f045e005142ca9f808e876e2d1a32 matches BAT-011's package. The same binary that was rejected is now running, with one recorded launch and no exit in the current registration; the user supplies its successful native diagnostic reply. Certificate identity is unchanged. No agent registration, removal, trust change or charging write was performed.

Correction to the earlier interpretation: launchctl print renders the cdhash array entry without a visible value in both the rejected and currently running service. This display alone does not establish an empty allowlist or identify the rejected rule. The confirmed failure is OS launch enforcement; the underlying intermittent trust/background-item state has not been isolated. Static signing, increased timeouts, XPC retries or a new build number do not repair or explain this pre-main rejection.

The local SDK SMAppService.h explicitly requires notarization for apps containing LaunchDaemons. [Apple's Developer ID distribution guidance](https://developer.apple.com/developer-id/) documents the Developer ID/notarization route; the current self-signed package does not meet it. This does not prove the missing notarization alone caused the intermittent failure or guarantee that another certificate resolves every BTM issue. [Apple DTS](https://developer.apple.com/forums/thread/799933) describes service-applied constraints and recommends capturing a failing-state sysdiagnose for a reproducible production case. No global background-item reset, custom launch constraint or security bypass is an app remedy here.

Next engineering action at that time was a Developer ID-signed/notarized comparison when available. The user subsequently selected continued self-signing; BAT-017 now owns the scoped recovery investigation. Self-signed output remains experimental. Preserve failing-state evidence before any user-owned recovery. Do not ask for another reinstall now that this helper is running. Clean-Mac, macOS 26 and runtime negative-peer acceptance remain open. Documentation-only follow-up; earlier test/build counts were not rerun.


## Build 4 pre-main rejection and stale service binding — 2026-10-20

User reports repeated Retry without a connection. Agent read-only inspection identifies installed build **4**, helper SHA-256 **ceaa5f87eae03a7df2d6894423fff3a5bafc06bc553f501bdb53f3901f97c5cc**, matching the packaged helper byte-for-byte. App strict/deep validation succeeds when run outside the tool sandbox; a sandbox-only CSSMERR_TP_NOT_TRUSTED result is not evidence that the installed signature is invalid. The existing permanent certificate pin is unchanged.

On M1 Max/macOS 27.0.1, the 10:40:16 local unified-log sequence resolves the correct absolute helper path, records amfid -423 (unknown signing chain), enforcing Launch Constraint Violation c[5]p[1]m[1]e[0], then removes the service after a 62 ms pre-main failure. Subsequent ten-second repair attempts retain an unresolved relative executable and EX_CONFIG. Current launchd's BTM UUID differs from the daemon item in sfltool dumpbtm; raw UUIDs and other apps' records stay local. This is concrete evidence of inconsistent registration state, consistent with the external update-failure mechanism below; the exact failed constraint rule remains unknown. A blank rendered cdhash value is still not an empty-allowlist diagnosis.

The fixed root recovery directory does not exist and no new helper-startup storage log is present. The build-4 startup/journal code is not established as the cause; the failure precedes it. Current Retry calls refresh/readStatus only. Extending the XPC timeout or repeating that operation cannot update launch constraints.

Local captures: /tmp/monny-helper-current-failure.log, /tmp/monny-helper-current-launch.log, /tmp/monny-lwcr-repair.log and filtered inspection of /tmp/monny-current-btm.txt. No raw capture is versioned. Privileged launchctl inspection was unavailable without a password; ordinary-user launchctl, BTM, codesign and approved read-only unified-log access supplied this evidence. No root command succeeded, no helper/service mutation or hardware setting write occurred.

[BAT-017](../tasks/BAT-017-helper-launch-recovery.md) owns recovery. Compare [iGhostVT's pinned source](https://github.com/owngoal-dev/iGhostVT/blob/dd1b3be882e6dea667bc754d5f52caf30095be4b/iGhostVT/Backend/Mac/MacLaunchAgent.swift), which describes a matching stale-item/AMFI/relative-path sequence and native re-registration after launchd invalidation. It uses an unprivileged agent, not a charging daemon: neither its automatic removal nor its timing is accepted as safe/proven for Monny. No recovery experiment has run. Required next step is a reviewed, separately authorized Monny-only recovery followed by authenticated connection and update/restart checks. Temporary native target verification remains on hold.
