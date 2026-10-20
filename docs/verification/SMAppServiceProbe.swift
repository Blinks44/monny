// Standalone registration experiment, compiled twice; not linked into Monny.
// The daemon only logs first light. It has no IPC, file writes, charging APIs or commands.
import Darwin
import Foundation
import OSLog
import ServiceManagement

@main
enum SMAppServiceProbe {
    #if PROBE_DAEMON
    static func main() {
        Logger(subsystem: "blinks44.monny.registration-probe", category: "Daemon")
            .notice("Registration probe first light; uid=\(getuid(), privacy: .public)")
        dispatchMain()
    }
    #else
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.count == 1,
              ["--status", "--register", "--unregister"].contains(arguments[0]) else {
            print("Usage: RegistrationProbe --status|--register|--unregister")
            exit(2)
        }
        let action = arguments[0]
        let service = SMAppService.daemon(plistName: "blinks44.monny.registration-probe.daemon.plist")
        var report: [String: Any] = ["action": action, "before": service.status.rawValue]
        var result: Int32 = 0
        do {
            switch action {
            case "--register": try service.register()
            case "--unregister": try await service.unregister()
            default: break
            }
        } catch {
            let error = error as NSError
            report["errorDomain"] = error.domain
            report["errorCode"] = error.code
            result = 1
        }
        report["after"] = service.status.rawValue
        do {
            let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
            try FileHandle.standardOutput.write(contentsOf: data + Data([10]))
        } catch { result = 1 }
        exit(result)
    }
    #endif
}
