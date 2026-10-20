import Foundation

/// One owner connection for a user-enabled native limit. A failed request closes it;
/// neither a transport error nor a timeout is retried with a new owner.
actor NativeLimitSession {
    private enum Operation { case status, apply(Int), restore }
    private let endpoint: NSXPCListenerEndpoint?
    private let timeout: Duration
    private var connection: NSXPCConnection?
    private var pending: CheckedContinuation<HelperStatus, any Error>?
    private var deadline: Task<Void, Never>?
    private var advertisedLimits: [Int] = []
    private var closed = false
    private var requestID: UUID?

    init(endpoint: NSXPCListenerEndpoint? = nil, timeout: Duration = .seconds(5)) {
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
        let status = try await request(.status)
        guard status.nativeLimitSessionAvailable == true,
              status.nativeLimitSessionVersion == HelperContract.nativeLimitSessionVersion,
              status.controlState == .notControlling,
              case .available(let snapshot) = status.nativeChargeLimit else {
            close()
            throw BatteryDiagnosticCommand.Failure.helperUpdateRequired
        }
        advertisedLimits = snapshot.availableLimits
        return status
    }

    func apply(_ limit: Int) async throws -> HelperStatus {
        guard advertisedLimits.contains(limit) else { throw HelperConnectionError.invalidReply }
        let response = try await request(.apply(limit))
        guard response.controlState == .nativeLimit, response.activeNativeLimit == limit else {
            fail(.invalidReply)
            throw HelperConnectionError.invalidReply
        }
        return response
    }

    func stop() async throws -> HelperStatus {
        defer { close() }
        let response = try await request(.restore)
        guard response.controlState == .notControlling else { throw HelperConnectionError.invalidReply }
        return response
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

    private func request(_ operation: Operation) async throws -> HelperStatus {
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
                case .apply(let limit): proxy.applyNativeChargeLimit(limit, withReply: reply)
                case .restore: proxy.restoreNativeChargeLimit(withReply: reply)
                }
            }
        } onCancel: {
            Task { await self.fail(.cancelled, for: id) }
        }
    }

    private func receive(_ data: Data, for id: UUID) {
        guard requestID == id, let continuation = pending else { return }
        do {
            let response = try HelperStatus.decode(data)
            pending = nil
            requestID = nil
            deadline?.cancel()
            deadline = nil
            continuation.resume(returning: response)
        } catch { fail(.invalidReply) }
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
