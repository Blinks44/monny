# BAT-025: One-shot adapter-byte research pulse

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: awaiting_verification (real byte round trip accepted; no visible effect noticed, physical/recovery gates open)
- Owner: app engineering; software ownership released for user verification
- Baseline: main cb9abff plus preserved uncommitted app/helper/design work; no Git commit
- Owned surfaces: pulse report/reader/transaction, helper transport/executor/startup construction, CLI routing, focused tests, build settings and records
- Requirements: BAT-022/024 bounded recovery; BAT-023 unverified isolation semantics

## Outcome and acceptance

Build 16 prepares one explicit, no-dwell CHIE 0→8→0 byte-research cycle. Candidate raw/external flags are observations, never proof of physical cable presence under isolation. Full physical-isolation verification remains unavailable; Discharge stays disabled.

- [x] Known initial zero, exact hex_/one-byte/0xD4 signature, fresh supported source/native snapshot, battery ≥30%, affirmative raw flag, known open lid and no Monny native owner before checkpoint/setter.
- [x] Fixed checkpoint precedes one isolation attempt; missing readings, cancellation, partial failure and budget expiry restore or retain recovery intent.
- [x] Candidate unknown/false raw flags and unknown source during the pulse remain data; no inferred physical capability.
- [x] Revisioned authenticated zero-argument IPC/CLI; no automatic registration, dwell, polling, retry, native setting write or UI invocation.
- [x] Single executor ownership and adapter recovery before native startup/listener activation; no native getter during isolation or unresolved adapter restoration.
- [x] App/helper build, behavioral/XPC tests and signed candidate checks recorded below.
- [x] User explicitly authorizes the single fixed pulse and rollback.
- [x] Installed build-16 feature handshake and exactly one real CHIE pulse/read-back/restoration pass.
- [x] User reports no noticeable monitor/link change, tentatively; no physical conclusion follows.
- [ ] Physical isolation and adapter-lifecycle recovery remain unverified.

## Implementation

`AdapterVerificationTransaction.pulse(observe:)` reuses the secure adapter checkpoint, reviewed signature/state validator, semantic helper-only setter and restore/read-back/clear path. Explicit before/during/after phases prevent the live reader from invoking PowerUI during isolation. Only fresh before/after native snapshots establish unchanged measured settings; the during-native field stays absent. External changes are preserved and prevent success. This cannot exclude unsampled changes or enforce exclusivity over other software.

`AdapterBytePulseReader` uses IOPowerSources, fixed AppleSmartBattery Boolean properties and IOPMrootDomain's kAppleClamshellStateKey. It accepts actual CFBoolean values only; missing/ambiguous lid/raw evidence refuses initial admission. Acquisition duration is monotonic, not firmware publication age. The initial raw flag is a research precondition correlated in BAT-023, not a physical-presence verdict. No raw registry dictionaries or identities cross IPC.

The actor admits the pulse only in ready/macOS state without another owner/reserved request. One synchronous actor turn performs the entire cycle; native commands cannot interleave. A fixed three-second software budget/watchdog is armed, but cannot interrupt stalled synchronous system calls. Partial restoration failure retains the fixed private journal and blocks further control/status reads that might call PowerUI; disconnect/expiry/lifecycle/restart can retry restoration. The backend factory opens and recovers the adapter record before native recovery or listener activation, including when native construction fails.

`--verify-adapter-byte-pulse` requires exactly zero extra arguments, an enabled registered helper, authenticated status, adapterBytePulseAvailable=true and adapterBytePulseVersion=1. Old/disabled/wrong-revision helpers refuse before the selector. One request only; timeout or disconnect never replays it. Reports fit the existing 4 KiB wire limit and reject mixed/malformed evidence. Exit zero means byteRoundTripRestored, always controlSupport=unverified. Full --verify-adapter-isolation remains unavailable, even though the pulse-only backend exists.

## Verification and candidate

