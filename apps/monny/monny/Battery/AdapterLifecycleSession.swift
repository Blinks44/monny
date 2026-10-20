import Foundation

/// One authenticated owner connection retained through sleep or removal preparation. No retry or renewal.
actor AdapterLifecycleSession {
    enum Purpose: Sendable { case sleep, removal }
    private let purpose: Purpose
    private enum Operation { case status, prepare, cancel }
    private let endpoint: NSXPCListenerEndpoint?
    private let timeout: Duration
    private var connection: NSXPCConnection?
    private var pending: CheckedContinuation<Data, any Error>?
    private var deadline: Task<Void, Never>?
    private var initialStatus: HelperStatus?
    private var closed = false
    private var requestID: UUID?

    init(purpose: Purpose = .sleep, endpoint: NSXPCListenerEndpoint? = nil, timeout: Duration = .seconds(5)) {
        self.purpose = purpose
        self.endpoint = endpoint
        self.timeout = timeout
    }

    func open(requirement: String) async throws -> HelperStatus {
        guard connection == nil, !closed, HelperSigning.parse(requirement) != nil else {
            throw HelperConnectionError.signingUnavailable
        }
        let connection = endpoint.map(NSXPCConnection.init(listenerEndpoint:))
            ?? NSXPCConnection(machServiceName: HelperContract.helperIdentifier, options: .privileged)
        connection.setCodeSigningRequirement(requirement)
        connection.remoteObjectInterface = NSXPCInterface(with: BatteryHelperProtocol.self)
        connection.invalidationHandler = { [weak self] in Task { await self?.fail(.connectionFailed) } }
        connection.interruptionHandler = { [weak self] in Task { await self?.fail(.connectionFailed) } }
        self.connection = connection
        connection.activate()
        let status: HelperStatus
        do { status = try HelperStatus.decode(await request(.status)) }
        catch { close(); throw error }
        let supported = switch purpose {
        case .sleep: status.adapterSleepVerificationAvailable == true && status.adapterSleepVerificationVersion == HelperContract.adapterSleepVerificationVersion
        case .removal: status.adapterRemovalVerificationAvailable == true && status.adapterRemovalVerificationVersion == HelperContract.adapterRemovalVerificationVersion
        }
        guard supported,
              status.helperInstance != nil, status.lifecycleDiagnostics != nil,
              status.controlState == .notControlling, case .available = status.nativeChargeLimit else {
            close()
            throw HelperConnectionError.versionMismatch
        }
        initialStatus = status
        return status
    }

    func prepare() async throws -> AdapterLifecyclePreparation {
        guard let initialStatus else { throw HelperConnectionError.connectionFailed }
        let data = try await request(.prepare)
        let preparation = try AdapterLifecyclePreparation.decode(data)
        guard preparation.helperInstance == initialStatus.helperInstance,
              initialStatus.nativeChargeLimit == .available(preparation.nativeLimit) else {
            close()
            throw HelperConnectionError.invalidReply
        }
        return preparation
    }

    func cancel() async throws {
        guard initialStatus != nil else { close(); return }
        defer { close() }
        let response = try HelperStatus.decode(await request(.cancel))
        guard response.controlState == .notControlling else { throw HelperConnectionError.invalidReply }
    }

    func close() {
        closed = true
        connection?.invalidationHandler = nil
        connection?.interruptionHandler = nil
        connection?.invalidate()
        connection = nil
        deadline?.cancel()
        deadline = nil
        let continuation = pending
        pending = nil
        requestID = nil
        continuation?.resume(throwing: HelperConnectionError.cancelled)
    }

    private func request(_ operation: Operation) async throws -> Data {
        let id = UUID()
        return try await withTaskCancellationHandler {
            guard !Task.isCancelled else { throw HelperConnectionError.cancelled }
            guard let connection, !closed, pending == nil else { throw HelperConnectionError.connectionFailed }
            return try await withCheckedThrowingContinuation { continuation in
                pending = continuation
                requestID = id
                deadline = Task { [weak self, timeout] in
                    do { try await Task.sleep(for: timeout, clock: .suspending) } catch { return }
                    await self?.fail(.timedOut, for: id)
                }
                guard let proxy = connection.remoteObjectProxyWithErrorHandler({ [weak self] _ in
                    Task { await self?.fail(.connectionFailed, for: id) }
                }) as? BatteryHelperProtocol else {
                    fail(.connectionFailed)
                    return
                }
                let reply: @Sendable (Data) -> Void = { [weak self] data in
                    Task { await self?.receive(data, for: id) }
                }
                switch operation {
                case .status: proxy.readStatus(withReply: reply)
                case .prepare:
                    switch purpose {
                    case .sleep: proxy.prepareAdapterSleep(withReply: reply)
                    case .removal: proxy.prepareAdapterRemoval(withReply: reply)
                    }
                case .cancel: proxy.cancelAdapterSleep(withReply: reply)
                }
            }
        } onCancel: {
            Task { await self.fail(.cancelled, for: id) }
        }
    }

    private func receive(_ data: Data, for id: UUID) {
        guard requestID == id, let continuation = pending else { return }
        guard data.count <= 4096 else { fail(.invalidReply); return }
        pending = nil
        requestID = nil
        deadline?.cancel()
        deadline = nil
        continuation.resume(returning: data)
    }

    private func fail(_ error: HelperConnectionError, for id: UUID) {
        guard requestID == id else { return }
        fail(error)
    }

    private func fail(_ error: HelperConnectionError) {
        let continuation = pending
        pending = nil
        close()
        continuation?.resume(throwing: error)
    }
}
