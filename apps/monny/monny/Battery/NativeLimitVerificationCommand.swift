import Foundation

/// Explicit developer-only write check; normal app startup never invokes it.
nonisolated enum NativeLimitVerificationCommand {
    static let flag = "--verify-native-limit"
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains(flag) }
    enum Failure: Error, Sendable, Equatable {
        case invalidArguments, helperNotEnabled, helperUpdateRequired
    }
    private struct ErrorOutput: Encodable { var error: String }

    static func target(in arguments: [String]) throws -> Int {
        guard arguments.count == 3, arguments[1] == flag, let limit = Int(arguments[2]),
              arguments[2] == String(limit), (80...100).contains(limit) else { throw Failure.invalidArguments }
        return limit
    }

    /// A legacy helper is never sent a selector it did not advertise. Never retry a write request.
    static func collect(target: Int, requirement: String,
                        status: @Sendable (String) async throws -> HelperStatus = {
                            try await HelperConnection().request(requirement: $0)
                        },
                        verify: @Sendable (Int, String) async throws -> HelperStatus = {
                            try await HelperConnection().verifyNativeLimit($0, requirement: $1)
                        }) async throws -> HelperStatus {
        guard (80...100).contains(target) else { throw Failure.invalidArguments }
        let handshake = try await status(requirement).validated()
        guard handshake.nativeVerificationAvailable == true else { throw Failure.helperUpdateRequired }
        let response = try await verify(target, requirement).validated()
        guard response.nativeVerification?.target == target else { throw HelperConnectionError.invalidReply }
        return response
    }

    @concurrent static func run() async -> Int32 {
        do {
            let target = try target(in: ProcessInfo.processInfo.arguments)
            guard let identity = await HelperSystem.signingIdentity(),
                  let requirement = HelperSigning.requirement(for: .helper, identity: identity) else {
                throw HelperConnectionError.signingUnavailable
            }
            guard await HelperSystem.registration() == .enabled else { throw Failure.helperNotEnabled }
            let response = try await collect(target: target, requirement: requirement)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try FileHandle.standardOutput.write(contentsOf: encoder.encode(response) + Data([10]))
            return response.nativeVerification?.outcome == .restored ? EXIT_SUCCESS : EXIT_FAILURE
        } catch {
            if let data = try? JSONEncoder().encode(ErrorOutput(error: String(describing: error))) {
                try? FileHandle.standardOutput.write(contentsOf: data + Data([10]))
            }
            return EXIT_FAILURE
        }
    }
}
