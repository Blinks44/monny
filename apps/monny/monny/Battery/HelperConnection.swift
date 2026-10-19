import Foundation

/// One connection and one reply. Actor isolation arbitrates reply/error/timeout/cancellation;
/// late callbacks cannot resume a continuation twice. Nothing is retained between requests.
actor HelperConnection {
    private let endpoint: NSXPCListenerEndpoint?
    private let timeout: Duration
    private var connection: NSXPCConnection?
    private var continuation: CheckedContinuation<HelperStatus, any Error>?
    private var result: Result<HelperStatus, HelperConnectionError>?
    private var deadline: Task<Void, Never>?
    private var started = false

    /// Anonymous endpoints support local IPC tests without registering a privileged service.
    init(endpoint: NSXPCListenerEndpoint? = nil, timeout: Duration = .seconds(5)) {
        self.endpoint = endpoint
        self.timeout = timeout
    }

    func request(requirement: String, forRemoval: Bool = false) async throws -> HelperStatus {
        try await withTaskCancellationHandler {
            if let result { return try result.get() }
            guard !started else { throw HelperConnectionError.connectionFailed }
            guard HelperSigning.parse(requirement) != nil else { throw HelperConnectionError.signingUnavailable }
            guard !Task.isCancelled else { throw HelperConnectionError.cancelled }
            started = true
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                let connection = endpoint.map(NSXPCConnection.init(listenerEndpoint:))
                    ?? NSXPCConnection(machServiceName: HelperContract.helperIdentifier, options: .privileged)
                self.connection = connection
                connection.setCodeSigningRequirement(requirement)
                connection.remoteObjectInterface = NSXPCInterface(with: BatteryHelperProtocol.self)
                connection.invalidationHandler = { [weak self] in
                    Task { await self?.complete(.failure(.connectionFailed)) }
                }
                connection.interruptionHandler = { [weak self] in
                    Task { await self?.complete(.failure(.connectionFailed)) }
                }
                deadline = Task { [weak self, timeout] in
                    do { try await Task.sleep(for: timeout) } catch { return }
                    await self?.complete(.failure(.timedOut))
                }
                connection.activate()
                guard let proxy = connection.remoteObjectProxyWithErrorHandler({ [weak self] _ in
                    Task { await self?.complete(.failure(.connectionFailed)) }
                }) as? BatteryHelperProtocol else {
                    complete(.failure(.connectionFailed))
                    return
                }
                let reply: @Sendable (Data) -> Void = { [weak self] data in
                    Task { await self?.receive(data) }
                }
                if forRemoval { proxy.prepareForRemoval(withReply: reply) }
                else { proxy.readStatus(withReply: reply) }
            }
        } onCancel: {
            Task { await self.complete(.failure(.cancelled)) }
        }
    }

    private func receive(_ data: Data) {
        do { complete(.success(try HelperStatus.decode(data))) }
        catch { complete(.failure(error as? HelperConnectionError ?? .invalidReply)) }
    }

    func complete(_ result: Result<HelperStatus, HelperConnectionError>) {
        guard self.result == nil else { return }
        self.result = result
        let continuation = continuation
        self.continuation = nil
        deadline?.cancel()
        deadline = nil
        connection?.invalidationHandler = nil
        connection?.interruptionHandler = nil
        connection?.invalidate()
        connection = nil
        continuation?.resume(with: result.mapError { $0 as any Error })
    }
}