Agent-observed dev.sh test: **240 tests in 29 suites pass**, compiling the app/helper with Swift 6 strict concurrency on the existing Xcode 27.1/Swift 6.4/Apple-silicon/macOS 27.0.1 environment. Pulse tests cover unknown flags/source, strict normal-mode refusal, admission states, checkpoint ordering, ignored/throw-after-effect writes, missing readings, budget expiry, cancellation, changed native settings and reconstruction after failed restoration. New transport tests exercise actual authenticated anonymous XPC, wrong peer, timeout, status-only/mixed/malformed replies, unavailable/version handshakes, pulse-only capability isolation, native-owner/invalid-session refusal, native-getter omission and adapter-before-native startup recovery. All charging effects are injected. An initial run exposed a nil-versus-false default-status mismatch; that was corrected and the final full suite passes.

Candidate: signed **Monny 1.0 build 16**, `apps/monny/build/release/Monny-1.0-16.dmg`, using the existing Apple Development identity. Signed, not notarized; clean-Mac/macOS 26 acceptance remains open. Release/signing checks pass: runtime app/helper signer match and negative wrong-ID/pin, ad-hoc, debugger and tampered fixtures. Image integrity and read-only mount review pass: build 16, Applications link, exact app/helper binaries matching signed staging and strict deep signature. Signed CLI rejects an extra pulse argument with invalidArguments/exit 1 before helper access. SHA-256: `9c1ae557515e957cdad7aee82d744c6d14825f6cdf2a221337288185329d9c46`. Build 15's historical package/evidence are preserved separately in BAT-024.

During candidate preparation no helper installation, actual write or Sketch edit was performed. The later authorized pulse is recorded below; no native setter or repeat pulse was used. The bounded native helper force-quit/restart/journal rollback is now user-confirmed in [BAT-024](BAT-024-adapter-verification-ipc.md#user-reported-helper-restart--2026-10-20); no repeat native crash is requested.

## Authorized single hardware pulse — 2026-10-20

After the user's explicit authorization and user-owned replacement/approval, read-only metadata identifies installed build 16. Authenticated diagnostics advertise adapterBytePulseAvailable=true/revision 1, full adapterVerificationAvailable=false and notControlling. The agent quit the ordinary app and invoked --verify-adapter-byte-pulse exactly once through the signed installed app, as an ordinary user. The command exits zero with byteRoundTripRestored: attempted/applied byte 8 and restored byte 0. Native before/after snapshots match; no Monny native session was active. The lid was reported open and admission accepted the battery/source preconditions.

Before/during/after telemetry reports adapter source and both raw/external flags true throughout; charging is false throughout. No native snapshot is taken during isolation. This is real byte write/read-back/rollback evidence, not physical isolation evidence. An immediate no-dwell sample may precede a driver's power-source update; unchanged telemetry cannot distinguish that from absent physical effect. Do not promote any raw flag into a physical-presence provider from this result.

A subsequent read-only --adapter-diagnostics succeeds, reports CHIE=0 with the expected one-byte hex_/0xD4 metadata and notControlling, and confirms the original native snapshot still matches. Raw bounded JSON remains temporary/local, outside the repository. No second pulse, dwell extension, native write, helper kill, sleep test or automatic retry was performed. Existing software/package verification above was not rerun because this step changes only evidence.

The user tentatively reports no noticeable monitor/link change during the pulse. This is an absence of a noticed effect, not proof that isolation did not occur; the no-dwell test remains physically inconclusive.

## Next action and limits

[BAT-026](BAT-026-bounded-adapter-observation.md) now owns the bounded observation implementation, upstream issue/PR review and separate hardware proposal. Do not repeat the pulse merely to obtain a visible transition. Software physical support and product Discharge remain disabled/unverified regardless of this answer. Any longer observation or adapter-specific crash/sleep/removal experiment needs its own concrete reviewed scope and authorization; the authorized single pulse has been consumed. Native helper restart/journal rollback remains separately accepted in BAT-024, not evidence of real adapter-journal restart recovery. No app-crash, sustained enforcement, other-hardware or macOS 26 gate is closed by this test.
