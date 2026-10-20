import AppKit

/// App-only wake barrier, armed before preparation. It neither requests nor delays sleep.
@MainActor
final class SystemWakeObserver {
    private let center: NotificationCenter
    private var tokens: [NSObjectProtocol] = []
    private var sleepObserved = false
    private nonisolated let events: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init(center: NotificationCenter = NSWorkspace.shared.notificationCenter) {
        self.center = center
        (events, continuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1))
        tokens = [
            center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.sleepObserved = true }
            },
            center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.sleepObserved else { return }
                    self.continuation.yield(())
                    self.continuation.finish()
                }
            }
        ]
    }

    /// Transition/DarkWake has its own finite awake-time bound; it never consumes post-wake status attempts.
    nonisolated func wait(timeout: Duration = .seconds(60)) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { [events] in
                for await _ in events {
                    try Task.checkCancellation()
                    return
                }
                throw CancellationError()
            }
            group.addTask {
                try await Task.sleep(for: timeout, clock: .suspending)
                throw AdapterSleepVerificationCommand.Failure.wakeNotObserved
            }
            defer { group.cancelAll() }
            try await group.next()
            try Task.checkCancellation()
        }
    }

    func stop() {
        tokens.forEach(center.removeObserver)
        tokens.removeAll()
        continuation.finish()
    }

    isolated deinit {
        tokens.forEach(center.removeObserver)
        continuation.finish()
    }
}
