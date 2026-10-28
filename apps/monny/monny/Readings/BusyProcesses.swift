import Foundation

/// When each process started keeping one core busy (`AlertMonitor.busyAppCPU`), for the popover's
/// Needs attention section. Durations are only what Monny observed, so they never overstate.
nonisolated struct BusyProcesses: Equatable {
    /// Shorter spikes, such as a page load or a compile step, are not worth attention.
    static let minimumDuration: TimeInterval = 60
    static let limit = 3

    private var since: [pid_t: (start: UInt64, date: Date)] = [:]

    static func == (first: Self, second: Self) -> Bool {
        first.since.mapValues(\.date) == second.since.mapValues(\.date)
    }

    /// A pass without processes means they were not read because the CPU was not busy enough for
    /// any process to pass the threshold, so every episode ends.
    mutating func update(_ processes: [ProcessUsage], now: Date) {
        var current: [pid_t: (start: UInt64, date: Date)] = [:]
        for process in processes where process.cpu >= AlertMonitor.busyAppCPU {
            guard let start = process.startTime else { continue }
            let previous = since[process.id].flatMap { $0.start == start ? $0.date : nil }
            current[process.id] = (start, previous ?? now)
        }
        since = current
    }

    /// The longest-busy processes, each with how long it has been busy.
    func attention(in processes: [ProcessUsage], now: Date, currentPID: pid_t = getpid()) -> [(process: ProcessUsage, duration: TimeInterval)] {
        processes.compactMap { process -> (process: ProcessUsage, duration: TimeInterval)? in
            guard let entry = since[process.id], entry.start == process.startTime, process.cpu >= AlertMonitor.busyAppCPU,
                  ProcessTarget(process)?.isAllowed(currentPID: currentPID) == true else { return nil }
            let duration = now.timeIntervalSince(entry.date)
            return duration >= Self.minimumDuration ? (process, duration) : nil
        }
        .sorted { $0.duration == $1.duration ? $0.process.id < $1.process.id : $0.duration > $1.duration }
        .prefix(Self.limit)
        .map { $0 }
    }
}
