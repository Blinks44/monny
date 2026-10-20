import Foundation

/// The adapter is still isolated in this reply. This is never a notControlling status acknowledgement.
nonisolated struct AdapterLifecyclePreparation: Codable, Sendable, Equatable {
    var version = 1
    var helperInstance: UUID
    var nativeLimit: NativeChargeLimit.Snapshot
    var lifecycleBefore: HelperLifecycleDiagnostics
    var appliedByte: UInt8 = 8
    var isValid: Bool { version == 1 && nativeLimit.isValid && lifecycleBefore.isValid && appliedByte == 8 }

    static func decode(_ data: Data) throws -> Self {
        guard data.count <= 4096, let value = try? JSONDecoder().decode(Self.self, from: data), value.isValid else {
            throw HelperConnectionError.invalidReply
        }
        return value
    }
}
