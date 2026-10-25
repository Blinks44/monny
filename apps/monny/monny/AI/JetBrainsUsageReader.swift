import Foundation

/// Bounded local-only reads. Called from AIUsageReader's actor, never from a view or main actor.
nonisolated enum JetBrainsUsageReader {
    static let logByteLimit = 4 * 1_024 * 1_024
    static let xmlByteLimit = 256 * 1_024

    struct Source: Sendable {
        let name: String
        let xml: URL
        let log: URL
        let xmlDate: Date?
        let logDate: Date?
    }

    /// Directory discovery alone: never reads quota, log content or credentials.
    static func sources(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [Source] {
        let prefixes = ["IntelliJIdea", "IdeaIC", "PyCharm", "WebStorm", "GoLand", "CLion", "DataGrip", "RubyMine",
                        "Rider", "PhpStorm", "RustRover", "AndroidStudio", "Fleet", "Aqua", "DataSpell", "AppCode"]
        var result: [Source] = []
        for vendor in ["JetBrains", "Google"] {
            let root = home.appending(path: "Library/Application Support/\(vendor)")
            let folders = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey],
                                                                        options: [.skipsHiddenFiles])) ?? []
            for folder in folders.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                guard result.count < 64, (try? folder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                      let prefix = prefixes.first(where: { folder.lastPathComponent.hasPrefix($0) }) else { continue }
                let version = String(folder.lastPathComponent.dropFirst(prefix.count))
                guard version.count <= 32, version.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || ".- ".contains($0)) }) else { continue }
                let xml = folder.appending(path: "options/AIAssistantQuotaManager2.xml")
                let log = home.appending(path: "Library/Logs/\(vendor)/\(folder.lastPathComponent)/idea.log")
                result.append(Source(name: version.isEmpty ? prefix : "\(prefix) \(version)", xml: xml, log: log,
                                     xmlDate: modified(xml), logDate: modified(log)))
            }
        }
        return result
    }

    static func read(home: URL = FileManager.default.homeDirectoryForCurrentUser, now: Date = .now) -> Result<AIUsage, AIUsageProblem> {
        read(sources: sources(home: home), now: now)
    }

    static func read(sources: [Source], now: Date) -> Result<AIUsage, AIUsageProblem> {
        // Never replace the selected installation's snapshot with another IDE's account.
        let xmlSource = sources.filter { $0.xmlDate != nil }.max { ($0.xmlDate ?? .distantPast) < ($1.xmlDate ?? .distantPast) }
        let source = xmlSource ?? sources.filter { $0.logDate != nil }.max { ($0.logDate ?? .distantPast) < ($1.logDate ?? .distantPast) }
        guard let source else { return .failure(.localDataMissing) }
        let xml = source.xmlDate.flatMap { date in
            boundedFile(source.xml, limit: xmlByteLimit).flatMap { JetBrainsQuota.xml($0, date: date) }
        }
        let content = logTail(source.log)
        let log = content.flatMap(JetBrainsQuotaLog.latest(in:))
        let selected: JetBrainsQuota? = if let xml {
            log.flatMap { $0.date > xml.date ? $0 : nil } ?? xml
        } else { log }
        guard let selected else {
            if source.xmlDate == nil, let content,
               !content.contains(JetBrainsQuotaLog.quotaMarker), !content.contains(JetBrainsQuotaLog.junieMarker) {
                return .failure(.localDataMissing)
            }
            return .failure(.unavailable(retryAfter: nil))
        }
        guard selected.date.timeIntervalSince(now) <= 60 else { return .failure(.unavailable(retryAfter: nil)) }
        return .success(selected.usage(source: source.name))
    }

    private static func modified(_ url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private static func boundedFile(_ url: URL, limit: Int) -> Data? {
        guard let file = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? file.close() }
        guard let size = try? file.seekToEnd(), size > 0, size <= UInt64(limit),
              (try? file.seek(toOffset: 0)) != nil,
              let data = try? file.read(upToCount: Int(size)), data.count == Int(size) else { return nil }
        return data
    }

    /// Captures the end offset before reading so a growing log cannot produce unbounded work.
    static func logTail(_ url: URL, limit: Int = logByteLimit) -> String? {
        guard limit > 0, let file = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? file.close() }
        guard let end = try? file.seekToEnd(), end > 0 else { return nil }
        let count = Int(min(end, UInt64(limit)))
        let start = end - UInt64(count)
        guard (try? file.seek(toOffset: start)) != nil,
              let data = try? file.read(upToCount: count), data.count == count,
              data.last == UInt8(ascii: "\n") else { return nil }
        if start > 0 {
            guard let newline = data.firstIndex(of: UInt8(ascii: "\n")) else { return nil }
            return String(data: data[data.index(after: newline)...], encoding: .utf8)
        }
        return String(data: data, encoding: .utf8)
    }
}
