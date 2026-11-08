import Foundation
import SQLite3

/// Small, bounded, read-only queries of a tool's own SQLite store. Never creates sidecars.
nonisolated enum AILocalDatabase {
    static func rows(_ file: URL, sql: String, limit: Int = 4) throws -> [[String]] {
        guard FileManager.default.fileExists(atPath: file.path) else { throw AIUsageProblem.signedOut }
        let hasWAL = FileManager.default.fileExists(atPath: file.path + "-wal")
        // Opening WAL mode without its existing shared-memory file can create a sidecar.
        guard !hasWAL || FileManager.default.fileExists(atPath: file.path + "-shm") else {
            throw AIUsageProblem.unavailable(retryAfter: nil)
        }
        let name = hasWAL ? file.path : file.absoluteString + "?immutable=1"
        var database: OpaquePointer?
        guard sqlite3_open_v2(name, &database, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) == SQLITE_OK else {
            if let database { sqlite3_close(database) }
            throw AIUsageProblem.unavailable(retryAfter: nil)
        }
        defer { sqlite3_close(database) }
        sqlite3_busy_timeout(database, 250)
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw AIUsageProblem.unavailable(retryAfter: nil)
        }
        defer { sqlite3_finalize(statement) }
        var result: [[String]] = []
        while true {
            let status = sqlite3_step(statement)
            if status == SQLITE_DONE { return result }
            guard status == SQLITE_ROW, result.count < limit else { throw AIUsageProblem.unavailable(retryAfter: nil) }
            var row: [String] = []
            for column in 0..<sqlite3_column_count(statement) {
                let count = Int(sqlite3_column_bytes(statement, column))
                guard count <= 256 * 1_024, let bytes = sqlite3_column_text(statement, column),
                    let text = String(data: Data(bytes: bytes, count: count), encoding: .utf8)
                else { throw AIUsageProblem.unavailable(retryAfter: nil) }
                row.append(text)
            }
            result.append(row)
        }
    }
}
