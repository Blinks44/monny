# BAT-030: Active adapter removal recovery

- Updated: 2026-10-21
- Stage: done (one authorized installed build-23 active removal and post-removal checks pass)
- Owner: app engineering; bounded acceptance recorded, ownership released
- Owned surfaces: lifecycle preparation/session, additive helper capability, explicit removal command/tests and associated docs
- Requirements: SPEC battery fail-safe/uninstall; PLAN phase 4
- Baseline: main cb9abff plus preserved uncommitted work; BAT-029 active sleep accepted

## Outcome and scope

Prepare one fixed checkpointed CHIE 0→8 attempt within the unchanged three-second watchdog. Retain its owner connection while the existing removal acknowledgement restores zero and gates further commands. Only a same-instance positive active-restoration receipt and matching native snapshot may permit one ordinary SMAppService unregister. After removal, independently read CHIE and source without XPC or automatic registration. No native setter, sleep, force kill, longer lease, root shortcut or automatic reinstall. The single separately authorized actual trial is accepted below; further execution requires new scope/authorization.

## Acceptance

- [x] Additive positive capability, typed preparation and old-helper refusal before mutation.
- [x] Exactly one preparation/acknowledgement/unregister; invalid or failed restoration prevents unregister.
- [x] After unregister, bounded registration/direct-byte/source checks; never contact/relaunch helper.
- [x] Tests cover actual anonymous XPC and failure, cancellation, timer-first and competing-lifecycle cases.
- [x] Signed candidate reviewed.
- [x] One separately authorized installed build-23 active removal passes on hardware.

## Mechanism and limits

