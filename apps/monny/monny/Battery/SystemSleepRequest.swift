import IOKit
import IOKit.pwr_mgt

/// Explicit engineering caller only; the ordinary console user requests normal sleep, never a schedule/assertion.
nonisolated enum SystemSleepRequest {
    enum Failure: Error, Sendable { case unavailable, rejected(Int32) }
    static func request() throws {
        let connection = IOPMFindPowerManagement(kIOMainPortDefault)
        guard connection != 0 else { throw Failure.unavailable }
        defer { IOServiceClose(connection) }
        let result = IOPMSleepSystem(connection)
        guard result == kIOReturnSuccess else { throw Failure.rejected(result) }
    }
}
