import Foundation

/// Process-local evidence of recovery completed before serving authenticated requests.
nonisolated struct AdapterStartupRecovery: Codable, Sendable, Equatable {
    var checkpointFound: Bool
    var initialByte: UInt8?
    var restoredByte: UInt8?

    var isValid: Bool {
        checkpointFound ? ((initialByte == 0 || initialByte == 8) && restoredByte == 0)
            : (initialByte == nil && restoredByte == nil)
    }
}
