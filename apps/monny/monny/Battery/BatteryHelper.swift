import Foundation
import Observation
import OSLog
import ServiceManagement

nonisolated enum HelperRegistration: Sendable { case notRegistered, enabled, requiresApproval, notFound, unknown }

/// The system boundary is injected only to test lifecycle failures without installing a daemon.
nonisolated struct HelperOperations: Sendable {
    var signingIdentity: @Sendable () async -> HelperSigning.Identity?
    var registration: @Sendable () async -> HelperRegistration
    var register: @Sendable () async throws -> Void
    var unregister: @Sendable () async throws -> Void
    var request: @Sendable (_ requirement: String, _ forRemoval: Bool) async throws -> HelperStatus
    // Writer-capable releases require acknowledgement. Only explicit non-writing fixtures opt out.
    var requiresRemovalAcknowledgement = true

    static let live = Self(
        signingIdentity: { await HelperSystem.signingIdentity() },
        registration: { await HelperSystem.registration() },
        register: { try await HelperSystem.register() },
        unregister: { try await HelperSystem.unregister() },
        request: { requirement, removing in try await HelperConnection().request(requirement: requirement, forRemoval: removing) },
        requiresRemovalAcknowledgement: true)
}

nonisolated enum HelperSystem {
    @concurrent static func signingIdentity() async -> HelperSigning.Identity? {
        guard let identity = HelperSigning.currentIdentity(for: .app),
              HelperSigning.matches(at: Bundle.main.bundleURL.appending(components: "Contents", "Library", "HelperTools", HelperContract.executableName),
                                 peer: .helper, identity: identity) else { return nil }
        return identity
    }

    @concurrent static func registration() async -> HelperRegistration {
        switch SMAppService.daemon(plistName: HelperContract.plistName).status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notRegistered: .notRegistered
        case .notFound: .notFound
        @unknown default: .unknown
        }
    }

    @concurrent static func register() async throws {
        try SMAppService.daemon(plistName: HelperContract.plistName).register()
    }

    static func unregister() async throws {
        try await SMAppService.daemon(plistName: HelperContract.plistName).unregister()
    }
}

/// The app owns one instance. Registration never happens at launch, refresh, or a sample.
@Observable
final class BatteryHelper {
    enum State: Equatable { case checking, unavailable, notInstalled, needsApproval, connected, incompatible, failed }
    enum Failure { case installation, connection, removal }
    private(set) var state = State.checking
    private(set) var status: HelperStatus?
    private(set) var isBusy = false
    private(set) var registration = HelperRegistration.notRegistered
    private(set) var failure: Failure?
    var isPresentingRemovalConfirmation = false
    private(set) var nativeLimit: Int?
    private(set) var nativeBusy = false
    private(set) var nativeFailed = false
    @ObservationIgnored private var nativeSession: NativeLimitSession?
    @ObservationIgnored private var nativeRenewal: Task<Void, Never>?
    var nativeLimits: [Int] {
        guard status?.nativeLimitSessionAvailable == true,
              status?.nativeLimitSessionVersion == HelperContract.nativeLimitSessionVersion,
              case .available(let snapshot) = status?.nativeChargeLimit else { return [] }
        return snapshot.availableLimits
    }
    var canControlNativeLimit: Bool {
        state == .connected && !nativeLimits.isEmpty && status?.controlState != .restorationRequired
    }

    @ObservationIgnored private var identity: HelperSigning.Identity?
    @ObservationIgnored private var connectionError: HelperConnectionError?
    @ObservationIgnored private let operations: HelperOperations
    @ObservationIgnored private let connectNativeSession: @MainActor (String) async throws -> NativeLimitSession
    @ObservationIgnored private let logger = Logger(subsystem: "blinks44.monny", category: "BatteryHelper")

    init(operations: HelperOperations = .live,
         connectNativeSession: @escaping @MainActor (String) async throws -> NativeLimitSession = { requirement in
             let session = NativeLimitSession()
             _ = try await session.open(requirement: requirement)
             return session
         }) {
        self.operations = operations
        self.connectNativeSession = connectNativeSession
    }

    var canInstall: Bool {
        !isBusy && identity != nil && (registration == .notRegistered || registration == .notFound)
    }
    var canRemove: Bool {
        !isBusy && identity != nil && (registration == .enabled || registration == .requiresApproval)
    }

