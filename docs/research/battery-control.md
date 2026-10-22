# Battery control: first implementation decision

> Battery helper and Discharge task/verification records referenced here (BAT-*, APP-005/006, helper verification) were retired from main on 2026-10-21; they are preserved on the `experiments/discharge` branch.

> Current main (2026-10-21): direct ordinary-user native limit, no helper/SMC writes. Historical helper/Discharge implementation and all tests are preserved on experiments/discharge at abe3a80. See [APP-007](../tasks/APP-007-native-simplification-design-parity.md).

Reviewed 2026-10-19 for BAT-001. This is source research and a software policy decision, not proof that charging can be controlled on the development Mac.

Current below-80%, Hold and Discharge decision: [SMC capability research](smc-charge-control.md) (2026-10-20). Historical implementation sections below retain their dated scope; current native product sessions are owned by BAT-018.

## Installation and IPC

Use Apple's [SMAppService daemon](https://developer.apple.com/documentation/servicemanagement/smappservice/daemon(plistname:)) with the launchd property list inside `Contents/Library/LaunchDaemons` and a bundled helper executable. Follow Apple's [Service Management sample](https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api). Installation remains an explicit user action; observe service status and direct pending approval to Login Items & Extensions. Require restoration acknowledgement before unregistering any charging-capable helper. The current non-writing contract permits explicit unregister after transport failure/timeout; invalid/mismatched/restoration-failure replies remain blocked (BAT-008). Do not use shell installers or SMJobBless.

Use native `NSXPCConnection` and a small versioned interface. Apple's [setCodeSigningRequirement](https://developer.apple.com/documentation/foundation/nsxpcconnection/setcodesigningrequirement(_:)) enforces requirements on the actual peer and must be called before resume. Require the expected identifier and the same validated signer in both directions: Apple anchor/team for Apple-issued identities, or an exact leaf-certificate pin for the experimental self-signed path; reject absent identities. Do not authorize by PID, executable path or bundle ID alone. Stable signing and a negative test with a differently signed client remain required before enabling privileged commands.

