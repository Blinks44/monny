# BAT-023: Read-only physical-adapter evidence candidate

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-20
- Stage: done (bounded build-14 read-only unplug/replug comparison accepted; isolation support remains unverified)
- Owner: unassigned; implementation/package ownership released
- Baseline: main cb9abff plus preserved uncommitted native/UI/adapter work; no Git commit
- Owned surfaces: app-only adapter-power reader/CLI, app lifecycle routing, focused tests, candidate build number, signing record and related docs
- Requirements: SPEC §5 fail-safe/real capability evidence; BAT-022 physical-presence dependency

## Outcome and acceptance

An unprivileged, fixed-field report compares OS source selection with AppleSmartBattery connection flags and adapter-description availability during physical unplug/replug. No inferred physical-presence verdict, SMC access, helper update, writable IPC or charging changes. Builds and injected tests cannot establish cable behavior.

- [x] Strict decoding distinguishes unavailable/missing/invalid from false and never infers write support.
- [x] Fixed output excludes serials, adapter identifiers, raw dictionaries and machine inventory.
- [x] CLI bypasses sampler/history/UI/helper work and runs off main actor.
- [x] Behavioral tests and signed candidate/package checks pass.
- [x] Agent-observed local baseline and remaining user cable check recorded separately.
- [x] User supplies connected/unplugged/reconnected reports for USB-C monitor power; baseline correlation and remaining limits assessed.

## Implementation and verification

`AdapterPowerDiagnostics` acquires one source description snapshot, exactly one AppleSmartBattery registry entry and public adapter details. All I/O runs on the concurrent executor; there is no sampler/cache or native-limit query. Missing, ambiguous and unavailable sources remain distinct. Boolean fields require actual CFBoolean values; numeric 0/1 and text are invalid. Adapter dictionaries are projected to shape only. A nil public adapter query is unavailable because the API conflates no adapter and read error. ContinuousClock measures acquisition time, not firmware publication age. The format/version, candidate build and unverified support are explicit.

`--adapter-power-diagnostics` routes before normal UI startup and prints JSON to stdout, with no files/network/helper/SMC work. Exit 0 means a report was written, including any unknown fields. AppModel is now lazy; diagnostic scene content and launch/activation/reopen/termination guards bypass it. This fixes previously eager construction of the sampler's SMC reader. Normal UI startup still uses the same model/sampler path. No visual design or localization changes; output is a stable developer schema, not product copy.

Agent-observed on the existing development Apple-silicon/macOS 27.0.1 environment with Xcode 27.1/Swift 6.4:

- Final `dev.sh test`: **215 tests in 26 suites pass**, including six new strict parsing/privacy tests and prior adapter/native/anonymous-XPC regressions. An initial sandboxed invocation stopped at cache permissions before compilation; the approved normal-cache run passed. After lazy-routing review, the full final run passed again. Existing unused-result/AppIntents and Release Text-concatenation warnings remain outside this slice.
- Final `release.sh` passes existing-signer identity and negative fixtures, app/helper/DMG signatures, arm64 packaging and image integrity. No identity or tool installation. The first package was rebuilt after the lazy-routing correction; only the final checksum below identifies this candidate.
- Running the final signed staging executable with the new flag exits 0, emits schema 1/build 14/unverified support, reports source/registry available and produces no stderr. Allowlisted registry Booleans decode. The complete sanitized baseline stays in temporary local storage; the agent did not manipulate or independently verify the cable state.
- Final DMG mounted read-only: build 14, Applications link and exact app/helper executable hashes match signed staging; deep/strict signature check passes. Image detached. No app/helper installation, helper request, native-setting operation, SMC write or physical isolation performed.
- Source/call-site review confirms no adapter backend in production; strict app reader isolation and output allowlist reviewed. New source/task paths are visible to Git; scoped local links and git diff --check pass.

Artifact: `apps/monny/build/release/Monny-1.0-14.dmg`. SHA-256: **983c79006361350555b83ef974bce8a86fae869bc7cd36d1d1f8fc35e5206d60**. Signed with the existing Apple Development identity, not notarized; clean-Mac/macOS 26 execution and all earlier physical recovery gates stay open. The signed staging app is also ready to run directly, without installation or helper replacement.

## User cable evidence — 2026-10-20

Three user-supplied schema-1/build-14 reports, with the latter two supplied in the requested disconnected/reconnected order, cover power through a USB-C monitor. Source and registry queries are available in every report; charging remains false. The comparison is:

| Observation | Initial adapter-source report | Disconnected | Reconnected |
| --- | --- | --- | --- |
| Power source | adapter | battery | adapter |
| ExternalConnected | yes | no | yes |
| AppleRawExternalConnected | yes | no | yes |
| ExternalChargeCapable | yes | no | yes |
| Public adapter details | populated | unavailable | populated |
| Registry AdapterDetails | populated | populated | populated |

This accepts the bounded read-only comparison. Raw/external flags correlate with unplug/replug on this setup; they are not yet independent physical-presence evidence during CHIE isolation. Registry AdapterDetails stays populated after unplugging and is rejected as a cable-presence predicate here. The public API's unavailable result remains ambiguous between absence and error; the supplied unplug condition gives this particular result context, not a general negative detector.

Exact lid state and settling intervals were not restated; no firmware publication-latency claim follows from the short acquisition duration. No new hardware/OS inventory or independent agent observation of physical steps was collected. The report format/build is known, while the user's actual artifact checksum was not recaptured. No raw JSON, terminal identity or personal paths retained. No new agent test/build, installed-helper change or hardware write was run for this evidence update.

## User check

Keep the lid open. Run this from the repository root; it does not need sudo, installation, a running Monny UI or a new helper:

```sh
apps/monny/build/release/Monny.app/Contents/MacOS/Monny --adapter-power-diagnostics
```

Run the same command for three labelled conditions:

1. Power connected normally.
2. Disconnect all sources of external power, including a powered dock/display if applicable. Wait about 10 seconds, then capture again.
3. Reconnect the original power source, wait about 10 seconds, and capture again.

For reproducing this check, label the three JSON outputs connected/disconnected/reconnected and identify the connector (MagSafe, USB-C direct, dock/display). Report any unavailable/unchanged fields as observed; do not reinterpret them as success or retry a write. Only sanitized observations are printed. If sharing manually, omit unrelated terminal/user information. Missing telemetry and system publication delays remain possible.

## Research, limits and next handoff

Apple [IOPMPowerSource](https://raw.githubusercontent.com/apple-oss-distributions/xnu/main/iokit/IOKit/pwr_mgt/IOPMPowerSource.h) defines ExternalConnected by external power draw. AppleRawExternalConnected and AdapterDetails remain candidates with unpublished CHIE-isolation semantics ([research](../research/smc-charge-control.md#physical-adapter-evidence-collection--2026-10-20)). A baseline plug cycle cannot prove behavior under CHIE isolation, physical current flow or firmware freshness. No candidate is silently promoted into a production provider.

No repeat baseline check is needed for this task. Next engineering action: prepare the bounded authenticated verification report/IPC and its injected negative/lifecycle checks, without constructing a production adapter backend. A later concrete CHIE experiment must collect candidate flags and source selection before/during/after isolation rather than assuming raw flags retain physical semantics. Keep physical-provider and applicable recovery gates explicit; the completed baseline alone does not resolve them. [BAT-022](BAT-022-adapter-verification-preparation.md) retains unbound operations/checkpoint recovery; writable capability remains off. CHIE-isolation, real crash/helper-restart and physical restoration require their own concrete test proposal and explicit authorization.
