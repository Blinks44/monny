import SwiftUI

/// Window CPU (Sketch `02 · Window · CPU`). Apple silicon exposes no CPU frequency without root
/// (only `powermetrics` reads it), so the Frequency card shows it as unavailable.
struct CPUPage: View {
    let sampler: Sampler
    @AppStorage(PreferenceKey.historyRange) private var range = HistoryRange.hour
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius

    private var snapshot: Snapshot? { sampler.snapshot }

    var body: some View {
        let tier = sampler.history.tier(range)
        VStack(spacing: Theme.spaceL) {
            HStack(spacing: Theme.spaceL) {
                KPICard(title: "Load", symbol: "cpu", color: Theme.metricCPU, value: snapshot?.cpu?.total.percentText,
                        detail: snapshot?.cpu.map { Text("user \($0.user.percentText) · system \($0.system.percentText)") },
                        points: tier.series(.cpu), domain: 0...1)
                KPICard(title: "Die temperature", symbol: "thermometer.medium", color: Theme.metricHeat,
                        value: snapshot?.sensors?.cpu?.temperatureText(temperatureUnit),
                        detail: temperatureDetail(tier), points: tier.series(.cpuTemperature))
                KPICard(title: "Frequency", symbol: "gauge.with.dots.needle.50percent", color: Theme.metricNetwork, value: nil,
                        detail: Text("Not available"), points: nil)
                KPICard(title: "Load average", symbol: "waveform.path.ecg", color: Theme.metricMemory,
                        value: snapshot?.loadAverage?.first?.formatted(.number.precision(.fractionLength(2))),
                        detail: snapshot?.loadAverage.map { Text("1 min · 5 min \($0[1].formatted(.number.precision(.fractionLength(2))))") },
                        points: tier.series(.loadAverage))
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                CPUHistoryCard(tier: tier, range: range)
                PerCoreCard(cpu: snapshot?.cpu).frame(width: 244)
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                ProcessListCard("Top processes by CPU", columns: ("CPU", "Memory"), processes: snapshot?.processes ?? [],
                                color: Theme.metricCPU, value: \.cpu, primary: { $0.cpu.cpuShareText }, secondary: { $0.memory.memoryText })
                CPUDetailsCard(snapshot: snapshot).frame(width: 244)
            }
        }
        .onAppear { sampler.setProcessListVisible(true) }
        .onDisappear { sampler.setProcessListVisible(false) }
    }

    /// "peak 71 °C · nominal".
    private func temperatureDetail(_ tier: HistoryTier) -> Text? {
        guard let snapshot else { return nil }
        let state = ThermalStateText.text(for: snapshot.thermalState)
        guard let peak = tier.series(.cpuTemperature).map(\.value).max() else { return state }
        return Text("peak \(peak.temperatureText(temperatureUnit)) · \(state)")
    }
}

/// One bar per core in two columns, Performance and Efficiency (`Card · Per-core load`).
private struct PerCoreCard: View {
    let cpu: CPULoad?

    private func cores(_ kind: CoreKind) -> [Double?] {
        guard let cpu else {
            let count = kind == .performance ? SystemInfo.performanceCores : SystemInfo.efficiencyCores
            return Array(repeating: nil, count: count)
        }
        return zip(cpu.cores, cpu.kinds).filter { $0.1 == kind }.map(\.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader("Per-core load",
                       subtitle: Text("\(SystemInfo.performanceCores) P-cores · \(SystemInfo.efficiencyCores) E-cores"))
            HStack(alignment: .top, spacing: 12) {
                column(prefix: "P", loads: cores(.performance), color: Theme.metricCPU)
                column(prefix: "E", loads: cores(.efficiency), color: Theme.metricCPUEfficiency)
            }
            Spacer(minLength: 0)
        }
        .dashboardCard(height: 284)
    }

    /// One row per core; rows tighten so up to ten fit the card.
    private func column(prefix: String, loads: [Double?], color: Color) -> some View {
        VStack(spacing: loads.count > 6 ? 4 : 8) {
            ForEach(Array(loads.enumerated()), id: \.offset) { index, load in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(verbatim: "\(prefix)\(index + 1)").font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                        Spacer(minLength: 2)
                        if let load {
                            Text(load.percentText).font(Theme.footnote.weight(.bold)).foregroundStyle(Theme.textPrimary).monospacedDigit()
                        }
                    }
                    CapsuleBar(fraction: load, color: color, height: 5)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

private struct CPUDetailsCard: View {
    let snapshot: Snapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("Details").padding(.bottom, 6)
            FactRow(title: "Chip", value: Text(verbatim: SystemInfo.chipName), height: 30)
            FactRow(title: "GPU", value: gpu, height: 30)
            FactRow(title: "Thermal state", value: snapshot.map { ThermalStateText.text(for: $0.thermalState) },
                    valueColor: thermalColor, height: 30)
            TimelineView(.periodic(from: .now, by: 60)) { _ in
                FactRow(title: "Uptime", value: Text(verbatim: SystemInfo.uptimeText(ProcessInfo.processInfo.systemUptime)),
                        isLast: true, height: 30)
            }
        }
        .dashboardCard(height: 176)
    }

    /// "32 cores · 7%".
    private var gpu: Text? {
        guard let gpu = snapshot?.gpu else { return nil }
        switch (gpu.cores, gpu.utilization) {
        case let (cores?, load?): return Text("\(cores) cores · \(load.percentText)")
        case let (cores?, nil): return Text("\(cores) cores")
        case let (nil, load?): return Text(load.percentText)
        default: return nil
        }
    }

    private var thermalColor: Color {
        switch snapshot?.thermalState {
        case .fair: Theme.statusWarningText
        case .serious, .critical: Theme.statusDangerText
        default: Theme.statusSuccessText
        }
    }
}