Reuse the existing retained session and checkpoint transaction, generalizing source type names without changing sleep revision-1 wire JSON/selectors. New removal preparation uses a separate positively advertised revision-1 selector. Existing prepareForRemoval remains the only restoration/removal gate. [Apple SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice) and [async unregister](https://developer.apple.com/documentation/servicemanagement/smappservice/unregister(completionhandler:)) define the ordinary app boundary; no custom uninstaller/dependency is needed. Registration status is not proof that a daemon process has already exited. Native preservation is measured through acknowledgement before unregister, not via an unavailable post-removal helper getter. Direct app CHIE read is required before preparation and after removal; unknown readings fail closed.

## Next

The single authorized build-23 removal below completes this bounded scope. Next engineering action: prepare bounded client-exit recovery verification for remaining quit/crash gates. The helper remains unregistered; any reinstall is a separate explicit user action. No further hardware action is authorized.

## Implementation and software verification

Build 23 adds `--verify-adapter-removal` with exactly zero extra arguments and diagnostic routing before eager app-model/sampler creation. Shared AdapterLifecyclePreparation/AdapterLifecycleSession replace the sleep-specific source names while retaining the existing sleep wire shape/selectors and revision 1. A purpose selects the appropriate positive capability. The new prepareAdapterRemoval selector delegates to the same guarded preparation, journal and three-second non-renewable watchdog; no second setter implementation exists. Typed preparation remains known-eight, never idle.

The app requires enabled registration, authenticated compatible removal revision 1, no control/native availability and direct unprivileged known-zero CHIE before preparation. A preparation reaching two awake seconds is cancelled by invalidation. Existing prepareForRemoval must then return a validated same-instance idle response, matching native snapshot, exactly one added removal-preparation receipt with adapterRestored, and unchanged sleep/wake counters. A timer-first rollback, missed active receipt, changed helper/settings or competing sleep cannot permit unregister. Direct zero is checked again before the final cancellation/registration check and single async unregister call.

After that call, the owner connection closes; at most 24 read-only attempts/15 awake seconds require unregistered/not-found status, directly read CHIE=0 and adapter source. No XPC occurs after unregister and no helper is automatically installed, restarted or re-registered. Source settling never extends isolation. Error/cancellation closes the retained owner without retrying preparation, acknowledgement or unregister; the existing watchdog/journal remains the recovery fallback. Synchronous API stalls still have no hard deadline. A post-removal failure can mean removal succeeded but evidence is absent; never automatically retry.

Final **dev.sh test: 287 tests in 34 suites pass**, compiling app/helper with existing Swift 6 complete concurrency settings. Three new test functions include actual authenticated anonymous XPC plus 12 parameterized scenarios: success, timer-first restoration, changed instance/native data, failed receipt, transport, cancellation, unregister error, stale registration, absent source, unknown initial byte and expired preparation. They assert at most one isolation/unregister, no unregister before a valid acknowledgement, byte-zero/checkpoint clearance and no native setter. Old helper refusal and malformed capability/version/exact argument tests pass. Existing failed-removal recovery, sleep/wake and competing-owner suites pass. All OS/SMC/registration effects are injected; no real helper install/removal or charging change.

The first integration run exposed a pre-existing fixture race: onRestored fired after the zero setter, before verified checkpoint clearance. The completion signal now fires after successful journal clearance, matching the assertions that await it. This changes test synchronization only, not production recovery. A full final run after that correction passes; the earlier failure is not hidden by rerunning.

## Proposed single hardware trial

User installs signed build 23 and explicitly replaces/approves its helper, then authorizes **one** fixed preparation and ordinary helper removal. Use dedicated power, disconnect USB-C monitor, keep lid open/battery ≥30%, turn off Monny native control and competing charge controllers. Quit the ordinary app. Do not sleep, unplug, run another charging command or kill/uninstall the helper concurrently.

After separately authorized read-only baseline, run once as the ordinary user:

```sh
/Applications/Monny.app/Contents/MacOS/Monny --verify-adapter-removal
```

Expect exit 0 with adapterRestoredBeforeRemoval, nativeSettingsPreservedBeforeRemoval, helperUnregistered and adapterSourceObserved true, restoredByte=0, support unverified. Removal intentionally leaves monitoring available but helper-dependent control unavailable. No automatic reinstall; any later install is an explicit separate user action through Monny. Native preservation after process removal is not independently measured by this command; its report explicitly describes the pre-unregister snapshot.

If refusal/timeout or uncertain recovery occurs, retain the report and stop. Keep lid open and dedicated power connected; if power remains absent, reconnect dedicated power and report before any further controller action. Do not delete journals, reset BTM/SIP, use root shells or automatically repeat the experiment. Actual unregistration, shutdown delivery, direct unprivileged readings on the named setup and broader platform/physical behavior remain runtime gates. No authorization is inferred from software checks.

## Signed candidate and review

`apps/monny/build/release/Monny-1.0-23.dmg`, SHA-256 `c3fe45a9b37dd12038c120d765e7eb8aa5fb119629f47983295e32d2371b321d`. Existing Apple Development identity retained; signed, not notarized. Release build/signing fixtures pass, including wrong ID/pin, ad-hoc, debugger and tampering rejection. Checksum and separate read-only mount review pass: build 23, Applications link, exact app/helper binaries matching signed staging and strict deep signature. Mounted app rejects extra removal/sleep arguments with invalidArguments/exit 1 before helper/OS access. Source and task remain visible to Git; generated DMG is ignored, with no cached ignored files. Local links, shell syntax and git diff --check pass. No Git commit or Sketch edit. The new helper capability requires explicit build-23 helper replacement; installed build 21/22 is refused before preparation/unregister.

## Authorized installed build-23 removal accepted — 2026-10-21

After the user confirmed readiness for the proposed single removal test, engineering independently verified installed build 23, advertised removal revision 1, no control, CHIE=0 and adapter source, and captured bounded baseline locally. The ordinary app was quit and the valid command invoked exactly once as the console user. It exited **0**, reporting adapterRestoredBeforeRemoval, nativeSettingsPreservedBeforeRemoval, helperUnregistered and adapterSourceObserved true, restoredByte=0 and controlSupport=unverified. This requires the actual same-instance active-restoration receipt/native snapshot before one SMAppService unregister and direct ordinary-app byte/source checks afterward; timer-first rollback cannot pass.

Additional independent read-only public power diagnostics confirm adapter source. A read-only launchd service lookup reports absence and a process-name lookup finds no helper process. Neither lookup registers/starts a service; no post-removal XPC occurred. No reinstall, second preparation, retry, helper force-kill, sleep or native setter. The helper remains removed, so helper-dependent charging controls are unavailable until an explicit user installation. Monitoring remains independent.

This accepts the observed checkpointed active-adapter removal/termination path on the existing Apple silicon/macOS 27.0.1 dedicated-adapter setup. Native endpoints match before unregister; no independent native getter after removal is claimed. Other failure boundaries, client quit/crash, sustained physical behavior, other hardware/adapters and macOS 26 remain open; Discharge/full physical verification stay disabled. Raw reports, settings, identifiers and process/service lookup output remain local; only bounded conclusions are recorded.

No code changed or build/test/package rerun for this evidence-only update. The prior 287-test/34-suite and signed candidate review remain artifact evidence. Affected documentation links and git diff --check pass; no Git commit. The one trial authorization is consumed.
