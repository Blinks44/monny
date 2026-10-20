import Foundation

/// One active adapter preparation and one user-authorized system sleep request; never retry either.
nonisolated enum AdapterSleepVerificationCommand {
    static let flag = "--verify-adapter-sleep"
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains(flag) }
    enum Failure: Error, Sendable, Equatable {
        case invalidArguments, helperNotEnabled, preparationExpired, recoveryNotConfirmed, wakeNotObserved
    }
    struct Report: Codable, Sendable, Equatable {
        var sameHelperInstance = true
        var sleepObserved = true
        var wakeObserved = true
        var adapterRestoredBeforeSleep = true
        var nativeSettingsPreserved = true
        var adapterSourceObserved = true
        var controlSupport = ChargeCapabilityProbe.ControlSupport.unverified
    }
    private struct ErrorOutput: Encodable { var error: String }

    static func validate(arguments: [String]) throws {
        guard arguments.count == 2, arguments[1] == flag else { throw Failure.invalidArguments }
    }

    static func collect(requirement: String, session: AdapterLifecycleSession,
                        requestSleep: @Sendable () async throws -> Void = { try SystemSleepRequest.request() },
                        waitForWake: @Sendable () async throws -> Void,
                        status: @Sendable () async throws -> HelperStatus,
                        adapterSource: @Sendable () async -> Bool = {
                            let value = await AdapterPowerDiagnostics.read()
                            return value.powerSource.availability == .available && value.powerSource.source == .adapter
                        },
                        now: @Sendable () -> SuspendingClock.Instant = { SuspendingClock().now },
                        pause: @Sendable () async throws -> Void = {
                            try await Task.sleep(for: .milliseconds(500), clock: .suspending)
                        }) async throws -> Report {
        do {
            _ = try await session.open(requirement: requirement)
            try Task.checkCancellation()
            let start = now()
            let preparation = try await session.prepare()
            try Task.checkCancellation()
            guard start.duration(to: now()) < .seconds(2) else { throw Failure.preparationExpired }
            try await requestSleep()
            // Arm the observer before preparation in run(); buffer an early wake and never poll through DarkWake.
            try await waitForWake()
            try Task.checkCancellation()
            // Keep the owner connection alive; helper owns the unchanged three-second rollback.
            let end = now().advanced(by: .seconds(15))
            for _ in 0..<30 {
                try Task.checkCancellation()
                guard now() < end else { break }
                if let after = try? await status().validated() {
                    guard after.helperInstance == preparation.helperInstance else { throw Failure.recoveryNotConfirmed }
                    if let lifecycle = after.lifecycleDiagnostics,
                       lifecycle.sleepCount > preparation.lifecycleBefore.sleepCount,
                       lifecycle.wakeCount > preparation.lifecycleBefore.wakeCount {
                        guard lifecycle.lastSleep == .adapterRestored,
                              lifecycle.lastWake == .noAdapterRecoveryNeeded,
                              after.controlState == .notControlling,
                              after.nativeChargeLimit == .available(preparation.nativeLimit) else { throw Failure.recoveryNotConfirmed }
                        if await adapterSource() {
                            await session.close()
                            return Report()
                        }
                    }
                }
                try await pause()
            }
            throw Failure.wakeNotObserved
        } catch {
            // A failed/cancelled request is never replayed; invalidation also triggers owner recovery.
            try? await session.cancel()
            await session.close()
            throw error
        }
    }

    @concurrent static func run() async -> Int32 {
        do {
            try validate(arguments: ProcessInfo.processInfo.arguments)
            guard let identity = await HelperSystem.signingIdentity(),
                  let requirement = HelperSigning.requirement(for: .helper, identity: identity) else { throw HelperConnectionError.signingUnavailable }
            guard await HelperSystem.registration() == .enabled else { throw Failure.helperNotEnabled }
            let wake = await SystemWakeObserver()
            let report: Report
            do {
                report = try await collect(requirement: requirement, session: AdapterLifecycleSession(),
                    waitForWake: { try await wake.wait() }, status: {
                        try await HelperConnection(timeout: .seconds(1)).request(requirement: requirement)
                    })
                await wake.stop()
            } catch {
                await wake.stop()
                throw error
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try FileHandle.standardOutput.write(contentsOf: encoder.encode(report) + Data([10]))
            return EXIT_SUCCESS
        } catch {
            if let data = try? JSONEncoder().encode(ErrorOutput(error: String(describing: error))) {
                try? FileHandle.standardOutput.write(contentsOf: data + Data([10]))
            }
            return EXIT_FAILURE
        }
    }
}
