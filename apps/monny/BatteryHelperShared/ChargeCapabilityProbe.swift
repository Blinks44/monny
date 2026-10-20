import Foundation

/// Diagnostic evidence only. Neither readable values nor raw attribute bits establish write support.
nonisolated struct ChargeCapabilityProbe: Codable, Sendable, Equatable {
    struct Entry: Codable, Sendable, Equatable {
        var key: String
        var inspection: SMCKeyInspection
    }

    enum ControlSupport: String, Codable, Sendable { case unverified }
    var entries: [Entry]
    var controlSupport = ControlSupport.unverified

    /// Fixed allowlist from reviewed compatibility reports, not a scan of arbitrary SMC keys.
    static let candidateKeys = ["CH0B", "CH0C", "CHTE", "bfF0", "bfD0", "bfE0"]

    /// Explicit diagnostic call only; never part of a view render or repeated sampler pass.
    @concurrent static func read() async -> Self {
        guard let connection = SMCConnection() else {
            return inspect { _ in .unavailable(.connectionUnavailable) }
        }
        return inspect(using: connection.inspect)
    }

    /// Wire validation is independent of any inferred hardware capability.
    var isValid: Bool {
        guard entries.map(\.key) == Self.candidateKeys else { return false }
        return entries.allSatisfy { entry in
            guard case let .readable(metadata, value) = entry.inspection else { return true }
            return metadata.isValid && value.type == metadata.type && value.bytes.count == Int(metadata.size)
        }
    }

    /// Injection keeps partial failures and firmware placeholders testable without real SMC access.
    static func inspect(using read: (String) -> SMCKeyInspection) -> Self {
        Self(entries: candidateKeys.map { Entry(key: $0, inspection: read($0)) })
    }
}
