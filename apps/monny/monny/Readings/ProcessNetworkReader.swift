import Foundation

/// Uses the system utility rather than linking the private NetworkStatistics framework.
/// Two samples in one invocation retain closed-connection deltas. The first sample is a
/// baseline, never a rate; the second covers nettop's one-second interval, in bytes/second.
nonisolated enum ProcessNetworkReader {
    static func read() async -> [Int32: NetworkRates]? {
        guard let output = await LocalCommand.run(URL(filePath: "/usr/bin/nettop"), arguments: [
            "-n", "-P", "-L", "2", "-s", "1", "-d", "-x", "-J", "bytes_in,bytes_out", "-t", "external",
        ], timeout: .seconds(3)), output.status == 0 else { return nil }
        return parse(output.stdout)
    }

    /// Header lookup tolerates column reordering; reject malformed samples rather than show zero.
    static func parse(_ csv: String) -> [Int32: NetworkRates]? {
        var sample = 0
        var downloadColumn: Int?, uploadColumn: Int?
        var result: [Int32: NetworkRates] = [:]
        for line in csv.split(whereSeparator: \.isNewline) {
            let columns = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            if columns.first == "", let down = columns.firstIndex(of: "bytes_in"), let up = columns.firstIndex(of: "bytes_out") {
                sample += 1
                downloadColumn = down
                uploadColumn = up
                result = [:]
                continue
            }
            guard sample == 2 else { continue }
            guard let down = downloadColumn, let up = uploadColumn, columns.count > max(down, up),
                  let name = columns.first, let suffix = name.split(separator: ".").last,
                  let pid = Int32(suffix), pid >= 0,
                  let received = UInt64(columns[down]), let sent = UInt64(columns[up]), result[pid] == nil else { return nil }
            if pid == 0 { continue }
            result[pid] = NetworkRates(download: Double(received), upload: Double(sent))
        }
        return sample == 2 ? result : nil
    }
}
