import Foundation

/// Runs only an installed tool's usage command; never a shell, login or agent session.
nonisolated enum AIUsageCommand {
    struct Output: Sendable {
        let stdout: String
        let stderr: String
        let status: Int32
    }

    static func executable(_ name: String, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL? {
        let folders = [
            "/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin",
            home.appending(path: ".local/bin").path, home.appending(path: ".amp/bin").path,
            home.appending(path: ".bun/bin").path, home.appending(path: ".nix-profile/bin").path,
            "/run/current-system/sw/bin", "/etc/profiles/per-user/\(NSUserName())/bin",
        ]
        return folders.map { URL(filePath: $0).appending(path: name) }.first {
            FileManager.default.isExecutableFile(atPath: $0.path)
        }
    }

    static func environment(for executable: URL) -> [String: String] {
        let inherited = ProcessInfo.processInfo.environment
        let allowed = [
            "HOME", "USER", "LOGNAME", "TMPDIR", "HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "NO_PROXY",
            "https_proxy", "http_proxy", "all_proxy", "no_proxy",
        ]
        var values = inherited.filter { allowed.contains($0.key) }
        values["PATH"] = [
            executable.deletingLastPathComponent().path, "/opt/homebrew/bin", "/usr/local/bin",
            "/opt/local/bin", "/usr/bin", "/bin",
        ].joined(separator: ":")
        values["LANG"] = "en_US.UTF-8"
        values["LC_ALL"] = "en_US.UTF-8"
        values["TZ"] = "UTC"
        values["TERM"] = "dumb"
        values["NO_COLOR"] = "1"
        values["CI"] = "1"
        if executable.lastPathComponent == "coderabbit" { values["CODERABBIT_CLI_DISABLE_AUTO_UPDATE"] = "true" }
        return values
    }

    static func run(_ executable: URL, arguments: [String], timeout: Duration = .seconds(10)) async -> Output? {
        guard
            let output = await LocalCommand.run(
                executable, arguments: arguments, timeout: timeout, environment: environment(for: executable))
        else { return nil }
        return Output(stdout: output.stdout, stderr: output.stderr, status: output.status)
    }
}
