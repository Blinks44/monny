import Foundation

/// Discovery only checks metadata. Secrets and usage are read only for enabled tools.
nonisolated enum AdditionalAISources {
    static func path(_ tool: AITool, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL? {
        let relative: String
        switch tool {
        case .openCodeGo: relative = ".local/share/opencode"
        case .kilo: relative = ".local/share/kilo/auth.json"
        case .kiro: relative = "Library/Application Support/kiro-cli/data.sqlite3"
        case .windsurf: relative = "Library/Application Support/Windsurf/User/globalStorage/state.vscdb"
        case .gemini: relative = ".gemini/oauth_creds.json"
        case .huggingFace: relative = ".cache/huggingface/token"
        default: return nil
        }
        return home.appending(path: relative)
    }

    static func isInstalled(_ tool: AITool) -> Bool? {
        if tool == .alibabaToken || tool == .alibabaCoding { return AIUsageCommand.executable("bl") != nil }
        if tool == .codeRabbit { return AIUsageCommand.executable("coderabbit") != nil }
        guard let file = path(tool) else { return nil }
        return FileManager.default.fileExists(atPath: file.path)
    }
}

extension AIUsageReader {
    func readAdditional(_ tool: AITool, home: URL = FileManager.default.homeDirectoryForCurrentUser, now: Date) async -> Result<
        AIUsage, AIUsageProblem
    > {
        do {
            try Task.checkCancellation()
            if tool == .alibabaToken || tool == .alibabaCoding || tool == .codeRabbit {
                return await readAdditionalCommand(tool, now: now)
            }
            if tool == .windsurf {
                guard let file = AdditionalAISources.path(tool, home: home) else { return .failure(.localDataMissing) }
                let rows = try AILocalDatabase.rows(
                    file, sql: "SELECT value FROM ItemTable WHERE key='windsurf.settings.cachedPlanInfo'", limit: 1)
                guard let text = rows.first?.first else { return .failure(.localDataMissing) }
                return .success(try WindsurfUsage.usage(Data(text.utf8), now: now))
            }
            let request: URLRequest
            switch tool {
            case .openCodeGo:
                let token = try OpenCodeGoUsage.credential(home: home, now: now)
                request = Self.bearerRequest("https://opencode.ai/inference/go/v1/usage", token: token)
            case .kilo:
                guard let file = AdditionalAISources.path(tool, home: home), let data = SavedAISession.data(at: file) else {
                    return .failure(.signedOut)
                }
                request = try KiloUsage.request(token: KiloUsage.token(data, now: now))
            case .kiro:
                guard let file = AdditionalAISources.path(tool, home: home) else { return .failure(.signedOut) }
                let saved = try KiroUsage.session(database: file, now: now)
                var value = Self.bearerRequest(saved.endpoint.absoluteString, token: saved.token)
                value.httpMethod = "POST"
                value.setValue("application/x-amz-json-1.0", forHTTPHeaderField: "Content-Type")
                value.setValue("AmazonCodeWhispererService.GetUsageLimits", forHTTPHeaderField: "X-Amz-Target")
                value.httpBody = try JSONSerialization.data(withJSONObject: ["profileArn": saved.profile])
                request = value
            case .gemini:
                guard let file = AdditionalAISources.path(tool, home: home), let data = SavedAISession.data(at: file) else {
                    return .failure(.signedOut)
                }
                let token = try GeminiUsage.token(data, now: now)
                var value = Self.bearerRequest("https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuota", token: token)
                value.httpMethod = "POST"
                value.setValue("application/json", forHTTPHeaderField: "Content-Type")
                var setup = Self.bearerRequest("https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist", token: token)
                setup.httpMethod = "POST"
                setup.setValue("application/json", forHTTPHeaderField: "Content-Type")
                setup.httpBody = Data(#"{"metadata":{"ideType":"GEMINI_CLI","pluginType":"GEMINI"}}"#.utf8)
                let project: String?
                switch await fetchData(setup, now: now) {
                case .failure(let problem): return .failure(problem)
                case .success(let data): project = try GeminiUsage.project(data)
                }
                value.httpBody = try JSONSerialization.data(withJSONObject: project.map { ["project": $0] } ?? [:])
                request = value
            case .huggingFace:
                guard let file = AdditionalAISources.path(tool, home: home), let data = SavedAISession.data(at: file),
                    let text = String(data: data, encoding: .utf8), let token = SavedAISession.token(text)
                else { return .failure(.signedOut) }
                request = Self.bearerRequest("https://huggingface.co/api/spaces/zero-gpu/quota", token: token)
            default: return .failure(.localDataMissing)
            }
            return await fetch(request, now: now, allowsUnmetered: tool == .kilo) { data in
                switch tool {
                case .openCodeGo: try OpenCodeGoUsage.usage(data, now: now)
                case .kilo: try KiloUsage.usage(data, now: now)
                case .kiro: try KiroUsage.usage(data, now: now)
                case .gemini: try GeminiUsage.usage(data, now: now)
                case .huggingFace: try HuggingFaceUsage.usage(data, now: now)
                default: throw AIUsageProblem.unavailable(retryAfter: nil)
                }
            }
        } catch let problem as AIUsageProblem { return .failure(problem) } catch { return .failure(.unavailable(retryAfter: nil)) }
    }

    private static func bearerRequest(_ endpoint: String, token: String) -> URLRequest {
        // Callers supply only fixed service endpoints or a validated Kiro region.
        var request = URLRequest(url: URL(string: endpoint)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func readAdditionalCommand(_ tool: AITool, now: Date) async -> Result<AIUsage, AIUsageProblem> {
        let name = tool == .codeRabbit ? "coderabbit" : "bl"
        guard let executable = AIUsageCommand.executable(name) else { return .failure(.signedOut) }
        let arguments =
            tool == .codeRabbit ? ["usage"] : ["usage", tool == .alibabaCoding ? "coding-plan" : "token-plan", "--output", "json"]
        guard let output = await AIUsageCommand.run(executable, arguments: arguments), !Task.isCancelled else {
            return .failure(.unavailable(retryAfter: nil))
        }
        let text = AICommandText.clean(output.stdout)
        if let problem = AICommandText.problem(in: text + output.stderr, now: now) { return .failure(problem) }
        guard output.status == 0 else { return .failure(.unavailable(retryAfter: nil)) }
        do {
            if tool == .codeRabbit { return .success(try CodeRabbitUsage.usage(text, now: now)) }
            return .success(try BailianUsage.usage(Data(text.utf8), codingPlan: tool == .alibabaCoding, now: now))
        } catch let problem as AIUsageProblem { return .failure(problem) } catch { return .failure(.unavailable(retryAfter: nil)) }
    }
}
