import Foundation
import OSLog
import SQLite3

nonisolated private let logger = Logger(subsystem: "blinks44.monny", category: "AIUsage")

/// Reads each tool's own sign-in on this Mac and asks its service for the plan limits
/// ([research](docs/research/ai-usage-limits.md)). Monny never stores, renews or sends the
/// tokens anywhere else; an expired token waits until the tool itself renews it.
actor AIUsageReader {
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpCookieStorage = nil
        return URLSession(configuration: configuration)
    }()

    private static var home: URL { FileManager.default.homeDirectoryForCurrentUser }

    /// Cursor.app's VS Code-style state database, which holds its sign-in.
    private static var cursorDatabase: URL {
        URL.applicationSupportDirectory.appending(path: "Cursor/User/globalStorage/state.vscdb")
    }

    /// Tools that are set up on this Mac, judged by their configuration folders.
    nonisolated static func installedTools() -> [AITool] {
        let fileManager = FileManager.default
        return AITool.allCases.filter { tool in
            let url = switch tool {
            case .claude: home.appending(path: ".claude")
            case .codex: home.appending(path: ".codex")
            case .cursor: cursorDatabase
            case .grok: home.appending(path: ".grok")
            }
            return fileManager.fileExists(atPath: url.path(percentEncoded: false))
        }
    }

    func read(_ tool: AITool, now: Date = .now) async -> Result<AIUsage, AIUsageProblem> {
        switch tool {
        case .claude: await readClaude(now: now)
        case .codex: await readCodex(now: now)
        case .cursor: await readCursor(now: now)
        case .grok: await readGrok(now: now)
        }
    }

    // MARK: Claude Code

    private func readClaude(now: Date) async -> Result<AIUsage, AIUsageProblem> {
        guard let data = await claudeCredentialData(),
              let oauth = try? JSONDecoder().decode(ClaudeCredentials.self, from: data).claudeAiOauth,
              let token = oauth.accessToken, !token.isEmpty else {
            return .failure(await Self.claudeUsesAPIKey() ? .apiKey : .signedOut)
        }
        if let expiresAt = oauth.expiresAt, Date(timeIntervalSince1970: expiresAt / 1_000) <= now { return .failure(.expired) }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // The usage endpoint answers only OAuth clients that name this beta.
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        return await fetch(request, now: now) { data in
            let response = try JSONDecoder().decode(ClaudeUsageResponse.self, from: data)
            return AIUsage(plan: oauth.subscriptionType, windows: response.windows(), date: now)
        }
    }

    /// Claude Code 2 keeps its sign-in in the login Keychain and writes it with `security`, which
    /// is therefore on the item's access list; reading it the same way asks the user nothing, while
    /// a direct Keychain read would ask again after every token renewal. Older versions use a file.
    private func claudeCredentialData() async -> Data? {
        let file = Self.home.appending(path: ".claude/.credentials.json")
        if let data = try? Data(contentsOf: file) { return data }
        return await Self.run("/usr/bin/security", ["find-generic-password", "-s", "Claude Code-credentials", "-w"])
    }

    /// Claude Code keeps an API key login in the Keychain item `Claude Code` (without
    /// `-credentials`), or as `primaryApiKey` in `~/.claude.json` in older versions. Only the
    /// item's existence is checked; the key is not read.
    private static func claudeUsesAPIKey() async -> Bool {
        if let data = try? Data(contentsOf: home.appending(path: ".claude.json")),
           let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           (config["primaryApiKey"] as? String)?.isEmpty == false { return true }
        return await run("/usr/bin/security", ["find-generic-password", "-s", "Claude Code"]) != nil
    }

    // MARK: Codex

    private func readCodex(now: Date) async -> Result<AIUsage, AIUsageProblem> {
        let file = Self.home.appending(path: ".codex/auth.json")
        guard let data = try? Data(contentsOf: file),
              let credentials = try? JSONDecoder().decode(CodexCredentials.self, from: data) else { return .failure(.signedOut) }
        if credentials.usesAPIKey { return .failure(.apiKey) }
        guard let tokens = credentials.tokens, let token = tokens.accessToken, !token.isEmpty else { return .failure(.signedOut) }
        if let expiry = CodexCredentials.expiry(ofJWT: token), expiry <= now { return .failure(.expired) }

        var request = URLRequest(url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let account = tokens.accountID { request.setValue(account, forHTTPHeaderField: "ChatGPT-Account-Id") }
        return await fetch(request, now: now) { data in
            let response = try JSONDecoder().decode(CodexUsageResponse.self, from: data)
            return AIUsage(plan: response.planType, windows: response.windows(), date: now, credits: response.creditsLeft)
        }
    }

    // MARK: Cursor

    /// The token Cursor.app keeps in its state database, sent as the dashboard's session cookie,
    /// `WorkosCursorSessionToken=<user ID>::<token>`.
    private func readCursor(now: Date) async -> Result<AIUsage, AIUsageProblem> {
        guard let token = Self.cursorToken(), let claims = JWT.claims(of: token),
              let subject = claims["sub"] as? String,
              let userID = subject.split(separator: "|").last.map(String.init),
              userID.allSatisfy({ $0.isLetter || $0.isNumber || "._-".contains($0) }) else { return .failure(.signedOut) }
        if let exp = claims["exp"] as? Double, Date(timeIntervalSince1970: exp) <= now { return .failure(.expired) }

        var request = URLRequest(url: URL(string: "https://cursor.com/api/usage-summary")!)
        request.setValue("WorkosCursorSessionToken=\(userID)%3A%3A\(token)", forHTTPHeaderField: "Cookie")
        return await fetch(request, now: now) { data in
            let response = try JSONDecoder().decode(CursorUsageResponse.self, from: data)
            return AIUsage(plan: response.membershipType, windows: response.windows(), date: now)
        }
    }

    /// Reads `cursorAuth/accessToken` read-only. Without write-ahead log files the database is
    /// opened immutable, so SQLite creates nothing in Cursor's folder.
    static func cursorToken(at database: URL = cursorDatabase) -> String? {
        let path = database.path(percentEncoded: false)
        let hasLog = FileManager.default.fileExists(atPath: path + "-wal")
        let name = hasLog ? path : database.absoluteString + "?immutable=1"
        var db: OpaquePointer?
        guard sqlite3_open_v2(name, &db, SQLITE_OPEN_READONLY | (hasLog ? 0 : SQLITE_OPEN_URI), nil) == SQLITE_OK else {
            sqlite3_close(db)
            return nil
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 250)
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT value FROM ItemTable WHERE key = 'cursorAuth/accessToken' LIMIT 1", -1,
                                 &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        let value: String? = switch sqlite3_column_type(statement, 0) {
        case SQLITE_TEXT: sqlite3_column_text(statement, 0).map { String(cString: $0) }
        case SQLITE_BLOB:
            // Some versions store the token as a BLOB, sometimes UTF-16LE.
            sqlite3_column_blob(statement, 0).map { bytes in
                let data = Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, 0)))
                let text = data.contains(0) ? String(data: data, encoding: .utf16LittleEndian) : String(data: data, encoding: .utf8)
                return text ?? ""
            }
        default: nil
        }
        let token = value?.trimmingCharacters(in: CharacterSet(charactersIn: "\"").union(.whitespacesAndNewlines))
        return token?.isEmpty == false ? token : nil
    }

    // MARK: Grok

    private func readGrok(now: Date) async -> Result<AIUsage, AIUsageProblem> {
        guard let data = try? Data(contentsOf: Self.home.appending(path: ".grok/auth.json")),
              let credentials = GrokCredentials.token(from: data) else { return .failure(.signedOut) }
        if let expiresAt = credentials.expiresAt, expiresAt <= now { return .failure(.expired) }

        var request = URLRequest(url: URL(string: "https://cli-chat-proxy.grok.com/v1/billing?format=credits")!)
        request.setValue("Bearer \(credentials.token)", forHTTPHeaderField: "Authorization")
        // The Grok CLI's proxy accepts its own token type only with this marker.
        request.setValue("xai-grok-cli", forHTTPHeaderField: "x-xai-token-auth")
        return await fetch(request, now: now) { data in
            let response = try JSONDecoder().decode(GrokBillingResponse.self, from: data)
            return AIUsage(plan: response.plan, windows: response.windows(), date: now)
        }
    }

    // MARK: Shared

    private func fetch(_ request: URLRequest, now: Date,
                       decode: (Data) throws -> AIUsage) async -> Result<AIUsage, AIUsageProblem> {
        var request = request
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Monny", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch status {
            case 200:
                let usage = try decode(data)
                return usage.windows.isEmpty ? .failure(.unavailable(retryAfter: nil)) : .success(usage)
            case 401, 403:
                return .failure(.signedOut)
            case 429:
                // Anthropic answers `Retry-After: 0` while its limit lasts for minutes; asking again
                // sooner than 5 minutes only extends it (CodexBar uses the same cooldown).
                let seconds = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Retry-After").flatMap(Double.init) ?? 0
                return .failure(.unavailable(retryAfter: now.addingTimeInterval(max(seconds, 5 * 60))))
            default:
                logger.error("Usage request to \(request.url?.host() ?? "", privacy: .public) returned \(status)")
                return .failure(.unavailable(retryAfter: nil))
            }
        } catch {
            logger.error("Usage request failed: \(error.localizedDescription, privacy: .public)")
            return .failure(.unavailable(retryAfter: nil))
        }
    }

    /// Runs a tool and returns its trimmed output, or `nil` on failure or after `timeout`, so a
    /// Keychain dialog that the item's access list did not expect cannot block refreshes.
    private static func run(_ path: String, _ arguments: [String], timeout: Duration = .seconds(3)) async -> Data? {
        let process = Process()
        process.executableURL = URL(filePath: path)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        let status: Int32? = await withCheckedContinuation { continuation in
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus) }
            do {
                try process.run()
            } catch {
                process.terminationHandler = nil
                continuation.resume(returning: nil)
                return
            }
            Task.detached {
                try? await Task.sleep(for: timeout)
                if process.isRunning { process.terminate() }
            }
        }
        guard status == 0 else { return nil }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8)
    }
}
