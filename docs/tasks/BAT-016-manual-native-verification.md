# BAT-016: Explicit native-limit verification through authenticated IPC

- Updated: 2026-10-20
- Stage: done (bounded one-shot setting verification)
- Owner: released; one authorized local setting round trip verified
- Baseline: main 1dc16bd; existing uncommitted work preserved
- Owned surfaces: verification report/executor/session/connection/CLI, helper configuration, removal policy, tests
- Requirements: SPEC §5 fail-safe; BAT-015 guarded native backend

## Scope and acceptance

- [x] Explicit verification request only; no normal control UI, installation or automatic test.
- [x] Validate target/session/capability before mutation, use fresh original state, apply/read-back/restore without a dwell timer or replay.
- [x] Structured outcomes distinguish restored, failed-restored, external change and unconfirmed recovery; never acknowledge unsafe removal.
- [x] Same peer requirements, bounded replies, timeout/cancellation and legacy capability handshake.
- [x] New writer-capable helper requires removal acknowledgement; no offline removal bypass.
- [x] Software/IPC/build checks pass; one authorized local native target/read-back/original-restoration check passes (result below).

The helper may create its fixed root journal when the user installs/starts this build. A process killed/blocked or a stalled private API cannot restore on schedule; no hardware timing or crash fail-safe claim. Actual verification needs explicit user target/rollback authorization. Do not run it while implementing.


## Implementation and verification

An additive nativeVerificationAvailable flag gates one typed verifyNativeChargeLimit target selector. HelperSession assigns the server session; no client owner token/path/duration is accepted. The existing authenticated connection and five-second timeout/cancellation/first-result behavior remain. Responses are bounded 4 KiB HelperStatus reports with target/before/applied/after/outcome; validation rejects invented restoration, wrong target, unadvertised reports and inconsistent restorationRequired control state. Legacy status/removal stays protocol-1/helper-1.0 compatible; old helpers never receive the new selector.

The factory-backed executor opens the fixed root journal/recover-before-admission on startup. Verification requires ready/non-controlling state and an advertised 80–100 target. It captures fresh original settings, refuses a change between preflight and first mutation, uses a five-second lease and immediately reads/applies/restores in one actor turn with no dwell. Error paths report failedRestored, externalChange, unavailable or restorationRequired without assuming rollback. User-owned external changes remain preserved. Pending recovery blocks status/removal acknowledgement. Live HelperOperations now always requires that acknowledgement; the historical offline-unregister exception remains only in explicitly non-writing test fixtures.

The app CLI is --verify-native-limit <integer>; exact argument/range validation precedes identity/service lookup. Normal UI/startup never invokes verification. No automatic retries or installs. Helper main now supplies guarded native operations and fixed storage; normal product charge modes remain disabled. App/helper build is **4**, marketing 1.0 and wire/helper versions unchanged. Root storage creation occurs only when the user starts this new helper; no agent helper start/install occurred.

Final dev.sh test: **158 tests in 19 suites pass**, app/helper compiled with Swift 6 strict concurrency on M1 Max/macOS 27.0.1/Xcode 27.1. New fixtures cover enabled/disabled originals, before/after-effect write failures, restore failure plus blocked removal/retry, external changes including the preflight gap, invalid/unavailable/stale/read-only requests, wire validation, CLI parsing/legacy handshake/no retry and real anonymous XPC through the production session. An initial test wrongly used client-side remote-peer rejection as proof of server-side nonexecution: rejection of a reply can follow dispatch. It was corrected to enforce the client requirement at listener/accepted-connection before dispatch, matching production's existing inbound checks; the denied client now performs zero fake writes. Initial Sendable capture was corrected by capturing the endpoint, not NSXPCListener. Local test log: /tmp/monny-manual-verification-final-test.log.

