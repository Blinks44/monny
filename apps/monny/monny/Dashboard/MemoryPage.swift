import SwiftUI

/// Window Memory (Sketch `03 · Window · Memory`).
struct MemoryPage: View {
    let sampler: Sampler
    @AppStorage(PreferenceKey.historyRange) private var range = HistoryRange.hour

    private var memory: MemoryUsage? { sampler.snapshot?.memory }

    var body: some View {
        let tier = sampler.history.tier(range)
        VStack(spacing: Theme.spaceL) {
            HStack(spacing: Theme.spaceL) {
                KPICard(title: "Used", symbol: "memorychip", color: Theme.metricMemory, value: memory?.used.memoryText,
                        detail: memory.map { Text("of \($0.total.memoryText) · \($0.fraction.percentText)") },
                        points: tier.series(.memory), domain: 0...1)
                KPICard(title: "Pressure", symbol: "waveform.path.ecg", color: Theme.metricBattery,
                        value: memory?.pressureLevel?.percentText, detail: pressureDetail,
                        points: tier.series(.memoryPressure), domain: 0...1)
                KPICard(title: "Swap", symbol: "internaldrive", color: Theme.metricDisk, value: memory?.swapUsed.memoryText,
                        detail: memory?.swapInsPerMinute.map { Text("swap-ins \(Int($0.rounded())) / min") },
                        points: tier.series(.swap))
                KPICard(title: "Compressed", symbol: "rectangle.compress.vertical", color: Theme.metricCPU,
                        value: memory?.compressed.memoryText,
                        detail: memory?.compressionRatio.map { Text("ratio \($0.formatted(.number.precision(.fractionLength(1)))) ×") },
                        points: tier.series(.compressed))
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                CompositionCard(memory: memory, pressure: tier, range: range)
                PressureCard(memory: memory).frame(width: 244)
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                ProcessListCard("Top processes by memory", columns: ("CPU", "Memory"), processes: sampler.snapshot?.processes ?? [],
                                color: Theme.metricMemory, value: { Double($0.memory) },
                                primary: { $0.cpu.cpuShareText }, secondary: { $0.memory.memoryText })
                MemoryDetailsCard(memory: memory).frame(width: 244)
            }
        }
        .onAppear { sampler.setProcessListVisible(true) }
        .onDisappear { sampler.setProcessListVisible(false) }
    }

    /// "Normal · no swapping".
    private var pressureDetail: Text? {
        guard let memory else { return nil }
        let level = PressureText.text(for: memory.pressure)
        let swapping = (memory.swapInsPerMinute ?? 0) > 0
        return swapping ? Text("\(level) · swapping") : Text("\(level) · no swapping")
    }
}

enum PressureText {
    static func text(for pressure: MemoryUsage.Pressure) -> Text {
        switch pressure {
        case .normal: Text("Normal")
        case .warning: Text("High")
        case .critical: Text("Critical")
        }
    }
}

/// Stacked bar of what fills memory, its legend, and pressure over the range with its zones.
private struct CompositionCard: View {
    let memory: MemoryUsage?
    let pressure: HistoryTier
    let range: HistoryRange

