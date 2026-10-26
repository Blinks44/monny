import Foundation
import Synchronization
import Darwin

/// Runs only an installed tool's usage command; never a shell, login or agent session.
nonisolated enum AIUsageCommand {
    struct Output: Sendable {
        let stdout: String
        let stderr: String
        let status: Int32
    }

    static func executable(_ name: String, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL? {
        let folders = ["/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin",
                       home.appending(path: ".local/bin").path, home.appending(path: ".amp/bin").path,
                       home.appending(path: ".bun/bin").path, home.appending(path: ".nix-profile/bin").path,
                       "/run/current-system/sw/bin", "/etc/profiles/per-user/\(NSUserName())/bin"]
        return folders.map { URL(filePath: $0).appending(path: name) }.first {
            FileManager.default.isExecutableFile(atPath: $0.path)
        }
    }

    static func environment(for executable: URL) -> [String: String] {
        let inherited = ProcessInfo.processInfo.environment
        let allowed = ["HOME", "USER", "LOGNAME", "TMPDIR", "HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "NO_PROXY",
                       "https_proxy", "http_proxy", "all_proxy", "no_proxy"]
        var values = inherited.filter { allowed.contains($0.key) }
        values["PATH"] = [executable.deletingLastPathComponent().path, "/opt/homebrew/bin", "/usr/local/bin",
                          "/opt/local/bin", "/usr/bin", "/bin"].joined(separator: ":")
        values["LANG"] = "en_US.UTF-8"
        values["LC_ALL"] = "en_US.UTF-8"
        values["TZ"] = "UTC"
        values["TERM"] = "dumb"
        values["NO_COLOR"] = "1"
        values["CI"] = "1"
        return values
    }

    static func run(_ executable: URL, arguments: [String], timeout: Duration = .seconds(10)) async -> Output? {
        guard !Task.isCancelled else { return nil }
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment(for: executable)
        process.currentDirectoryURL = URL(filePath: "/")
        process.standardInput = FileHandle.nullDevice
        let out = Pipe(), err = Pipe()
        process.standardOutput = out
        process.standardError = err
        let capture = Capture()
        out.fileHandleForReading.readabilityHandler = { capture.read($0, isError: false) }
        err.fileHandleForReading.readabilityHandler = { capture.read($0, isError: true) }
        defer {
            // This PID belongs to the Process created above, never a sampled user process.
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            out.fileHandleForReading.readabilityHandler = nil
            err.fileHandleForReading.readabilityHandler = nil
            try? out.fileHandleForReading.close()
            try? err.fileHandleForReading.close()
            try? out.fileHandleForWriting.close()
            try? err.fileHandleForWriting.close()
        }
        do {
            try process.run()
            try out.fileHandleForWriting.close()
            try err.fileHandleForWriting.close()
            let deadline = ContinuousClock.now.advanced(by: timeout)
            while true {
                try Task.checkCancellation()
                let snapshot = capture.state.withLock { $0 }
                guard !snapshot.overflow, ContinuousClock.now < deadline else { return nil }
                if !process.isRunning, snapshot.outEnded, snapshot.errEnded {
                    guard let stdout = String(data: snapshot.out, encoding: .utf8),
                          let stderr = String(data: snapshot.err, encoding: .utf8) else { return nil }
                    return Output(stdout: stdout, stderr: stderr, status: process.terminationStatus)
                }
                // Only active during this bounded child invocation, not an extra monitoring timer.
                try await Task.sleep(for: .milliseconds(25))
            }
        } catch { return nil }
    }

    private final class Capture: Sendable {
        struct State: Sendable {
            var out = Data(), err = Data()
            var outEnded = false, errEnded = false, overflow = false
        }
        let state = Mutex(State())

        func read(_ handle: FileHandle, isError: Bool) {
            let data = (try? handle.read(upToCount: 64 * 1_024)) ?? Data()
            state.withLock { value in
                if data.isEmpty {
                    if isError { value.errEnded = true } else { value.outEnded = true }
                } else if data.count + value.out.count + value.err.count > 256 * 1_024 {
                    value.overflow = true
                } else if !value.overflow {
                    if isError { value.err.append(data) } else { value.out.append(data) }
                }
            }
            if data.isEmpty { handle.readabilityHandler = nil }
        }
    }
}
