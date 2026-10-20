import Foundation

/// Developer diagnostic: machine-readable output only, no registration, monitoring or writes.
nonisolated enum BatteryDiagnosticCommand {
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains("--battery-diagnostics") }
    enum Failure: Error, Sendable, Equatable { case helperNotEnabled, helperUpdateRequired }
    private struct ErrorOutput: Encodable { var error: String }

    @concurrent static func run() async -> Int32 {
        do {
            guard let identity = await HelperSystem.signingIdentity(),
                  let requirement = HelperSigning.requirement(for: .helper, identity: identity) else {
                throw HelperConnectionError.signingUnavailable
            }
            guard await HelperSystem.registration() == .enabled else { throw Failure.helperNotEnabled }
            let response = try await collect(requirement: requirement)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try FileHandle.standardOutput.write(contentsOf: encoder.encode(response))
            try FileHandle.standardOutput.write(contentsOf: Data([10]))
            return EXIT_SUCCESS
        } catch {
            if let data = try? JSONEncoder().encode(ErrorOutput(error: String(describing: error))) {
                try? FileHandle.standardOutput.write(contentsOf: data + Data([10]))
            }
            return EXIT_FAILURE
        }
    }

    /// The old status selector is checked first; never send a new selector to a legacy helper.
    static func collect(requirement: String,
                        status: @Sendable (String) async throws -> HelperStatus = {
                            try await HelperConnection().request(requirement: $0)
                        },
                        diagnostics: @Sendable (String) async throws -> HelperStatus = {
                            try await HelperConnection().diagnose(requirement: $0)
                        }) async throws -> HelperStatus {
        let handshake = try await status(requirement).validated()
        guard handshake.chargeDiagnosticsAvailable == true, handshake.nativeLimitDiagnosticsAvailable == true else { throw Failure.helperUpdateRequired }
        let response = try await diagnostics(requirement).validated()
        guard response.chargeDiagnostics != nil, response.nativeChargeLimit != nil else { throw HelperConnectionError.invalidReply }
        return response
    }
}
