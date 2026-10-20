import Foundation

/// Explicit failure experiment. Sends the mutating selector once, then reads only; never installs a helper.
nonisolated enum AdapterRestartVerificationCommand {
    static let flag = "--verify-adapter-restart"
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains(flag) }
    enum Failure: Error, Sendable, Equatable {
        case invalidArguments, helperNotEnabled, helperUpdateRequired, unsafeInitialState
        case unexpectedReply, restartNotObserved, recoveryNotConfirmed
    }
    struct Report: Codable, Sendable, Equatable {
        var helperRestarted: Bool
        var startupRecovery: AdapterStartupRecovery
        var nativeSettingsPreserved: Bool
        var adapterSourceObserved: Bool
        var controlSupport = ChargeCapabilityProbe.ControlSupport.unverified
    }
    private struct ErrorOutput: Encodable { var error: String }

    static func validate(arguments: [String]) throws {
        guard arguments.count == 2, arguments[1] == flag else { throw Failure.invalidArguments }
    }

    /// The disconnect is expected, but only a different instance's positive recovery receipt establishes success.
    static func collect(requirement: String,
                        status: @Sendable (String) async throws -> HelperStatus = {
                            try await HelperConnection(timeout: .seconds(1)).request(requirement: $0)
                        },
                        terminate: @Sendable (String) async throws -> HelperStatus = {
                            try await HelperConnection().verifyAdapterRestart(requirement: $0)
                        },
                        adapterSource: @Sendable () async -> Bool = {
                            let report = await AdapterPowerDiagnostics.read()
                            return report.powerSource.availability == .available && report.powerSource.source == .adapter
                        },
                        pause: @Sendable () async throws -> Void = {
                            try await Task.sleep(for: .milliseconds(500), clock: .suspending)
                        }) async throws -> Report {
        let before = try await status(requirement).validated()
        guard before.adapterRestartVerificationAvailable == true,
              before.adapterRestartVerificationVersion == HelperContract.adapterRestartVerificationVersion,
              let instance = before.helperInstance else { throw Failure.helperUpdateRequired }
        guard before.controlState == .notControlling,
              case let .available(original) = before.nativeChargeLimit else { throw Failure.unsafeInitialState }
        try Task.checkCancellation()
        do {
            _ = try await terminate(requirement)
            throw Failure.unexpectedReply
        } catch let error as HelperConnectionError {
            guard error == .connectionFailed || error == .timedOut else { throw error }
        }
        let clock = SuspendingClock()
        let end = clock.now.advanced(by: .seconds(15))
        // Attempt count also bounds injected/no-delay tests. No mutating selector occurs in this loop.
        for _ in 0..<24 {
            try Task.checkCancellation()
            guard clock.now < end else { break }
            if let after = try? await status(requirement).validated(), after.helperInstance != instance,
               after.helperInstance != nil {
                guard let recovery = after.adapterStartupRecovery, recovery.checkpointFound,
                      recovery.initialByte == 8, recovery.restoredByte == 0,
                      after.controlState == .notControlling,
                      case let .available(restored) = after.nativeChargeLimit,
                      original == restored else { throw Failure.recoveryNotConfirmed }
                if await adapterSource() {
                    return .init(helperRestarted: true, startupRecovery: recovery,
                                 nativeSettingsPreserved: true, adapterSourceObserved: true)
                }
            }
            try await pause()
        }
        throw Failure.restartNotObserved
    }

    @concurrent static func run() async -> Int32 {
        do {
            try validate(arguments: ProcessInfo.processInfo.arguments)
            guard let identity = await HelperSystem.signingIdentity(),
                  let requirement = HelperSigning.requirement(for: .helper, identity: identity) else {
                throw HelperConnectionError.signingUnavailable
            }
            guard await HelperSystem.registration() == .enabled else { throw Failure.helperNotEnabled }
            let report = try await collect(requirement: requirement)
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
