import Foundation
import Darwin

/// Standalone subprocess fixture. All hardware values live in its private temporary directory.
@main struct AdapterRecoveryProcess {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else { throw CocoaError(.fileReadInvalidFileName) }
        let action = CommandLine.arguments[1]
        let directory = URL(filePath: CommandLine.arguments[2], directoryHint: .isDirectory)
        let byteFile = directory.appending(path: "injected-byte")
        let nativeSentinel = directory.appending(path: "injected-native")
        let native = NativeChargeLimit.Snapshot(availableLimits: [80,85,90,95,100], configuredLimit: 85, enabled: true)
        let journal = try ChargeRecoveryFileJournal(privateDirectory: directory, record: .adapterVerification)
        let readByte: @Sendable () throws -> UInt8 = {
            guard let value = UInt8(try String(contentsOf: byteFile, encoding: .utf8)) else { throw CocoaError(.fileReadCorruptFile) }
            return value
        }
        let operations = AdapterVerificationTransaction.Operations(readCHIE: {
            .readable(metadata: .init(type: "hex_", size: 1, attributes: 0xD4),
                      value: .init(type: "hex_", bytes: [try readByte()]))
        }, readEnvironment: {
            .init(nativeLimit: native, nativeSessionActive: false, isAdapterConnected: true,
                  source: .adapter, isCharging: false, level: 0.85)
        }, setAdapterIsolated: { isolated in
            try Data((isolated ? "8" : "0").utf8).write(to: byteFile, options: .atomic)
        })
        if action == "crash" {
            try Data("0".utf8).write(to: byteFile)
            try Data("native-unchanged".utf8).write(to: nativeSentinel)
            var transaction = try AdapterVerificationTransaction(operations: operations, journal: journal.journal)
            var report = AdapterBytePulseReport(outcome: .unavailable)
            try transaction.beginByteObservation(observe: { _ in
                .init(reading: .init(nativeLimit: native, nativeSessionActive: false, source: .adapter,
                    isCharging: false, level: 0.85, rawExternalConnected: true, externalConnected: true, isLidClosed: false))
            }, report: &report)
            guard report.appliedByte == 8, try readByte() == 8, try journal.journal.load() != nil else {
                throw CocoaError(.fileWriteUnknown)
            }
            _exit(75) // Deliberately skip all in-process cleanup; no real SMC access.
        }
        guard action == "recover" || action == "recoverAgain" else { throw CocoaError(.fileReadInvalidFileName) }
        var recovered = try AdapterVerificationTransaction(operations: operations, journal: journal.journal)
        let expected: AdapterVerificationTransaction.State = action == "recover" ? .restorationRequired : .idle
        guard recovered.state == expected else { throw CocoaError(.fileReadCorruptFile) }
        try recovered.restore()
        guard try readByte() == 0, try journal.journal.load() == nil,
              try String(contentsOf: nativeSentinel, encoding: .utf8) == "native-unchanged" else {
            throw CocoaError(.fileReadCorruptFile)
        }
        print(action + ": injected byte zero, checkpoint absent, native sentinel unchanged")
    }
}
