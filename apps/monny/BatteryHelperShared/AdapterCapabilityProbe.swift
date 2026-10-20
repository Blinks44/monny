import Foundation

/// Read access is diagnostic evidence only, never permission to isolate adapter power.
nonisolated struct AdapterCapabilityProbe: Codable, Sendable, Equatable {
    var entries: [ChargeCapabilityProbe.Entry]
    var controlSupport = ChargeCapabilityProbe.ControlSupport.unverified

    static let candidateKeys = ["CHIE", "CH0I", "CH0J"]

    @concurrent static func read() async -> Self {
        guard let connection = SMCConnection() else {
            return inspect { _ in .unavailable(.connectionUnavailable) }
        }
        return inspect(using: connection.inspect)
    }

    static func inspect(using read: (String) -> SMCKeyInspection) -> Self {
        Self(entries: candidateKeys.map { .init(key: $0, inspection: read($0)) })
    }

    var isValid: Bool {
        guard entries.map(\.key) == Self.candidateKeys else { return false }
        return entries.allSatisfy { entry in
            guard case let .readable(metadata, value) = entry.inspection else { return true }
            return metadata.isValid && value.type == metadata.type && value.bytes.count == Int(metadata.size)
        }
    }
}