    /// Explicit UI action only. UserDefaults never enables a limit at launch.
    func setNativeLimit(_ limit: Int) async {
        guard !nativeBusy, !isBusy, canControlNativeLimit, nativeLimits.contains(limit) else { return }
        nativeBusy = true
        nativeFailed = false
        defer { nativeBusy = false }
        nativeRenewal?.cancel()
        nativeRenewal = nil
        do {
            let session: NativeLimitSession
            if let current = nativeSession { session = current }
            else {
                guard let identity, let requirement = HelperSigning.requirement(for: .helper, identity: identity) else {
                    throw HelperConnectionError.signingUnavailable
                }
                session = try await connectNativeSession(requirement)
                nativeSession = session
            }
            status = try await session.apply(limit)
            nativeLimit = limit
            nativeRenewal = Task { [weak self] in
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(10), clock: .suspending) } catch { return }
                    guard let self, !Task.isCancelled else { return }
                    await self.renewNativeLimit()
                    guard self.nativeLimit != nil else { return }
                }
            }
        } catch { await nativeConnectionFailed() }
    }

    func stopNativeLimit() async {
        guard !nativeBusy else { return }
        nativeBusy = true
        defer { nativeBusy = false }
        await endNativeLimit()
    }

    private func endNativeLimit() async {
        nativeRenewal?.cancel()
        nativeRenewal = nil
        let session = nativeSession
        nativeSession = nil
        nativeLimit = nil
        guard let session else { return }
        do { status = try await session.stop() }
        catch {
            await session.close()
            await nativeConnectionFailed()
        }
    }

    private func renewNativeLimit() async {
        guard !nativeBusy, let nativeSession, let nativeLimit else { return }
        nativeBusy = true
        defer { nativeBusy = false }
        do { status = try await nativeSession.apply(nativeLimit) }
        catch {
            // This is the renewal task itself: let it finish after the read-back rather
            // than cancelling it before HelperConnection checks task cancellation.
            nativeRenewal = nil
            await nativeConnectionFailed()
            // Sleep or lease expiry invalidates the owner. A fresh read may confirm safe
            // macOS control; it never reapplies a target or re-registers the helper.
            nativeBusy = false
            await refresh()
        }
    }

    private func nativeConnectionFailed() async {
        nativeRenewal?.cancel()
        nativeRenewal = nil
        await nativeSession?.close()
        nativeSession = nil
        nativeLimit = nil
        nativeFailed = true
        status = nil
        state = .failed
        failure = .connection
    }

    func refresh() async {
        guard !isBusy, !nativeBusy else { return }
        isBusy = true
        defer { isBusy = false }
        status = nil
        failure = nil
        identity = await operations.signingIdentity()
        registration = await operations.registration()
        await readStatus()
    }

    func install() async {
        guard canInstall else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try Task.checkCancellation()
            try await operations.register()
        } catch {
            // SMAppService may throw while still recording a pending approval. Read it back.
            logger.error("Helper registration did not complete: \(String(describing: error), privacy: .private)")
        }
        registration = await operations.registration()
        if registration == .notRegistered || registration == .notFound {
            state = .failed
            failure = .installation
        } else {
            await readStatus()
        }
    }

    /// Explicit recovery for an approved item whose launchd job is missing. Refresh stays read-only.
    func retryConnection() async {
        guard !isBusy else { return }
        await refresh()
        guard !isBusy, registration == .enabled, state == .failed, identity != nil,
              connectionError == .connectionFailed || connectionError == .timedOut else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try Task.checkCancellation()
            try await operations.register()
        } catch {
            // Already-registered and pending-approval errors require fresh state, not a retry loop.
            let error = error as NSError
            logger.error("Explicit helper re-registration failed: domain=\(error.domain, privacy: .public) code=\(error.code, privacy: .public)")
        }
        registration = await operations.registration()
        await readStatus()
    }

    func remove() async {
        guard canRemove, !nativeBusy else { return }
        isBusy = true
        defer { isBusy = false }
        await endNativeLimit()
        do {
            try Task.checkCancellation()
            registration = await operations.registration()
            if registration == .enabled {
                guard let identity, let requirement = HelperSigning.requirement(for: .helper, identity: identity) else {
                    throw HelperConnectionError.signingUnavailable
                }
                do {
                    let response = try await operations.request(requirement, true)
                    _ = try response.validated()
                    guard response.controlState == .notControlling else { throw HelperConnectionError.invalidReply }
                } catch let error as HelperConnectionError where error == .connectionFailed || error == .timedOut {
                    guard !operations.requiresRemovalAcknowledgement else { throw error }
                    // This release has no charge writer or writable IPC. An unreachable helper
                    // cannot acknowledge removal; unregistering still goes through SMAppService.
                    logger.notice("Removing unreachable status-only helper through SMAppService")
                }
            } else if registration != .requiresApproval {
                throw HelperConnectionError.connectionFailed
            }
            try Task.checkCancellation()
            try await operations.unregister()
            registration = await operations.registration()
            guard registration == .notRegistered || registration == .notFound else {
                throw HelperConnectionError.connectionFailed
            }
            status = nil
            state = .notInstalled
            failure = nil
        } catch {
            status = nil
            state = error as? HelperConnectionError == .versionMismatch ? .incompatible : .failed
            failure = .removal
            logger.error("Helper removal did not complete: \(String(describing: error), privacy: .private)")
        }
    }

    private func readStatus() async {
        connectionError = nil
        guard let identity, let requirement = HelperSigning.requirement(for: .helper, identity: identity) else {
            state = .unavailable
            return
        }
        switch registration {
        case .notRegistered, .notFound: state = .notInstalled
        case .requiresApproval: state = .needsApproval
        case .unknown: state = .failed
        case .enabled:
            do {
                let response = try await operations.request(requirement, false)
                status = try response.validated()
                if nativeSession != nil && response.controlState != .nativeLimit {
                    nativeRenewal?.cancel()
                    nativeRenewal = nil
                    await nativeSession?.close()
                    nativeSession = nil
                    nativeLimit = nil
                }
                state = .connected
                nativeFailed = response.controlState == .restorationRequired
                failure = nil
            } catch {
                if nativeSession != nil { await nativeConnectionFailed() }
                connectionError = error as? HelperConnectionError
                status = nil
                state = error as? HelperConnectionError == .versionMismatch ? .incompatible : .failed
                failure = .connection
                logger.error("Helper status check failed: \(String(describing: error), privacy: .private)")
            }
        }
    }
}
