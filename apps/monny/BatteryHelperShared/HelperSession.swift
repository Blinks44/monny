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

    func readAdapterDiagnostics(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.diagnoseAdapter(for: token)))
            } catch {
                logger.error("Adapter diagnostics refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
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

    func prepareAdapterRemoval(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.prepareAdapterRemoval(for: token)))
            } catch {
                logger.error("Adapter removal preparation refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func prepareAdapterSleep(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.prepareAdapterSleep(for: token)))
            } catch {
                logger.error("Adapter sleep preparation refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func cancelAdapterSleep(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.cancelAdapterSleep(for: token)))
            } catch {
                logger.error("Adapter sleep cancellation refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func verifyAdapterRestart(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.verifyAdapterRestart(for: token)))
            } catch {
                logger.error("Adapter restart verification refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func observeAdapterByte(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.observeAdapterByte(for: token)))
            } catch {
                logger.error("Adapter byte observation refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func verifyAdapterBytePulse(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.verifyAdapterBytePulse(for: token)))
            } catch {
                logger.error("Adapter byte pulse refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func verifyAdapterIsolation(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.verifyAdapterIsolation(for: token)))
            } catch {
                logger.error("Adapter verification refused: \(String(describing: error), privacy: .private)")
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

    func applyNativeChargeLimit(_ limit: Int, withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.setNativeLimit(limit, for: token)))
            } catch {
                logger.error("Native limit request refused: \(String(describing: error), privacy: .private)")
                reply(Data())
            }
        }
    }

    func restoreNativeChargeLimit(withReply reply: @escaping @Sendable (Data) -> Void) {
        Task {
            do {
                let token = try await session.value
                reply(try JSONEncoder().encode(await executor.releaseNativeLimit(for: token)))
            } catch {
                logger.error("Native limit restoration refused: \(String(describing: error), privacy: .private)")
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
