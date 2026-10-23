# OpenDente and AlDente: CHIE and physical observation

> Battery helper and Discharge task/verification records referenced here (BAT-*, APP-005/006, helper verification) were retired from main on 2026-10-21; they are preserved on the `experiments/discharge` branch.

Reviewed **2026-10-20** for BAT-026, after BAT-025's real byte round trip produced no sampled source change and no clear visible effect. Public GitHub REST responses, issue/PR discussions and vendor documentation were read; no releases installed, attached debug archives downloaded or upstream code copied.

## OpenDente

- [Repository](https://github.com/killerk3emstar/OpenDente): GPL-3.0, not archived. Main remains `06c5a8199f5c0657374e667073b3aa6a75f50df8`, last pushed 2026-05-04. Main's lack of new commits does **not** mean no relevant newer contribution exists.
- [Issue #3](https://github.com/killerk3emstar/OpenDente/issues/3), opened 2026-10-11: contributor reports M1/macOS 14.8.9 with a 65 W USB-C PD monitor, rejected CH0B/CH0C/CH0I/CHTE and available CHIE. They describe 8 as adapter isolation and 0 as reconnection, and report hysteresis-driven recovery. This is their hardware report, not Monny acceptance on macOS 27. Their explanation involving a private entitlement is not independently established by this review; error 132 alone does not prove the entitlement cause.
- [PR #4](https://github.com/killerk3emstar/OpenDente/pull/4), head `8665d30ab780f210ec5cacade5bca2186c0fb187`: open, unmerged; REST review/comment endpoints return no entries at review time. Read its body and complete four-file diff, including the helper fallback and app state-machine changes. No maintainer approval or additional hardware validation is inferred.
- The important failure is state ownership: after CHIE isolation, IOKit may report battery/not-plugged-in. Treating that as an ordinary unplug can abandon the branch responsible for reconnecting power. Restoration must depend on Monny's checkpoint/owner, not on connected/source telemetry.
- The PR uses adapter switching as a fallback for charge inhibition, makes an undetected charging API fall back to legacy and changes Swift mode to 5. Monny adopts none of those decisions. Adapter isolation consumes battery and cannot represent automatic holding while powered from the adapter. Unknown capabilities stay unavailable; Swift 6 strict concurrency remains.
- Main's [issue #1](https://github.com/killerk3emstar/OpenDente/issues/1) reports no effect on macOS 27. The newer Sonoma contribution cannot be assumed to fix that platform. Main README itself limits actual testing to one M4/Tahoe setup.

Licensing decision: GPL-3.0 implementation remains reference-only. Monny's existing BSD/MIT-reviewed fixed constants/transport, private recovery journal and actor lifecycle are extended independently. No source import, ready-package adoption or toolchain change is justified.

## AlDente

- The vendor [FAQ](https://apphousekitchen.com/faq/) says only early Classic versions through Classic 2.0 are open source; modern Free/Pro are closed source. The [public repository](https://github.com/AppHouseKitchen/AlDente-Battery_Care_and_Monitoring) contains legacy code and current issue/release information, not a verifiable current helper implementation. Repository metadata reports last push 2026-10-08; current public code cannot establish which modern key/backend is used.
- Exact CHIE issue search in that repository returns zero matches at review time. That does not establish that AlDente does or does not use CHIE. No reverse engineering of the closed binary is performed.
- [Features](https://apphousekitchen.com/aldente-overview/features/) distinguish charge inhibition from Discharge, describe internal adapter reconnection at the target, and explain sleep prevention in clamshell mode. Monny does not adopt sleep prevention; the engineering experiment requires an open lid and restores on sleep.
- [Issue #1795](https://github.com/AppHouseKitchen/AlDente-Battery_Care_and_Monitoring/issues/1795), closed: user reports repeated AC/battery switching around six seconds apart with USB-C display flicker on an M1 Pro/macOS 27 beta. The [maintainer response](https://github.com/AppHouseKitchen/AlDente-Battery_Care_and_Monitoring/issues/1795#issuecomment-5091959013) points to early beta support, not a demonstrated fix for all hardware. Use it as a risk/negative-test lead, not proof of a CHIE implementation or current universal failure.
- [Issue #1835](https://github.com/AppHouseKitchen/AlDente-Battery_Care_and_Monitoring/issues/1835), open/investigating: M2 Pro/macOS 27 with CalDigit TS4. The [maintainer](https://github.com/AppHouseKitchen/AlDente-Battery_Care_and_Monitoring/issues/1835#issuecomment-6038852917) reports about ten seconds on battery before return to dock power, says investigation continues and asks for direct-adapter comparison. A short successful byte write cannot establish sustained isolation, especially through a dock.
- [Issue #1775](https://github.com/AppHouseKitchen/AlDente-Battery_Care_and_Monitoring/issues/1775) concerns early macOS 27 charge-control failure; maintainer responses acknowledge compatibility work. [Issue #1642](https://github.com/AppHouseKitchen/AlDente-Battery_Care_and_Monitoring/issues/1642) reports a sleep/wake reconnection failure. Neither closes Monny's own lifecycle gates.

## Retired experiment decision and results

The 2026-10-20 decision prepared one fixed bounded source observation, not a production charge mode. Restoration depended on the checkpoint/owner rather than source/cable telemetry. Direct-adapter, open-lid testing separated display/dock behavior; a read-only settling window followed byte rollback. Stalled synchronous firmware calls still have no hard wall-clock recovery guarantee.

Builds 17–18 observed adapter→battery→adapter with CHIE restored to zero and native endpoints preserved. Raw/external connection flags became false during isolation and cannot prove independent cable presence. Immediate post-rollback source publication lagged; no setter retry or extended isolation was justified. Bounded results do not establish sustained electrical behavior, client-exit recovery or broader hardware/firmware support.

Main excludes helper/SMC writes and defers Discharge. Detailed artifacts, lifecycle results and unresolved checks belong to BAT-025–030 on **experiments/discharge** at `09595b5`; summary: [SMC findings](smc-charge-control.md#final-experiment-findings-and-remaining-gates). Next: no experiment without a new scoped product/safety decision and concrete authorization.
