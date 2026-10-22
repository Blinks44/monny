import SwiftUI

/// Sketch's Battery window: facts, recorded level and the system charge limit. Discharge,
/// sailing, heat protection, calibration and trips are deferred (SPEC §5), so they are not shown.
struct BatteryPage: View {
    let sampler: Sampler
    let controller: ChargeLimitController
    @AppStorage(PreferenceKey.historyRange) private var range = HistoryRange.hour
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius
    @State private var showsChargingGuidance = false

    private var battery: BatteryReading? { sampler.snapshot?.battery }

    var body: some View {
        let tier = sampler.history.tier(range)
        VStack(spacing: Theme.spaceL) {
            HStack(spacing: Theme.spaceL) {
                KPICard(title: "Level", symbol: "battery.100percent", color: Theme.metricBattery,
                        value: battery?.level.percentText, detail: powerSource,
                        points: tier.series(.battery), domain: 0...1)
                KPICard(title: "Health", symbol: "checkmark.shield.fill", color: Theme.metricMemory,
                        value: sampler.batteryHealth?.maximumCapacity.percentText,
                        detail: capacity, points: nil)
                KPICard(title: "Cycles", symbol: "arrow.clockwise", color: Theme.metricCPU,
                        value: battery?.cycleCount?.formatted(), detail: nil, points: nil)
                KPICard(title: "Power", symbol: "bolt.fill", color: Theme.metricDisk,
                        value: battery?.systemLoad?.wattsText, detail: powerFlow, footnote: powerSupply, points: nil)
            }
            // Both cards take the taller one's height, which grows with translated text.
            HStack(alignment: .top, spacing: Theme.spaceL) {
                chargeHistory(tier)
                chargingControls.frame(width: 244)
            }
            .fixedSize(horizontal: false, vertical: true)
            batteryDetails
        }
        .task { await controller.refresh() }
    }

    private var capacity: Text? {
        battery?.fullChargeCapacity.map { Text("\($0.formatted()) mAh") }
    }

    private var powerSource: Text? {
        guard let battery else { return nil }
        switch battery.state {
        case .charging: return Text("Charging")
        case .onAdapter: return Text("On adapter")
        case .onBattery: return Text("On battery")
        }
    }

    /// Where the power comes from (Sketch `18 · Battery · Power card`, without its “Mac uses ·”
    /// prefix, which does not fit the card at the minimum window width in any language).
    private var powerFlow: Text? {
        guard let battery, battery.systemLoad != nil else { return nil }
        switch battery.state {
        case .onBattery:
            return Text("From battery")
        case .charging:
            // A charge rate below 1 W rounds to “+0 W”, so it reads as from the adapter.
            if let watts = battery.batteryPower, watts >= 1 { return Text("+\(watts.wattsText) to battery") }
            return Text("From adapter")
        case .onAdapter:
            return Text("From adapter")
        }
    }

    /// The adapter's rating, or macOS's estimate of the time left on battery.
    private var powerSupply: Text? {
        guard let battery else { return nil }
        if battery.state == .onBattery {
            return battery.timeToEmpty.map { Text("\($0.estimateText) left") }
        }
        return battery.adapterWatts.map { Text("Adapter \($0) W") }
    }

    private func chargeHistory(_ tier: HistoryTier) -> some View {
        let levels = tier.series(.battery)
        return VStack(alignment: .leading, spacing: Theme.spaceL) {
            CardHeader(title: Text("Charge level") + Text(verbatim: " · ") + Text(range.batteryChartTitle),
                       subtitle: Text("Recorded battery level"))
            if levels.count > 1 {
                HistoryChart(series: [.init(id: "battery", points: levels, color: Theme.metricBattery, filled: true)],
                             tier: tier, range: range, yDomain: 0...1,
                             yTicks: [0, 0.2, 0.5, 0.8, 1], format: { $0.percentText })
                    .accessibilityLabel(Text("Charge level"))
                    .accessibilityValue(Text(battery?.level.percentText ?? String(localized: "Unavailable")))
            } else {
                CollectingHistoryContent().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .batteryCard(minHeight: 284)
    }

    private var chargingControls: some View {
        VStack(alignment: .leading, spacing: Theme.spaceL) {
            CardHeader("battery.charging.title") {
                Button { showsChargingGuidance = true } label: {
                    Image(systemName: "info.circle").foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(StaticButtonStyle())
                .accessibilityLabel(Text("macOS charging settings"))
                .popover(isPresented: $showsChargingGuidance) { MacOSChargingGuidance() }
            }
            NativeLimitControls(controller: controller)
            Spacer(minLength: 0)
            Text("macOS manages charging. The limit stays set when Monny quits.")
                .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Theme.textPrimary)
        .batteryCard(minHeight: 284)
    }

    private var batteryDetails: some View {
        VStack(alignment: .leading, spacing: Theme.spaceM) {
            CardHeader("Details")
            FactRow(title: "Temperature", value: sampler.snapshot?.sensors?.battery.map { Text($0.temperatureText(temperatureUnit)) })
            FactRow(title: "Full charge capacity", value: battery?.fullChargeCapacity.map { Text("\($0.formatted()) mAh") })
            FactRow(title: "Design capacity", value: battery?.designCapacity.map { Text("\($0.formatted()) mAh") }, isLast: true)
        }
        .dashboardCard(height: 176)
    }
}

private extension HistoryRange {
    var batteryChartTitle: LocalizedStringKey {
        switch self {
        case .minute: "1m"
        case .hour: "1h"
        case .day: "24h"
        case .week: "7d"
        }
    }
}

private extension View {
    /// Sketch's 284 pt card that grows with localized content.
    func batteryCard(minHeight: CGFloat) -> some View {
        padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(minHeight: minHeight, maxHeight: .infinity, alignment: .top)
            .card()
    }
}
