import CryptoKit
import Foundation

/// Official Kimi credential slots bind a saved session to its regional API.
nonisolated struct KimiSession {
    enum Region: CaseIterable, Sendable {
        case china, international

        var oauthHost: String { self == .china ? "https://auth.kimi.com" : "https://auth.kimi.ai" }
        var apiBase: String { self == .china ? "https://api.kimi.com/coding/v1" : "https://api.kimi.ai/coding/v1" }

        var credentialName: String {
            if self == .china { return "kimi-code.json" }
            // Matches resolveKimiCodeOAuthKey's ordered JSON and truncated SHA-256.
            let identity = "{\"oauthHost\":\"\(oauthHost)\",\"baseUrl\":\"\(apiBase)\"}"
            let hex = Array("0123456789abcdef")
            let suffix = SHA256.hash(data: Data(identity.utf8)).prefix(8)
                .flatMap { [hex[Int($0 >> 4)], hex[Int($0 & 15)]] }
            return "kimi-code-env-\(String(suffix)).json"
        }
    }

    let region: Region
    let file: URL

    /// Metadata only. Multiple/custom slots need explicit source selection, not fallback.
    static func locate(in home: URL) -> KimiSession? {
        let directory = home.appending(path: "credentials")
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey]),
              files.count <= 128 else { return nil }
        let slots = files.filter {
            let name = $0.lastPathComponent
            return name == "kimi-code.json" || (name.hasPrefix("kimi-code-env-") && name.hasSuffix(".json"))
        }
        guard slots.count == 1, let file = slots.first,
              let metadata = try? file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]),
              metadata.isRegularFile == true, metadata.isSymbolicLink != true,
              let region = Region.allCases.first(where: { $0.credentialName == file.lastPathComponent }) else { return nil }
        return KimiSession(region: region, file: file)
    }
}
