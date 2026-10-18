import OSLog
import ServiceManagement

/// Launch at login through `SMAppService.mainApp`; macOS owns the state, so it is read back
/// rather than stored.
@Observable
final class LoginItem {
    private(set) var isEnabled = SMAppService.mainApp.status == .enabled
    private let logger = Logger(subsystem: "blinks44.monny", category: "LoginItem")

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            logger.error("Launch at login change failed: \(error.localizedDescription, privacy: .public)")
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
