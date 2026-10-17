# Monny: mechanism and dependency decisions

Updated 2026-10-17. No mechanism has been chosen yet; [CORE-001](../tasks/CORE-001-readings-research.md) fills the readings table and the battery-control task fills the helper table. Record dates, sources, revisions, licenses and what was actually tested.

## Readings

| Metric | Source (public/private) | Units and semantics | Model/OS limits | Evidence |
| --- | --- | --- | --- | --- |
| — | Not researched yet | | | |

## Battery control

| Area | Decision | Evidence / open question |
| --- | --- | --- |
| Helper installation | SMAppService daemon (ENGINEERING) | Approval flow, signing requirement and update path to research |
| Charging keys | Not researched | Per chip family; existing open-source tools are reference only and several are GPL |
| Fail-safe | Restore macOS charging when control stops (SPEC §5) | Sleep/wake and restart behavior to verify on hardware |

## Other dependencies

| Need | Candidates to evaluate | Decision |
| --- | --- | --- |
| Global shortcut | Native `NSEvent` monitors vs a maintained shortcut package | Open |
| Update check | GitHub Releases API vs Sparkle | Open |
| History storage | Ring buffers + file, SwiftData, SQLite | Open (CORE-001) |

## Recording a new decision

Use the affected task for a small decision; a broad mechanism can have a focused file here. Record the problem, sources with URLs/revisions, license/maintenance/platform limits, alternatives (including native APIs), the choice and what was tested. Explicitly supersede a previous decision. Any third-party code adopted gets a bundled notice and an entry here.
