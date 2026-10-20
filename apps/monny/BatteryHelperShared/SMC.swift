import Foundation
import IOKit

/// A raw SMC value: the four-character data type and its bytes as the SMC returns them.
nonisolated struct SMCValue: Codable, Sendable, Equatable {
    var type: String
    var bytes: [UInt8]

    /// The value as a number, or `nil` for types Monny does not read.
    /// `flt ` is a little-endian Float on Apple silicon; the fixed-point and integer types are big-endian.
    var number: Double? {
        switch type {
        case "flt " where bytes.count == 4:
            Double(Float(bitPattern: bytes.reversed().reduce(0) { $0 << 8 | UInt32($1) }))
        case "sp78" where bytes.count == 2:
            Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))) / 256
        case "fpe2" where bytes.count == 2:
            Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1])) / 4
        case "ui8 " where bytes.count == 1,
             "ui16" where bytes.count == 2,
             "ui32" where bytes.count == 4:
            Double(bytes.reduce(UInt32(0)) { $0 << 8 | UInt32($1) })
        default:
            nil
        }
    }
}

/// Raw metadata only: attributes are not treated as permission to write a key.
nonisolated struct SMCKeyMetadata: Codable, Sendable, Equatable {
    var type: String
    var size: UInt32
    var attributes: UInt8

    var isValid: Bool {
        (1...32).contains(size) && type.utf8.count == 4
            && type.utf8.allSatisfy { (32...126).contains($0) }
    }
}

nonisolated enum SMCReadFailure: Error, Codable, Sendable, Equatable {
    case connectionUnavailable, invalidKey, invalidMetadata, invalidResponse
    case kernel(Int32), smc(UInt8)
}

nonisolated enum SMCKeyInspection: Codable, Sendable, Equatable {
    case readable(metadata: SMCKeyMetadata, value: SMCValue)
    case unavailable(SMCReadFailure, metadata: SMCKeyMetadata? = nil)
}

/// Read-only connection to the `AppleSMC` user client, opened without privilege escalation.
/// Access varies by key/firmware; the undocumented call layout is described in research.
nonisolated final class SMCConnection {
    private let connection: io_connect_t
    private var infoCache: [UInt32: KeyInfo] = [:]

    init?() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var connection: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, 0, &connection) == KERN_SUCCESS else { return nil }
        self.connection = connection
    }

    deinit { IOServiceClose(connection) }

    /// Existing sensor API: unavailable/failed readings stay nil.
    func read(_ key: String) -> SMCValue? {
        guard case let .readable(_, value) = inspect(key) else { return nil }
        return value
    }

    /// Inspect metadata and read bytes only. No SMC write command is implemented.
    func inspect(_ key: String) -> SMCKeyInspection {
        guard key.utf8.count == 4, key.utf8.allSatisfy({ (32...126).contains($0) }) else {
            return .unavailable(.invalidKey)
        }
        let code = Self.fourCC(key)
        let info: KeyInfo
        do { info = try keyInfo(code) }
        catch { return .unavailable(error) }
        let metadata = SMCKeyMetadata(type: Self.string(info.dataType), size: info.dataSize, attributes: info.attributes)
        guard metadata.isValid else { return .unavailable(.invalidMetadata, metadata: metadata) }
        var input = KeyData()
        input.key = code
        input.keyInfo.dataSize = info.dataSize
        input.command = Command.readBytes
        do {
            let output = try call(input)
            let bytes = withUnsafeBytes(of: output.bytes) { Array($0.prefix(Int(info.dataSize))) }
            return .readable(metadata: metadata, value: SMCValue(type: metadata.type, bytes: bytes))
        } catch {
            return .unavailable(error, metadata: metadata)
        }
    }

    private func keyInfo(_ code: UInt32) throws(SMCReadFailure) -> KeyInfo {
        if let cached = infoCache[code] { return cached }
        var input = KeyData()
        input.key = code
        input.command = Command.readKeyInfo
        let output = try call(input)
        infoCache[code] = output.keyInfo
        return output.keyInfo
    }

    private func call(_ input: KeyData) throws(SMCReadFailure) -> KeyData {
        var input = input
        var output = KeyData()
        var size = MemoryLayout<KeyData>.stride
        let result = IOConnectCallStructMethod(connection, Command.kernelIndex, &input, MemoryLayout<KeyData>.stride, &output, &size)
        guard result == KERN_SUCCESS else { throw .kernel(result) }
        guard size == MemoryLayout<KeyData>.stride else { throw .invalidResponse }
        // Preserve the SMC's status; non-zero can mean missing, gated or another rejection.
        guard output.result == 0 else { throw .smc(output.result) }
        return output
    }

    static func fourCC(_ key: String) -> UInt32 { key.utf8.prefix(4).reduce(0) { $0 << 8 | UInt32($1) } }

    static func string(_ code: UInt32) -> String {
        String(decoding: [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: code >> $0) }, as: UTF8.self)
    }

    private enum Command {
        static let kernelIndex: UInt32 = 2
        static let readBytes: UInt8 = 5
        static let readKeyInfo: UInt8 = 9
    }

    /// Mirrors the kernel's `SMCParamStruct` (80 bytes). Explicit padding keeps the C layout,
    /// because Swift would otherwise pack `result` right after the 9-byte `KeyInfo`.
    private struct KeyInfo {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var attributes: UInt8 = 0
        var padding: (UInt8, UInt8, UInt8) = (0, 0, 0)
    }

    private struct KeyData {
        var key: UInt32 = 0
        var version: (UInt8, UInt8, UInt8, UInt8, UInt16) = (0, 0, 0, 0, 0)
        var powerLimits: (UInt16, UInt16, UInt32, UInt32, UInt32) = (0, 0, 0, 0, 0)
        var keyInfo = KeyInfo()
        var result: UInt8 = 0
        var status: UInt8 = 0
        var command: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: (UInt64, UInt64, UInt64, UInt64) = (0, 0, 0, 0)
    }
}
