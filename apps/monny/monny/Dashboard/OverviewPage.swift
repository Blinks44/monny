import AppKit
import Charts
import SwiftUI

/// Window Overview (Sketch `01 · Window · Overview`): KPI cards with sparklines for the chosen
/// range, CPU load & temperature, the battery over 24 h, top processes and sensors.
struct OverviewPage: View {
    let sampler: Sampler
    @AppStorage(PreferenceKey.historyRange) private var range = HistoryRange.hour
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius

    private var snapshot: Snapshot? { sampler.snapshot }

    var body: some View {
        let tier = sampler.history.tier(range)
        VStack(spacing: Theme.spaceL) {
            HStack(spacing: Theme.spaceL) {
                KPICard(title: "CPU", symbol: "cpu", color: Theme.metricCPU, value: snapshot?.cpu?.total.percentText,
                        detail: Text("\(SystemInfo.performanceCores + SystemInfo.efficiencyCores) cores"),
                        points: tier.series(.cpu), domain: 0...1)
                KPICard(title: "Memory", symbol: "memorychip", color: Theme.metricMemory, value: snapshot?.memory?.used.memoryText,
                        detail: snapshot?.memory.map { memory in
                            memory.swapUsed > 0 ? Text("of \(memory.total.memoryText) · swap \(memory.swapUsed.memoryText)")
                                : Text("of \(memory.total.memoryText)")
                        },
                        points: tier.series(.memory), domain: 0...1)
                KPICard(title: "Temperature", symbol: "thermometer.medium", color: Theme.metricHeat,
                        value: snapshot?.sensors?.cpu?.temperatureText(temperatureUnit),
                        detail: temperatureDetail(tier), points: tier.series(.cpuTemperature), domain: nil)
                if SystemInfo.hasBattery {
                    KPICard(title: "Battery", symbol: "battery.100percent", color: Theme.metricBattery,
                            value: snapshot?.battery?.level.percentText,
                            detail: snapshot?.battery.map(BatteryStatusText.text(for:)),
                            points: tier.series(.battery), domain: 0...1)
                }
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                CPUHistoryCard(tier: tier, range: range)
                if SystemInfo.hasBattery {
                    BatteryDayCard(day: sampler.history.day, battery: snapshot?.battery, health: sampler.batteryHealth)
                        .frame(width: 244)
                }
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                ProcessListCard("Top processes", columns: ("CPU", "Memory"), processes: snapshot?.processes ?? [],
                                color: Theme.metricCPU, value: \.cpu, primary: { $0.cpu.cpuShareText }, secondary: { $0.memory.memoryText })
                SensorsCard(sensors: snapshot?.sensors)
                    .frame(width: 244)
            }
        }
        .onAppear { sampler.setProcessListVisible(true) }
        .onDisappear { sampler.setProcessListVisible(false) }
    }

    /// "CPU die · peak 71 °C" over the chosen range.
    private func temperatureDetail(_ tier: HistoryTier) -> Text? {
        guard snapshot?.sensors?.cpu != nil else { return nil }
        guard let peak = tier.series(.cpuTemperature).map(\.value).max() else { return Text("CPU die") }
        return Text("CPU die · peak \(peak.temperatureText(temperatureUnit))")
    }
}

/// Summary card with the current value and a sparkline of the chosen range (`KPI · …`).
struct KPICard: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color
    let value: String?
    let detail: Text?
    /// A second line under the detail, for a card without a sparkline.
    var footnote: Text? = nil
    /// `nil` for a value without history (no sparkline).
    let points: [(date: Date, value: Double)]?
    /// The sparkline's y range; `nil` fits the values with some room.
    var domain: ClosedRange<Double>?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MetricLabel(title: title, symbol: symbol, color: color)
            if let value {
                Text(value).font(Theme.metricL).foregroundStyle(Theme.textPrimary).monospacedDigit()
            } else {
                UnavailableValue(font: Theme.metricL)
            }
            detail?.font(Theme.footnote).foregroundStyle(Theme.textSecondary).lineLimit(1)
            footnote?.font(Theme.footnote).foregroundStyle(Theme.textSecondary).lineLimit(1)
            Spacer(minLength: 0)
            if let points, points.count > 1 {
                Sparkline(series: [SparklineSeries(id: "value", points: points, color: color, filled: true)],
                          domain: domain ?? fittedDomain, showsLiveDot: false)
                    .frame(height: 24)
            } else if points != nil {
                Text("Collecting history…").font(Theme.footnote).foregroundStyle(Theme.textTertiary)
                Capsule().fill(Theme.fillTrack).frame(height: 4)
            }
        }
        .padding(Theme.spaceXL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 116, alignment: .top)
        .card()
        .accessibilityElement(children: .combine)
    }

    private var fittedDomain: ClosedRange<Double> {
        let values = (points ?? []).map(\.value)
        let low = values.min() ?? 0, high = values.max() ?? 1
        let room = max((high - low) * 0.25, 1)
        return (low - room)...(high + room)
    }
}

/// Battery card: hourly level over the last 24 h (amber where it charged), state and facts.
private struct BatteryDayCard: View {
    let day: HistoryTier
    let battery: BatteryReading?
    let health: BatteryHealth?

    private struct Hour: Identifiable {
        let date: Date
        let level: Double
        let charged: Bool
        var id: Date { date }
    }

