# Battery control: first implementation decision

Reviewed 2026-10-19 for [BAT-001](../tasks/BAT-001-battery-foundations.md). This is source research and a software policy decision, not proof that charging can be controlled on the development Mac.

## Installation and IPC

Use Apple's [SMAppService daemon](https://developer.apple.com/documentation/servicemanagement/smappservice/daemon(plistname:)) with the launchd property list inside `Contents/Library/LaunchDaemons` and a bundled helper executable. Follow Apple's [Service Management sample](https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api). Installation remains an explicit user action; observe service status and direct pending approval to Login Items & Extensions. Unregister only after restoration has been acknowledged. Do not use shell installers or SMJobBless.

Use native `NSXPCConnection` and a small versioned interface. Apple's [setCodeSigningRequirement](https://developer.apple.com/documentation/foundation/nsxpcconnection/setcodesigningrequirement(_:)) enforces requirements on the actual peer and must be called before resume. Require the expected identifier and the same validated signer in both directions: Apple anchor/team for Apple-issued identities, or an exact leaf-certificate pin for the experimental self-signed path; reject absent identities. Do not authorize by PID, executable path or bundle ID alone. Stable signing and a negative test with a differently signed client remain required before enabling privileged commands.

Alternative evaluated: [SecureXPC](https://github.com/trilemma-dev/SecureXPC) (MIT). It supports SMAppService and secure peer checking. The [Swift Package Index](https://swiftpackageindex.com/trilemma-dev/SecureXPC) lists 0.8.0 and a sparse release history; Swift 6 strict-concurrency/macOS 26 integration is not established here. Native Foundation already provides the needed peer enforcement, so another dependency is unnecessary. No package installed.

## Charging support varies with firmware

[batt's compatibility notes](https://github.com/charlie0129/batt#compatibility-matrix) and [issue 152](https://github.com/charlie0129/batt/issues/152) report legacy keys `CH0B`/`CH0C`/`CHTE` and firmware limits `bfF0`/`bfD0`/`bfE0`. New firmware can expose empty placeholders or deny access even to root. This can affect an older OS after firmware updates; model/OS checks alone cannot establish support. These are third-party reports, not a Monny hardware result.

Do not infer write access from key existence/readability, install a helper automatically, request private entitlements or change SIP. Unsupported charging stays with macOS. Cutting adapter power makes the Mac discharge and can affect clamshell use; it does not implement Hold and is not an automatic fallback. Hardware commands require their own capability and restoration evidence.

Licensing: [batt](https://github.com/charlie0129/batt/blob/master/LICENSE) is GPL-2.0; only compatibility documentation was consulted, no implementation copied. [actuallymentor/battery](https://github.com/actuallymentor/battery) has an [MIT root license](https://github.com/actuallymentor/battery/blob/main/LICENSE), but its shell/GUI installation and bundled SMC tool are not a ready native SMAppService integration. No code or binaries adopted; a root license alone would not establish licensing for every bundled component. No suitable ready charging package was established by the Swift Package Index search.

## App-side policy

`ChargePolicy` is an isolated value type with injected readings and no I/O. It is currently exercised only by tests, not connected to the sampler or any command executor.

- Charge stops at the configured 50–100 % limit, then resumes at the lower sailing bound. With sailing off, a one-percentage-point deadband prevents repeated switching around the limit.
- Hold inhibits charging with adapter power connected. Discharge requires a separate capability, stops at the limit and stays held until the mode/settings change.
- Heat protection pauses above the configured temperature and resumes two degrees below it. Missing/invalid temperature releases control when protection is enabled. Heat pauses restore adapter power even during Discharge.
- Disabled settings, unavailable capability, missing/invalid readings, disconnected adapter or observations older than 30 seconds release control to macOS and clear episode state. The age must come from a monotonic clock. Physical adapter connection must be distinguished from the power source during forced discharge.

## Next implementation and hardware gates

1. Status-only helper target, registration UI and authenticated version/support handshake implemented in [BAT-002](../tasks/BAT-002-helper-connection.md). Reconcile signing on the final app/helper artifact and verify real registration/approval. The handshake explicitly reports `notImplemented`, without probing or claiming hardware support.
2. Add a short, renewable command lease and serialized command acknowledgements. Restore adapter/charging on start, client invalidation, lease expiry, sleep and uninstall; reconnect after wake without replaying old inhibition. A failed restoration remains an error, never a successful pause/uninstall. Helper crash recovery must restore on restart; a watchdog/launchd restart cannot be treated as a proven guarantee without hardware checks.
3. Add the smallest hardware adapter on a verified firmware family. Test restoration after each partial write and read-back failure before enabling modes. Measure helper cost with background sampling.
4. With explicit user authorization, verify charge limit, hold/discharge and heat behavior on a named MacBook, then quit, crash, helper termination, sleep/wake, reboot and uninstall. Keep phase 4 awaiting verification until those gates pass. Calibration, one-time overrides and trips follow after the basic lifecycle is reliable.

## Status-only helper implementation (2026-10-19)

The separate executable shares a versioned `Data`/Codable status interface with the app; only status and prepare-for-removal methods are exported. No SMC writer, shell invocation, charge policy, timer or persistent setting is included in the daemon. The launchd job is on-demand, without KeepAlive; writable control will require a reviewed crash-recovery lifecycle before that changes.

The listener applies [native incoming-peer requirements](https://developer.apple.com/documentation/foundation/nsxpclistener/setconnectioncodesigningrequirement(_:)) before activation and repeats enforcement on accepted connections. The client requires the helper identity. The Apple-issued path requires Apple generic anchor, exact identifier, matching certificate team and `!entitlement["com.apple.security.get-task-allow"] exists`. Apple's [requirement language](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/RequirementLang/RequirementLang.html) defines existence as false for a missing or Boolean-false value, so this excludes debuggable peers. Native parser tests caught and corrected an invalid negation spelling. Team input is constrained before requirement construction; self/embedded signatures are validated off the main actor.

The [local SDK SMAppService header and Apple sample](https://developer.apple.com/documentation/servicemanagement/updating-your-app-package-installer-to-use-the-new-service-management-api) require signed apps, admin approval for daemons and notarization for apps containing daemons. Matching team validation is necessary but does not establish registration/notarization acceptance. No credentials, entitlements or helper installation were added on the development Mac. Replacement of an incompatible helper remains an implementation gate; failed authentication/version checks do not cause automatic unregister/re-register.


## Self-signed investigation (2026-10-19)

[BAT-003](../tasks/BAT-003-self-signed-helper.md) adds certificate-pinned authentication and prepares a status-only DMG without changing the registration mechanism. [Apple’s requirement language](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/RequirementLang/RequirementLang.html) supports complete certificate hashes, explicitly distinguishes self-signed certificates from ad-hoc signatures, and does not require system trust when a requirement pins a certificate. This establishes the authentication mechanism, not installation eligibility.

The upstream [Microsoft Process Explorer README](https://github.com/microsoft/Procexp-Mac#testing-without-a-developer-id-certificate-local-self-signed) describes self-signed SMAppService daemon testing. Its [identity-generation script](https://github.com/microsoft/Procexp-Mac/blob/main/Scripts/dev_make_signing_id.sh) contains a contradictory statement that root daemon registration requires Developer ID. Treat these as unverified/inconsistent implementation notes, not evidence that Monny works on another Mac. No upstream code was copied or dependency installed. Native Security/Foundation remain sufficient.

The local SDK still documents signing/notarization requirements for apps containing daemons. Neither Open Anyway for the GUI nor a successful static signature check proves that the daemon can register or run. Verify local registration with explicit authorization, then repeat with a downloaded DMG on a clean Mac lacking the signing identity. Keep Gatekeeper enabled and record any failure; do not add trust roots, remove quarantine or silently migrate to a shell installer/legacy service API. The release distribution route remains undecided until this evidence exists.


## macOS charging settings (2026-10-19)

[Apple’s charging documentation](https://support.apple.com/en-us/102338) confirms that Optimized Battery Charging can delay charging above 80% based on learned usage. Apple silicon Macs with macOS 26.4+ also offer a separate 80–100% Charge Limit. Both can occasionally charge to 100% for state-of-charge estimation. These are independent OS behaviors, not Monny modes or errors.

[batt’s own setup guidance](https://github.com/charlie0129/batt#installation-gui-version) recommends disabling optimization and the built-in limit for its controller. This is third-party mechanism evidence, not a Monny hardware test. Monny’s current status-only helper makes no charging requests, so neither feature needs to be disabled for monitoring or helper installation. Before future active Monny control, recommend manually turning off optimization and setting the system limit to 100% where available, to avoid conflicting targets. Confirm coexistence per hardware backend before enabling writes; do not claim this is a universally tested prerequisite or force a setting change.

[APP-005](../tasks/APP-005-battery-design-parity.md) adds a Battery info popover with this manual guidance, a Battery Settings link, and a reminder that macOS features can be re-enabled when Monny control is no longer used. No public supported API to reliably read/change both settings was established in this investigation; there is no on/off detector, private-preference write or automatic configuration. The current build does not need the user to follow these preparation steps.
