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

    static let live = Self(
        signingIdentity: { await HelperSystem.signingIdentity() },
        registration: { await HelperSystem.registration() },
        register: { try await HelperSystem.register() },
        unregister: { try await HelperSystem.unregister() },
        request: { requirement, removing in try await HelperConnection().request(requirement: requirement, forRemoval: removing) })
}

nonisolated private enum HelperSystem {
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
    @ObservationIgnored private var identity: HelperSigning.Identity?
    @ObservationIgnored private let operations: HelperOperations
    @ObservationIgnored private let logger = Logger(subsystem: "blinks44.monny", category: "BatteryHelper")

    init(operations: HelperOperations = .live) { self.operations = operations }

    var canInstall: Bool {
        !isBusy && identity != nil && (registration == .notRegistered || registration == .notFound)
    }
    var canRemove: Bool {
        !isBusy && identity != nil && (registration == .enabled || registration == .requiresApproval)
    }

    func refresh() async {
        guard !isBusy else { return }
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

    func remove() async {
        guard canRemove else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try Task.checkCancellation()
            registration = await operations.registration()
            if registration == .enabled {
                guard let identity, let requirement = HelperSigning.requirement(for: .helper, identity: identity) else {
                    throw HelperConnectionError.signingUnavailable
                }
                let response = try await operations.request(requirement, true)
                _ = try response.validated()
                guard response.controlState == .notControlling else { throw HelperConnectionError.invalidReply }
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
                state = .connected
                failure = nil
            } catch {
                status = nil
                state = error as? HelperConnectionError == .versionMismatch ? .incompatible : .failed
                failure = .connection
                logger.error("Helper status check failed: \(String(describing: error), privacy: .private)")
            }
        }
    }
}
