import Foundation

/// Fixed semantic admission shared with tests; this type performs no I/O.
nonisolated enum AdapterIsolationCommand {
    /// nil means restoration is already acknowledged by this fresh read.
    static func byte(isolated: Bool, inspection: SMCKeyInspection) throws -> UInt8? {
        let current = try value(inspection)
        if isolated {
            guard current == 0 else { throw AdapterVerificationTransaction.Failure.busy }
            return 8
        }
        return current == 0 ? nil : 0
    }

    static func value(_ inspection: SMCKeyInspection) throws -> UInt8 {
        guard case let .readable(metadata, value) = inspection else {
            throw AdapterVerificationTransaction.Failure.unavailable
        }
        guard metadata.type == "hex_", metadata.size == 1, metadata.attributes == 0xD4,
              value.type == "hex_", value.bytes.count == 1 else {
            throw AdapterVerificationTransaction.Failure.unsupportedSignature
        }
        let byte = value.bytes[0]
        guard byte == 0 || byte == 8 else { throw AdapterVerificationTransaction.Failure.unknownAdapterValue }
        return byte
    }
}
