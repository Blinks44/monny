import Foundation

/// A one-shot, unprivileged report. No helper installation, SMC, sampler or history is involved.
nonisolated enum AdapterPowerDiagnosticCommand {
    static let flag = "--adapter-power-diagnostics"
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains(flag) }

    @concurrent static func run() async -> Int32 {
        do {
            let report = await AdapterPowerDiagnostics.read()
            try FileHandle.standardOutput.write(contentsOf: encode(report))
            return EXIT_SUCCESS
        } catch {
            // stdout may itself be unavailable (e.g. a closed pipe); do not start another operation.
            return EXIT_FAILURE
        }
    }

    static func encode(_ report: AdapterPowerDiagnostics) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(report) + Data([10])
    }
}
