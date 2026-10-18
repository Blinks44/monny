import Foundation

/// Compares the running version with the latest GitHub release. Runs only when the user presses
/// Check for Updates; this is Monny's one network request (SPEC §7, §8). Monny never installs
/// updates itself: Download… opens the release page.
@Observable
final class UpdateChecker {
    enum Status: Equatable {
        case idle, checking, upToDate
        case available(version: String, page: URL)
        case failed(offline: Bool)
    }

    private(set) var status = Status.idle

    private static let latestRelease = URL(string: "https://api.github.com/repos/Blinks44/monny/releases/latest")!

    private struct Release: Decodable {
        let tagName: String
        let htmlURL: URL

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }

    func check() async {
        status = .checking
        var request = URLRequest(url: Self.latestRelease)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode
            // 404: nothing has been published yet, so this build is the latest there is.
            if code == 404 {
                status = .upToDate
                return
            }
            guard code == 200 else { throw URLError(.badServerResponse) }
            let release = try JSONDecoder().decode(Release.self, from: data)
            let latest = release.tagName.trimmingPrefix("v")
            status = Self.isVersion(String(latest), newerThan: Bundle.main.shortVersion)
                ? .available(version: String(latest), page: release.htmlURL)
                : .upToDate
        } catch {
            let offline = (error as? URLError)?.code == .notConnectedToInternet
            status = .failed(offline: offline)
        }
    }

    /// Numeric comparison of dotted versions: "1.10" is newer than "1.9", "1.0" equals "1".
    nonisolated static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let a = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let b = current.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? a[index] : 0
            let y = index < b.count ? b[index] : 0
            if x != y { return x > y }
        }
        return false
    }
}
