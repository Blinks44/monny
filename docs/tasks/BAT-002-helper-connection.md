# BAT-002: Bundled battery helper and authenticated connection

- Updated: 2026-10-19
- Stage: awaiting_verification (matching signed daemon acceptance)
- Owner: unassigned
- Ownership checked: `main` at fd8ba18; released, BAT-001 work preserved
- Owned surfaces: new helper/shared sources, Xcode helper target and embedding, app helper lifecycle/client, Settings and popover helper actions, translations, tests and related records
- Requirements: SPEC §§3, 5, 7; ENGINEERING helper security; phase 4
- Baseline: fd8ba18 plus uncommitted BAT-001/BAT-002 sources and records

## Outcome and scope

Bundle a separate SMAppService daemon and support explicit registration, approval, authenticated version/status checks and confirmed removal. This slice exposes status/removal preparation only: no hardware commands, charging changes, policy activation or automatic registration. Both peers require the expected identifier and the same validated signer without a debugging entitlement. The original Apple-anchor/team route is preserved; experimental certificate pinning and preparation are tracked in [BAT-003](BAT-003-self-signed-helper.md). Ad-hoc development builds remain unavailable for installation.

## Acceptance

- [x] App bundle contains helper and launchd plist with valid local signatures; existing app settings preserved.
- [x] Listener/client enforce native peer requirements before activation; malformed input and ad-hoc helper startup fail closed. Real signed/debuggable peer checks remain below.
- [x] Version/status decoding, timeout/cancellation and late replies have tests.
- [x] Registration is explicit; pending approval/errors/removal confirmation are represented in all six languages.
- [x] Build/tests, bundle inspection and security/runtime limitations recorded. No helper installed by the agent.
- [x] User-confirmed self-signed installation/approval, Connected after app/Mac restart, removal to Not installed and reinstallation to Connected (BAT-003); removal code requires a validated non-controlling acknowledgement.
- [ ] Same-team positive IPC and negative different-signer/debuggable-app checks on the final signed artifact.
- [ ] Final interactive UI/VoiceOver verification after rebuild; offscreen fixtures do not close this gate.

## Source and next gate

Live Monny.sketch Settings/Error/Uninstall states inspected 2026-10-19; source unchanged. Mechanism research: [battery control](../research/battery-control.md). Local self-signed registration/status/restart/removal/reinstallation are user-confirmed under BAT-003. Runtime wrong-signer rejection, Apple-team path and clean-Mac distribution remain open. Command leases/restoration follow before any SMC write interface is added.

## Implementation and verification

- `BatteryHelper/` is a separate executable, `BatteryHelperShared/` owns protocol/status/signing, and `HelperResources/` contains the launchd plist. The Objective-C protocol has an explicit stable name across both modules. Xcode dependency/copy phases embed both products in the app; the existing scheme builds them without a new dependency package. Both targets use Swift 6, strict concurrency and MainActor default isolation, sandbox off and Hardened Runtime enabled as a build setting.
- The original immutable daemon was status-only; [BAT-005](BAT-005-helper-lifecycle.md) now adds session/lifecycle state without enabling writes. Native listener and per-connection requirements bind the expected identifier and signer and exclude get-task-allow; BAT-003 adds an exact-certificate route alongside Apple anchor/team. The app validates self/embedded identity off the main actor. Unsupported versions fail closed. The on-demand daemon still has no KeepAlive, writer, shell execution or persistent policy. The later BAT-007 adds only an explicit fixed-key diagnostic reader. Its executor only schedules expiry after an accepted command; no production backend/charge IPC exists, so ordinary status monitoring creates no charge timer.
- `HelperConnection` owns each one-shot request on an actor, with a five-second deadline, cancellation/invalidation handling and first-result arbitration. Anonymous endpoints are used only by local IPC tests; production uses the privileged Mach service and the full helper requirement.
- One `BatteryHelper` model owns read-back of SMAppService status and explicit lifecycle operations. Removal rechecks registration, requires an authenticated compatible non-controlling response when enabled, then verifies unregister completion. Unapproved registration cancellation does not start a daemon. Incompatible-helper replacement remains unsupported; no automatic downgrade or registration retry bypasses authentication.
- Status/actions are shared by Settings, Battery and popover. The actual helper version appears in Settings. Approval opens Login Items & Extensions, removal uses a native confirmation alert, and activation refreshes status without polling. Twenty strings added in six languages; existing translations unchanged.
- `dev.sh build`, final `dev.sh test` (61 tests, 11 suites) and `dev.sh release` pass. Bundle/signature checks, unprivileged ad-hoc refusal, source inspection and localized renders are recorded in [verification](../verification/helper-connection.md). No real registration/removal or charging operation was performed.

## Review and limitations

Review covered interface size, peer validation before activation, cancellation/late callbacks, actor reentrancy during lifecycle operations, read-back of system status, disabled charging controls, bundle paths and unchanged app identity/settings. No unverified hardware capability is advertised. Initial native parser assertions caught an invalid `not` negation spelling, fixed to `!` and retested. Temporary visual harness/captures/logs are outside the final Git changes.

Default development signatures are ad-hoc. Xcode disables Hardened Runtime for these artifacts and there is no matching Apple team, so helper installation is unavailable. Both the experimental self-signed artifact and the future signed/notarized release artifact still need native registration and peer tests. This is an unverified capability boundary, not evidence that hardware charging is unsupported on this Mac.

## Next handoff

Engineering: executor/lease foundations are implemented in [BAT-004](BAT-004-charge-command-safety.md); authenticated session/native lifecycle wiring and its remaining runtime gates are owned by [BAT-005](BAT-005-helper-lifecycle.md). Read-only capabilities and real sleep/crash/restoration still precede SMC writes. Keep hardware capability probing separate from policy and do not infer write support from readable keys.

Signed-artifact verification: use the prepared [BAT-003](BAT-003-self-signed-helper.md) status-only artifact, then explicitly install/approve the helper and check registration acceptance, status, wrong-signer rejection and removal. A Developer ID/notarized release remains a separate route. This requires user authorization; no charging test is needed for the current status-only interface.
