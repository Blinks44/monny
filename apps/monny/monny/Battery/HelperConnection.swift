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
    private var needsDiagnostics = false
    private var verificationTarget: Int?
    private enum Operation: Equatable { case status, removal, diagnostics, verification(Int) }

    /// Anonymous endpoints support local IPC tests without registering a privileged service.
    init(endpoint: NSXPCListenerEndpoint? = nil, timeout: Duration = .seconds(5)) {
        self.endpoint = endpoint
        self.timeout = timeout
    }

    func request(requirement: String, forRemoval: Bool = false) async throws -> HelperStatus {
        try await request(requirement: requirement, operation: forRemoval ? .removal : .status)
    }

    /// Call only after status advertises this additive selector; legacy helpers stay removable.
    func diagnose(requirement: String) async throws -> HelperStatus {
        try await request(requirement: requirement, operation: .diagnostics)
    }

    /// Requires an explicit caller and a successful feature handshake first.
    func verifyNativeLimit(_ limit: Int, requirement: String) async throws -> HelperStatus {
        try await request(requirement: requirement, operation: .verification(limit))
    }

    private func request(requirement: String, operation: Operation) async throws -> HelperStatus {
        try await withTaskCancellationHandler {
            if let result { return try result.get() }
            guard !started else { throw HelperConnectionError.connectionFailed }
            guard HelperSigning.parse(requirement) != nil else { throw HelperConnectionError.signingUnavailable }
            guard !Task.isCancelled else { throw HelperConnectionError.cancelled }
            started = true
            needsDiagnostics = operation == .diagnostics
            if case .verification(let target) = operation { verificationTarget = target }
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
                switch operation {
                case .status: proxy.readStatus(withReply: reply)
                case .removal: proxy.prepareForRemoval(withReply: reply)
                case .diagnostics: proxy.readChargeDiagnostics(withReply: reply)
                case .verification(let limit): proxy.verifyNativeChargeLimit(limit, withReply: reply)
                }
            }
        } onCancel: {
            Task { await self.complete(.failure(.cancelled)) }
        }
    }

    private func receive(_ data: Data) {
        do {
            let response = try HelperStatus.decode(data)
            guard !needsDiagnostics || response.chargeDiagnostics != nil else { throw HelperConnectionError.invalidReply }
            if let verificationTarget {
                guard response.nativeVerification?.target == verificationTarget else { throw HelperConnectionError.invalidReply }
            }
            complete(.success(response))
        }
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
