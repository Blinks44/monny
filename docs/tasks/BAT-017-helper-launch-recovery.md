# BAT-017: Recover updated self-signed helper launch

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: awaiting_verification
- Owner: app engineering chat
- Ownership checked: main at 1dc16bd; existing uncommitted work preserved; diagnosis/research active
- Owned surfaces: helper registration/retry, popover refresh event, behavioral tests, build metadata and evidence; no visual or Sketch edits
- Requirements: SPEC §§5, 7; phase 4; preserve authenticated removal and user-owned SMAppService installation
- Code baseline: main at 1dc16bd plus existing uncommitted work; build 6 adds explicit approved-service retry and popover refresh

## Outcome and acceptance

Restore reliable helper connection after an updated self-signed app replaces the bundle. Repeated status checks currently leave an enabled but unlaunchable service unchanged. Continue using the permanent self-signed identity; Developer ID is not a prerequisite for continuing this investigation.

- [x] Identify whether failure precedes helper startup, without changing charging or service registration.
- [x] Compare actual installation/update code in OpenDente and relevant alternatives, with revisions/licenses.
- [ ] Verify a scoped native recovery for Monny, then repeat update/reconnect checks on the final artifact.
- [ ] Preserve acknowledgement before removal of a potentially writing helper; no generic offline bypass.
- [x] Save evidence and prioritize launch recovery ahead of native target verification.

## Diagnosis and research

Read-only inspection identifies installed build 4 and the same helper bytes as the release artifact. Strict signature validation outside the tool sandbox succeeds. Unified logs establish enforcing AMFI rejection before main, followed by launchd repair retries with an unresolved relative executable. Current launchd and BTM records refer to different background-item UUIDs. This supports a stale service/background-item binding as the next testable mechanism; it does not prove that missing notarization is the sole cause or that re-registration will succeed.

