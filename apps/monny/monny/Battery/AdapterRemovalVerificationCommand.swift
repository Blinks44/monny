import Foundation

/// Explicit one-shot removal experiment. No registration, mutation retry or post-removal XPC.
nonisolated enum AdapterRemovalVerificationCommand {
    static let flag = "--verify-adapter-removal"
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains(flag) }
    enum Failure: Error, Sendable, Equatable {
        case invalidArguments, helperNotEnabled, byteUnavailable, preparationExpired
        case recoveryNotConfirmed, removalNotConfirmed
    }
    struct Report: Codable, Sendable, Equatable {
        var adapterRestoredBeforeRemoval = true
        var nativeSettingsPreservedBeforeRemoval = true
        var helperUnregistered = true
        var restoredByte: UInt8 = 0
        var adapterSourceObserved = true
        var controlSupport = ChargeCapabilityProbe.ControlSupport.unverified
    }
    private struct ErrorOutput: Encodable { var error: String }

    static func validate(arguments: [String]) throws {
        guard arguments.count == 2, arguments[1] == flag else { throw Failure.invalidArguments }
    }

    /// Never open XPC after unregister: the remaining checks are ordinary local read-only APIs.
    static func collect(requirement: String, session: AdapterLifecycleSession,
                        acknowledge: @Sendable () async throws -> HelperStatus,
                        unregister: @Sendable () async throws -> Void,
                        registration: @Sendable () async -> HelperRegistration,
                        readByte: @Sendable () async -> UInt8?,
                        adapterSource: @Sendable () async -> Bool,
                        now: @Sendable () -> SuspendingClock.Instant = { SuspendingClock().now },
                        pause: @Sendable () async throws -> Void = {
                            try await Task.sleep(for: .milliseconds(500), clock: .suspending)
                        }) async throws -> Report {
        do {
            guard await registration() == .enabled else { throw Failure.helperNotEnabled }
            _ = try await session.open(requirement: requirement)
            guard await readByte() == 0 else { throw Failure.byteUnavailable }
            try Task.checkCancellation()
            let start = now()
            let preparation = try await session.prepare()
            try Task.checkCancellation()
            guard start.duration(to: now()) < .seconds(2) else { throw Failure.preparationExpired }
            let ack = try await acknowledge().validated()
            guard ack.helperInstance == preparation.helperInstance,
                  ack.controlState == .notControlling,
                  ack.nativeChargeLimit == .available(preparation.nativeLimit),
                  let lifecycle = ack.lifecycleDiagnostics,
                  lifecycle.removalPreparationCount == preparation.lifecycleBefore.removalPreparationCount + 1,
                  lifecycle.lastRemovalPreparation == .adapterRestored,
                  lifecycle.sleepCount == preparation.lifecycleBefore.sleepCount,
                  lifecycle.wakeCount == preparation.lifecycleBefore.wakeCount else { throw Failure.recoveryNotConfirmed }
            guard await readByte() == 0 else { throw Failure.recoveryNotConfirmed }
            try Task.checkCancellation()
            guard await registration() == .enabled else { throw Failure.helperNotEnabled }
            try Task.checkCancellation()
            try await unregister()
            // The restored helper is now removal-gated. Closing cannot replay the preparation.
            await session.close()
            let end = now().advanced(by: .seconds(15))
            for _ in 0..<24 {
                try Task.checkCancellation()
                guard now() < end else { break }
                let state = await registration()
                if state == .notRegistered || state == .notFound {
                    guard await readByte() == 0 else { throw Failure.recoveryNotConfirmed }
                    if await adapterSource() { return Report() }
                }
                try await pause()
            }
            throw Failure.removalNotConfirmed
        } catch {
            // Invalidation restores a still-owned preparation. Never unregister/re-register as error recovery.
            await session.close()
            throw error
        }
    }

    @concurrent private static func readByte() async -> UInt8? {
        guard let connection = SMCConnection(),
              case let .readable(metadata, value) = connection.inspect("CHIE"),
              metadata.type == "hex_", metadata.size == 1, metadata.attributes == 0xD4,
              value.type == "hex_", value.bytes.count == 1 else { return nil }
        return value.bytes.first
    }

    @concurrent static func run() async -> Int32 {
        do {
            try validate(arguments: ProcessInfo.processInfo.arguments)
            guard let identity = await HelperSystem.signingIdentity(),
                  let requirement = HelperSigning.requirement(for: .helper, identity: identity) else {
                throw HelperConnectionError.signingUnavailable
            }
            let report = try await collect(requirement: requirement, session: AdapterLifecycleSession(purpose: .removal),
                acknowledge: { try await HelperConnection().request(requirement: requirement, forRemoval: true) },
                unregister: { try await HelperSystem.unregister() }, registration: { await HelperSystem.registration() },
                readByte: { await readByte() }, adapterSource: {
                    let power = await AdapterPowerDiagnostics.read()
                    return power.powerSource.availability == .available && power.powerSource.source == .adapter
                })
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
