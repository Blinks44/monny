# APP-017: Process network rates and readable daily traffic

- Updated: 2026-11-04
- Stage: awaiting_verification
- Owner: current Codex implementation/design session
- Ownership checked: main d65c0d3; implementation owned by this session, released after packaging
- Owned surfaces: network reader, shared sampler/process values, process sort/list, Network window, String Catalog; Monny.sketch network/process specimens; relevant contracts
- Requirements: SPEC §3–4
- Code baseline: main b20daaa contains the initial feature, preserved footer spacing and build-tooling changes. The build-81 VPN source fix and build-82 review fixes are committed on top for the 1.4.0 release.

## Outcome and scope

Add Network sorting to the existing grouped/searchable process list, showing download and upload rates. Add the same ranking to the Network dashboard. Give each of seven days an explicit date, download, upload and total instead of anonymous bars. Daily history represents recorded estimates while Monny runs, not ISP billing or historical traffic before monitoring.

## Acceptance

- [x] Network rates use a bounded, unprivileged macOS source; missing readings remain unavailable.
- [x] Group/search/sort preserve helpers and distinguish transfer speed from daily volume.
- [x] Both surfaces and daily values are reviewed in Light/Dark and six languages.
- [x] Tests, incremented build and signed DMG; real-device agreement/cost limitations recorded.

## Investigation

The existing contract explicitly excluded per-process network because no public in-process counter exists. The user authorizes adding it. The system nettop utility provides TCP/UDP process summary CSV without root. A local read-only probe succeeds outside the agent sandbox; sandbox execution reports NStatManagerCreate failed. No privileged helper or network request is needed. Live Monny.sketch already has a network process table, but the app intentionally omitted it under the old contract.

## Saved design

Monny.sketch saved 2026-11-04. Popover frame 29 (Light/Dark) shows the new sort and rate pairs; Window frame 23 shows the full-width daily traffic table. The APP-017 note next to it specifies placement below the existing Network process table, rates versus volumes, source availability and historical gaps. Final live MCP screenshots confirm unclipped selectors/rate pairs, ordered unknown rows and readable dated daily values in both appearances. No routine image exports were versioned.

## Implementation and checks

