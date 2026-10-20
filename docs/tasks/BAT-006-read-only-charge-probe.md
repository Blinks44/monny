# BAT-006: Read-only SMC charge-key inspection

- Updated: 2026-10-19
- Stage: done
- Owner: unassigned (bounded inspection complete)
- Baseline: main 1dc16bd plus preserved uncommitted battery/helper/UI/packaging work
- Scope: existing read-only SMC adapter, app-side bounded diagnostic report, decoding tests and research/current records
- Requirements: ENGINEERING capability/fail-safe rules; phase 4

## Outcome

Inspect only the six reviewed legacy/firmware charge-key candidates using the existing native read-only adapter. Distinguish invalid metadata, kernel/SMC rejection and successful reads without interpreting attributes/readability as write permission. One explicit off-main pass; no background sampler cost, UI changes, helper commands, privileged install or SMC writes.

## Acceptance

- [x] Preserve existing sensor read behavior while validating key identifiers, metadata bounds and response size.
- [x] Return per-key metadata/read outcomes and explicitly leave control unavailable/unverified.
- [x] Meaningful fixtures cover malformed/empty placeholders and partial/denied reads; full tests/build pass.
- [x] Run one unprivileged read-only pass locally if possible; retain raw machine data outside Git and document limits.

## Research

Refreshed batt compatibility documentation and issue 152 on 2026-10-19; only documentation was consulted, no GPL implementation copied. Reported key candidates remain CH0B/CH0C/CHTE and bfF0/bfD0/bfE0. Firmware can gate or expose placeholders; key access is not proof of writes. Existing native adapter is sufficient; no dependency install.

## Implementation and evidence — 2026-10-19

SMCConnection now returns typed per-key inspections while preserving read(_:)'s nil-on-failure sensor interface. It rejects malformed identifiers, invalid type/size metadata and incorrectly sized IOKit replies, preserves kernel and SMC status separately, and requires exact byte counts for integer decoding. ChargeCapabilityProbe performs one explicit @concurrent pass over a fixed six-key allowlist, opens/closes one connection, retains raw metadata without guessing write permissions, and always leaves control support unverified. It is not called by UI, sampling or helper IPC; there is no runtime background cost or new writable command.

Full dev.sh test: **92 tests in 13 suites passed** on macOS 27.0.1 / Xcode 27.1. New fixtures cover the exact allowlist, partial/denied reads, no connection, invalid metadata/type bounds, unknown printable types and strict integer decoding. dev.sh release also passed (existing unrelated BatteryPage Text-concatenation deprecation warnings remain).

An outside-repository harness compiled the two production source files with Swift 6 and invoked the probe as the ordinary user, without sudo/helper installation or launch. On the development MacBook Pro M1 Max, CH0B/CH0C/CHTE metadata requests returned SMC 0x84; bfF0/bfD0/bfE0 returned IOKit -536870207. No candidate metadata or values were accepted. A separate regression read through the same adapter decoded Tp09/Tg05/TB0T/FNum/F0Ac successfully. Raw local diagnostic JSON remains outside Git; no machine values are committed. Tests use injected fixtures and do not prove hardware control.

Signed release.sh packaging also passed: arm64 build, strict app/helper/DMG signatures, positive/negative native signing fixtures and hdiutil integrity. Final artifact: apps/monny/build/release/Monny-1.0-1.dmg, SHA-256 **7a061034b7e291dac3bb924c5a6e64211d12d4f1fafd2bafceea95b62488406f**. Self-signed/not notarized; clean-Mac acceptance remains open. Affected document links, source visibility under ignore rules and git diff --check pass. No Git commit was made; prior uncommitted work is preserved.

## Limits and next step

This completes bounded read-only software inspection, not battery-control acceptance. The rejection may depend on process privileges/firmware; it does not establish root access, missing keys or unsupported writes. No privileged probe, SMC write, charging change, helper install, sleep/restart, entitlement/system-setting change or publication was performed. The installed app/helper is unchanged.

The fixed authenticated helper diagnostic is implemented in [BAT-007](BAT-007-helper-read-only-diagnostics.md); user-owned installation and explicit execution evidence is next. SMC.swift and ChargeCapabilityProbe.swift now live in BatteryHelperShared for both targets. Keep writes and UI control disabled until capabilities, bounded read-back, crash recovery and physical restoration have been established. BAT-005 native event runtime gates remain open.
