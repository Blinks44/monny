import SwiftUI

/// Popover Overview. Until the sampler exists (CORE-001) every reading shows as unavailable;
/// the layout and the static facts (core counts, battery presence) are real.
struct OverviewTab: View {
    var body: some View {
        VStack(spacing: Theme.spaceM) {
            HStack(spacing: Theme.spaceM) {
                RingCard(title: "CPU", symbol: "cpu", color: Theme.metricCPU, unit: "load")
                RingCard(title: "Memory", symbol: "memorychip", color: Theme.metricMemory, unit: "used")
            }
            HStack(spacing: Theme.spaceM) {
                DiskCard()
                NetworkCard()
            }
            CoresCard()
            if SystemInfo.hasBattery { BatteryStrip() } else { ThermalStrip() }
        }
    }
}

/// CPU or memory: header, ring gauge with the value inside, footnote below.
private struct RingCard: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color
    let unit: LocalizedStringKey

    var body: some View {
        VStack(spacing: 0) {
            HStack { MetricLabel(title: title, symbol: symbol, color: color); Spacer(minLength: 0) }
            Spacer(minLength: 0)
            RingGauge(fraction: nil, color: color)
                .frame(width: 68, height: 68)
                .overlay {
                    VStack(spacing: 0) {
                        UnavailableValue(font: Theme.metricM)
                        Text(unit).font(Theme.caption).foregroundStyle(Theme.textTertiary)
                    }
                }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 152)
        .card()
        .accessibilityElement(children: .combine)
    }
}

private struct DiskCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MetricLabel(title: "Disk", symbol: "internaldrive", color: Theme.metricDisk)
            Spacer(minLength: 0)
            UnavailableValue(font: Theme.metricL)
            Text("free").font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            CapsuleBar(fraction: nil, color: Theme.metricDisk).padding(.top, Theme.spaceL)
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 152)
        .card()
        .accessibilityElement(children: .combine)
    }
}

private struct NetworkCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MetricLabel(title: "Network", symbol: "network", color: Theme.metricNetwork)
            Spacer(minLength: 0)
            Label { UnavailableValue(font: Theme.metricS) } icon: {
                Image(systemName: "arrow.down").foregroundStyle(Theme.textPrimary)
            }
            .accessibilityLabel(Text("Download"))
            Label { UnavailableValue(font: Theme.metricS) } icon: {
                Image(systemName: "arrow.up").foregroundStyle(Theme.metricUpload)
            }
            .accessibilityLabel(Text("Upload"))
            Spacer(minLength: 0)
        }
        .font(Theme.metricS)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 152)
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// One track per core, Performance cores first. Tracks stay empty until loads are read.
private struct CoresCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("Cores").font(Theme.label).foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 0)
                legend("\(SystemInfo.performanceCores) Performance", color: Theme.metricCPU)
                legend("\(SystemInfo.efficiencyCores) Efficiency", color: Theme.metricCPUEfficiency)
            }
            HStack(spacing: 6) {
                ForEach(0..<max(SystemInfo.performanceCores + SystemInfo.efficiencyCores, 1), id: \.self) { _ in
                    Capsule().fill(Theme.fillTrack).frame(height: 38)
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

/// Battery level and mode; the charge-limit switch arrives with the helper (PLAN phase 4).
private struct BatteryStrip: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "battery.0percent")
                .font(.system(size: 28))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                UnavailableValue(font: Theme.metricM)
                Text("Battery").font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.spaceXL)
        .frame(height: 68)
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// Shown instead of the battery strip on a Mac without a battery.
private struct ThermalStrip: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.statusSuccessText)
                .frame(width: 36, height: 36)
                .background(Theme.statusSuccessBg, in: .rect(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                UnavailableValue(font: Theme.metricM)
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
