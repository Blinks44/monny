# Self-signed helper artifact verification

Date: 2026-10-19. Baseline: main at fd8ba18 plus uncommitted BAT-001–003 work. Agent-observed software verification on the existing Apple silicon development Mac, macOS 27.0.1 / Xcode 27.1 / SDK 27; no macOS 26 or second-Mac claim. Task: [BAT-003](../tasks/BAT-003-self-signed-helper.md).

## Observed results

- Final `apps/monny/scripts/dev.sh test`: 63 tests in 11 suites passed, including Apple/pin requirement parsing, malformed input, lifecycle and existing anonymous XPC tests. These tests do not register a service. Local log: `/tmp/monny-self-sign-test.log`.
- `apps/monny/scripts/prepare-self-signed.py`: arm64 Release build succeeded; app/helper signed with one persistent local self-signed certificate, no Team ID. `codesign -d --verbose=4` reports `flags=0x10000(runtime)` for both thin arm64 executables. No library-validation exception, debugging entitlement, system trust import or quarantine removal added.
- `verify-helper-signing.sh`: the temporary signed unprivileged executable derives its own runtime identity; app/helper signatures match it. Native Security requirements reject the wrong peer identifier and a different pin. Ad-hoc and debugger-entitled copies are rejected; changing a signed executable byte is rejected. The daemon itself was not executed by this harness. These are native signature tests, not privileged IPC or registration tests.
- An initial tampering fixture changed the x86_64 slice of a universal helper while default validation checked only native arm64. Final static validation checks all architectures with strict bundle validation; packaging builds arm64 only. The final tampering check passes.
- `codesign --verify --strict --deep`, `hdiutil verify`, shell/Python syntax checks and `git diff --check` passed. The DMG contains the signed app plus the Applications shortcut; signing state is outside staging in ignored `.local-signing/`. Source scripts/task records remain visible to Git.
- Repeated preparation reuses the dedicated keychain rather than regenerating it; exported DER certificates before/after the final repeat are byte-identical (`cmp` exit 0). Keychain search-list restoration is in a `finally` block; no trust settings are changed. Private key/password remain local and are not logged or versioned.

Final artifact: `apps/monny/build/SelfSigned/Monny-SelfSigned.dmg`, SHA-256 `4f13345f923ff7b36cca86a91e15c55d38c9d561f14c2c19bf0ae2b45aa7fc2e`. This identifies the local test artifact, not a published release. Repackaging can change the DMG hash while preserving the certificate.

## Open acceptance

No app/helper was installed or service registered/removed. Charging remains with macOS. Local explicit SMAppService registration, administrator approval, positive authenticated status IPC, restart/reconnect and removal remain unverified. Also test actual IPC rejection with a separately signed client, beyond static pin rejection. Finally download this DMG on a clean Mac without developer credentials/signing identity and record Gatekeeper approval and full service lifecycle. Keep system security enabled; do not infer distribution support from local fixture success.

Next action: authorize installation of the prepared status-only helper, then execute the local lifecycle checklist from [BAT-003](../tasks/BAT-003-self-signed-helper.md). Lease/restoration remains required before any future hardware write interface.
