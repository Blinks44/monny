import Foundation
import OSLog

/// One exported object per native XPC connection; clients cannot choose or reuse its owner token.
nonisolated final class HelperSession: NSObject, BatteryHelperProtocol, Sendable {
    private let executor: ChargeCommandExecutor
    private let session: Task<UUID, any Error>
    private let logger = Logger(subsystem: "blinks44.monny.helper", category: "Session")

    init(executor: ChargeCommandExecutor) {
        self.executor = executor
        self.session = Task { try await executor.beginSession() }
    }

    func readStatus(withReply reply: @escaping @Sendable (Data) -> Void) {
        respond(removing: false, reply: reply)
    }

    func readChargeDiagnostics(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.diagnose(for: token)))
            } catch {
                logger.error("Helper diagnostics refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func verifyNativeChargeLimit(_ limit: Int, withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.verifyNativeLimit(limit, for: token)))
            } catch {
                logger.error("Native verification refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func prepareForRemoval(withReply reply: @escaping @Sendable (Data) -> Void) {
        respond(removing: true, reply: reply)
    }

    private func respond(removing: Bool, reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                let status = try await executor.status(for: token, removing: removing)
                reply(try JSONEncoder().encode(status))
            } catch {
                // An empty reply is deliberately rejected by the existing versioned client.
                // Never acknowledge removal or claim macOS control after failed restoration.
                logger.error("Helper request refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func disconnect() async {
        do {
            let token = try await session.value
            try await executor.disconnect(owner: token)
        } catch {
            logger.error("Helper session cleanup failed: \(String(describing: error), privacy: .private)")
        }
    }
}
