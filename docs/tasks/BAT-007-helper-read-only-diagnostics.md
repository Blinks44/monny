# BAT-007: Authenticated read-only helper diagnostics

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-19
- Stage: done
- Owner: unassigned (implementation/checks complete)
- Ownership checked: main 1dc16bd; preserved uncommitted lifecycle/UI/packaging work
- Owned surfaces: shared SMC/probe, helper contract/session/executor, app XPC client and explicit diagnostic launch mode, behavioral tests, signing/build guidance
- Requirements: SPEC §5 fail-safe and capability limits; phase 4

## Outcome and scope

Expose only the fixed six-key read-only probe through the existing authenticated helper. Run explicitly from the signed app executable, write JSON to stdout and exit; never install/register a helper, change charging, or add monitoring/sampling cost. Preserve status/removal compatibility with older status-only helpers. Document release version/build settings and existing signing-key reuse.

## Acceptance

- [x] Exact fixed allowlist, off-main single cached probe per helper lifetime; live session/lifecycle gates before and after suspended I/O.
- [x] Explicit diagnostics over authenticated XPC, bounded/validated replies, no arbitrary keys or writes; old helper detected before invoking a new selector.
- [x] Tests cover round-trip, malformed replies, concurrency/cache and invalidated sessions; signed release checks pass.
- [x] User supplied the installed helper diagnostic result; bounded read-only IPC acceptance is complete.

## Implementation and verification — 2026-10-19

SMC.swift and ChargeCapabilityProbe.swift moved to BatteryHelperShared so both existing targets compile the same read-only adapter. The zero-argument XPC selector accepts no arbitrary keys, values or paths. Optional additive status fields advertise diagnostics and carry the report; protocol/helper versions remain 1/1.0 so old status/removal clients keep working. BatteryDiagnosticCommand checks the old status selector before sending the new selector. Signing and SMAppService installation boundaries are unchanged.

The executor gates diagnostics on a live ready session before and after suspension. One Task caches/coalesces the off-main probe for that helper process's lifetime; ordinary status reads do not perform SMC diagnostics. The client retains its five-second timeout/cancellation handling and validates the 4 KiB reply, exact key order and readable type/size/byte consistency. Control support always remains unverified/notImplemented. The explicit --battery-diagnostics app launch path prints JSON and exits before UI/monitoring/history writes, with machine-readable failures. A development-build invocation returned signingUnavailable before native IPC. No privileged helper was launched/installed, no charging writes/system changes performed.

Full dev.sh test passed: **98 tests in 14 suites** (macOS 27.0.1 / Xcode 27.1 / Apple silicon). New cases cover status without probing, concurrent requests sharing a cached report, disconnect/sleep/removal while the read is suspended, the legacy handshake, malformed report bounds, real anonymous XPC through HelperSession, missing diagnostic payload and wrong-peer rejection. All hardware reads in those tests are injected; they do not establish privileged SMC availability. No macOS 26 runtime claim.

Signed release.sh passed: arm64 build, strict app/helper/DMG signatures, native positive/negative signing fixtures and hdiutil integrity. Artifact: apps/monny/build/release/Monny-1.0-1.dmg; SHA-256 **c675c5b4ed4d54eec496fe0c3ee47b38581077b21470b2f8c9c78a6707463954**. Permanent signing identity retained. This remains self-signed/not notarized; clean-Mac verification is open. Signing guide now explains that .local-signing is retired and documents Xcode Version/Build, automatic DMG naming and independent helper protocol versions. Affected local links, shell syntax, source/output ignore checks and git diff --check pass. No key/marketing-version rotation, commit or publication.

## Installed runtime evidence — 2026-10-19

User supplied JSON from the installed app's --battery-diagnostics command. The authenticated status/diagnostic path completed with protocol 1/helper 1.0, chargeDiagnosticsAvailable true, notControlling/notImplemented and unverified control support. CH0B/CH0C/CHTE each returned SMC 132 (0x84); bfF0/bfD0/bfE0 each returned IOKit -536870207. All metadata/values remain unavailable, matching the prior unprivileged results. This establishes an actual connected diagnostic-capable helper and no successful candidate read through that helper. The exact newly installed artifact hash/build, recovery steps and process uid were not independently recaptured; do not infer removal/reboot/popover acceptance from the JSON. No writes performed or claimed.

## Next step

Engineering: research the current supported charge-control mechanism beyond this six-key path before selecting a backend. These rejections do not prove all control mechanisms impossible. No blind writes or key scans. Native lifecycle, crash recovery, physical restoration, runtime wrong-signer and clean-Mac gates remain open. BAT-008 owns remaining removal/popover/UI verification; its earlier launch-constraint failure remains dated evidence rather than current proof of an unresponsive service.
