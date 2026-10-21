# BAT-021: Authenticated read-only adapter diagnostics

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: done (bounded read-only installed-helper acceptance)
- Owner: unassigned; implementation/package ownership released
- Baseline: main cb9abff plus preserved uncommitted native-limit/UI/research work
- Owned surfaces: adapter probe, additive helper status/selector, serialized executor/session, one-shot client/CLI, focused tests and scoped records
- Requirements: SPEC §5 fail-safe/capability limits; BAT-019 next engineering slice

## Outcome and acceptance

Expose an explicit fixed CHIE/CH0I/CH0J read through the authenticated helper. Cache/coalesce one off-main probe per process; status and existing six-key diagnostics never run it. Require a positive additive capability handshake before the new selector; old status/removal and six-key replies stay compatible. Validate bounded report keys/types/sizes, and recheck session/lifecycle after suspended reads. Control remains unverified. No writer, registration, helper update, charging change or physical crash test.

The user separately removes below-80% limits from product scope and authorizes saved Sketch cleanup in BAT-020; adapter research now concerns future Discharge, not a sub-80 fallback.

## Verification

Implemented `AdapterCapabilityProbe`, additive `adapterDiagnosticsAvailable`/`adapterDiagnostics`, zero-argument `readAdapterDiagnostics`, cached executor work with pre/post-suspension gates, exported HelperSession method, one-shot client validation and `--adapter-diagnostics` CLI mode. Existing `--battery-diagnostics` still has its fixed six-key payload and does not start adapter reads. Status/removal compatibility, protocol 1/helper 1.0 and native-session revision 3 are preserved; positive feature advertisement gates the new selector.

Full `dev.sh test`: **187 tests in 22 suites pass** on the current development toolchain/macOS. New tests cover exact allowlist, partial failures/unverified support, malformed/missing/unadvertised reports, old-helper refusal, no implicit status/legacy-probe work or injected writes, shared parallel/cache reads, invalidation through disconnect/sleep/removal/shutdown, and real anonymous XPC via the production session/client. All hardware reads in these tests are injected. Final build-13 Settings/range follow-up: rebuild and **19 tests in two affected suites pass**. No macOS 26 execution claimed by these software tests; installed evidence is recorded separately below.

`release.sh` initially stopped before packaging because the standalone signing fixture omitted the new shared report source. Added that source to its explicit compiler list; final rerun passes signed runtime/peer positive and negative fixtures, strict app/helper/DMG signatures and image integrity. Existing signer retained, no credentials or toolchain changes. Artifact: `apps/monny/build/release/Monny-1.0-13.dmg`, SHA-256 **a5da06bed88b4b6c2c215b917089b66f321f27a0fea5f04bc372dfe87b056332**. Signed but not notarized; clean-Mac acceptance remains open.

Read-only final mount verifies build 13, exact release-signed helper payload, root/KeepAlive daemon configuration and Applications link; temporary mount removed. An initial byte comparison used the pre-release-signing DerivedData helper and failed; the correct signed staging payload matches. No installed-app/helper replacement, service registration, adapter write or hardware crash test. Shell syntax, scoped documentation links/catalog JSON and git diff --check pass. No Git commit.

## Installed diagnostic accepted — 2026-10-20

The user supplies successful JSON from the installed app's `--adapter-diagnostics` command following the build-13 handoff. The new feature flag and payload are present: CHIE is readable with one-byte hex_ metadata; CH0I returns SMC 132; CH0J returns IOKit -536870207. Control support remains unverified and helper state is notControlling. The native snapshot shows an enabled system limit in the supported 80/85/90/95/100 set; that is an OS setting observation, not a Monny-owned active session or physical enforcement proof.

This closes the installed read-only diagnostic acceptance. Do not commit the raw JSON, terminal identity or live preference values. Exact installed app/helper build/hash, process uid, adapter connection and physical power flow were not independently recaptured. No adapter write, crash/restart, current native-session enforcement or other-platform acceptance follows from this report.

## Next action

Engineering: the bounded transaction and injected restoration tests are prepared in [BAT-022](BAT-022-adapter-verification-preparation.md); injected single-owner watchdog/startup/lifecycle integration is tested there. Unbound helper-only writer/readings are prepared there; [BAT-023](BAT-023-adapter-power-observation.md) now owns the read-only physical cable evidence check before guarded writable IPC. In the revised 80–100% scope, native-limit holding combined with CHIE isolation under one owner is a candidate requiring its own coexistence and restoration evidence; CHIE alone supplies no at-limit ceiling. No adapter writer is authorized by this diagnostic handoff.

BAT-018/BAT-005 still own real crash/helper-restart, sustained physical/native enforcement and broader platform gates. Close applicable recovery gates and obtain explicit adapter-write/rollback authorization before changing hardware. Read-only diagnostics need no repeat installation or rerun solely to close this task.