release.sh passes arm64 Release, strict signatures, signed positive/negative fixtures and hdiutil integrity. The signing verifier's explicit source list now includes NativeLimitVerification. Artifact: apps/monny/build/release/Monny-1.0-4.dmg, SHA-256 **18cd8bdd9d361cfaca886b429498ffc842ff2bd404276f506208822025705a33**. Same permanent certificate, no trust change. First packaging attempt caught that missing model in the isolated verifier; final packaging succeeds. A packaged CLI smoke check with invalid target 50 returns exit 1/invalidArguments before signing/service lookup; no valid-target command was run. Helper main's added private factory-error log compiled in final Release. A final comment-only cleanup does not change behavior.

No agent install/register/remove, real root journal creation, valid-target execution, setting write or publication. Affected records/relative links, shell syntax and git diff --check reviewed. No commit.

## Current outcome and next action

One explicitly authorized target-80 round trip has completed successfully on the identified local setup, using app build 9 and the already-running build-8 helper. Native setter read-back and immediate original enabled/limit restoration pass, followed by an independent authenticated getter check. No retry was needed. This closes the bounded manual-verification task, not product charging support.

Next app-engineering slice: plan a native-limit-only product control with the supported 80/85/90/95/100 options and accurate capability/copy, after reviewing required lifecycle/ownership and live Sketch contracts. Sustained physical charge behavior and actual quit/sleep/crash/restart/removal restoration stay open under BAT-005 and the phase-4 gates; helper replacement/post-update restart remains BAT-017. Existing arbitrary Hold/discharge/calibration controls must stay disabled. Do not infer permission for sustained changes or more targets from this one-shot authorization.

No physical timing/crash guarantee: a stalled synchronous private API cannot be forcibly interrupted, and a killed/OS-blocked helper cannot recover until running again. Native observer, restart availability, physical charge behavior, macOS 26, clean-Mac and wrong-signer production acceptance remain open. The experimental path is not normal user charge control or a public release; continue self-signing as chosen.


## System settings prerequisite clarified — 2026-10-20

User asks whether to disable the system limit before proceeding; no target authorization is granted by this question. Decision for the prepared one-shot native-setting round trip: leave the existing native limit and Optimized Battery Charging unchanged beforehand. The verification changes the same native enabled/limit pair, captures it fresh and attempts immediate original restoration; there is no separate SMC charge-inhibition writer in this test. It verifies setting read-back/restoration, not sustained physical charging, so optimization is not required to be disabled for this scope. If physical charge behavior is tested later, independently evaluate optimization and other inhibitors rather than attributing every pause to Monny.

Current Connected UI accurately describes authenticated IPC; normal charge controls remain disabled and chargingSupport is notImplemented. nativeVerificationAvailable only advertises the explicit diagnostic request. A Connected badge is not product control activation. No UI/copy/Sketch change, setter command or system preference change in this clarification.


## Authorized native setting round trip passes — 2026-10-20

User explicitly authorizes the prepared single target-80 test with immediate restoration of the captured original pair. Read-only preflight succeeds with enabled native limit 85 and verification capability. Ordinary Monny is not running according to native app inventory; no UI session is quit or service re-registered. Installed app is 1.0/build 9; launchd still runs the existing build-8 helper, runs=1, no prior exit. Test environment remains M1 Max/macOS 27.0.1 from the established local evidence.

Installed --verify-native-limit 80 is invoked exactly once, exits 0 and returns target=80, before enabled/85, applied enabled/80, after enabled/85, outcome=restored, controlState=notControlling. A separate subsequent --battery-diagnostics exits 0 and confirms native enabled/85 plus notControlling. No new write is issued for that check. Optimized Battery Charging and prior system configuration are not changed as setup steps. No authorization prompt, permission/trust modification, helper update, extra target, replay or timeout occurs. No source/build/test rerun for this runtime-only verification.

This establishes native setting write permission, target read-back and original-pair restoration for this local happy path. It does not prove sustained physical charging enforcement, disabling the native limit, independent enabled-state transitions, other values/models/OS releases, error-path hardware rollback, sleep/crash/restart/removal behavior or a hard deadline. Normal product controls and chargingSupport remain notImplemented. Dated injected negative/error-path coverage above remains software evidence. No temporary raw diagnostic files or private machine dumps were created for this check.
