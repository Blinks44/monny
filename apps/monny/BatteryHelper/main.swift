import Foundation
import OSLog

nonisolated final class HelperListenerDelegate: NSObject, NSXPCListenerDelegate {
    let executor: ChargeCommandExecutor
    let requirement: String

    init(executor: ChargeCommandExecutor, requirement: String) {
        self.executor = executor
        self.requirement = requirement
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.setCodeSigningRequirement(requirement)
        let session = HelperSession(executor: executor)
        connection.exportedInterface = NSXPCInterface(with: BatteryHelperProtocol.self)
        connection.exportedObject = session
        connection.invalidationHandler = { Task { await session.disconnect() } }
        connection.interruptionHandler = { Task { await session.disconnect() } }
        connection.activate()
        return true
    }
}

let logger = Logger(subsystem: "blinks44.monny.helper", category: "Connection")
guard let identity = HelperSigning.currentIdentity(for: .helper),
      let requirement = HelperSigning.requirement(for: .app, identity: identity) else {
    logger.error("Helper cannot establish a trusted signing identity; refusing connections")
    exit(EXIT_FAILURE)
}
// Ordinary status/diagnostics never apply a target. Mutation requires an explicit verification RPC.
let executor = ChargeCommandExecutor(nativeBackendFactory: {
    do {
        return .init(operations: NativeChargeLimitBackend.operations,
                     journal: try NativeChargeLimitFileJournal.systemJournal().journal)
    } catch {
        logger.error("Native recovery storage could not open: \(String(describing: error), privacy: .private)")
        throw error
    }
}, nativeDiagnosticRead: { await NativeChargeLimitReader.read() })
guard let powerMonitor = HelperPowerMonitor(executor: executor) else { exit(EXIT_FAILURE) }
let delegate = HelperListenerDelegate(executor: executor, requirement: requirement)
let listener = NSXPCListener(machServiceName: HelperContract.helperIdentifier)
listener.setConnectionCodeSigningRequirement(requirement)
listener.delegate = delegate
Task {
    do {
        try await executor.start()
        listener.activate()
        logger.info("Battery helper started with explicit native verification")
    } catch {
        logger.fault("Startup restoration failed; refusing connections")
        exit(EXIT_FAILURE)
    }
}
RunLoop.current.run()
