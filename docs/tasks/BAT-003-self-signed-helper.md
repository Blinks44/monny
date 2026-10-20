# BAT-003: Self-signed helper preparation and installation verification

- Updated: 2026-10-19
- Stage: awaiting_verification
- Owner: unassigned
- Ownership checked: main at fd8ba18; released; BAT-001/BAT-002 uncommitted work preserved
- Owned surfaces: HelperSigning, helper/client signing integration, signing tests/scripts, related documentation
- Requirements: SPEC battery helper/security and distribution; phase 4
- Baseline: fd8ba18 plus uncommitted battery foundations and helper scaffold

## Outcome and scope

Prepare a persistent self-signed app/helper artifact and verify native certificate-pinned peer requirements. Keep the existing Apple-team route. This is a status-only helper: no charging commands, automatic registration, installation scripts, manual launchd jobs or system trust exceptions.

## Acceptance

- [x] App/helper accept a matching certificate pin with exact peer identifier and no debugger entitlement; ad-hoc identities remain rejected.
- [x] Apple-issued identities still require the Apple anchor and matching team; a failed Apple-team check cannot fall back to the alternate route.
- [x] Release artifact and signed positive/negative fixture verification pass.
- [x] Persistent local identity is reused; private signing state excluded from Git and the DMG.
- [x] User reports local registration/approval and Connected status after updating from the DMG; screenshot corroborates the connected state.
- [x] User confirms Connected after full app quit/reopen and Mac restart; removal shows Not installed and reinstallation returns Connected.
- [ ] Downloaded DMG installed on a clean second Mac without the signing identity or developer credentials; Gatekeeper and daemon approval results recorded.

## Implementation and verification

`Identity` distinguishes Apple team and complete certificate fingerprint. The alternate path derives the leaf pin from the caller's own validated signature and only admits a single-certificate chain without a Team ID. Both directions bind that same signer and the expected peer identifier. It never trusts a certificate name, user-supplied path, peer-claimed team or installation success as authentication. Security's requirement syntax uses a SHA-1 hash of the DER certificate; certificate generation and code signatures use modern hashes. Static checks cover every architecture and strict bundle validation; native XPC requirements remain installed before connection activation.

`release.sh` uses an existing identity in the user keychain, builds arm64 Release through dev.sh, signs app/helper and the versioned DMG with Hardened Runtime, and verifies fixtures. The original preparation used an ignored `.local-signing/` keychain; [REL-001](REL-001-signing-workflow.md) owns importing that same identity and backup/recovery. No release command creates or rotates a key. It does not add a trust anchor, install into /Applications, remove quarantine, launch the app or register a service. `verify-helper-signing.sh` executes only a temporary unprivileged verifier; it does not execute the daemon.

Source research: [battery control](../research/battery-control.md#self-signed-investigation-2026-10-19). Installation claims in the upstream example conflict; they do not establish Monny's compatibility. Final 63 tests and arm64 Release build pass; signed native positive/negative fixture checks and DMG integrity verification pass. Evidence and runtime limits: [self-signed helper verification](../verification/self-signed-helper.md).

## User-reported local installation — 2026-10-19

User reports helper installation succeeded after the app and System Settings authentication steps, then updated the app through the DMG and observed Connected. The supplied screenshot shows the helper-connected explanation with charge control still unavailable. This supports a successful local authenticated status reply through the existing version/signature-checked client, including after an app replacement. User subsequently confirms Connected after full app quit/reopen and Mac restart, then Not installed after removal and Connected after reinstallation. These are user-reported local checks, not agent-observed process traces. Exact installed artifact hash, runtime wrong-signer rejection and clean-Mac checks remain open. Approval clarity improvements are tracked by [APP-006](APP-006-helper-approval-clarity.md).

## Next handoff

Local lifecycle and build-3 native diagnostic success are confirmed, but repeated AMFI launch rejection makes self-signed installation unreliable even on the development Mac. The same installed binary subsequently runs after user-owned unregister/register; underlying trust/background-item cause remains unisolated. See the dated [launch verification](../verification/self-signed-helper.md#recurring-launch-rejection-on-build-3--2026-10-19). User explicitly chooses to continue development without Developer ID; retain existing self-signing for experimental local testing. A notarized comparison remains a future optional investigation when an identity is available, not a prerequisite for independent implementation. Runtime wrong-signer, clean-machine and macOS 26 checks remain open. Independent restoration-policy work can continue without charging writes. The agent has not changed the installed service; real charging tests require explicit authorization.
