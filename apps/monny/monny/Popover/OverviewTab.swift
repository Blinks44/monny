import SwiftUI

/// Popover Overview: CPU, memory, disk, network, cores and the battery (or thermal) strip.
/// Temperatures arrive with CORE-002; the network sparkline with history (phase 3).
struct OverviewTab: View {
    let snapshot: Snapshot?

    var body: some View {
        VStack(spacing: Theme.spaceM) {
            HStack(spacing: Theme.spaceM) {
                RingCard(title: "CPU", symbol: "cpu", color: Theme.metricCPU, unit: "load",
                         fraction: snapshot?.cpu?.total, footnote: cpuFootnote)
                RingCard(title: "Memory", symbol: "memorychip", color: Theme.metricMemory, unit: "used",
                         fraction: snapshot?.memory?.fraction, footnote: memoryFootnote) {
                    if let pressure = snapshot?.memory?.pressure { PressureChip(pressure: pressure) }
                }
            }
            HStack(spacing: Theme.spaceM) {
                DiskCard(disk: snapshot?.disk)
                NetworkCard(network: snapshot?.network)
            }
            CoresCard(cpu: snapshot?.cpu)
            if SystemInfo.hasBattery {
                BatteryStrip(battery: snapshot?.battery)
            } else {
                ThermalStrip(state: snapshot?.thermalState)
            }
        }
    }

    private var cpuFootnote: Text? {
        guard let cpu = snapshot?.cpu, let p = cpu.performance, let e = cpu.efficiency else { return nil }
        return Text("P \(p.percentText)  ·  E \(e.percentText)")
    }

    private var memoryFootnote: Text? {
        guard let memory = snapshot?.memory else { return nil }
        return Text("\(memory.used.memoryText) of \(memory.total.memoryText)")
    }
}

/// CPU or memory: header with an optional chip, ring gauge with the value inside, footnote below.
private struct RingCard<Accessory: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color
    let unit: LocalizedStringKey
    let fraction: Double?
    let footnote: Text?
    @ViewBuilder var accessory: Accessory

    init(title: LocalizedStringKey, symbol: String, color: Color, unit: LocalizedStringKey, fraction: Double?,
         footnote: Text?, @ViewBuilder accessory: () -> Accessory = { EmptyView() }) {
        self.title = title
        self.symbol = symbol
        self.color = color
        self.unit = unit
        self.fraction = fraction
        self.footnote = footnote
        self.accessory = accessory()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                MetricLabel(title: title, symbol: symbol, color: color)
                Spacer(minLength: 0)
                accessory
            }
            Spacer(minLength: 0)
            RingGauge(fraction: fraction, color: color)
                .frame(width: 68, height: 68)
                .overlay {
                    VStack(spacing: 0) {
                        if let fraction {
                            Text(fraction.percentText).font(Theme.metricM).foregroundStyle(Theme.textPrimary)
                                .monospacedDigit()
                        } else {
                            UnavailableValue(font: Theme.metricM)
                        }
                        Text(unit).font(Theme.caption).foregroundStyle(Theme.textTertiary)
                    }
                }
            Spacer(minLength: 0)
            (footnote ?? Text(verbatim: " ")).font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                .monospacedDigit()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 152)
        .card()
        .accessibilityElement(children: .combine)
    }
}

private struct PressureChip: View {
    let pressure: MemoryUsage.Pressure

    var body: some View {
        switch pressure {
        case .normal: Chip(title: "Normal", kind: .memory)
        case .warning: Chip(title: "High", kind: .warning)
        case .critical: Chip(title: "Critical", kind: .danger)
        }
    }
}

private struct DiskCard: View {
    let disk: DiskUsage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetricLabel(title: "Disk", symbol: "internaldrive", color: Theme.metricDisk)
            Spacer(minLength: 0)
            if let disk {
                Text(disk.free.storageText).font(Theme.metricL).foregroundStyle(Theme.textPrimary)
                Text("free of \(disk.total.storageText)").font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            } else {
                UnavailableValue(font: Theme.metricL)
                Text("free").font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            }
            CapsuleBar(fraction: disk?.usedFraction, color: Theme.metricDisk).padding(.top, Theme.spaceL)
            Spacer(minLength: 0)
            if let read = disk?.readRate, let write = disk?.writeRate {
                Text("R \(read.rateText)  ·  W \(write.rateText)")
                    .font(Theme.footnote).foregroundStyle(Theme.textSecondary).lineLimit(1).minimumScaleFactor(0.8)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 152)
        .card()
        .accessibilityElement(children: .combine)
    }
}

private struct NetworkCard: View {
    let network: NetworkRates?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MetricLabel(title: "Network", symbol: "network", color: Theme.metricNetwork)
            Spacer(minLength: 0)
            rate(network?.download, symbol: "arrow.down", color: Theme.textPrimary, font: Theme.metricS)
                .accessibilityLabel(Text("Download"))
            rate(network?.upload, symbol: "arrow.up", color: Theme.metricUpload, font: Theme.bodyEmphasized)
                .accessibilityLabel(Text("Upload"))
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 152)
        .card()
        .accessibilityElement(children: .combine)
    }

    private func rate(_ value: Double?, symbol: String, color: Color, font: Font) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).foregroundStyle(color).accessibilityHidden(true)
            if let value {
                Text(value.rateText).foregroundStyle(color).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            } else {
                UnavailableValue(font: font)
            }
        }
        .font(font)
    }
}

