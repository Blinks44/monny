import Foundation
import IOKit.pwr_mgt
import IOKit
import OSLog

/// Native sleep notifications run on the main dispatch queue; all command state stays on its actor.
/// No AppKit/NSWorkspace dependency, private notifications, polling, or power assertions.
@MainActor
final class HelperPowerMonitor {
    private let executor: ChargeCommandExecutor
    private var root: io_connect_t = 0
    private var notifier: io_object_t = 0
    private var port: IONotificationPortRef?
    private var signals: [any DispatchSourceSignal] = []
    private var pendingPowerEvent: Task<Void, Never>?
    private let logger = Logger(subsystem: "blinks44.monny.helper", category: "Lifecycle")

    init?(executor: ChargeCommandExecutor) {
        self.executor = executor
        root = IORegisterForSystemPower(Unmanaged.passUnretained(self).toOpaque(), &port, { context, _, message, argument in
            guard let context else { return }
            let token = Int(bitPattern: argument)
            MainActor.assumeIsolated {
                Unmanaged<HelperPowerMonitor>.fromOpaque(context).takeUnretainedValue()
                    .handle(message: message, token: token)
            }
        }, &notifier)
        guard root != 0, let port else {
            logger.error("Cannot observe system sleep; refusing service startup")
            return nil
        }
        IONotificationPortSetDispatchQueue(port, .main)
        for number in [SIGTERM, SIGINT] {
            signal(number, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
            source.setEventHandler { [weak self] in self?.terminate() }
            source.resume()
            signals.append(source)
        }
    }

    private func handle(message: UInt32, token: Int) {
        let root = root
        switch message {
        case MonnyCanSystemSleep:
            // Never veto idle sleep; will-sleep selects backend-specific preservation/recovery.
            IOAllowPowerChange(root, token)
        case MonnySystemWillSleep:
            let previous = pendingPowerEvent
            pendingPowerEvent = Task {
                await previous?.value
                do { try await executor.willSleep() }
                catch { logger.fault("Sleep preparation failed; hardware safety is unverified") }
                // Native limits retain their journal and owner; other modes attempt restoration.
                // The OS continues sleep regardless after 30 s; acknowledge after preparation.
                IOAllowPowerChange(root, token)
            }
        case MonnySystemHasPoweredOn:
            let previous = pendingPowerEvent
            pendingPowerEvent = Task {
                await previous?.value
                do { try await executor.didWake() }
                catch { logger.fault("Wake restoration failed; commands remain blocked") }
            }
        default: break // Early power-on/will-not-sleep notifications must not be acknowledged.
        }
    }

    private func terminate() {
        Task {
            do {
                try await executor.shutdown()
                exit(EXIT_SUCCESS)
            } catch {
                logger.fault("Shutdown restoration failed")
                exit(EXIT_FAILURE)
            }
        }
    }

    isolated deinit {
        signals.forEach { $0.cancel() }
        if notifier != 0 { IODeregisterForSystemPower(&notifier) }
        if let port { IONotificationPortDestroy(port) }
        if root != 0 { IOServiceClose(root) }
    }
}