Alternative evaluated: [SecureXPC](https://github.com/trilemma-dev/SecureXPC) (MIT). It supports SMAppService and secure peer checking. The [Swift Package Index](https://swiftpackageindex.com/trilemma-dev/SecureXPC) lists 0.8.0 and a sparse release history; Swift 6 strict-concurrency/macOS 26 integration is not established here. Native Foundation already provides the needed peer enforcement, so another dependency is unnecessary. No package installed.

## Charging support varies with firmware

[batt's compatibility notes](https://github.com/charlie0129/batt#compatibility-matrix) and [issue 152](https://github.com/charlie0129/batt/issues/152) report legacy keys `CH0B`/`CH0C`/`CHTE` and firmware limits `bfF0`/`bfD0`/`bfE0`. New firmware can expose empty placeholders or deny access even to root. This can affect an older OS after firmware updates; model/OS checks alone cannot establish support. These are third-party reports, not a Monny hardware result.

Do not infer write access from key existence/readability, install a helper automatically, request private entitlements or change SIP. Unsupported charging stays with macOS. Cutting adapter power makes the Mac discharge and can affect clamshell use; it does not implement Hold and is not an automatic fallback. Hardware commands require their own capability and restoration evidence.

Licensing: [batt](https://github.com/charlie0129/batt/blob/master/LICENSE) is GPL-2.0; only compatibility documentation was consulted, no implementation copied. [actuallymentor/battery](https://github.com/actuallymentor/battery) has an [MIT root license](https://github.com/actuallymentor/battery/blob/main/LICENSE), but its shell/GUI installation and bundled SMC tool are not a ready native SMAppService integration. No code or binaries adopted; a root license alone would not establish licensing for every bundled component. No suitable ready charging package was established by the Swift Package Index search.

## App-side policy

`ChargePolicy` is an isolated value type with injected readings and no I/O. It is currently exercised only by tests, not connected to the sampler or any command executor.

- Charge stops at the configured 50–100 % limit, then resumes at the lower sailing bound. With sailing off, a one-percentage-point deadband prevents repeated switching around the limit.
- Hold inhibits charging with adapter power connected. Discharge requires a separate capability, stops at the limit and stays held until the mode/settings change.
- Heat protection pauses above the configured temperature and resumes two degrees below it. Missing/invalid temperature releases control when protection is enabled. Heat pauses restore adapter power even during Discharge.
- Disabled settings, unavailable capability, missing/invalid readings, disconnected adapter or observations older than 30 seconds release control to macOS and clear episode state. The age must come from a monotonic clock. Physical adapter connection must be distinguished from the power source during forced discharge.

## Next implementation and hardware gates

1. Local status-only registration/approval, app/Mac restart and removal/reinstallation are user-confirmed in BAT-003. Clean-Mac and runtime negative-peer acceptance remain open.
2. Serialized leases, authenticated session ownership and native lifecycle hooks exist in BAT-005. New observer runtime acceptance and reviewed crash/restart recovery remain prerequisites for writes.
3. Unprivileged read-only inspection is implemented in BAT-006. All six candidates rejected metadata access locally. The authenticated helper diagnostic in BAT-007 also rejects all six keys in user-supplied installed evidence. The [2026-10-20 adapter follow-up](smc-charge-control.md#local-read-only-evidence) reads CHIE but rejects CH0I/CH0J; no SMC writes or control support follow.
4. Only after a supported backend is established, add bounded writes/read-back and test restoration after each partial failure. With explicit authorization, verify limit, hold/discharge, heat and recovery across quit, crash, helper termination, sleep/wake, reboot and uninstall on a named MacBook. Calibration and trips follow reliable basic control.

## Status-only helper implementation (2026-10-19)

The separate executable shares a versioned `Data`/Codable status interface with the app; only status and prepare-for-removal methods are exported. No SMC writer, shell invocation, active charge policy or persistent setting is included in the daemon. The later executor adds an inactive lease mechanism; no production backend can start a lease. The launchd job is on-demand, without KeepAlive; writable control will require a reviewed crash-recovery lifecycle before that changes.

The listener applies [native incoming-peer requirements](https://developer.apple.com/documentation/foundation/nsxpclistener/setconnectioncodesigningrequirement(_:)) before activation and repeats enforcement on accepted connections. The client requires the helper identity. The Apple-issued path requires Apple generic anchor, exact identifier, matching certificate team and `!entitlement["com.apple.security.get-task-allow"] exists`. Apple's [requirement language](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/RequirementLang/RequirementLang.html) defines existence as false for a missing or Boolean-false value, so this excludes debuggable peers. Native parser tests caught and corrected an invalid negation spelling. Team input is constrained before requirement construction; self/embedded signatures are validated off the main actor.

The [local SDK SMAppService header and Apple sample](https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api) require signed apps, admin approval for daemons and notarization for apps containing daemons. Matching team validation is necessary but does not establish registration/notarization acceptance. No credentials, entitlements or helper installation were added on the development Mac. Replacement of an incompatible helper remains an implementation gate; failed authentication/version checks do not cause automatic unregister/re-register.


## Self-signed investigation (2026-10-19)

BAT-003 adds certificate-pinned authentication and prepares a status-only DMG without changing the registration mechanism. [Apple’s requirement language](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/RequirementLang/RequirementLang.html) supports complete certificate hashes, explicitly distinguishes self-signed certificates from ad-hoc signatures, and does not require system trust when a requirement pins a certificate. This establishes the authentication mechanism, not installation eligibility.

The upstream [Microsoft Process Explorer README](https://github.com/microsoft/Procexp-Mac#testing-without-a-developer-id-certificate-local-self-signed) describes self-signed SMAppService daemon testing. Its [identity-generation script](https://github.com/microsoft/Procexp-Mac/blob/main/Scripts/dev_make_signing_id.sh) contains a contradictory statement that root daemon registration requires Developer ID. Treat these as unverified/inconsistent implementation notes, not evidence that Monny works on another Mac. No upstream code was copied or dependency installed. Native Security/Foundation remain sufficient.

The local SDK still documents signing/notarization requirements for apps containing daemons. Neither Open Anyway for the GUI nor a successful static signature check proves that the daemon can register or run. Verify local registration with explicit authorization, then repeat with a downloaded DMG on a clean Mac lacking the signing identity. Keep Gatekeeper enabled and record any failure; do not add trust roots, remove quarantine or silently migrate to a shell installer/legacy service API. The release distribution route remains undecided until this evidence exists.


## macOS charging settings (2026-10-19)

[Apple’s charging documentation](https://support.apple.com/en-us/102338) confirms that Optimized Battery Charging can delay charging above 80% based on learned usage. Apple silicon Macs with macOS 26.4+ also offer a separate 80–100% Charge Limit. Both can occasionally charge to 100% for state-of-charge estimation. These are independent OS behaviors, not Monny modes or errors.

[batt’s own setup guidance](https://github.com/charlie0129/batt#installation-gui-version) recommends disabling optimization and the built-in limit for its controller. This is third-party mechanism evidence, not a Monny hardware test. Monny’s current status-only helper makes no charging requests, so neither feature needs to be disabled for monitoring or helper installation. Before future active Monny control, recommend manually turning off optimization and setting the system limit to 100% where available, to avoid conflicting targets. Confirm coexistence per hardware backend before enabling writes; do not claim this is a universally tested prerequisite or force a setting change.

APP-005 adds a Battery info popover with this manual guidance, a Battery Settings link, and a reminder that macOS features can be re-enabled when Monny control is no longer used. No public supported API to reliably read/change both settings was established in this investigation; there is no on/off detector, private-preference write or automatic configuration. The current build does not need the user to follow these preparation steps.

## Bounded command executor — 2026-10-19

BAT-004 adds one actor with synchronous acknowledged adapter/charging operations, connection-owned renewable leases (maximum 30 seconds), and both-step restoration on release, disconnect, expiry or partial failure. Restoration failure remains unknown and blocks further commands until a successful restore. No dependency or production writer is introduced; the status-only XPC contract is unchanged.

Use native [ContinuousClock](https://developer.apple.com/documentation/swift/clock/continuous), which includes elapsed system sleep, and a cancellable [clock deadline suspension](https://developer.apple.com/documentation/swift/task/sleep(until:tolerance:clock:)). This avoids wall-clock changes and polling. The timer retains its executor until expiry so loss of an external reference does not abandon inhibition. Software expiry after wake does not restore during sleep or after process death. Before wiring a writer, connect explicit sleep/shutdown/removal events, authenticated per-connection ownership, bounded I/O/read-back and reviewed helper restart/crash recovery; then test real hardware. No claim of crash/sleep safety is made by the injected tests.

## Native helper lifecycle — 2026-10-19

BAT-005 wires the executor/session lifecycle while retaining the status-only protocol and absent hardware backend. Each accepted connection gets a server-created session, bounded to 16 concurrent live sessions; invalidation/interruption closes it. Sleep revokes all sessions and restores; wake restores and requires a fresh connection. Removal latches a non-controlling phase and only acknowledges successful restoration; failure remains blocked/retryable. Startup and graceful SIGTERM/SIGINT use the same restore boundary.

[IORegisterForSystemPower](https://developer.apple.com/documentation/iokit/1557114-ioregisterforsystempower) and the installed IOPMLib.h specify that CanSystemSleep/WillSleep must be acknowledged, early/complete power-on must not, and sleep proceeds after a 30-second timeout. The API does not provide shutdown/restart notifications; dispatch signal sources cover graceful launchd termination, not SIGKILL or crashes. Native events are delivered on the main dispatch queue, sequenced through one pending task, with I/O state on the executor actor. A small C bridging header exposes SDK IOMessage macros that Swift cannot import; no numeric message constants are hardcoded.

No production writer is passed to the executor. Its status-only branch does not pretend to perform physical restoration and always refuses charge commands as unsupported. Before enabling any writer, establish supported SMC keys through read-only capability probing, bounded writes/read-back, a crash/restart strategy and real hardware sleep/crash/removal acceptance. The existing on-demand launchd plist has no KeepAlive; notification callbacks and a renewable lease alone cannot guarantee recovery from a killed helper. Native observer/runtime acceptance is still open on the newly built artifact.

## Read-only charge-key inspection — 2026-10-19

ChargeCapabilityProbe reuses the native SMC reader for one explicit off-main pass over CH0B/CH0C/CHTE/bfF0/bfD0/bfE0. It validates four-byte printable identifiers/types, 1–32-byte metadata and exact reply size, preserves kernel/SMC failures separately, and never interprets attributes as write permissions. Existing sensor callers retain nil-on-failure behavior. No dependency or GPL implementation was adopted; compatibility documentation above was refreshed.

On the development MacBook Pro M1 Max / macOS 27.0.1, ordinary-user metadata requests returned SMC 0x84 for all three CH keys and IOKit -536870207 for all three bf keys. No value or metadata was accepted. Five existing temperature/fan keys still decoded successfully. This establishes only unprivileged read unavailability on that machine, not absent keys, root access, firmware-wide incompatibility or writable support. Raw results stay outside Git. The explicit helper diagnostic is implemented in BAT-007; its installed runtime result is recorded below; production control stays unavailable.

## Authenticated helper diagnostics — 2026-10-19

The SMC adapter and probe now live in BatteryHelperShared, compiled into both existing targets. No package or copied third-party implementation is needed. A zero-argument diagnostic selector accepts no keys, values or paths; native peer enforcement is unchanged. The executor admits only a live ready session, coalesces one off-main probe per process lifetime and rechecks lifecycle/session after suspension. Read reports use optional additive status fields to preserve removal/status compatibility with the installed original helper; a status capability flag gates the new selector. This flag advertises diagnostics only, never charging support. Reply size/key/value bounds remain enforced.

[AlDente's official compatibility FAQ](https://apphousekitchen.com/faq/) currently lists macOS 27 and the M1 Pro/Max MacBook Pro as supported. That product's support statement is not evidence of which current mechanism or entitlement Monny can use. No AlDente implementation was adopted. The local unprivileged failures in BAT-006 cannot rule out helper access; BAT-007 subsequently obtained rejected-key results through the installed helper; a writable backend is still unverified.

## Installed launch-policy regression — 2026-10-19

BAT-008 records a matched signed BAT-007 helper that is registered but killed before main by AMFI launch constraints. Both signed artifact validation and certificate pin checks pass; these checks cannot establish SMAppService launch acceptance. The actual failure retains the experimental self-signed route's release gate. [Apple DTS](https://developer.apple.com/forums/thread/799933) documents service-applied constraints/background-item-state failures but does not establish a universally valid self-signed workaround. Build 3 reproduces AMFI rejection, then runs the same binary after user-owned unregister/register. The rendered launchctl cdhash entry is also blank in the running service and is not evidence of an empty allowlist. Underlying trust/background-item state remains unisolated; dated evidence retains the unsupported self-signing limitation. Build 2 gives this non-writing release an explicit removal route. It does not weaken OS or peer validation, set custom constraints, modify trust or reset other background jobs.

## Installed helper read results — 2026-10-19

User-supplied authenticated diagnostic JSON now confirms successful installed-helper IPC. All CH candidates return SMC 132; all bf candidates return IOKit -536870207, with no metadata/values. This matches ordinary-user reads. No write-support claim, process-uid capture or conclusion that every control mechanism is unavailable. Research the current supported mechanism beyond these six keys before adding a backend. BAT-007 bounded read-only acceptance is complete; BAT-008 removal/popover retention is user-confirmed; visual/accessibility and broader hardware/distribution gates stay open.

## Existing-solution review and adapter-key lead — 2026-10-19

BAT-009 records the requested OpenDente review at pinned revision 06c5a8199f5c0657374e667073b3aa6a75f50df8, licensing and maintenance checks for its referenced ready projects, and current batt alternatives. OpenDente's reviewed CHTE/CH0B detection uses the same read mechanism and does not resolve our rejected-key result. No GPL implementation adopted. Battery-Toolkit is archived; SMCKit predates Apple silicon; no suitable maintained drop-in package established.

The specific new lead is CHIE adapter control. A local ordinary-user read through Monny's existing adapter returned valid hex_/one-byte metadata; CH0I returned SMC 132. Writes were neither attempted nor proved. batt documents opt-in adapter cycling and a private PowerUIAgent 80%+ fallback, both requiring separate assessment. Adapter cycling changes power-source behavior and cannot replace Hold silently. BAT-010 verifies native-limit getter support; next implement its bounded read-only diagnostic adapter, preserving physical-write/crash-recovery acceptance gates.

## Native limit client verified read-only — 2026-10-19

BAT-010 compares current batt/battery/Ampere native-limit approaches and records an independent local system-runtime getter probe. PowerUI's SmartChargeClient reports support and **80/85/90/95/100** on M1 Max/macOS 27.0.1; current limit/enabled getters succeed as an ordinary user, with no private entitlement or mutation. This is a reachable private API, not a documented public SDK controller, write verification or proof of sub-80 support. No GPL implementation copied or executed, no private preferences edited.

The system native-limit path remains the candidate before adapter cycling. The isolated getter-only diagnostic adapter with runtime availability/signature guards is implemented in BAT-011; installed-helper native reads are verified and no production writer is activated. Before active control, preserve/restore the user's original native setting, require confirmed read-back and explicit physical-test authorization. Do not translate native range/hysteresis into arbitrary Hold, sailing, calibration or heat-pause support; capability/UI contracts must remain honest. Full evidence/limits and concrete handoff are in BAT-010.

## Native diagnostic integration — 2026-10-19

BAT-011 compiles a small independent Objective-C getter bridge only into the existing helper and adds an optional typed native snapshot to authenticated diagnostics. The exact production reader succeeds as the ordinary user locally. No controller package was appropriate; no GPL implementation, shell, preference edits, private entitlement or setter was introduced. ABI/number/wire checks fail unavailable; cache/coalescing keeps native work explicit and off the main actor. Private getters cannot be forcibly interrupted by the five-second client timeout, so the process bounds them to one worker/task and keeps status/lifecycle independent. Getter support is not write/enforcement capability.


## Native setting ownership policy — 2026-10-20

BAT-012 implements the independent original-setting/read-back policy with injected operations. No maintained native transaction package was identified in BAT-009/010; the private getter bridge remains independent and no dependency/GPL code is adopted. Preserve the first fresh enabled/limit pair across targets, compare current values before every write, restore on failure/release and retain uncertain recovery as a blocking state. Valid external changes stop ownership rather than being overwritten. Separate getter/setter calls are not atomic across other processes; process-restart checkpoint recovery is verified in BAT-013/014; physical enforcement/restart availability remain unverified. User explicitly chooses continued local self-signing without Developer ID; this does not close launch-reliability acceptance.


## Native checkpoint storage — 2026-10-20

BAT-013 adds bounded versioned checkpoints and reconstructed-process recovery, with no live backend. Native Foundation/POSIX is sufficient; no database or recovery package is needed for one small record. Apple's [atomic-write documentation](https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic) describes temporary-write/replace semantics, and [FileHandle.synchronize](https://developer.apple.com/documentation/foundation/filehandle/synchronize()) flushes file contents before returning. The [secure file-operations guidance](https://developer.apple.com/library/archive/documentation/Security/Conceptual/SecureCodingGuide/Articles/RaceConditions.html) motivates directory-relative descriptors and no-follow/exclusive opens for privileged storage rather than unchecked public paths. Installed SDK Darwin APIs supply openat/renameat/fsync. The implemented adapter synchronizes the private file before rename and directory afterwards; it claims process-restart ordering, not guaranteed power-loss durability. Production directory ownership/ancestors, serialized startup recovery, restart availability and physical rollback remain open; the on-demand helper cannot recover while killed/OS-blocked.


## Native executor lifecycle — 2026-10-20

BAT-014 reuses the existing executor actor, session ownership, monotonic lease and native-event entry points for an injected native backend. No extra controller/service, package, polling or production writer. Recovery is attempted before session admission and at sleep/disconnect/shutdown/removal/expiry. External setting ownership permits non-controlling removal without overwriting settings, but prevents automatic reapplication. A blocked synchronous future API or dead/OS-blocked helper cannot satisfy physical timing guarantees; setter/restart acceptance and a charging-aware wire/removal contract still precede activation.


## Guarded native setter preparation — 2026-10-20

BAT-015 records independently enumerated installed setter encodings, a disconnected typed Objective-C adapter, fake-client ABI/error tests and fixed root-owned journal traversal. No new library, implementation copied from GPL sources or private entitlement added. Selector availability and successful getters do not establish write permission or that a setter leaves the other setting unchanged; this must be tested with explicit target/rollback authorization. Future live use must use the journal-backed actor and a charging-aware removal/status protocol, not the current non-writing offline-removal exception. Root path creation and actual setters remain unexecuted.


## Explicit manual verification contract — 2026-10-20

BAT-016 adds one capability-gated authenticated temporary-target request with before/applied/after reporting and immediate original restoration. The root journal/native backend now initializes at helper startup, but only the explicit request can apply a new target. Live removal no longer uses the non-writing transport-failure exception. CLI timeouts never retry. Server-side peer enforcement must precede dispatch: a client rejecting its remote peer/reply is insufficient evidence that a request was not executed; the anonymous negative test enforces the incoming requirement to prove zero fake writes. No extra package or new mechanism adopted; real native setter semantics, entitlement, root path behavior and physical restoration remain untested. Existing synchronous API/restart limitations prevent claiming a hard physical timeout or crash guarantee.


## Self-signed update and installation comparison — 2026-10-20

BAT-017 re-examines installation rather than SMC access. Reviewed source, not executed/downloaded apps:

| Project and pinned revision | Mechanism and applicability | License / decision |
| --- | --- | --- |
| [OpenDente HelperInstaller](https://github.com/killerk3emstar/OpenDente/blob/06c5a8199f5c0657374e667073b3aa6a75f50df8/OpenDente/Services/HelperInstaller.swift), same revision as BAT-009 | Uses SMAppService.daemon register/unregister and directs pending approval to Settings. No stale-binding repair in this installer. project.yml configures an Apple Team ID for app/helper, so this is not evidence of reliable self-signed updates. | GPL-3.0; reference only, no code copied. |
| [iGhostVT MacLaunchAgent](https://github.com/owngoal-dev/iGhostVT/blob/dd1b3be882e6dea667bc754d5f52caf30095be4b/iGhostVT/Backend/Mac/MacLaunchAgent.swift) | Describes no-Team-ID updated helper rejection, launchd invalidation and unresolved relative-path retries despite enabled status. Uses async unregister completion, bounded re-registration after observed repair settling and a helper response to confirm success. It fingerprints the executable. This is a user LaunchAgent; automatic removal is unsafe to transplant into Monny's writer-capable daemon. | MIT; mechanism reference only; no implementation copied or dependency added. |
| [Procexp-Mac](https://github.com/microsoft/Procexp-Mac/tree/8427dfc3ee6cea2d1701a8773b156504ebd29497) | README advertises self-signed local SMAppService tests, but dev_make_signing_id.sh explicitly says the self-signed identity cannot register the root daemon. This inconsistency prevents treating it as verified precedent. Its sudo helper-restart workflow is outside Monny's native-service boundaries. | No root LICENSE file found in the inspected tree; do not adopt source without resolving terms. |

The current Monny logs and differing launchd/BTM item UUIDs strengthen the stale-binding hypothesis. Apple's [SMAppService walkthrough](https://developer.apple.com/forums/thread/802443) and [service-applied constraint explanation](https://developer.apple.com/forums/thread/799933) remain the native authority; neither guarantees this self-signed recovery sequence. No suitable drop-in installer package was established. Keep native SMAppService, preserve the permanent certificate and investigate one scoped recovery before adding lifecycle logic. Do not copy blind timing loops, reset global BTM state, alter trust/constraints, migrate to manual launchd jobs or bypass restoration acknowledgement. A responding helper and repeatable update acceptance, rather than enabled registration or a successful build, must establish recovery.


## Team ID and development versus distribution signing — 2026-10-20

Focused Apple-source review corrects the earlier overly narrow self-signing-versus-paid-Developer-ID framing. [Apple DTS](https://developer.apple.com/forums/thread/799910) recommends the same Apple-issued identity for app and embedded helper. [Launch-constraint documentation](https://developer.apple.com/documentation/security/defining-launch-environment-and-library-constraints?changes=_1_2&language=objc) explicitly distinguishes development signatures (validation category 3), Developer ID (6) and other identities (10), and makes Team ID a verifiable signing fact. Team ID can therefore matter to launch/security checks; adding DEVELOPMENT_TEAM or a claimed entitlement to a self-issued certificate does not create an Apple-issued identity.

[Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account) supports limited personal testing without paid membership. An actual Apple Development identity issued through that account is a reasonable controlled local comparison, subject to Xcode/account availability and existing peer validation; it has not been created, inspected or tested for Monny. No primary source located guarantees free Personal Team SMAppService daemon launch/update reliability. The forum participant reporting free development signing is not an Apple confirmation of success. Do not claim either that Personal Team certainly fixes Monny or that all development signing requires Developer ID.

For direct customer distribution, Apple's [distribution-signing guide](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/) requires Developer ID Application rather than Apple Development, signing nested code inside-out with Hardened Runtime/secure timestamp before notarization. The installed SDK SMAppService.h also states that apps containing LaunchDaemons must be notarized and changed daemon executables/plists must be re-registered (unregister first recommended). Development samples do not remove this distribution contract. Development signing is not a free substitute for the notarized release route.

OpenDente's DEVELOPMENT_TEAM plus Automatic settings establish only requested signing configuration, not the certificate on a shipped binary, paid membership or notarization. Confirming those needs an actual artifact's signature/assessment, not inference from project.yml. Existing Monny identity, release script and installed service remain unchanged; preserve the key. Next compare an available Apple Development identity on an isolated local build before deciding whether it improves launch acceptance; native target writes remain on hold.


## Approved registration without a launchd job — 2026-10-20

BAT-017's development-signed re-registration first returns internal Register error 1/effective disallow, then consent transitions to allowed. Fresh diagnostics passes the SMAppService enabled gate while native launchd job remains absent. This is not a new AMFI launch rejection: no new helper process was established. Apple's [register contract](https://developer.apple.com/documentation/servicemanagement/smappservice/register%28%29) registers subject to user consent and documents already-registered/denied errors. Build 6 adds one explicit register attempt after a fresh enabled-plus-transport-failure check, followed by authenticated status; no automatic removal, polling or dependency. Native bootstrap success is still unverified. Preserve exact error domain/code and fail closed if the API does not recover this state.


## Minimal development-signed daemon execution — 2026-10-20

The explicitly authorized standalone probe launches real code as uid 0 with the available Apple Development identity and a category-3/team/identifier launch constraint. This disproves a blanket claim that this identity cannot launch any SMAppService root daemon locally. Native unregistration, job/process absence and generated/installed probe-app removal are verified. It does not close Monny, update, distribution or charging acceptance.

[Karabiner-Elements development documentation](https://github.com/pqrs-org/Karabiner-Elements/blob/main/DEVELOPMENT.md#macos-service-management) describes a combined agent/daemon approval UI issue where one enabled item masks another requiring approval, and stale daemon cases after unregister/register. Monny has an additional SMAppService.mainApp login-item registration; the minimal probe does not. Whether this particular mainApp/daemon combination explains the current macOS 27 behavior is unverified. Compare with autostart temporarily disabled and restore the original preference before considering architecture changes. No Karabiner source copied or dependency added; do not adopt multiple management apps or global resets merely from this lead.


## Deleted rows and retained identity are different checks — 2026-10-20

Apple's [Service Management installer sample](https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api) documents delayed removal of deleted login-item rows by overnight maintenance. The [deployment guide](https://support.apple.com/guide/deployment/manage-login-items-background-tasks-mac-depdca572563/web) describes dumpbtm and a broad resetbtm, not a selective Monny permission reset. These BTM records are not Accessibility/TCC consent. Do not use tccutil, edit a private database, or infer active execution from a retained row.

The user-owned no-autostart/reinstall/reapprove sequence does not recover Monny. Current on-disk Apple Development Team ID contrasts with missing Team ID in its historical system BTM app/daemon records; fresh probe records contained the actual team and its daemon ran. This is a useful retained-identity hypothesis, not proof that all differences are cached state or a reason to rename production identifiers. No global reset or new service experiment is authorized by these findings.


## Public bundle permission defect — 2026-10-20

Stored original-signer build-1/build-3 DMGs and the current installed comparison have 0700 directories/executables and 0600 metadata/resources. release.sh applies umask 0077 to the whole public build pipeline; successful codesign does not establish other processes' file access. Apple DTS's [packaging-permission investigation](https://developer.apple.com/forums/thread/788895) explicitly distinguishes signature validity from unreadable signature/profile metadata and shows normal 0755 directories/code and 0644 data. Build 8 uses umask 0022, normalizes copied cached output without following symlinks and fails packaging on unreadable content. Final mounted/extracted bundle checks pass. Correcting installed modes preserves executable bytes/signature but leaves helperNotEnabled; a native re-registration check is still required before assigning this defect as the complete runtime cause. No dependency, trust exception, BTM/TCC edit or signing identity rotation.


## Approved development-signed spawn rejection — 2026-10-20

Build 8 now passes consent and creates a launchd job, but kernel AMFI rejects it before main with c[5]p[1]m[1]e[0] and development validation category 3. Apple DTS's [field interpretation](https://developer.apple.com/forums/thread/795022) identifies a process-self LWCR spawn constraint that did not match; e[0] does not mean a successful launch. Both strict signatures and actual team match; no embedded launch constraints are displayed. The job still binds an older BTM UUID and cdhash LWCR while the current BTM daemon record now carries the actual team and a different UUID. Retained launch state is a strong hypothesis, not proof of the exact expected hash.

In a [similar case](https://developer.apple.com/forums/thread/799933), resetbtm plus restart resolves the failure; DTS asks for pre-reset sysdiagnose if it recurs on production-only systems. Apple's [deployment guide](https://support.apple.com/guide/deployment/manage-login-items-background-tasks-mac-depdca572563/web) documents resetting BTM test data and recommends restarting. This broad diagnostic reset is not an in-app repair or selective Monny cleanup and needs separate authorization with its effects on other login/background records explained. Preserve failing evidence before proposing it. No reset, custom constraint override, identity rename, dependency or source adoption performed.


## Post-reset local recovery result — 2026-10-20

Following explicitly approved resetbtm and user-owned restart/reinstallation, build 8 connects on its first native install with one password prompt. Agent independently confirms one running launchd instance and authenticated read-only diagnostics. The new job's LWCR uses development validation category/team/identifier, replacing the earlier cdhash-based constraint; this strongly supports retained launch binding as the immediate blocker. This is a local Apple Development result, not self-signed update/distribution acceptance or proof of physical writes. Do not automate broad resets in the product or release pipeline. Subsequent same-signer update/restart checks remain; no new dependency, constraint override or identifier change is needed.


## Native round-trip versus charging-policy coexistence — 2026-10-20

Apple [distinguishes Optimized Battery Charging from Charge Limit](https://support.apple.com/en-gb/102338): optimization may delay completing charging, while the explicit limit sets what the Mac considers full. These can coexist; their existence alone is not evidence that both must be disabled for every test. Monny's prepared one-shot verification writes the native enabled/limit pair itself and immediately attempts original restoration. Leave the existing system configuration intact before this bounded setting round trip; this does not prove sustained charge inhibition, arbitrary Hold or coexistence with future independent SMC control. The older manual 100%/optimization-off guidance concerns future active control and needs backend-specific acceptance before activation. Normal UI control remains disabled. No new dependency or preference/setter mutation.


## Authorized native setting write confirmed — 2026-10-20

BAT-016 now has a real local one-shot result through the installed authenticated helper: target 80 applies and reads back, original enabled/limit pair restores, and a separate authenticated getter confirms the restoration. One invocation, no retries or setup-time optimization/limit changes. This confirms native setter permission and limit read-back for that local path, not sustained physical enforcement, all enabled transitions/targets, other hardware, crash timing or lifecycle recovery. The existing native backend suffices for this bounded result; no new SMC key, package, private entitlement or copied implementation is needed. Product activation remains a separate scope.


## Native product sessions and restart availability — 2026-10-20

BAT-018 reuses the researched PowerUI adapter, journal transaction and system NSXPCConnection; no suitable extra library is needed and no GPL source is copied. Native-limit control uses the same macOS setting, so the earlier preparatory 100%/optimization-off recommendation is superseded for this backend. Optimization can still delay charging; sustained behavior remains a hardware gate.

Apple's [launchd job guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html) and [launchd.plist manual](https://github.com/apple-oss-distributions/launchd/blob/main/man/launchd.plist.5) define KeepAlive as a request to keep a registered daemon running. Enable it for the explicitly installed helper so a process crash can reach startup journal restoration without waiting for another client. Retain a single 30-second lease/10-second owner renewal; no custom supervisor, silent reinstallation or periodic charge writes. Identical renewals do not rewrite the setting. KeepAlive does not guarantee OS restart latency, execution while disabled or recovery from a stalled synchronous private API. Final installed-helper crash/sleep/quit/removal acceptance remains open.


## Expired native owner admission — 2026-10-20

The app-coordinator/anonymous-XPC regression in BAT-018 exposed that restoring on expiry alone did not revoke the connection token: its next queued renewal could start a new transaction. Build 11 removes the expired owner before attempting restoration and rechecks admission after checking time; failure/recovery cannot revive that token. Native session revision 2 makes the app require the corrected helper while preserving legacy read/removal. The app performs one fresh read after a failed renewal and on NSWorkspace wake notification, without automatically registering or applying a target. Same system APIs and no new dependencies; physical lifecycle timing remains an acceptance gate.


## Native limit survives ordinary sleep — 2026-10-20

The user changes the native sleep contract in BAT-018. Apple [Charge Limit](https://support.apple.com/en-gb/102338) documents a system-managed 80–100% setting, approximate stopping threshold and occasional full charging for estimation. It does not explicitly promise sleep behavior; retaining this setting across sleep is Monny's backend-specific product decision requiring runtime acceptance, not an Apple API guarantee.

OpenDente revision `06c5a8199f5c0657374e667073b3aa6a75f50df8` was inspected directly: [Watchdog.swift](https://github.com/killerk3emstar/OpenDente/blob/06c5a8199f5c0657374e667073b3aa6a75f50df8/OpenDenteHelper/Watchdog.swift) suspends the watchdog and resets heartbeat time on resume; [main.swift](https://github.com/killerk3emstar/OpenDente/blob/06c5a8199f5c0657374e667073b3aa6a75f50df8/OpenDenteHelper/main.swift) wires IOKit sleep/wake and also has SMC-specific sleep inhibition. It uses a different hardware backend. GPL-3.0 reference only: no source copied, dependency installed, SMC operation or safety claim adopted.

Monny keeps its native owner and original checkpoint during sleep, cancels the expiry task, then validates the actual setting and rearms its existing 30-second lease on wake without setters. Identical in-flight renewals during the sleep transition only read status; changed targets are refused. Disconnect, shutdown, restart, explicit stop/removal and awake expiry still restore or preserve external settings. A failed wake read/recovery fails closed. [Apple SuspendingClock](https://developer.apple.com/documentation/swift/suspendingclock) excludes system sleep; use it for executor lease instants and XPC/renewal timers to prevent sleeping time from producing false expiry. No custom clock or power assertion is needed. Session revision 3 prevents app 12 from claiming these semantics with an older helper. Ordinary build-12 sleep preservation is now user-confirmed in BAT-018; forced crash/helper-restart, sustained physical and broader platform acceptance remain open.

## Optimized Battery Charging through PowerUI — 2026-10-22

The same `PowerUISmartChargeClient` that owns the native limit exposes `isSmartChargingCurrentlyEnabled:` (`Q`, `^@`), `enableSmartCharging:` and `disableSmartCharging:` (`B`, `^@`). A read-only probe on M1 Max/macOS 27.0.1 reports `isOBCSupported` true and Optimized Battery Charging on while the native 80% limit is on, so both settings coexist. The bridge checks these signatures separately from the limit methods, so a change to them hides only the Optimized switch. The user confirmed on this Mac that turning it off from Monny reads back and appears in System Settings once its Battery sheet is reopened; an already open sheet keeps the old value ([APP-014](../tasks/APP-014-limit-slider-optimized-charging.md)). The local runtime also reports a disabled limit as target 100, which is why the app treats 100% as no limit. No dependency or copied source.
