import SwiftUI

/// Window Overview: the KPI row with current values, then history. Until the sampler exists
/// (CORE-001) values are unavailable and the charts show the first-launch state.
struct OverviewPage: View {
    var body: some View {
        VStack(spacing: Theme.spaceL) {
            HStack(spacing: Theme.spaceL) {
                KPICard(title: "CPU", symbol: "cpu", color: Theme.metricCPU)
                KPICard(title: "Memory", symbol: "memorychip", color: Theme.metricMemory)
                KPICard(title: "Temperature", symbol: "thermometer.medium", color: Theme.metricHeat)
                if SystemInfo.hasBattery {
                    KPICard(title: "Battery", symbol: "battery.100percent", color: Theme.metricBattery)
                }
            }
            CollectingHistoryCard()
        }
    }
}

/// Summary card with the current value and a sparkline (`KPICard`).
struct KPICard: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MetricLabel(title: title, symbol: symbol, color: color)
            UnavailableValue(font: Theme.metricL)
            Spacer(minLength: 0)
            Text("Collecting history…").font(Theme.footnote).foregroundStyle(Theme.textTertiary)
            Capsule().fill(Theme.fillTrack).frame(height: 4)
        }
        .padding(Theme.spaceXL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 116)
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// The first-launch chart state (Sketch frame `09 · Window · Overview · First launch`).
struct CollectingHistoryCard: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.metricCPU)
                .accessibilityHidden(true)
            Text("Collecting history").font(Theme.headline).foregroundStyle(Theme.textPrimary)
            Text("Charts fill in while Monny runs. The 24 h and 7 d ranges are kept across restarts.")
                .font(Theme.footnote)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.space3XL)
        .frame(maxWidth: .infinity)
        .frame(height: 284)
        .card()
        .accessibilityElement(children: .combine)
    }
}
