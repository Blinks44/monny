# BAT-011: Native charge-limit diagnostics in the signed helper

- Updated: 2026-10-19
- Stage: done
- Owner: unassigned; implementation/checks complete
- Baseline: main 1dc16bd with preserved uncommitted helper/UI/release work
- Scope: isolated getter-only PowerUI bridge, typed report, existing authenticated diagnostics and tests; no UI or setter

## Acceptance

- [x] Validate runtime class/getter ABI before native calls; unavailable/malformed results never advertise write support.
- [x] Add optional versioned report to the existing diagnostic reply; older helpers remain status/removal compatible.
- [x] Off-main explicit single diagnostic pass, lifecycle revalidation and client timeout remain; no sampling, shell, preferences or charging writes.
- [x] Behavioral/wire tests, actual ordinary-user production-reader check and signed DMG verification.
- [x] Native report verified through the installed signed helper on M1 Max/macOS 27.0.1; macOS 26 runtime remains a separate release gate.

## Implementation — 2026-10-19

NativeChargeLimitBridge.h/.m live only in the existing helper target, exposed through its existing bridging header. The independent bridge loads the installed private system framework once, checks class/getter return and argument encodings before invocation, uses typed Objective-C messages rather than unchecked objc_msgSend casts, catches Objective-C exceptions and validates returned number types/count/range. No setter/disable selector, shell/JXA, private preference write, entitlement or extra daemon is introduced. Source research/licensing stays in BAT-010; no GPL implementation adopted.

NativeChargeLimitReader runs explicitly @concurrent and maps the plain C result into an immutable Codable/Sendable snapshot or typed unavailable reason. Wire validation requires sorted unique 80–100 limits (at most 21) and a configured limit among those advertised. Disabled means the setting is not enabled, not that the Mac is physically charging. Separate getter calls are observations rather than an atomic control transaction; no future writer may treat this process-lifetime diagnostic cache as a fresh pre-write snapshot.

The existing executor adds an injected native getter task alongside SMC diagnostics. Requests coalesce to one cached read per helper lifetime, status checks never probe, and session/phase are revalidated after suspension. The app's existing five-second XPC timeout/cancellation remains. A private synchronous getter cannot be forcibly cancelled; one stuck worker can leave this diagnostic unavailable until helper restart, but neither executor status/lifecycle turns nor the main actor wait synchronously on it. No repeated tasks/retries are spawned for a stuck read.

Optional nativeLimitDiagnosticsAvailable/nativeChargeLimit fields preserve protocol-1/helper-1.0 status/removal compatibility. The diagnostic command requires the new feature flag and nonempty report; an older running helper returns helperUpdateRequired before diagnostic invocation. Charging support remains notImplemented and no product control is enabled. App/helper build number is 3; marketing/protocol versions and permanent signing key are unchanged.

## Verification

Full dev.sh test passed: **107 tests in 15 suites**, including native wire round-trip, malformed/duplicate/out-of-range/unadvertised settings, typed query failure without fake values, old diagnostic handshake, explicit/coalesced read, session invalidation/sleep/removal during suspended native I/O, and a real anonymous XPC native-report round-trip through HelperSession. Injected tests never invoke PowerUI or a privileged service.

A temporary ordinary-user executable compiled the exact production NativeChargeLimitBridge.m/NativeChargeLimitReader.swift/model and called the getter once under an external eight-second timeout. On M1 Max/macOS 27.0.1/Xcode 27.1 it exited successfully and returned validated 80/85/90/95/100 limits. Current native setting values remain only in local temporary JSON. A separate temporary Objective-C fixture checked the production ABI guard with valid, missing, wrong-return and wrong-argument signatures; all passed. No third-party implementation executed, installed helper changed or charge setting written. No macOS 26 runtime claim.

Signed release.sh completed: arm64 app/helper build, strict signatures, positive/negative native signing fixtures and hdiutil DMG integrity pass. Artifact: apps/monny/build/release/Monny-1.0-3.dmg; SHA-256 **fd2beb6f655e42e2c9f1bcde91f318d08fd1a569545996733bb5e57e0d28303a**. Permanent self-signing identity retained; clean-Mac/notarization gates unchanged. Affected links, source/output ignore policy, header/script syntax and git diff --check reviewed. No commit or publication.

## Next action and limits

User supplied a successful authenticated build-3 native diagnostic report. Read-only agent inspection confirms installed build 3 and helper SHA-256 e312af751c2cf54e8dd3564453427630223f045e005142ca9f808e876e2d1a32 match the packaged helper; launchd currently reports it running. The native snapshot validates and advertises 80/85/90/95/100; original SMC candidates still reject metadata access. Personal current settings and raw logs remain outside Git. This closes getter-only installed-helper acceptance, not setter support or physical enforcement. Repeated OS launch rejection before the eventual successful registration remains an independent release blocker in BAT-003 and the self-signed verification record; no repeated diagnostic is required.

Next independent engineering slice: prepare native-setting ownership/restoration policy and injected transaction tests before adding any setter. Capture a fresh prior enabled/limit pair, validate requested returned limits, acknowledge read-back and restore the user's original setting when relinquishing control, including partial failure and external-setting changes. Real writes require explicit authorized target/rollback testing; do not silently add Hold/sub-80/sailing/heat/calibration support. Physical lifecycle, crash recovery, clean-Mac and runtime wrong-signer gates remain open.