    /// The day tier's minutes averaged per clock hour.
    private var hours: [Hour] {
        let calendar = Calendar.current
        let levels = Dictionary(grouping: day.series(.battery)) { calendar.dateInterval(of: .hour, for: $0.date)?.start ?? $0.date }
        let charging = Dictionary(grouping: day.series(.charging)) { calendar.dateInterval(of: .hour, for: $0.date)?.start ?? $0.date }
        return levels.keys.sorted().map { hour in
            let level = levels[hour]!.map(\.value).reduce(0, +) / Double(levels[hour]!.count)
            let charged = charging[hour]?.contains { $0.value > 0 } ?? false
            return Hour(date: hour, level: level, charged: charged)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Battery").font(Theme.headline).foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                if let battery { stateChip(battery).fixedSize() }
            }
            Text("Charge level · last 24 h").font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary)
                .padding(.top, 2)
            let hours = hours
            Group {
                if hours.count > 1 {
                    Chart(hours) { hour in
                        BarMark(x: .value("Hour", hour.date, unit: .hour), y: .value("Level", hour.level), width: 6)
                            .clipShape(.capsule)
                            .foregroundStyle(LinearGradient(colors: hour.charged ? [Theme.metricDisk, Theme.metricDiskLight]
                                                                : [Theme.metricBattery, Theme.metricBattery.opacity(0.7)],
                                                            startPoint: .bottom, endPoint: .top))
                    }
                    .chartXScale(domain: Date.now.addingTimeInterval(-86_400)...Date.now)
                    .chartYScale(domain: 0...1)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .accessibilityLabel(Text("Charge level · last 24 h"))
                } else {
                    Text("Collecting history…").font(Theme.footnote).foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 64)
            .padding(.top, 16)
            Spacer(minLength: 12)
            VStack(spacing: 0) {
                FactRow(title: "Health", value: health.map { Text($0.maximumCapacity.percentText) })
                FactRow(title: "Cycles", value: battery?.cycleCount.map { Text($0.formatted()) })
                FactRow(title: "Capacity", value: battery?.fullChargeCapacity.map { Text("\($0.formatted()) mAh") })
                FactRow(title: "System load", value: systemLoad, isLast: true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(height: 284)
        .card()
    }

    private var systemLoad: Text? {
        guard let battery, let watts = battery.systemLoad else { return nil }
        let number = watts.formatted(.number.precision(.fractionLength(0)))
        return battery.state == .onBattery ? Text("\(number) W from battery") : Text("\(number) W from adapter")
    }

    @ViewBuilder
    private func stateChip(_ battery: BatteryReading) -> some View {
        switch battery.state {
        case .charging: Chip(title: "Charging", symbol: "bolt.fill", kind: .success)
        case .onAdapter: Chip(title: "On adapter", symbol: "powerplug.fill", kind: .neutral)
        case .onBattery: Chip(title: "On battery", symbol: "battery.75percent", kind: .neutral)
        }
    }
}

/// CPU, GPU, SSD and battery temperatures as tiles, with the fan (`Card · Sensors`).
private struct SensorsCard: View {
    let sensors: SensorReading?
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sensors").font(Theme.headline).foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                fan.font(Theme.footnote).foregroundStyle(Theme.textTertiary).lineLimit(1).minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 6)
            Grid(horizontalSpacing: 4, verticalSpacing: 6) {
                GridRow {
                    SensorTile(title: "CPU", celsius: sensors?.cpu, color: Theme.metricHeat, unit: temperatureUnit)
                    SensorTile(title: "GPU", celsius: sensors?.gpu, color: Theme.metricHeat, unit: temperatureUnit)
                }
                GridRow {
                    SensorTile(title: "SSD", celsius: sensors?.ssd, color: Theme.metricDisk, unit: temperatureUnit)
                    SensorTile(title: "Battery", celsius: sensors?.battery, color: Theme.metricBattery, unit: temperatureUnit)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .frame(height: 176)
        .card()
    }

    private var fan: Text {
        guard let rpm = sensors?.fanRPM else { return Text(verbatim: "") }
        guard let fastest = rpm.max() else { return Text("No fan") }
        return Text("Fan \(fastest.rpmText)")
    }
}

private struct SensorTile: View {
    let title: LocalizedStringKey
    let celsius: Double?
    let color: Color
    let unit: TemperatureUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            HStack(alignment: .center) {
                if let celsius {
                    Text(celsius.temperatureText(unit)).font(Theme.metricM).foregroundStyle(Theme.textPrimary).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.7)
                } else {
                    UnavailableValue(font: Theme.metricM)
                }
                Spacer(minLength: 4)
                // Share of 100 °C, as a quick sense of heat.
                CapsuleBar(fraction: celsius.map { $0 / 100 }, color: color, height: 5)
                    .frame(width: 36)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 58)
        .background(color.opacity(0.08), in: .rect(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// The first-launch chart state (Sketch frame `09 · Window · Overview · First launch`).
struct CollectingHistoryCard: View {
    var body: some View {
        CollectingHistoryContent()
            .padding(Theme.space3XL)
            .frame(maxWidth: .infinity)
            .frame(height: 284)
            .card()
    }
}

struct CollectingHistoryContent: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.metricCPU)
                .accessibilityHidden(true)
            Text("Collecting history").font(Theme.headline).foregroundStyle(Theme.textPrimary)
            Text("Charts fill in while Monny runs. The 24 h and 7 d ranges are kept across restarts.")
                .frame(maxWidth: 320)
                .font(Theme.footnote)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
}
