import Foundation

/// Explicit engineering entry point only. Production's absent backend refuses before the new selector.
nonisolated enum AdapterVerificationCommand {
    static let flag = "--verify-adapter-isolation"
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains(flag) }
    enum Failure: Error, Sendable, Equatable {
        case invalidArguments, helperNotEnabled, helperUpdateRequired, verificationNotEnabled
    }
    private struct ErrorOutput: Encodable { var error: String }

    static func validate(arguments: [String]) throws {
        guard arguments.count == 2, arguments[1] == flag else { throw Failure.invalidArguments }
    }

    /// One handshake and one attempt; there is no retry on failure, timeout or disconnect.
    static func collect(requirement: String,
                        status: @Sendable (String) async throws -> HelperStatus = {
                            try await HelperConnection().request(requirement: $0)
                        },
                        verify: @Sendable (String) async throws -> HelperStatus = {
                            try await HelperConnection().verifyAdapterIsolation(requirement: $0)
                        }) async throws -> HelperStatus {
        let handshake = try await status(requirement).validated()
        guard let advertised = handshake.adapterVerificationAvailable else { throw Failure.helperUpdateRequired }
        guard advertised else { throw Failure.verificationNotEnabled }
        guard handshake.adapterVerificationVersion == HelperContract.adapterVerificationVersion else {
            throw Failure.helperUpdateRequired
        }
        let response = try await verify(requirement).validated()
        guard response.adapterVerification != nil else { throw HelperConnectionError.invalidReply }
        return response
    }

    @concurrent static func run() async -> Int32 {
        do {
            try validate(arguments: ProcessInfo.processInfo.arguments)
            guard let identity = await HelperSystem.signingIdentity(),
                  let requirement = HelperSigning.requirement(for: .helper, identity: identity) else {
                throw HelperConnectionError.signingUnavailable
            }
            guard await HelperSystem.registration() == .enabled else { throw Failure.helperNotEnabled }
            let response = try await collect(requirement: requirement)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try FileHandle.standardOutput.write(contentsOf: encoder.encode(response) + Data([10]))
            guard let report = response.adapterVerification else { return EXIT_FAILURE }
            // Register restoration alone must never produce the command's success exit.
            return report.isSuccessful ? EXIT_SUCCESS : EXIT_FAILURE
        } catch {
            if let data = try? JSONEncoder().encode(ErrorOutput(error: String(describing: error))) {
                try? FileHandle.standardOutput.write(contentsOf: data + Data([10]))
            }
            return EXIT_FAILURE
        }
    }
}