- `ProcessNetworkReader` parses the system utility's second, one-second delta sample. Shared `LocalCommand` extracts the already bounded AI child runner; AI environment/limits remain unchanged. The shared sampler joins stable PID launch identities, sums helpers and samples only for the visible Network list/page (numeric process lookup has no network sampling).
- Popover search/actions and grouping are retained. Dashboard reuses ProcessListCard and adds DailyTraffic/WeekCard, with six-language copy and VoiceOver direction/column labels. Historical volumes remain explicitly approximate; unobserved days stay unavailable.
- macOS 27.2 / M1 Max: real ordinary-user nettop CSV and CPU-cost probes succeed ([research](../research/process-network.md)). A temporary hosted integration test also passed: ReadingSource produced a successful source status and live rows with network rates. This is source availability, not a sustained-transfer accuracy comparison.
- Initial full suite: 154 passed. Extended suite: 156 passed, including the temporary live-source and visual fixture. The fixture produced 48 native captures: network/failed-source lists, dashboard ranking and daily traffic, six locales × Light/Dark. Inspected individual renders and both contact sheets confirm rate pairs, nine-row fit, dates/columns and unknown versus zero. ImageRenderer cannot paint the AppKit text field and draws its yellow unsupported-view placeholder; no search-input acceptance is inferred. Environment-injected locales verify SwiftUI text/fit; String(localized:) numeric/detail text retains the host's app language, so installed per-language formatting and assistive-technology checks stay open.
- After one successful shared-checkout run, later test hosts stalled in dyld opening dependencies before application code. A retry and a diagnostic no-debug-dylib invocation did not resolve it; no project setting was changed. A fresh temporary copy runs the standard dev.sh successfully. App sources, tests and project settings were compared with the workspace (only .DS_Store exclusions differ). The permanent suite after removing the temporary fixture has 154 passing tests. The final demand-lifecycle refinement also passed all 154 permanent tests (2026-11-04, build 79). The temporary copy uses the standard project settings; the unsuccessful no-debug-dylib diagnostic left no setting change.
- Follow-up: the Desktop consent reported by the user identified the build-location problem. Build scripts now place executables in Library/Caches; all 154 tests pass directly from the original checkout, so a temporary source copy is no longer needed. [Build-path evidence](../history/2026-11.md#2026-11-04-build-executables-outside-protected-folders).
- `git diff --check` and six-language key coverage pass. No settings, charging control, process action, installation or publication was performed during verification.

## Final package and review

Build 81 (the user-checked package) was built successfully by `release.sh`: Monny 1.4.0/build 81 (Debug/Release aligned), arm64, Apple Development signed, not notarized or published. App/DMG signature verification, DMG integrity and Sparkle appcast generation passed. Package: `apps/monny/build/release/Monny.dmg`; checksum file and appcast are beside it. SHA-256: `adf18b5d93fe2a9f210666b2a5087fa4478e897b00efbf2d2e37a72a0a54b3cc`.

Final code/project/test sources matched the temporary verification copy before its documented cleanup; 154 permanent tests pass. The additional two temporary checks passed before removal. Reviewed final diff against grouped sums, unknown/zero semantics, named units/dates, visibility demand and the saved Sketch. No new dependency, ignored source or versioned capture was introduced; generated package remains under the existing ignored build directory. API naming follows the existing reader/sampler conventions. Ownership is released; runtime acceptance stays open.

## Open checks and next action

The user checked build 81 on 2026-11-04 (network rates, VPN-backed browser traffic and the rest of the 1.4.0 work) and approved the release. macOS 15/26 source compatibility remains unverified on hardware. No per-process history or network destinations are collected.

Build-tooling follow-up: [DEV-001](DEV-001-build-cache-lifecycle.md) owns the temporary-build policy and successful repackaging. The app source and build number did not change; the package checksum above identifies the regenerated local DMG.

Release preparation 2026-11-04: source build raised to 80 so a later published release can update local build 79. All 154 tests pass on build 80. Release notes are prepared; packaging of build 80 and GitHub publication were stopped at the user’s request. Build 80 was not packaged; the later build-81 fix supersedes that candidate.

## VPN/browser traffic fix, build 81

Owner: current implementation session, reader/research/task/state. Baseline main b20daaa; uncommitted fix. The user reported whole-Mac traffic while the browser was absent from both process rankings. Simultaneous nettop probes reproduce the cause: external-only filtering drops active browser sockets classified as undefined while the VPN transport has an external interface. Added the undefined category alongside external, keeping explicitly loopback-classified sockets excluded. No design, grouping or permission change; this is the shared source for both views.

A temporary hosted ReadingSource probe observes positive raw process traffic and identical grouped totals after the initial identity baseline. Existing grouped-value/parser tests cover the unchanged math. All 154 permanent tests pass on build 81. release.sh completed: app/DMG signatures, image integrity and appcast generation pass. TestRuns/ReleaseRuns are empty after cleanup; only the small summary remains. Installed Twitch/VPN confirmation remains open; ownership is released. Publication remains on hold; no commit/push is authorized by this fix request.

## Review fixes, build 82

From the 2026-11-04 review: a group no longer becomes unavailable when one helper lacks a reading (a newly launched browser helper made the whole app flicker to a dash and the bottom of the ranking). Launch identities now come from the previous pass's process read, so a network pass enumerates processes once and CPU/energy/disk rates keep the full refresh interval. Commas in unquoted nettop process names no longer discard the whole sample. VoiceOver no longer reads the direction arrows. Tests updated for partial groups and comma names. 155 tests pass on build 82. Release package: Monny 1.4.0/build 82, SHA-256 `5dc072042b9fc94b6a9208353510ee03cbd991dc95a11d41dacfd2e82cd97d7a`; signatures, image integrity and appcast (version 82) pass. Publication: [history](../history/2026-11.md#2026-11-04-140-release).
