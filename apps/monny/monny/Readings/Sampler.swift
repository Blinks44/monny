import Foundation
import OSLog

/// Everything read in one sampling pass. `nil` means unavailable, never zero.
nonisolated struct Snapshot: Sendable {
    var cpu: CPULoad?
    var memory: MemoryUsage?
    var disk: DiskUsage?
    var network: NetworkRates?
    var battery: BatteryReading?
    var thermalState: ProcessInfo.ThermalState
    var processes: [ProcessUsage]
}

/// Owns the readers and their previous counters; runs off the main actor.
actor ReadingSource {
    private var cpu = CPUReader()
    private var disk = DiskReader()
    private var network = NetworkReader()
    private var processes = ProcessReader()
    private let memory = MemoryReader()
    private let power = PowerReader()
    private let signposter = OSSignposter(subsystem: "blinks44.monny", category: "Sampler")

    /// Process enumeration is most of a pass's cost, so it runs only while a process list is shown.
    func sample(includeProcesses: Bool) -> Snapshot {
        let state = signposter.beginInterval("Sample")
        defer { signposter.endInterval("Sample", state) }
        return Snapshot(cpu: cpu.read(), memory: memory.read(), disk: disk.read(), network: network.read(),
                        battery: power.read(), thermalState: ProcessInfo.processInfo.thermalState,
                        processes: includeProcesses ? processes.read() : [])
    }
}

/// The one shared sampler. It reads at the user's refresh rate while the popover or the
/// dashboard is visible and stops otherwise; history and charge control will add a slower
/// background cadence when they exist.
@Observable
final class Sampler {
    enum Surface: Hashable { case popover, dashboard }

    private(set) var snapshot: Snapshot?
    private(set) var batteryHealth: BatteryHealth?

    @ObservationIgnored private let source = ReadingSource()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var visible: Set<Surface> = []
    @ObservationIgnored private var healthDate: Date?
    /// Set while a process list is on screen.
    @ObservationIgnored var showsProcesses = false

    func setVisible(_ surface: Surface, _ isVisible: Bool) {
        if isVisible { visible.insert(surface) } else { visible.remove(surface) }
        if visible.isEmpty { stop() } else { start() }
    }

    private func start() {
        guard task == nil else { return }
        refreshHealthIfNeeded()
        task = Task { [weak self, source] in
            // The first pass only primes the delta counters (CPU ticks, bytes, process times).
            _ = await source.sample(includeProcesses: self?.showsProcesses ?? false)
            try? await Task.sleep(for: .milliseconds(500))
            while !Task.isCancelled {
                let snapshot = await source.sample(includeProcesses: self?.showsProcesses ?? false)
                guard let self, !Task.isCancelled else { return }
                self.snapshot = snapshot
                let interval = max(UserDefaults.standard.integer(forKey: PreferenceKey.refreshInterval), 1)
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    private func stop() {
        task?.cancel()
        task = nil
    }

    /// Battery health changes over weeks; read it at most every six hours.
    private func refreshHealthIfNeeded() {
        guard SystemInfo.hasBattery, healthDate.map({ Date.now.timeIntervalSince($0) > 6 * 3_600 }) ?? true else { return }
        healthDate = .now
        Task { [weak self] in
            let health = await BatteryHealthReader.read()
            self?.batteryHealth = health
        }
    }
}
