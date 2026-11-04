# DEV-001: Builds outside protected folders without accumulating test products

- Updated: 2026-11-04
- Stage: done
- Owner: current shared Monny/Rebind build-tooling session
- Ownership: dev.sh, release.sh, DEVELOPMENT and this task; released
- Baseline: main d65c0d3 plus the existing uncommitted app/tooling work

## Outcome and acceptance

Build tooling only; app code, version, signing identity and permissions stay unchanged. Default test and packaging runs use owned temporary directories under Library/Caches, remove their intermediate products on completion/failure/handled interruption, and preserve one small test summary plus requested final release artifacts. Explicit `MONNY_DERIVED_DATA` overrides are never automatically removed. Build/run/build-for-testing products remain available until `dev.sh clean`, which protects live cached app/build files. No broad cache sweep or scheduled cleanup service.

- [x] Real dev.sh test succeeds from the original Desktop checkout, with no retained default test build.
- [x] Success/failure exit codes, cleanup and explicit-path preservation are checked with stub commands.
- [x] Real packaging succeeds and removes its owned ReleaseRuns directory.
- [x] Obsolete owned verification products are removed; existing source and packaged releases are preserved.
- [x] Documentation, state and dated evidence updated; diff/shell checks pass.

## Current checks and next action

Shell syntax passes; the embedded Rebind release Python parses. Black-box stub checks pass for successful/failed test cleanup, exit status, explicit-path preservation and refusal to clean an override. Both real release scripts succeeded and removed their ReleaseRuns directories. Success/failure/interrupt cleanup and a clean refusal while a fixture file is open pass. The live-file check was corrected to use lsof output, since absent sibling product paths can cause a nonzero exit status even with users of an existing file. Build-tool verification and cleanup are complete; no completed run directories remain. Ownership is released. User confirmation of future Desktop-dialog recurrence remains separate from build-tool checks.

## Verification

M1 Max/macOS 27.2: all 154 Monny tests pass from the original checkout. TestRuns and ReleaseRuns contain no completed run directories. Default persistent DerivedData and the old repo-local DerivedData were cleaned after checking for users; the session's obsolete verification copy and captures were removed, about 2 GiB of logical artifacts in total. Source, live apps and final packages were preserved.

Monny 1.4.0/build 79 was repackaged for tooling verification, with unchanged application source/version and no installation/publication. SHA-256: `02e0eea9d63258862c2b0fb4e9d1012123277434ff63b2a108d8e0b625164e0c`. The generated app/DMG signatures, image integrity and appcast checks passed.

## Next use

Use the normal dev.sh/release.sh commands; default tests/packaging clean themselves. Use dev.sh clean once an intentional build/run artifact is no longer needed. If a Desktop dialog recurs from an installed app, identify that distinct protected-file access; the build-location change does not alter system privacy grants.
