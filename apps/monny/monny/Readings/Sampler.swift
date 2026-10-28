import Foundation
import OSLog

/// Everything read in one sampling pass. `nil` means unavailable, never zero.
nonisolated struct Snapshot: Sendable {
    var cpu: CPULoad?
    var memory: MemoryUsage?
    var disk: DiskUsage?
    var network: NetworkRates?
    var battery: BatteryReading?
    var sensors: SensorReading?
    var thermalState: ProcessInfo.ThermalState
    var processes: [ProcessUsage]
    /// 1, 5 and 15 minutes.
    var loadAverage: [Double]? = nil
    var gpu: GPUReading? = nil
}

/// Owns the readers and their previous counters; runs off the main actor.
actor ReadingSource {
    private var cpu = CPUReader()
    private var disk = DiskReader()
    private var network = NetworkReader()
    private var processes = ProcessReader()
    private var memory = MemoryReader()
    private var power = PowerReader()
    private let sensors = SensorReader()
    private let signposter = OSSignposter(subsystem: "blinks44.monny", category: "Sampler")

    /// Process enumeration is most of a pass's cost, so it runs only while a process list is shown,
    /// or for the busy app alert while the whole CPU does at least the work of its threshold;
    /// free disk space is refreshed only while something is visible.
    func sample(isVisible: Bool, includeProcesses: Bool, watchesBusyApps: Bool = false) -> Snapshot {
        let state = signposter.beginInterval("Sample")
        defer { signposter.endInterval("Sample", state) }
        let load = cpu.read()
        let mayHaveBusyApp = load.map { $0.total * Double($0.cores.count) >= AlertMonitor.busyAppCPU } ?? false
        return Snapshot(cpu: load, memory: memory.read(), disk: disk.read(includeSpace: isVisible), network: network.read(),
                        battery: power.read(), sensors: sensors.read(), thermalState: ProcessInfo.processInfo.thermalState,
                        processes: includeProcesses || (watchesBusyApps && mayHaveBusyApp) ? processes.read() : [],
                        loadAverage: LoadAverage.read(), gpu: GPUReading.read())
    }
}

/// The one shared sampler. It reads at the user's refresh rate while the popover or the
/// dashboard is visible or readings are shown in the menu bar, and every 10 s otherwise, which
/// is what history needs (its 1 h tier has 10 s buckets). Every pass is recorded in `history`.
@Observable
final class Sampler {
    enum Surface: Hashable { case popover, dashboard }

    private(set) var snapshot: Snapshot?
    private(set) var batteryHealth: BatteryHealth?
    private(set) var ssdHealth: SSDHealth?
    private(set) var busyProcesses = BusyProcesses()
    let history = History()
    /// Called on the main actor after every pass, for alerts.
    @ObservationIgnored var onSample: ((Snapshot) -> Void)?
    /// Values from outside the readers to record with each pass, such as AI quota.
    @ObservationIgnored var extraHistoryValues: () -> [HistoryMetric: Double] = { [:] }

    @ObservationIgnored private let source = ReadingSource()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var visible: Set<Surface> = []
    @ObservationIgnored private var healthDate: Date?
    @ObservationIgnored private var ssdHealthDate: Date?
    /// Process lists on screen (popover Processes, window Overview); processes are read while any is.
    @ObservationIgnored private var processLists = 0
    var showsProcesses: Bool { processLists > 0 }
    /// Menu bar readings follow the refresh rate, without the work done only for visible views.
    @ObservationIgnored var updatesMenuBar = false {
        didSet {
            if updatesMenuBar, !oldValue, visible.isEmpty, task != nil { restart(primed: true) }
        }
    }

    func setProcessListVisible(_ isVisible: Bool) {
        processLists = max(processLists + (isVisible ? 1 : -1), 0)
    }

    /// An explicit process action wakes the shared loop; it never starts a second sampler.
    func refreshProcesses() {
        guard task != nil, !visible.isEmpty, showsProcesses else { return }
        restart(primed: true)
    }

    /// Starts background sampling; called once at launch.
    func start() {
        guard task == nil else { return }
        restart(primed: false)
    }

    func setVisible(_ surface: Surface, _ isVisible: Bool) {
        let wasVisible = !visible.isEmpty
        if isVisible { visible.insert(surface) } else { visible.remove(surface) }
        // Becoming visible must not wait for the rest of a 10 s background pause.
        if !visible.isEmpty, !wasVisible { restart(primed: true) }
    }

    private func restart(primed: Bool) {
        task?.cancel()
        if !visible.isEmpty { refreshHealthIfNeeded() }
        task = Task { [weak self, source] in
            if !primed {
                // The first pass only primes the delta counters (CPU ticks, bytes, process times).
                _ = await source.sample(isVisible: false, includeProcesses: false)
                try? await Task.sleep(for: .milliseconds(500))
            }
            while !Task.isCancelled {
                guard let isVisible = self.map({ !$0.visible.isEmpty }) else { return }
                let snapshot = await source.sample(isVisible: isVisible, includeProcesses: isVisible && self?.showsProcesses == true,
                                                   watchesBusyApps: UserDefaults.standard.bool(forKey: PreferenceKey.notifyBusyApp))
                guard let self, !Task.isCancelled else { return }
                self.snapshot = snapshot
                busyProcesses.update(snapshot.processes, now: .now)
                history.record(snapshot, adding: extraHistoryValues())
                onSample?(snapshot)
                // Settings shows 2 s until the user picks a rate; `integer(forKey:)` would read 0 then.
                let refresh = max(UserDefaults.standard.object(forKey: PreferenceKey.refreshInterval) as? Int ?? 2, 1)
                let isFrequent = isVisible || self.updatesMenuBar
                try? await Task.sleep(for: .seconds(isFrequent ? refresh : 10))
            }
        }
    }

    /// Battery health changes over weeks; read it at most every six hours. SSD health is cheap,
    /// and its lifetime writes grow during the day, so it is read at most every hour.
    private func refreshHealthIfNeeded() {
        if ssdHealthDate.map({ Date.now.timeIntervalSince($0) > 3_600 }) ?? true {
            ssdHealthDate = .now
            Task { [weak self] in
                let health = await Task.detached { SSDHealthReader.read() }.value
                self?.ssdHealth = health
            }
        }
        guard SystemInfo.hasBattery, healthDate.map({ Date.now.timeIntervalSince($0) > 6 * 3_600 }) ?? true else { return }
        healthDate = .now
        Task { [weak self] in
            let health = await BatteryHealthReader.read()
            self?.batteryHealth = health
        }
    }
}