    private var parts: [(title: LocalizedStringKey, bytes: Int64, color: Color)] {
        guard let memory else { return [] }
        return [("App", memory.app, Theme.metricMemory), ("Wired", memory.wired, Theme.metricCPU),
                ("Compressed", memory.compressed, Theme.metricDisk), ("Cached files", memory.cached, Theme.metricNetworkLight),
                ("Free", memory.free, Theme.fillTrack)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader("Memory composition", subtitle: memory.map {
                Text("\($0.total.memoryText) unified · \($0.used.memoryText) used · \(max($0.total - $0.used, 0).memoryText) available")
            })
            bar
            legend
            Text("Memory pressure · \(range.periodName)").font(Theme.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
            let points = pressure.series(.memoryPressure)
            if points.count > 1 {
                HistoryChart(series: [.init(id: "pressure", points: points, color: Theme.statusSuccessText)],
                             tier: pressure, range: range, yDomain: 0...1, yTicks: [], format: { $0.percentText },
                             bands: [(0...0.5, Theme.statusSuccessBg.opacity(0.5)), (0.5...0.8, Theme.statusWarningBg.opacity(0.6)),
                                     (0.8...1, Theme.statusDangerBg.opacity(0.6))],
                             showsAxes: false)
            } else {
                Text("Collecting history…").font(Theme.footnote).foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .dashboardCard(height: 284)
    }

    private var bar: some View {
        GeometryReader { proxy in
            let total = Double(max(parts.map(\.bytes).reduce(0, +), 1))
            HStack(spacing: 3) {
                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    RoundedRectangle(cornerRadius: 5, style: .continuous).fill(part.color)
                        .frame(width: max((proxy.size.width - 12) * Double(part.bytes) / total, 0))
                }
            }
        }
        .frame(height: 22)
        .background(parts.isEmpty ? Theme.fillTrack : .clear, in: .rect(cornerRadius: 5, style: .continuous))
        .accessibilityHidden(true)
    }

    private var legend: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3), alignment: .leading, spacing: 6) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                HStack(alignment: .top, spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(part.color).frame(width: 9, height: 9).padding(.top, 2)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(part.title).font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                        Text(part.bytes.memoryText).font(Theme.bodyEmphasized.weight(.bold)).foregroundStyle(Theme.textPrimary)
                            .monospacedDigit()
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// Pressure ring: green up to 50 %, amber to 80 %, red above, with macOS's own level as a chip.
private struct PressureCard: View {
    let memory: MemoryUsage?

    private var color: Color {
        switch memory?.pressureLevel ?? 0 {
        case ..<0.5: Theme.metricBattery
        case ..<0.8: Theme.metricDisk
        default: Theme.statusDanger
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            CardHeader("Pressure", subtitle: Text("How hard macOS works to free memory"))
            Spacer(minLength: 8)
            RingGauge(fraction: memory?.pressureLevel, color: color, diameter: 108, lineWidth: 12)
                .overlay {
                    VStack(spacing: 0) {
                        if let level = memory?.pressureLevel {
                            Text(level.percentText).font(Theme.metricL).foregroundStyle(Theme.textPrimary).monospacedDigit()
                        } else {
                            UnavailableValue(font: Theme.metricL)
                        }
                        Text("pressure").font(Theme.footnote).foregroundStyle(Theme.textTertiary)
                    }
                }
            Spacer(minLength: 8)
            if let pressure = memory?.pressure {
                switch pressure {
                case .normal: Chip(title: "Normal", symbol: "checkmark.circle.fill", kind: .success)
                case .warning: Chip(title: "High", symbol: "exclamationmark.circle.fill", kind: .warning)
                case .critical: Chip(title: "Critical", symbol: "exclamationmark.triangle.fill", kind: .danger)
                }
            }
            Text("Yellow from 50%, red from 80%.").font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                .padding(.top, 10)
        }
        .dashboardCard(height: 284)
    }
}

private struct MemoryDetailsCard: View {
    let memory: MemoryUsage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("Details").padding(.bottom, 6)
            FactRow(title: "Wired", value: memory.map { Text($0.wired.memoryText) }, height: 30)
            FactRow(title: "Purgeable", value: memory.map { Text($0.purgeable.memoryText) }, height: 30)
            FactRow(title: "Page-ins / s", value: memory?.pageInsPerSecond.map { Text(Int($0.rounded()).formatted()) }, height: 30)
            FactRow(title: "Swap file", value: memory.map { $0.swapUsed > 0 ? Text($0.swapUsed.memoryText) : Text("None") }, isLast: true, height: 30)
        }
        .dashboardCard(height: 176)
    }
}
