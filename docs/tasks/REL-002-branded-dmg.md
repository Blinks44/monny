# REL-002: Monny-style drag-to-install disk image

- Updated: 2026-10-19
- Stage: done
- Owner: unassigned; released
- Baseline: main 1dc16bd plus preserved uncommitted BAT-004/review work
- Ownership: scoped DMG frame in live Monny.sketch, one shipping background asset, existing release.sh and packaging docs

## Outcome

A Finder DMG window using Monny's light surfaces, rounded cards, brand accent and app icon, with a native Applications drop target. Keep the existing stable app/helper/DMG signatures and one release command. No app installation, helper registration or charging operation. Use installed create-dmg (also used by Rebind), not custom Finder automation. No app-interface or new instructional raster-copy changes.

## Acceptance

- [x] Inspect live design, save a self-contained DMG frame/background source and visually review it.
- [x] A single committed Retina background asset is used by release.sh; previews/exports remain temporary.
- [x] Styled package is produced by the ordinary command and passes native signatures/image verification.
- [x] Mount and inspect actual Finder layout; native app and Applications targets remain usable.
- [x] Docs record dependency, source/regeneration, final artifact and any open runtime gates.

## Source and verification — 2026-10-19

Live Monny.sketch inspected through MCP; the new saved frame is `09 · Distribution · DMG · Light` on `03 · Flows & System` (frame 1C791AA2-07A7-4547-9070-D98FF4BA5C96). Background-only child 4F629E68-6054-49E2-86B9-E77FB48EEC7C is the export source; native icon/filename previews stay separate. Uses existing surface/text/metric/brand variables and shared card elevation. Screenshot-reviewed source and actual Finder window: 660×420, icon centres 170/490 at y210, 128 pt icons, 13 pt filenames, arrow and rounded cards. Finder exposes both native targets; Applications resolves to /Applications. No installation performed.

Export the background child at 1× and 2× to temporary PNGs, then use `tiffutil -cathidpicheck background-1x.png background-2x.png -out apps/monny/scripts/dmg/background.tiff`. This one shipping asset is intentionally versioned; no preview/duplicate generator committed. Existing release.sh uses installed create-dmg 1.3.0 (MIT), fails early with installation instructions if absent, preserves stable app/helper/DMG signing and verifies the image. Dependency: https://github.com/create-dmg/create-dmg . No package installs were performed.

Final ordinary release.sh passed arm64 Release, native helper signature fixtures, strict app/DMG signature checks and hdiutil integrity. Artifact: apps/monny/build/release/Monny-1.0-1.dmg; SHA-256 d9878c602a7418b9e8e0580364a98e70152c492cf807799eab51700fb76b12e0. Includes APP-006 approval copy/actions. Mounted read-only; saved Finder metadata confirms background image, 660×420 window, 128 pt icons and 13 pt labels. Actual CUA screenshot after raising the window confirms layout. Full app suite 75 tests passes for the accompanying UI change. Final syntax, asset ignore-policy and document links checked. No publication or helper change by the agent. Next user action: use this DMG for the remaining status-only helper checks; clean-Mac acceptance remains BAT-003.
