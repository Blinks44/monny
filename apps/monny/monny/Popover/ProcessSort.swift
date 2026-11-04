import Foundation

/// The popover's sort order, applied after searching the full process snapshot and grouping apps.
nonisolated enum ProcessSort: Hashable {
    case cpu, memory, energy, network

    /// Searches before taking the visible rows; equal values keep a stable PID order.
    func rows(in processes: [ProcessUsage], matching query: String, limit: Int) -> [ProcessUsage] {
        let groups = ProcessUsage.groupedByApp(processes, matching: query)
        let sorted = groups.sorted { first, second in
            switch self {
            case .cpu:
                return first.cpu == second.cpu ? first.id < second.id : first.cpu > second.cpu
            case .memory:
                return first.memory == second.memory ? first.id < second.id : first.memory > second.memory
            case .network:
                let a = first.network.map { $0.download + $0.upload } ?? -1
                let b = second.network.map { $0.download + $0.upload } ?? -1
                return a == b ? first.id < second.id : a > b
            case .energy:
                return first.power == second.power ? first.id < second.id : first.power > second.power
            }
        }
        return Array(sorted.prefix(max(limit, 0)))
    }
}
