# Bundled helper and authenticated connection

- Date: 2026-10-19
- Revision: `main` at fd8ba18 plus uncommitted BAT-001/BAT-002 sources
- Environment: Apple M1 Max MacBook Pro, macOS 27.0.1, Xcode 27.1 / Swift 6.4
- Source: agent-observed builds/bundle checks, native anonymous XPC tests and injected service/visual fixtures

## Artifact and software checks

- `apps/monny/scripts/dev.sh build`: passed with the new helper target and embedding.
- Final `apps/monny/scripts/dev.sh test`: 61 tests in 11 suites passed. Twenty helper tests supplement the previous 41. Parameterized tests include additional cases.
- `apps/monny/scripts/dev.sh release`: passed. Xcode's AppIntents metadata warning remains; test hosts emit system autoShortcut connection warnings without test failures.
- `codesign --verify --strict --deep` passed on the Debug and final Release apps. The embedded executable has identifier `blinks44.monny.battery-helper`, an embedded Info.plist and arm64 architecture. Its current signature is ad-hoc with no team; Xcode explicitly reports disabling Hardened Runtime for ad-hoc signing on both targets. Build settings retain Hardened Runtime enabled. This does not validate a release identity or notarization.
- The bundled plist passes `plutil -lint`; hosted tests verify Label, BundleProgram, MachServices and root account. There are no shell arguments or KeepAlive entries. No writer or SMC source is linked into the helper target.
- Running the built ad-hoc helper executable directly as the normal user exits with status 1 before opening its listener (rechecked on the final Release artifact). This is a negative signing-gate check, not daemon registration or root execution.

## IPC and lifecycle coverage

Native anonymous `NSXPCListener` tests exercise real Foundation message/reply transport without SMAppService or privileges: status and removal replies, wrong-identifier rejection by the client and listener separately, an unanswered request's deadline and cancellation. A test-only requirement accepts the app identifier for positive anonymous IPC; production uses the Apple anchor, exact helper identity, matching team and debugging exclusion. Positive anonymous IPC does not prove production daemon authentication.

Other tests cover the native requirement parser, malformed team input, wrong self identifier, malformed/oversized/controlling status replies, version mismatch, early/late first-result preservation and embedded artifact paths. Initial parser assertions failed on an unsupported negation spelling; corrected it to `!` and the final suite passes.

Injected lifecycle tests prove refresh does not register, explicit install waits for approval, unsigned builds cannot register/connect, compatible status does not enable charge control, removal requires acknowledgement, failed handshake never unregisters, mismatched versions remain incompatible, pending approval can be cancelled and registration/removal errors stay visible. These fixtures do not establish macOS approval behavior.

## UI checks

Live Monny.sketch Settings/Error/Uninstall frames were inspected through MCP; no design edit or save. A temporary hosted harness rendered narrow Settings content (620 pt) in EN/RU/DE/FR/ES/zh-Hans using unavailable, pending-approval and connected fixtures, with both appearances represented. RU and DE Battery popover fixtures were also rendered. The renders confirmed the disabled Install action for unavailable builds, approval actions, connected version, explanatory off banner and space for localized controls. They caught a missing translation for Open System Settings, which was added and re-rendered. Fixtures did not install/remove a service or change preferences. Captures remain in temporary storage; the harness was removed.

Live app capture after rebuilding failed with ScreenCaptureKit -3811 (the available initial snapshot was an older running app). Final interactive capture, confirmation alert, keyboard navigation and VoiceOver remain unverified. Offscreen source/fixture checks are not user acceptance.

## Open acceptance and next action

No daemon was registered, approved, removed or run as root by the agent; no charging operation occurred. Production same-team IPC, rejection of an actually differently signed/debuggable client, notarized registration, return from System Settings and real removal all require the final matching signed app/helper. Incompatible-helper replacement is not implemented.

Next engineering slice: command lease/executor/restoration fixtures before any hardware writer. Separately, obtain an authorized matching signing configuration and explicit permission to install the status-only helper for native lifecycle verification. macOS 26 runtime, hardware charging fail-safe and helper runtime cost remain open.

## Native lifecycle wiring follow-up — 2026-10-19

[BAT-005](../tasks/BAT-005-helper-lifecycle.md) supersedes the immutable service implementation with per-connection HelperSession and native sleep/wake/termination hooks, retaining status-only protocol and no SMC backend. 85 software tests and signed Release/native fixture/app/DMG checks pass. Its task records the exact final artifact/hash, injected operations, unexecuted native observer and runtime/crash/hardware limits. Prior user-confirmed lifecycle does not validate the new observer.
