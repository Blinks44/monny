import SwiftUI

/// Window Sensors (Sketch `07 · Window · Sensors`). Monny reads CPU, GPU, SSD and battery
/// temperatures (research: SMC keys per chip generation); cluster, SoC, palm rest and ambient
/// tiles wait until their keys are confirmed, and missing sensors are omitted, never invented.
struct SensorsPage: View {
    let sampler: Sampler
    @AppStorage(PreferenceKey.historyRange) private var range = HistoryRange.hour
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius

    private var sensors: SensorReading? { sampler.snapshot?.sensors }

    private var kinds: [SensorKind] {
        [SensorKind(title: "CPU die", metric: .cpuTemperature, color: Theme.metricHeat, value: sensors?.cpu),
         SensorKind(title: "GPU", metric: .gpuTemperature, color: Theme.metricHeatHot, value: sensors?.gpu),
         SensorKind(title: "SSD", metric: .ssdTemperature, color: Theme.metricDisk, value: sensors?.ssd),
         SensorKind(title: "Battery", metric: .batteryTemperature, color: Theme.metricBattery, value: sensors?.battery)]
    }

    var body: some View {
        let tier = sampler.history.tier(range)
        VStack(spacing: Theme.spaceL) {
            HStack(spacing: Theme.spaceL) {
                ForEach(kinds) { kind in
                    let points = tier.series(kind.metric)
                    KPICard(title: kind.title, symbol: "thermometer.medium", color: kind.color,
                            value: kind.value?.temperatureText(temperatureUnit),
                            detail: points.map(\.value).max().map { Text("peak \($0.temperatureText(temperatureUnit))") },
                            points: kind.value == nil ? nil : points)
                }
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                TemperaturesCard(kinds: kinds.filter { $0.value != nil }, tier: tier, range: range, unit: temperatureUnit)
                ThermalStateCard(state: sampler.snapshot?.thermalState, sensors: sensors).frame(width: 244)
            }
        }
    }
}

private struct SensorKind: Identifiable {
    let title: LocalizedStringKey
    let metric: HistoryMetric
    let color: Color
    let value: Double?
    var id: HistoryMetric { metric }
}

private struct TemperaturesCard: View {
    let kinds: [SensorKind]
    let tier: HistoryTier
    let range: HistoryRange
    let unit: TemperatureUnit

    var body: some View {
        let series = kinds.map { HistoryChart.Series(id: $0.metric.rawValue, points: tier.series($0.metric), color: $0.color) }
        VStack(alignment: .leading, spacing: 12) {
            CardHeader("Temperatures", subtitle: range.periodName) {
                HStack(spacing: Theme.spaceL) {
                    ForEach(kinds) { ChartLegend(title: $0.title, color: $0.color) }
                }
            }
            if series.contains(where: { $0.points.count > 1 }) {
                HistoryChart(series: series, tier: tier, range: range, yDomain: 20...100, yTicks: [20, 40, 60, 80, 100],
                             format: { $0.temperatureText(unit) })
            } else {
                CollectingHistoryContent().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .dashboardCard(height: 284)
    }
}

/// The four macOS thermal states with the current one highlighted, then the fan.
private struct ThermalStateCard: View {
    let state: ProcessInfo.ThermalState?
    let sensors: SensorReading?

    private let states: [(ProcessInfo.ThermalState, Color)] = [
        (.nominal, Theme.metricBattery), (.fair, Theme.metricDiskLight), (.serious, Theme.metricHeat), (.critical, Theme.statusDanger),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Thermal state")
            ForEach(states, id: \.0) { item in
                let isCurrent = item.0 == state
                HStack(spacing: 8) {
                    Circle().fill(item.1).frame(width: 8, height: 8)
                    ThermalStateText.text(for: item.0)
                        .font(isCurrent ? Theme.bodyEmphasized : Theme.body)
                        .foregroundStyle(isCurrent ? Theme.textPrimary : Theme.textSecondary)
                    Spacer()
                    if isCurrent { Text("now").font(Theme.footnote.weight(.semibold)).foregroundStyle(Theme.statusSuccessText) }
                }
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(isCurrent ? item.1.opacity(0.15) : Theme.fillTrack.opacity(0.6),
                            in: .rect(cornerRadius: 10, style: .continuous))
                .overlay {
                    if isCurrent { RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(item.1.opacity(0.4)) }
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
            }
            Spacer(minLength: 0)
            fan
        }
        .dashboardCard(height: 284)
    }

    @ViewBuilder private var fan: some View {
        if let rpm = sensors?.fanRPM {
            if let fastest = rpm.max() {
                let share = sensors?.fanMaxRPM.max().map { fastest / $0 }
                VStack(spacing: 6) {
                    HStack {
                        Text("Fan").foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Group {
                            if let share { Text("\(fastest.rpmText) · \(share.percentText)") } else { Text(fastest.rpmText) }
                        }
                        .font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary).monospacedDigit()
                    }
                    .font(Theme.body)
                    CapsuleBar(fraction: share, color: Theme.metricNetwork, height: 6)
                }
                .accessibilityElement(children: .combine)
            } else {
                Text("Passively cooled. macOS slows the CPU when it gets hot.")
                    .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
