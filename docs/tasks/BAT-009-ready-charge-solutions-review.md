# BAT-009: Review existing charging solutions against local firmware

> Historical battery/helper record. The full build-23 implementation is preserved on `experiments/discharge` at abe3a80. Current native-only main scope is [APP-007](APP-007-native-simplification-design-parity.md); dated evidence below remains valid only for its stated artifact.
- Updated: 2026-10-19
- Stage: done
- Owner: unassigned; bounded research complete
- Baseline: main 1dc16bd plus preserved uncommitted helper/UI/release work
- Scope: user-provided OpenDente, its referenced packages, current batt compatibility, two-key read-only comparison; no production changes

## Findings and decision

[OpenDente](https://github.com/killerk3emstar/OpenDente) reviewed at **06c5a8199f5c0657374e667073b3aa6a75f50df8**, latest main commit dated 2026-05-04 according to GitHub API. README states beta, with hardware verification limited to one M4/macOS 26 machine. GPL-3.0 LICENSE confirmed. This is a whole app/helper, not a ready Swift package. Read-only source review covered SMCService, HelperDelegate, HelperState, Watchdog, main and shared constants; no implementation copied, compiled or run. Temporary research files remain outside Git. Project licensing policy excludes adopting GPL implementation without an explicit licensing decision.

Its [SMC reader](https://github.com/killerk3emstar/OpenDente/blob/06c5a8199f5c0657374e667073b3aa6a75f50df8/OpenDente/Services/SMCService.swift) uses the same AppleSMC client type 0, selector 2, metadata/read commands and four-character key packing as Monny. [Backend detection](https://github.com/killerk3emstar/OpenDente/blob/06c5a8199f5c0657374e667073b3aa6a75f50df8/OpenDenteHelper/HelperDelegate.swift) chooses CHTE if readable, then CH0B, otherwise unknown. The actual Monny helper rejects both candidates, so this reviewed detection path does not supply an alternate charging backend for our observed failure. It also references CHIE/CH0I for adapter control. No firmware-gated/native-limit fallback was found in the reviewed detection/SMC source. Do not generalize this to every later fork/version.

Useful mechanisms to compare, not safety guarantees to copy: heartbeat expiry, explicit disconnect restoration, root-owned persisted inhibition state/startup restoration. A watchdog in the same process cannot run after that process dies; restart and real physical restoration remain separate gates. Monny already has shorter monotonic leases and lifecycle/session tests; no reason to replace them with the reviewed wall-clock watchdog.

[Battery-Toolkit](https://github.com/mhaeuser/Battery-Toolkit), referenced by OpenDente, is BSD-3-Clause but archived (GitHub API: last pushed 2025-09-25). [SMCKit](https://github.com/beltex/SMCKit) is MIT but last pushed 2020-03-06, predating Apple silicon support requirements. These metadata checks do not establish maintained macOS 27 charging support. Swift Package Index search was unavailable in this session, so no new registry-completeness claim is made. No dependency installed.

Current [batt documentation](https://github.com/charlie0129/batt#compatibility-matrix), [issue 152](https://github.com/charlie0129/batt/issues/152) and [merged PR 154](https://github.com/charlie0129/batt/pull/154) provide a newer lead: opt-in adapter cycling through CHIE on gated firmware, or a PowerUIAgent native-limit fallback (80%+). These are third-party mechanism reports, not Monny write evidence. They also describe clamshell/sleep and battery-cycling differences. Adapter cycling cannot silently implement SPEC's Hold/run-on-adapter behavior; PowerUIAgent's private interface cannot be assumed public, stable or usable. No private entitlements, OS setting writes, system sleep assertions or fallbacks were added.

## Local read-only evidence — 2026-10-19

A temporary Swift 6 harness compiled only Monny's existing SMC.swift and read exactly CHIE and CH0I, as the ordinary user, with no sudo or helper invocation. On the development M1 Max/macOS 27.0.1, CHIE returned readable metadata (hex_, one byte); CH0I returned SMC 132. No raw value was printed/committed, no arbitrary key enumeration and no write command exists in the harness. This is the first local positive adapter-key read, **not write support or charging capability**. App/helper installations, settings and charging remain unchanged.

## Next engineering step

Native-limit read availability/range is now verified in [BAT-010](BAT-010-native-charge-limit-research.md); its getter-only diagnostic adapter is the next implementation slice before any writer. If only adapter control is feasible, present it as a distinct opt-in Discharge/adapter behavior with its limitations; do not call it Hold or silently replace Charge. Physical writes require explicit user authorization plus bounded read-back/restoration and crash-recovery checks. Readability alone is insufficient.

## Checks

Research/local temporary probe only; no app build/tests needed because repository app code is unchanged. Affected document links and git diff --check reviewed. No Git commit/publication or new permanent tooling.
