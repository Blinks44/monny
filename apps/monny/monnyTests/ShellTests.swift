import Foundation
import Testing
@testable import monny

@MainActor
struct ShellTests {
    /// The sidebar follows the Sketch order, with Settings last.
    @Test func dashboardPageOrder() {
        #expect(DashboardPage.allCases == [.overview, .cpu, .memory, .disk, .network, .battery, .sensors, .aiUsage, .settings])
        #expect(!DashboardPage.settings.showsTimeRange)
    }

    @Test(arguments: [
        (TimeInterval(35 * 60), "35m"),
        (TimeInterval(2 * 86_400 + 4 * 3_600 + 10 * 60), "2d 4h"),
    ])
    func uptimeShowsTwoUnits(seconds: TimeInterval, expected: String) {
        #expect(SystemInfo.uptimeText(seconds, locale: Locale(identifier: "en_US")) == expected)
    }
}
