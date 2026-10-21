import Foundation
import IOKit

/// A raw SMC value: the four-character data type and its bytes as the SMC returns them.
nonisolated struct SMCValue: Sendable, Equatable {
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

/// Read-only connection to the `AppleSMC` user client. Any unprivileged process may open it;
/// the call layout below is undocumented but stable across Apple silicon (see research).
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

    /// `nil` when the key does not exist on this Mac or the read fails.
    func read(_ key: String) -> SMCValue? {
        let code = Self.fourCC(key)
        guard let info = keyInfo(code) else { return nil }
        var input = KeyData()
        input.key = code
        input.keyInfo.dataSize = info.dataSize
        input.command = Command.readBytes
        guard let output = call(input) else { return nil }
        let bytes = withUnsafeBytes(of: output.bytes) { Array($0.prefix(Int(min(info.dataSize, 32)))) }
        return SMCValue(type: Self.string(info.dataType), bytes: bytes)
    }

    private func keyInfo(_ code: UInt32) -> KeyInfo? {
        if let cached = infoCache[code] { return cached }
        var input = KeyData()
        input.key = code
        input.command = Command.readKeyInfo
        guard let output = call(input) else { return nil }
        infoCache[code] = output.keyInfo
        return output.keyInfo
    }

    private func call(_ input: KeyData) -> KeyData? {
        var input = input
        var output = KeyData()
        var size = MemoryLayout<KeyData>.stride
        let result = IOConnectCallStructMethod(connection, Command.kernelIndex, &input, MemoryLayout<KeyData>.stride, &output, &size)
        // `output.result` is the SMC's own status; non-zero means the key does not exist.
        guard result == KERN_SUCCESS, size == MemoryLayout<KeyData>.stride, output.result == 0 else { return nil }
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
