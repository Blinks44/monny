import Foundation

/// Prepared operations only. The shipped daemon does not construct or install this backend.
nonisolated enum NativeChargeLimitBackend {
    enum Failure: Error { case unavailable, invalidTarget, writeFailed }

    /// These synchronous operations must be owned by the off-main journal-backed executor.
    static var operations: NativeChargeLimitTransaction.Operations {
        .init(read: {
            guard case .available(let snapshot) = NativeChargeLimitReader.decode(MonnyReadNativeChargeLimit()) else {
                throw Failure.unavailable
            }
            return snapshot
        }, setLimit: { limit in
            guard (80...100).contains(limit) else { throw Failure.invalidTarget }
            guard MonnySetNativeChargeLimit(UInt8(limit)) == .available else { throw Failure.writeFailed }
        }, setEnabled: { enabled in
            guard MonnySetNativeChargeLimitEnabled(enabled) == .available else { throw Failure.writeFailed }
        })
    }
}
