# DES-005: Find and stop a process by name, PID or port; Needs attention

- Updated: 2026-10-28
- Stage: done
- Owner: implementation chat (2026-10-28, design and build 68)
- Ownership checked: main b07c30a; this record and its related SPEC/DESIGN/PLAN/STATE/history notes were uncommitted drafts of the same task
- Owned surfaces: Monny.sketch page `01 · Popover` frames `24`–`28` and the DES-005 handoff; Symbols `Light|Dark/Process/Port row` and `Light|Dark/Process/Inspector`; SPEC Processes proposal, DESIGN, PLAN, STATE and this record
- Requirements: SPEC §1, §3 Processes; user requests 2026-10-26 (port search) and 2026-10-28 (search by PID or port, hung processes on top)
- Code baseline: main b07c30a, released 1.1.1/build 67; implemented in uncommitted build 68.

## Outcome and scope

One Processes search field finds a process by name, PID or local TCP port (including `localhost:3002`-style input), explains what the process is (folder, executable, parent, listening ports) and offers Quit / Force Quit… for that single PID. A Needs attention section above the list surfaces processes that keep a CPU core busy, with a direct action. A planned "not responding" signal was dropped during implementation (no public source, see research).

## Acceptance

- [x] Saved Light/Dark frames: Needs attention, number search with port and PID sections, inline process details with actions, single-process Force Quit confirmation, port-free result.
- [x] Actions target exactly one PID, never the grouped app or its helpers; confirmation before force; no automatic kill or escalation.
- [x] Handoff frame covers inputs, empty/unreadable/still-running/restarted states, signal honesty, discovery sources to research and native checks.
- [x] User review of the concept (2026-10-28, with the compact sort decision).
- [x] Implemented in build 68 with tests and six-language render review.
- [x] Installed acceptance: the user checked build 68 on their Mac on 2026-10-28 and reported it working (port/PID search, details, Quit/Force Quit, Needs attention).

## Sketch source and review

Saved Monny.sketch 2026-10-28, page `01 · Popover`, x 14720–17840: `24 · Needs attention`, `25 · Search by port or PID`, `26 · Process details`, `27 · Force quit process`, `28 · Port is free`; Light at y 0, Dark at y 900. Handoff: `Process search & Needs attention · Behavior & implementation handoff · DES-005` at y 1820. Frames reuse the existing popover chrome, buttons, alert and the `Process/Port row` and `Process/Inspector` symbols (Dark masters added; Inspector now shows Quit + Force Quit… + •••). The earlier 2026-10-26 port-only frames were no longer in the document; their unused `Process/Port listener` masters were removed. Process data is synthetic. All ten frames and the handoff were reviewed live through MCP screenshots. No PNG exports added to Git.

Compact sort (user decision 2026-10-28, the tabs + search + sort stack looked heavy): the full-width CPU/Memory/Energy row is replaced by a `Popup Button` ("CPU ⌄") to the right of the search field, giving the list one more row. Applied and saved in Light/Dark frames `19`–`22` and `24`; hidden for number/URL queries (`25`–`28`). Frame `10` predates the search field and is unchanged. Implemented in build 68.

## Implementation and verification (build 68, 2026-10-28)

- `Readings/ProcessLookup.swift`: `ProcessQuery` parsing (name, number, port, loopback URL), `PortListenerReader` (libproc listening TCP sockets), `ProcessLookup.find` (listeners of a port, the PID's process, executable, folder, parent, ports) and `waitForExit`.
- `Readings/BusyProcesses.swift`: per-process busy episodes kept by `Sampler` from the shared snapshots (80 % of one core, at least 1 minute, at most three).
- `Popover/ProcessLookupList.swift`: results, inline details, single-PID Quit/Force Quit…, ••• menu, verified result states and `NeedsAttentionCard`; `ProcessList` places the `PopupPicker` sort next to the field; new `DestructiveButtonStyle`.
- 30 new String Catalog keys in all six languages; the unused "Search processes" key removed.
- `apps/monny/scripts/dev.sh test`: **148 tests in 19 suites passed** on macOS 27.0.1, including query parsing, busy episodes, a test-owned loopback listener found by port and PID, and an end-to-end Quit of a test-owned `/bin/sleep` found by PID with verified exit. The port scan of all processes took about 4 ms.
- Temporary native render review (removed afterwards): Needs attention, port result with details, empty port, unmatched number × six languages × Light/Dark. Fixed a truncated busy detail by removing the PID from it. Product strings from `String(localized:)` follow the host language in these renders, so their fit was checked in Russian; view strings used each locale.
- `scripts/release.sh`: Monny 1.1.1 build 68 DMG signed (not notarized). Sketch frames `24` and `28` and the handoff were updated to the implemented copy and saved.

## Open questions and native checks

- Decided: no "not responding" signal and no global "port is free" claim ([research](../research/process-actions.md#pidport-lookup-and-needs-attention-2026-10-28-des-005)). Container forwarders are not special-cased.
- Native checks: IPv4/IPv6/wildcard bindings, several listeners per process, ignored SIGTERM, PID reuse, launcher restart, container forwarders, six-language fit, keyboard and VoiceOver.

## Next handoff

Done and released in 1.2.0 (build 69, 2026-10-28). Coverage not separately claimed: IPv6-only and several-listener cases beyond tests, ignored SIGTERM, PID reuse and launcher restarts on real servers; revisit with an actual issue.
