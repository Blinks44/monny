# BAT-013: Recover native settings across helper process restart

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: done
- Owner: unassigned; bounded software implementation and checks complete
- Baseline: main 1dc16bd; existing uncommitted work preserved
- Owned surfaces: transaction checkpointing, isolated file journal and restart/failure tests
- Requirements: SPEC §5 fail-safe; BAT-012 original-setting transaction

## Scope and acceptance

- [x] Persist original/expected/attempted settings before each injected setter; no setter after checkpoint failure.
- [x] Reconstructed transaction blocks targets until explicit recovery; never replay an active command.
- [x] Corrupt/unknown-version journals fail closed. Delete only after verified recovery or observed external ownership change.
- [x] Atomic bounded file journal in a caller-owned private directory; test using temporary files and injected I/O failures.
- [x] App/helper build, behavioral tests and affected records checked.

No production setters, service changes, global paths or active lifecycle wiring. Process-restart recovery requires the helper to launch again; launchd restart/recovery availability and sudden power-loss guarantees remain separate gates. No journal can restore hardware while its process is dead. Production use requires a fixed root-owned storage directory and one serialized executor, never a client-supplied path.


## Implementation and verification

NativeChargeLimitJournal is three injected operations (load/save/clear), with no default path. The transaction initializer loads a bounded schema-1 record and starts restorationRequired; malformed, unknown-version or invalid single-step records throw before writes. Every setter checkpoints original/expected/attempted pairs first. The record remains sufficient whether a setter throws/dies before or after its effect. Clearing follows verified original read-back or an observed external change; failed journal I/O keeps recovery blocked and retryable. Initialization never resumes an active target. Existing transaction tests now explicitly supply memory journals rather than silently opting out of persistence.

NativeChargeLimitFileJournal uses an opened private-directory descriptor (O_DIRECTORY/O_NOFOLLOW, effective uid ownership and no group/other permissions), relative openat/renameat/unlinkat, 0600 exclusive temporary files, file synchronization before atomic rename, and directory fsync. Reads reject symlinks, nonregular/multiply linked/wrong-owner/public/empty/oversized files before bounded decoding. There is no IPC path input or production location. One serialized owner is required; this is not cross-process locking. Caller must provide trusted directory ancestors. Aborted writes before rename can leave an unused temporary file; startup does not treat it as a checkpoint. No sudden-power-loss or storage-device guarantee.

On M1 Max/macOS 27.0.1/Xcode 27.1, final dev.sh test passed **132 tests in 17 suites** and compiled app/helper with Swift 6 strict concurrency. Local log: /tmp/monny-recovery-journal-final-test.log. Tests cover restart recovery, checkpoint before/after effect, disk failure before the first setter and during target update, failed clear/retry, external changes, malformed/future schema, file-size bounds, symlink preservation and private-directory enforcement. Existing signature/IPC negative-test messages are expected fixture output; no helper installed by these tests.

A separate temporary command-line fixture compiled the exact production transaction/journal/model sources and used fake on-disk settings. In five independent subprocesses, _exit(77) forced termination after checkpoint, after limit write, after enable, during restoration disable and after original-limit restoration. A new subprocess restored the original pair and cleared the journal in every case. No real setting/helper/power API was called. This validates process-restart files/ordering, not launchd restart, actual privileged paths or physical charging.

Affected source/diff, relative documentation links and git diff --check reviewed. No dependency, commit, publication, new DMG, installed-service change or hardware write.

## Next engineering slice / open hardware gates

Injected startup/sleep/disconnect/removal and bounded-lease integration is now verified in [BAT-014](BAT-014-native-executor-lifecycle.md). Before any production writer, establish the fixed root-owned storage location, restart availability despite self-signed launch instability, native setter ABI/entitlement behavior and explicit physical target/rollback testing. The current on-demand helper cannot restore while dead or OS-blocked; the journal alone does not satisfy SPEC's hardware crash fail-safe. Existing self-signing remains the user's selected development route.
