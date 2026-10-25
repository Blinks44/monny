import AppKit
import Darwin

/// One process from the snapshot the user chose, never a process-group signal target.
nonisolated struct ProcessTarget: Sendable {
    let id: pid_t
    let name: String
    let startTime: UInt64

    init?(_ process: ProcessUsage) {
        guard let startTime = process.startTime, startTime > 0 else { return nil }
        self.id = process.id
        self.name = process.name
        self.startTime = startTime
    }

    func isAllowed(currentPID: pid_t) -> Bool {
        id > 1 && id != currentPID && name.lowercased() != "loginwindow" && name.lowercased() != "monny"
    }
}

/// Freezes the selected app and sampled members before a menu or confirmation can become stale.
nonisolated struct ProcessTerminationRequest: Sendable {
    let target: ProcessTarget
    let helpers: [ProcessTarget]

    init?(row: ProcessUsage, processes: [ProcessUsage], currentPID: pid_t = getpid()) {
        guard let target = ProcessTarget(row), target.isAllowed(currentPID: currentPID) else { return nil }
        let members = row.app == nil ? [] : processes.filter {
            $0.app?.pid == row.id && $0.app?.startTime == row.app?.startTime && $0.id != row.id
        }
        // An app responsible for Monny must not indirectly terminate the monitor either.
        guard members.allSatisfy({ $0.id != currentPID }) else { return nil }
        self.target = target
        self.helpers = members.compactMap(ProcessTarget.init).filter { $0.isAllowed(currentPID: currentPID) }
    }
}

nonisolated enum ProcessTerminationFailure: Error, Equatable {
    case gone, changed, protected, denied, rejected, partial

    var message: LocalizedStringResource {
        switch self {
        case .gone, .changed: "This process is no longer available. The list has been refreshed."
        case .protected: "Monny cannot end this process."
        case .denied: "macOS did not allow this process to be ended."
        case .rejected: "The quit request could not be sent. The list has been refreshed."
        case .partial: "Some processes could not be ended. The list has been refreshed."
        }
    }
}

/// Small system boundary used by behavioral tests without touching the user's applications.
nonisolated struct ProcessTerminationClient: Sendable {
    var identity: @Sendable (pid_t) throws -> ProcessIdentity = ProcessIdentity.read
    /// nil means Launch Services has no running application for this PID.
    var quitApplication: @Sendable (pid_t, Bool) -> Bool? = { pid, force in
        guard let app = NSRunningApplication(processIdentifier: pid) else { return nil }
        guard app.bundleIdentifier != Bundle.main.bundleIdentifier else { return false }
        return force ? app.forceTerminate() : app.terminate()
    }
    var signal: @Sendable (pid_t, Int32) throws -> Void = { pid, signal in
        guard Darwin.kill(pid, signal) == 0 else {
            throw errno == ESRCH ? ProcessTerminationFailure.gone : ProcessTerminationFailure.denied
        }
    }
}

/// Serializes only explicit user requests; libproc validation and signals run off the main actor.
actor ProcessTerminator {
    private let client: ProcessTerminationClient
    private let currentPID: pid_t
    private let userID: uid_t

    init(client: ProcessTerminationClient = .init(), currentPID: pid_t = getpid(), userID: uid_t = geteuid()) {
        self.client = client
        self.currentPID = currentPID
        self.userID = userID
    }

    /// A successful request is not proof of exit: an app may still show its own save dialog.
    func terminate(_ request: ProcessTerminationRequest, force: Bool) throws {
        try validate(request.target)
        if let accepted = client.quitApplication(request.target.id, force) {
            guard accepted else { throw ProcessTerminationFailure.rejected }
        } else {
            try validate(request.target)
            try client.signal(request.target.id, force ? SIGKILL : SIGTERM)
        }
        guard force else { return }
        var hadFailure = false
        for helper in request.helpers {
            do {
                try validate(helper)
                try client.signal(helper.id, SIGKILL)
            } catch ProcessTerminationFailure.gone {
                // The app or macOS may already have cleaned up this member.
            } catch {
                hadFailure = true
            }
        }
        if hadFailure { throw ProcessTerminationFailure.partial }
    }

    private func validate(_ target: ProcessTarget) throws {
        guard target.isAllowed(currentPID: currentPID) else { throw ProcessTerminationFailure.protected }
        let live = try client.identity(target.id)
        guard live.startTime == target.startTime else { throw ProcessTerminationFailure.changed }
        guard live.userID == userID else { throw ProcessTerminationFailure.denied }
        guard live.name.lowercased() != "loginwindow", live.name.lowercased() != "monny" else {
            throw ProcessTerminationFailure.protected
        }
    }
}
