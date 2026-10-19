import Foundation
import OSLog

/// Immutable status-only service. No SMC writer is linked into this executable.
nonisolated final class BatteryHelperService: NSObject, BatteryHelperProtocol {
    private let response: Data

    init(response: Data) { self.response = response }

    func readStatus(withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }

    /// This version cannot inhibit charging, so there is no state to restore. Future writable
    /// versions must acknowledge real restoration here before the app unregisters the daemon.
    func prepareForRemoval(withReply reply: @escaping @Sendable (Data) -> Void) { reply(response) }
}

nonisolated final class HelperListenerDelegate: NSObject, NSXPCListenerDelegate {
    let service: BatteryHelperService
    let requirement: String

    init(response: Data, requirement: String) {
        self.service = BatteryHelperService(response: response)
        self.requirement = requirement
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.setCodeSigningRequirement(requirement)
        connection.exportedInterface = NSXPCInterface(with: BatteryHelperProtocol.self)
        connection.exportedObject = service
        connection.activate()
        return true
    }
}

let logger = Logger(subsystem: "blinks44.monny.helper", category: "Connection")
guard let identity = HelperSigning.currentIdentity(for: .helper),
      let requirement = HelperSigning.requirement(for: .app, identity: identity),
      let response = try? JSONEncoder().encode(HelperStatus.current) else {
    logger.error("Helper cannot establish a trusted signing identity; refusing connections")
    exit(EXIT_FAILURE)
}
let delegate = HelperListenerDelegate(response: response, requirement: requirement)
let listener = NSXPCListener(machServiceName: HelperContract.helperIdentifier)
listener.setConnectionCodeSigningRequirement(requirement)
listener.delegate = delegate
listener.activate()
logger.info("Status-only battery helper started")
RunLoop.current.run()
