# BAT-015: Guarded native writer and fixed recovery storage preparation

- Updated: 2026-10-20
- Stage: done
- Owner: unassigned; bounded preparation/checks complete
- Baseline: main 1dc16bd with preserved uncommitted work
- Owned surfaces: private Objective-C bridge, helper-only native backend adapter, fixed journal factory, isolated fixtures
- Requirements: SPEC §5 fail-safe; BAT-014 executor lifecycle

## Acceptance

- [x] Inspect installed setter signatures without calling any setter; review existing mechanism research/licensing.
- [x] Guard all setter ABI/availability, advertised target and error returns; keep diagnostics getter-only and production backend absent.
- [x] Prepare fixed root-owned recovery location with descriptor-relative traversal; no client path or trust/permission bypass.
- [x] Test guards against fake Objective-C clients and storage under temporary test roots; compile app/helper and run behavioral suite.
- [x] Preserve runtime entitlement, setter side-effect/read-back and physical recovery gates; no charging changes, installation or new DMG.


## Implementation and verification

Independent read-only Objective-C runtime inspection on M1 Max/macOS 27.0.1 found setMCLLimit:error: returning BOOL with unsigned-char/NSError** arguments (B28@0:8C16^@20), enableMCL:/disableMCL: returning BOOL with NSError** (B24@0:8^@16). No setter or client mutation was invoked during inspection. BAT-009/010's maintained-solution/license review still owns the native adapter choice; no ready wrapper/package or GPL implementation adopted. Attempts to re-open the pinned batt tree through the web tool failed; current behavior claims come from installed runtime metadata, not a newly inspected upstream implementation.

NativeChargeLimitBridge now has separately guarded limit/enable/disable entry points. It validates getter plus all three setter signatures on both class and constructed client, fresh native support/advertised target/current-setting shape, acknowledgement and NSError. Wrong ABI, missing selectors, malformed ranges, false acknowledgement and exceptions fail closed. A failure may follow a partial effect: the transaction must still own journal/read-back/recovery. NativeChargeLimitBackend exposes prepared synchronous operations only; helper main still supplies no backend, does not create storage and has no writable IPC. Diagnostics still call getters only. Setter side effects on the other field, actual entitlement/permission, physical enforcement and API stall behavior remain unknown; reachability of selectors is not write capability.

NativeChargeLimitFileJournal.systemJournal refuses non-root before I/O and selects only /Library/Application Support/Monny/native-charge-recovery.json. Descriptor-relative traversal checks every fixed ancestor's uid and nonwritable group/other modes, refuses symlinks, creates only Monny as 0700 and refuses insecure existing directories without chmod/chown. The test-root factory exercises identical traversal under private temporary directories. No production directory was created; no IPC path is accepted. ACL/real production-directory and single-owner/runtime checks remain before activation; the existing atomic journal does not promise power-loss durability.

Final dev.sh test passed **149 tests in 18 suites**, compiling app/helper in Swift 6 strict concurrency. New storage tests cover safe creation/reopening, symlinks at all three components, writable ancestors/public app directory, wrong owner and non-root rejection. Two preexisting inline #require macro warnings in lifecycle tests were removed without behavior changes. Local log: /tmp/monny-writer-preparation-final-test.log; only expected AppIntents metadata warning remains.

An isolated temporary Objective-C fixture compiled the exact production .m with its class lookup redirected to fake clients. It exercised eight invalid preflight cases, all 52 integer targets 50–101, enable/disable acknowledgements, false/error/exception returns, wrong return/argument ABI and missing selectors; all passed with no system setters called. This is a one-off native fixture, not part of the 149 Swift tests. A separate executable compiled the exact production getter/reader/model and succeeded as the ordinary user under an eight-second process timeout, advertising 80/85/90/95/100 without recording personal current settings. The sandboxed getter attempt returned unsupported; repeating the same getter with normal system-service access succeeded. No macOS 26 claim.

Affected links, source/output ignore policy and git diff --check reviewed. No commit/publication, new DMG, helper/service changes or charging writes.

## Next engineering slice

Build-4 bounded manual verification IPC/CLI and strict live removal acknowledgement are now implemented in [BAT-016](BAT-016-manual-native-verification.md), awaiting installed hardware acceptance. The new helper has guarded native operations, so the offline-unregister exception is disabled in live operations. Actual target/rollback execution requires explicit user authorization. Preserve native setter-side-effect/entitlement, restart availability despite self-signing, sleep/crash/quit/uninstall, macOS 26 and clean-Mac gates; do not enable normal product controls from metadata or fake-client success.