The root recovery directory is absent, consistent with this helper not reaching initialization. Do not generalize that observation into a race-free permission to remove an unreachable writer-capable helper. Current Retry only refreshes status/XPC; it does not re-register. Details and artifact hash: [dated evidence](../verification/self-signed-helper.md#build-4-pre-main-rejection-and-stale-service-binding--2026-10-20). Source comparison and licensing: [research](../research/battery-control.md#self-signed-update-and-installation-comparison--2026-10-20).

No service mutation, valid-target command, root journal creation, security setting change, new build/DMG or new app test run occurred. Previous build-4 tests remain historical evidence, not recovery acceptance.

## Signing comparison prerequisite

The requested internet review identifies same-identity Apple Development signing as a meaningful local comparison before implementing bespoke self-signed recovery. See [Team ID research](../research/battery-control.md#team-id-and-development-versus-distribution-signing--2026-10-20). Personal Team success is unverified; DEVELOPMENT_TEAM alone is not a signature. No account/certificate/service change occurred. Preserve the permanent self-signed key and compare in isolated build output if an Apple-issued identity is available. Distribution still requires Developer ID/notarization under Apple's documented route.

## Next action and dependency

Local build-8 recovery is verified after the explicitly approved BTM reset and user-owned restart/reinstallation. User reports one password prompt and first-attempt connection. Agent independently confirms running launchd job (one run), fresh category-3/team/identifier LWCR and authenticated read-only diagnostics with native limit support. This strongly supports stale launch binding as the immediate blocker; the permission packaging fix remains independently correct. No generic claim that self-signed updates or distribution are reliable.

Next verify a subsequent same-identity update/reconnect and later restart; do not rotate the signer or reset BTM as routine release behavior. Review other apps' background/login settings manually: the pre-reset /tmp snapshot did not survive this restart. BAT-016's explicitly authorized target/rollback test can be prepared now, but no hardware write is authorized by this connection confirmation. Clean-Mac/macOS 26, negative-peer, update reliability and physical restoration gates remain open.


## Apple Development comparison artifact — 2026-10-20

User supplied Xcode certificate availability; approved ordinary-user keychain inspection confirms a valid Apple Development signing identity. Prepared a separate artifact with existing release.sh overrides: MONNY_SIGN_IDENTITY selects the exact available identity and MONNY_PACKAGE_DIR points to apps/monny/build/apple-development. No private key export, new identity, release default change or source-code change. Both app/helper report the same Apple Team ID and Hardened Runtime. Native signed verifier passes positive app/helper identity checks and negative wrong identifier/pin, ad-hoc, debugger and tamper fixtures. Arm64 Release, strict app/DMG signatures and hdiutil integrity succeed. No behavioral tests rerun because app behavior is unchanged.

Artifact: apps/monny/build/apple-development/Monny-1.0-4.dmg; SHA-256 **f1807a9fa0dcdae05581dadd69d7e80b05ec76365dcb05af44769241f52d362c**. This is a separate development-signed comparison using build 4, not a new release or replacement of the self-signed package. Local packaging log: /tmp/monny-apple-development-package.log. The existing script's final self-signed sentence is hardcoded and inaccurate for this override; actual code signature and native verifier establish Apple Development signing. It remains not notarized.

Current installed app/helper are unchanged. The new signer cannot authenticate the installed old self-signed helper: do not copy over /Applications as if this were an ordinary same-identity update. Next review and explicitly authorize a scoped registration/identity transition for the currently OS-blocked service before runtime comparison. No agent registration/removal/launch of helper, charging write or native verification occurred. Successful signing is not launch or distribution acceptance.


## User-owned transition preparation — 2026-10-20

User is attempting removal in the old installed app; no success report yet and no concurrent agent mutation. Additional native codesign requirement checks accept the comparison helper's Apple-team requirement and reject the installed self-signed helper. Public leaf certificate dates show validity through 2027-10-18; no private key was exported. Initial extra command used a requirement string without codesign's inline `=` prefix and failed as a filename; corrected command passes the intended positive/negative checks. Existing packaging/native verifier results were unaffected. Rechecked DMG SHA-256 matches the recorded artifact.

[Signing guide](../SIGNING.md#local-apple-development-comparison) now records the concrete sequence: confirm old-app removal, quit, replace using the development comparison DMG, explicitly install/approve, then check Connected/read-only diagnostics. Do not replace while removal fails, authenticate the old helper with a new signer, or claim the old registration has been fixed. User subsequently reports removal failure; no new app build/test needed for this documentation/static-check follow-up. No service or charging changes. Next action is read-only confirmation of user-reported removal, or diagnosis of its exact error.


## Removal failure and native consent-revocation check — 2026-10-20

User reports old-app removal repeatedly fails. Fresh ordinary-user launchctl still shows no active helper, spawn failure/EX_CONFIG and repair attempts; fixed root recovery directory remains absent. Installed app retains the old no-Team-ID signature. Local /tmp/monny-removal-current.log captures repeated removal failures (private error details redacted); code inspection explains that enabled registration must obtain a helper acknowledgement before unregister. No claim that the redacted log identifies a specific transport error.

Next user-owned experiment: turn off only Monny under System Settings > General > Login Items & Extensions > Allow in the Background, return to the old app and refresh/reopen. The SDK describes revoked consent as requiresApproval; existing remove() permits native unregister from that state. Verify actual status before inferring success. This is scoped to the currently never-started build-4 case with absent recovery storage, not a generic removal recovery for an active writer or proof that consent revocation restores settings. Do not replace the app until old registration is actually removed. No new bypass/repair CLI, manual launchd command, global BTM reset, service mutation or charging write performed by the agent. If revoked consent does not update status or native unregister still fails, capture the exact resulting state before selecting another action.


## Old registration removal confirmed — 2026-10-20

After the scoped background-consent step, the user supplies old-app Not installed state. Independent ordinary-user launchctl print system/blinks44.monny.battery-helper returns service not found (exit 113), confirming the old job is unloaded. Agent did not unregister or change settings. This closes the immediate stuck-removal step only, not future writer restoration, Apple Development launch or update reliability. Development DMG SHA-256 rechecked unchanged.

Next user action: fully quit old Monny, replace Applications/Monny.app from the isolated Apple Development DMG, launch the installed copy and explicitly install/approve its helper (background permission may need re-enabling). Next engineering check: capture installed signer and authenticated read-only diagnostics after Connected. No native target command, rebuild or new test run.


## Development approval discrepancy and popover refresh — 2026-10-20

User installs/permits the Apple Development comparison, but the app still shows Needs approval. Agent verifies installed Team ID matches the comparison. A fresh installed --battery-diagnostics process returns helperNotEnabled before XPC, while launchctl reports no job. BTM contains enabled/allowed daemon and user app records but a disallowed system parent app record; registration logs reuse the historical item and report incomplete registration. Thus stale UI alone does not explain this failure. No claim of successful development-helper launch. Raw local files: /tmp/monny-development-btm.txt and /tmp/monny-development-approval.log; no UUIDs/other apps' records are versioned.

A separate code defect is real: MenuBarPanel is nonactivating and showPopover previously did not refresh the helper. applicationDidBecomeActive covers ordinary app activation but need not fire when opening this panel. MenuBarController.showPopover now requests the existing serialized refresh on opening, without periodic polling, automatic registration or new lifecycle machinery. No visual/copy change. dev.sh build succeeds (/tmp/monny-popover-helper-refresh-build.log); no behavioral test that merely mirrors this event hook is added. Runtime return-from-Settings acceptance remains open.

App/helper build advances to 5 for the comparison package; wire version unchanged. release.sh succeeds with the same Apple Development identity: arm64 Release, native positive/negative signing verifier, strict app/DMG signatures and hdiutil integrity. New artifact apps/monny/build/apple-development/Monny-1.0-5.dmg; SHA-256 **2d0d91f1a92b231ab905d09bf8d9da0367aa1ba0e61051701e47cdeef819540a**. Local log /tmp/monny-apple-development-build5-package.log. Its hardcoded final self-signed sentence remains inaccurate for the development override; it is not notarized. No new install is requested until the current OS approval state is resolved. Existing installed build 4 is unchanged. Current user-owned next check is one Mac restart, reopening the installed copy and checking fresh service/status; this is a diagnostic step, not a guaranteed BTM repair. No new agent installation, consent change or hardware target command.


## Post-restart registration diagnosis — 2026-10-20

User reports one restart and background-toggle cycle did not clear Needs approval. Agent verifies same installed development-signed build, absent system launchd job and absent root journal directory. Fresh captures remain local: /tmp/monny-post-reboot-btm.txt and /tmp/monny-post-reboot.log. Narrow --info retrieval of the first development registration (/tmp/monny-development-register-info.log, 11:10:50 local) exposes SMAppService Register error 1, service status 2 and smd effective disposition enabled/disallowed with an existing LWCR. BTM explicitly reuses the prior daemon item. The original app Logger redacted error detail; the numeric internal log does not by itself establish its NSError domain or mean kSMErrorLaunchDeniedByUser (the SDK's legacy constants have different values). Do not label this an invalid-signature error or successful new launch.

The permitted child/user entries and disallowed system parent remain inconsistent after restart. This is evidence of effective-registration denial, not proof of which stored record or signing property caused it. Polling the UI cannot bootstrap a missing daemon. Neither free-development success nor a universal inability to launch without Developer ID is established.

One bounded user-owned experiment is pending: remove and register once in the currently installed Apple Development app after consent, capturing its precise result. Earlier successful removal was through the old self-signed app, so it does not cover this new-signer re-registration. No further restarts/toggle cycles are requested. No agent service mutation, new build/code change or native target command in this follow-up. If the experiment fails, retain failing evidence and pursue an isolated native signing/registration comparison or an Apple bug report rather than blind loops, global BTM reset or identity/launchd hacks.


## New-signer re-registration result and explicit retry — 2026-10-20

User performs removal/reinstall in the development-signed build. Detailed logs show the prior item disabled, then reused at 11:45:47, with Register error 1 and effective disallow. At 11:46:10 the effective disposition becomes enabled/allowed. Current BTM parent and daemon both show allowed; fresh installed diagnostics now passes the registration gate but fails connection immediately. launchctl still reports no system job. This distinguishes the current approved-but-unbootstrapped state from the earlier approval denial. Local captures: /tmp/monny-development-reregister.log and /tmp/monny-development-reregister-btm.txt. No global reset or agent mutation.

BatteryHelper.retryConnection is now a user-action-only path: refresh identity/registration and try authenticated status first; only enabled registration plus transport failure/timeout attempts one native register, then reads registration/status again. It never unregisters, runs target verification or retries in a loop. Ordinary refresh/startup remain registration-free. Invalid, incompatible and cancelled replies, unsigned builds, missing registration and pending consent cannot trigger it. The existing Try Again button invokes this path; its appearance/copy are unchanged. Public error domain/code are logged for this explicit registration call, without private descriptions. App/helper build 6 retains wire version and the same development signer.

Final dev.sh test passes **162 tests in 19 suites** (/tmp/monny-approved-retry-test.log), including successful injected missing-job recovery, one failed registration with no loop/removal, invalid/incompatible/cancelled reply rejection and no registration when not installed or awaiting approval. These use injected operations and do not prove native bootstrap. release.sh arm64 Release, native positive/negative signing fixtures, strict app/DMG signatures and hdiutil integrity all pass. Artifact apps/monny/build/apple-development/Monny-1.0-6.dmg; SHA-256 **90d4ecab1f585fc6dc5d639e69f165f4861368e8ce0b18e74790f61dedfab612**. Local packaging log: /tmp/monny-apple-development-build6-package.log. Actual Apple Development signature remains verified despite the script's hardcoded self-signed output sentence. Not notarized. No agent install/register/remove/charging write. Native bootstrap and authenticated connection after explicit Retry remain open; user should replace with build 6 using the same signing identity, then open Battery and click Try Again once if shown. If approval remains pending, it is not bypassed. Do not repeat blind attempts or run target verification on an uncertain result.


## Build-6 runtime failure and isolated comparison prepared — 2026-10-20

User supplies the same requiresApproval screen after build-6 replacement. Agent independently identifies installed build 6 and no launchd job. /tmp/monny-build6-registration.log shows effective approval reverting to disallow and reuse of the same historical BTM item. A domain=monny.HelperConnectionError retry message from 11:48:11 belongs to the injected test process, not a native user registration: do not count it as a production SMAppService result. The latest user process later removes/registers and gets native internal error 1. Approval changes have not established actual launch. Build-6 software checks remain valid but runtime recovery has failed; do not request another toggle/reboot/reinstallation loop.

Prepared an independent minimal same-signer registration probe; [source, checks, scope and cleanup](../verification/helper-registration-probe.md). No production behavior change or build 7. Both probe components compile/sign/strict-validate, and the no-argument smoke check performs no service access. No probe registered or copied to Applications. A concrete user authorization request is pending for this log-only native daemon experiment and cleanup; no charging, Monny registration, trust or global BTM change is included. This comparison is the next diagnostic step, not a proven remedy.


## Same-signer minimal daemon launches; cleanup verified — 2026-10-20

User explicitly authorizes the isolated probe and cleanup. It starts under native SMAppService as uid 0, with a category-3 development/team/identifier LWCR. Thus the available free development identity can launch this local minimal root daemon. It does not establish that all remaining Monny failures are cached signing state, because registration/payload/RunAtLoad differ. [Full evidence](../verification/helper-registration-probe.md#authorized-runtime-result-and-cleanup).

Native unregister returns notRegistered, the launchd job disappears and the observed process no longer exists. Installed probe app and generated probe build folder are deleted. No global BTM reset, Monny mutation or hardware writes. Source fixture/evidence intentionally retained; raw probe log is removed after recording its result.

Code inspection confirms Monny separately registers SMAppService.mainApp for launch at login. Karabiner's primary documentation describes approval UI masking when one app manages agents and daemons. A similar mainApp/daemon interaction is now a candidate distinct from stale signer state. No automatic architecture split or extra production app is justified yet. User authorization is requested separately for a temporary Monny autostart-disable/daemon-permission test followed by restoring the original setting; this action has not been performed.


Cleanup UI follow-up: native job/process/files are absent, but System Settings retains a historical probe row with its permission switch on. Revoking only that probe permission opens native Apple Watch/password authorization; refreshed UI subsequently confirms the probe switch off. Historical row remains as having run today, with no installed executable or registered job. The proposed Monny autostart test is independently awaiting authorization and has not started.


## Autostart comparison fails; retained BTM identity reviewed — 2026-10-20

User reports removing Monny from autostart, unregistering/reinstalling the helper, revoking/reapproving background consent, restarting the app, and attempting full app deletion/reinstallation without resolution. The mainApp/daemon masking hypothesis is therefore not established as a sufficient cause/remedy; do not request repeating that sequence or restore a preference the user changed independently.

Read-only current inspection finds Monny.app again present in Applications with the Apple Development Team ID, no Monny launchd job, and no installed probe app or probe job. Raw local BTM/log captures are /tmp/monny-after-delete-btm.txt and /tmp/monny-after-delete.log. Monny's historical system app/daemon records omit Team ID while the successfully executed fresh probe records include it. This strengthens retained identity/state as a hypothesis without proving causation. Current system parent is disabled/disallowed while child is enabled/allowed; no clean-registration claim. Reinstalling the same app does not establish a fresh BTM database.

Apple's [official Service Management sample](https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api) explicitly says deleted login items may remain visible until overnight maintenance. [Deployment guidance](https://support.apple.com/guide/deployment/manage-login-items-background-tasks-mac-depdca572563/web) documents dumpbtm and a broad resetbtm for test data, with restart recommended. Background-task records are distinct from TCC/Accessibility consent; no tccutil reset is justified. A retained row is not evidence of a live daemon or incomplete executable cleanup. The probe's native unregister/process/job/file removal and permission revocation remain verified; a historical row may remain.

No supported per-app BTM erase was established in the reviewed Apple documentation. Do not present global resetbtm as a selective Monny cleanup or run it under current instructions; it affects other login/background records and is outside the authorized recovery scope. No BTM/TCC database edit, reset, service mutation, new code/build or hardware command performed in this follow-up. Next engineering step is to distinguish retained Monny registration from full helper packaging/payload using a controlled comparison or failing-state report; ordinary reinstalls and signature success do not close native acceptance.


## Release packaging defect isolated and corrected — 2026-10-20

Audited the actual stored build-1/build-3 DMGs, current release output and installed bundle. Both historical DMGs contain the original certificate SHA-1 b42ad07994f6a1fc1eae792f53d26e685c5dd31a; the release-script alignment did not rotate those two artifacts to a shared signer. Both already have owner-only bundle permissions: directories/executables 0700 and data including Info.plist 0600. The committed release.sh starts with umask 0077 and runs the entire build/copy/sign pipeline under it. The same modes recur in the installed development comparison. This is a concrete packaging bug independent of certificate validity; prior occasional launch does not establish correct distribution permissions or causation for every BTM failure.

release.sh now uses 0022 for public build artifacts and normalizes the copied bundle before signing: directories/executable files 0755, other regular files 0644, symlinks untouched. This repairs cached owner-only Xcode output as well as preventing new output from inheriting the wrong mask. A final all-files readability/traversal gate follows signing. No keys are created/exported by this pipeline. The generic final signing message now correctly handles Apple Development overrides rather than falsely calling them self-signed. No key, identifier, peer requirement, library-validation or charging behavior change.

Fixture check verifies owner-only cached directories/executables/data become readable, bytes stay unchanged and an outside symlink target is untouched. Shell/Python syntax and git diff --check pass. Installed bundle permissions were independently normalized in place under approved filesystem execution; app/helper byte hashes before/after match, strict signature passes, but a fresh --battery-diagnostics still returns helperNotEnabled. Old BTM registration has not been repaired by chmod alone; do not claim a runtime fix.

Version **8** packages this fix using the same Apple Development identity. Arm64 release build, native positive/negative signing fixtures, strict app/DMG signatures and hdiutil integrity pass. Artifact apps/monny/build/apple-development/Monny-1.0-8.dmg SHA-256 **35bb7186daf56b9eb94d63ca44701e1a99a097449c3a447f7ebe1329ef4fe7b3**. Local log /tmp/monny-permissions-build8-package.log. Version 7 was an intermediate packaging-only review, not user runtime acceptance. A read-only mounted final DMG and an independent ditto-extracted app both retain readable files/traversable directories, correct build 8 and strict signature validity. Temporary audit copies/mounts are removed. Existing 162 behavioral tests remain the latest app-code test evidence; packaging changes did not rerun or claim new hardware tests.

User authorizes one agent-operated native recovery. The old requiresApproval registration is removed through Monny and its confirmation; the UI confirms Not installed. Monny quits through its menu, build 8 replaces the installed bundle with a temporary rollback copy retained, and strict signature verification passes outside the sandbox. One install action in build 8 returns Needs approval. System Settings shows the Monny switch already on. A subsequent fresh read-only diagnostic returns connectionFailed (past the registration gate), but launchctl still finds no system job. Local log /tmp/monny-build8-registration.log records reuse of the historical daemon item. Correct permissions plus native re-registration have therefore not restored launch; permissions are not established as the sole cause. No charging command, global reset or autostart change.

Automatic approval review rejects clicking the Monny background switch, stating that helper re-registration authorization does not explicitly cover that security-sensitive toggle. No toggle is performed and no alternative bypass is attempted. The user subsequently performs the switch cycle themselves; see the result below. The temporary build-6 rollback copy has been removed; the existing original package remains available. Authenticated connection and restart/update acceptance stay open.


## Approved build-8 spawn rejection — 2026-10-20

User confirms the background switch cycle and reports registered-but-unresponsive; Retry does not help. Agent read-only checks now find an actual system job for build 8, with spawn scheduled/failed, six attempts and EX_CONFIG. At 12:28:56 local, kernel AMFI and launchd record enforcing OS_REASON_CODESIGNING / Launch Constraint Violation c[5]p[1]m[1]e[0], validation category 3, before helper main. Fresh diagnostic times out. Root recovery directory remains absent. These facts supersede the previous missing-job diagnosis; the UI correctly distinguishes consent from connection failure.

Both installed signatures strictly validate outside the tool sandbox, use the same actual Apple Team ID, and carry no displayed embedded Launch Constraints. The launchd job retains an older BTM UUID and cdhash LWCR while the current system BTM daemon item has a different UUID and now includes the actual team. This is consistent with retained launch binding after signature/code changes; the blank launchctl hash rendering is not evidence of an empty hash or proof of the expected hash. No new library, app-code change, build or behavioral test is justified by this pre-main failure.

Local evidence: /tmp/monny-approved-build8.log, /tmp/monny-approved-build8-btm.txt, /tmp/monny-build8-launch-constraint.log. Historical probe remains unregistered and absent on disk. Temporary rollback copy is removed; build 8 remains installed. No service mutation, permission toggle or hardware write by the agent during this follow-up.

Apple DTS [decodes the same spawn failure](https://developer.apple.com/forums/thread/795022) as a constraint applied to the process itself that did not match, without a matching-engine error. Another [Apple forum case](https://developer.apple.com/forums/thread/799933) resolves a similar failure with resetbtm and restart, with DTS requesting pre-reset sysdiagnose if recurring in production. This is precedent, not a guaranteed Monny fix. [Apple deployment guidance](https://support.apple.com/guide/deployment/manage-login-items-background-tasks-mac-depdca572563/web) documents the broad reset; it is not selective cleanup. Proposed next step is separately approved reset/restart followed by one native install/approval and authenticated status, checking other apps' background/login settings afterwards. No reset has been run.


## Authorized BTM reset completed; restart pending — 2026-10-20

User explicitly approves the broad reset. Agent saves a local pre-reset dump, runs /usr/bin/sfltool resetbtm once outside the sandbox as the ordinary user, and receives exit 0 / Database reset. No sudo/root shell, trust change, private database edit or hardware command. A subsequent dump has zero Monny identifier occurrences versus 20 before. Snapshots remain local at /tmp/monny-before-authorized-btm-reset.txt and /tmp/monny-after-authorized-btm-reset.txt; these contain other apps' settings and must not be committed or uploaded.

The existing launchd job still retains its old UUID/constraint and spawn-failed state before restart. This confirms that database reset is not equivalent to clearing the already-loaded job. No further retry or registration is performed. User must save work and restart; do not remotely reboot with potentially unsaved documents. After restart, inspect the installed build-8 service/registration, perform only a necessary native install/approval, verify authenticated diagnostics, and compare other background/login settings. Task remains implementing; recovery, update reliability and charging acceptance remain unverified.


## Post-reset local connection verified — 2026-10-20

After restart, user reports first-attempt native installation with one password prompt and supplies the Connected screen. Agent independently confirms installed build-8 system job running, runs=1, with a newly created BTM binding and LWCR using actual development validation category 3, signing identifier and Team ID rather than the earlier cdhash constraint. Fresh installed --battery-diagnostics exits 0, returns validated protocol 1/helper 1.0, notControlling, native getter limits 80/85/90/95/100, and nativeVerificationAvailable. Legacy SMC probes still reject reads; no new sensor-support claim. No target/setter command is run.

This verifies current local recovery and strongly supports retained launch constraints as the immediate failure mechanism. It does not establish subsequent app update/restart reliability, other-Mac installation, self-signed distribution or physical charge control. Task advances to awaiting_verification for those scoped repeatability checks. No app code/build/test rerun or service mutation during this follow-up.

Post-restart BTM snapshot stays local at /tmp/monny-post-reboot-btm.txt. The pre-reset /tmp snapshot is no longer available, so automatic comparison of other apps' settings cannot be completed; user should review background/login settings manually. No other application's permission was changed by the agent.


## App build-9 update connection verified; daemon replacement open — 2026-10-20

User reports replacing build 8 with 9 and retaining Connected. Independent installed Info.plist confirms app build 9, and authenticated read-only diagnostics exits 0 with notControlling, native limits/getters and manual-verification capability. launchd still reports the same existing running process, one run and parent bundle version 8. Thus new app → existing helper communication is verified; no fresh build-9 daemon execution, automatic replacement or post-update reboot acceptance is established. The helper wire version stays 1 and helperVersion 1.0, so this reply does not distinguish app build numbers. No service restart/removal, charging command, code change or build/test rerun.

Current native getter reports enabled with configured limit 85. A separate proposed one-shot target-80/apply/read-back/immediate-original-restoration experiment remains subject to explicit authorization under BAT-016. No assumption that a Connected badge verifies helper update lifecycle; retain replacement/restart acceptance separately.