/// One bar per core, Performance cores first as in Sketch.
private struct CoresCard: View {
    let cpu: CPULoad?

    private var bars: [(load: Double?, kind: CoreKind)] {
        guard let cpu else {
            let kinds = Array(repeating: CoreKind.performance, count: SystemInfo.performanceCores)
                + Array(repeating: CoreKind.efficiency, count: SystemInfo.efficiencyCores)
            return kinds.map { (nil, $0) }
        }
        let indexed = zip(cpu.cores, cpu.kinds).map { (load: Optional($0), kind: $1) }
        return indexed.filter { $0.kind == .performance } + indexed.filter { $0.kind == .efficiency }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("Cores").font(Theme.label).foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 0)
                legend("\(SystemInfo.performanceCores) Performance", color: Theme.metricCPU)
                legend("\(SystemInfo.efficiencyCores) Efficiency", color: Theme.metricCPUEfficiency)
            }
            HStack(spacing: 6) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Theme.fillTrack)
                        .overlay(alignment: .bottom) {
                            if let load = bar.load {
                                GeometryReader { proxy in
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(bar.kind == .performance ? Theme.metricCPU : Theme.metricCPUEfficiency)
                                        .frame(height: max(proxy.size.height * load, 3))
                                        .frame(maxHeight: .infinity, alignment: .bottom)
                                }
                            }
                        }
                        .frame(height: 38)
                }
            }
            .accessibilityHidden(true)
        }
        .padding(14)
        .card()
        .accessibilityElement(children: .combine)
    }

    private func legend(_ title: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title).font(Theme.caption).foregroundStyle(Theme.textSecondary)
        }
    }
}

/// Battery level and state; the charge-limit switch arrives with the helper (PLAN phase 4).
private struct BatteryStrip: View {
    let battery: BatteryReading?

    var body: some View {
        HStack(spacing: 14) {
            BatteryGlyph(level: battery?.level)
            VStack(alignment: .leading, spacing: 2) {
                if let battery {
                    Text(battery.level.percentText).font(Theme.metricM).foregroundStyle(Theme.textPrimary)
                    BatteryStatusText(battery: battery).font(Theme.footnote.weight(.semibold))
                        .foregroundStyle(battery.state == .onBattery ? Theme.textSecondary : Theme.statusSuccessText)
                } else {
                    UnavailableValue(font: Theme.metricM)
                    Text("Battery").font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.spaceXL)
        .frame(height: 68)
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// Small battery drawing with the level in the metric color.
struct BatteryGlyph: View {
    let level: Double?

    var body: some View {
        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Theme.textTertiary, lineWidth: 2)
                .overlay(alignment: .leading) {
                    if let level {
                        GeometryReader { proxy in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Theme.metricBattery.gradient)
                                .frame(width: max((proxy.size.width - 6) * level, 2))
                                .padding(3)
                        }
                    }
                }
                .frame(width: 40, height: 22)
            Capsule().fill(Theme.textTertiary).frame(width: 3, height: 8)
        }
        .accessibilityHidden(true)
    }
}

/// "Charging · Adapter 96 W", "On adapter · not charging" or "On battery · 2 hr 10 min left".
struct BatteryStatusText: View {
    let battery: BatteryReading

    var body: some View { Self.text(for: battery) }

    static func text(for battery: BatteryReading) -> Text {
        switch battery.state {
        case .charging:
            if let watts = battery.adapterWatts { return Text("Charging · Adapter \(watts) W") }
            return Text("Charging")
        case .onAdapter:
            return battery.isFullyCharged ? Text("Charged · on adapter") : Text("On adapter · not charging")
        case .onBattery:
            if let left = battery.timeToEmpty { return Text("On battery · \(left.estimateText) left") }
            return Text("On battery")
        }
    }
}

/// Shown instead of the battery strip on a Mac without a battery.
private struct ThermalStrip: View {
    let state: ProcessInfo.ThermalState?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.statusSuccessText)
                .frame(width: 36, height: 36)
                .background(Theme.statusSuccessBg, in: .rect(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                if let state {
                    ThermalStateText(state: state).font(Theme.metricM).foregroundStyle(Theme.textPrimary)
                } else {
                    UnavailableValue(font: Theme.metricM)
                }
                Text("Thermal state").font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.spaceXL)
        .frame(height: 68)
        .card()
        .accessibilityElement(children: .combine)
    }
}

struct ThermalStateText: View {
    let state: ProcessInfo.ThermalState

    var body: some View {
        switch state {
        case .fair: Text("Fair")
        case .serious: Text("Serious")
        case .critical: Text("Critical")
        default: Text("Nominal")
        }
    }
}
