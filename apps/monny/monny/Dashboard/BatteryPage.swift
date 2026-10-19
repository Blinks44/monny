import SwiftUI

/// Sketch's Battery window, using the shared sampler. No charging command leaves this page.
/// Hardware control and verification are still pending, so controls remain visibly off.
struct BatteryPage: View {
    let sampler: Sampler
    let helper: BatteryHelper
    @AppStorage(PreferenceKey.historyRange) private var range = HistoryRange.hour
    @AppStorage(PreferenceKey.defaultChargeLimit) private var limit = 80
    @AppStorage(PreferenceKey.sailingRange) private var sailingRange = 5
    @AppStorage(PreferenceKey.heatProtectionThreshold) private var heatThreshold = 35
    @State private var showsChargingGuidance = false
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius

    private var battery: BatteryReading? { sampler.snapshot?.battery }

    var body: some View {
        let tier = sampler.history.tier(range)
        VStack(spacing: Theme.spaceL) {
            VStack(alignment: .leading, spacing: Theme.spaceM) {
                BatteryHelperBanner(helper: helper)
                BatteryHelperActions(helper: helper)
            }
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
                        value: adapterPower, detail: Text("From adapter"), points: nil)
            }
            BatteryCardRow(minimumHeight: 284, spacing: Theme.spaceL) {
                chargeHistory(tier)
                chargingControls
            }
            BatteryCardRow(minimumHeight: 176, spacing: Theme.spaceL) {
                calibration
                trips
            }
            batteryDetails
        }
        .task { await helper.refresh() }
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

    private var adapterPower: String? {
        guard let battery, battery.state != .onBattery, let watts = battery.systemPowerIn else { return nil }
        return Measurement(value: watts, unit: UnitPower.watts)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                    numberFormatStyle: .number.precision(.fractionLength(0))))
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
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("battery.charging.title") {
                HStack(spacing: Theme.spaceM) {
                    Button { showsChargingGuidance = true } label: {
                        Image(systemName: "info.circle").font(Theme.body)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help(Text("macOS charging settings"))
                    .accessibilityLabel(Text("macOS charging settings"))
                    .popover(isPresented: $showsChargingGuidance) { MacOSChargingGuidance() }
                    Chip(title: "Off", kind: .neutral)
                }
            }
            .padding(.bottom, 12)
            SegmentedControl(title: "Charging mode", selection: .constant(ChargePolicy.Mode.charge), options: [
                (.charge, "Charge"), (.hold, "Hold"), (.discharge, "Discharge"),
            ], height: 32)
            .disabled(true)
            .padding(.bottom, 14)
            VStack(spacing: 8) {
                HStack {
                    Text("Charge limit").font(Theme.body)
                    Spacer()
                    Text((Double(limit) / 100).percentText)
                        .font(Theme.bodyEmphasized).foregroundStyle(Theme.metricBattery)
                }
                chargeLimitPreview
                HStack {
                    Text(0.5, format: .percent)
                    Spacer()
                    Text(1.0, format: .percent)
                }
                .font(Theme.caption).foregroundStyle(Theme.textTertiary)
            }
            .padding(.bottom, 10)
            Divider()
            unavailableToggle("Sailing mode", detail: Text("Drift to \(Double(max(50, limit - sailingRange)) / 100, format: .percent) before topping up"))
                .padding(.vertical, 8)
            Divider()
            unavailableToggle("Heat protection", detail: Text("Pause charging above \(Double(heatThreshold).temperatureText(temperatureUnit))"))
                .padding(.top, 8)
        }
        .foregroundStyle(Theme.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
        .batteryCard(minHeight: 284)
    }

    /// A non-interactive preview of the saved limit, matching Sketch's 6 pt track and 20 pt knob.
    /// The accessible representation stays a disabled slider until hardware control is available.
    private var chargeLimitPreview: some View {
        GeometryReader { proxy in
            let fraction = min(max((Double(limit) - 50) / 50, 0), 1)
            let travel = max(0, proxy.size.width - 20)
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.fillTrack).frame(height: 6)
                Capsule().fill(Theme.metricBattery).frame(width: 10 + travel * fraction, height: 6)
                Circle().fill(.white).controlElevation()
                    .frame(width: 20, height: 20).offset(x: travel * fraction)
            }
            .frame(height: 20)
        }
        .frame(height: 20)
        .accessibilityRepresentation {
            Slider(value: .constant(Double(limit)), in: 50...100, step: 5) { Text("Charge limit") }
                .disabled(true)
        }
    }

    private var calibration: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("Calibration", subtitle: Text("No calibration history"))
                .padding(.bottom, 14)
            HStack(alignment: .top, spacing: 0) {
                calibrationStep("1", title: "Charge", detail: Text("to \(1.0.percentText)"), connects: true)
                calibrationStep("2", title: "Rest", detail: Text(Duration.seconds(3_600), format: .units(allowed: [.hours], width: .wide)), connects: true)
                calibrationStep("3", title: "Discharge", detail: Text("to \(0.15.percentText)"), connects: true)
                calibrationStep("4", title: "Recharge", detail: Text("to limit"), connects: false)
            }
            .padding(.bottom, 6)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.spaceM) {
                    calibrationDuration
                    Spacer(minLength: 0)
                    calibrationButton
                }
                VStack(alignment: .leading, spacing: Theme.spaceM) {
                    calibrationDuration
                    HStack { Spacer(); calibrationButton }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .batteryCard(minHeight: 176)
    }

    private var calibrationDuration: some View {
        Label("Keep the Mac plugged in", systemImage: "clock.arrow.circlepath")
            .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            .fixedSize()
    }

    private var calibrationButton: some View {
        Button("Start Calibration") { }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(true)
            .fixedSize()
    }

    private func calibrationStep(_ number: String, title: LocalizedStringKey, detail: Text, connects: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text(verbatim: number)
                    .font(Theme.bodyEmphasized)
                    .foregroundStyle(Theme.accentBrand)
                    .frame(width: 32, height: 32)
                    .background(Theme.statusInfoBg, in: .circle)
                    .overlay { Circle().strokeBorder(Theme.accentBrand.opacity(0.2), lineWidth: 1) }
                Rectangle().fill(connects ? Theme.fillSeparator : .clear).frame(height: 2)
            }
            .accessibilityHidden(true)
            Text(title).font(Theme.body).fixedSize(horizontal: false, vertical: true)
            detail.font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var trips: some View {
        VStack(alignment: .leading, spacing: 12) {
            unavailableToggle("Full charge before trips", detail: nil, emphasized: true)
            Text("Charges to 100% an hour before you leave, then returns to the limit.")
                .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                PopupPicker(title: "Days", selection: .constant(0), options: [(0, Text("Days"))])
                PopupPicker(title: "Time", selection: .constant(0), options: [(0, Text("Time"))])
            }
            .disabled(true)
            Label("No trip scheduled", systemImage: "calendar")
                .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .batteryCard(minHeight: 176)
    }

    /// The row keeps explanatory text readable while the unavailable control remains disabled.
    private func unavailableToggle(_ title: LocalizedStringKey, detail: Text?, emphasized: Bool = false) -> some View {
        HStack(spacing: Theme.spaceM) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(emphasized ? Theme.headline : Theme.body)
                    .foregroundStyle(Theme.textPrimary)
                detail?.font(Theme.caption).foregroundStyle(Theme.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(true)
            Spacer(minLength: 0)
            Toggle(title, isOn: .constant(false))
                .labelsHidden().toggleStyle(SwitchStyle()).disabled(true)
                .accessibilityHint(detail ?? Text("Battery control is off"))
        }
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
    /// Sketch's baseline heights grow with localized content; cells in each row stay aligned.
    func batteryCard(minHeight: CGFloat) -> some View {
        padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(minHeight: minHeight, maxHeight: .infinity, alignment: .top)
            .card()
    }
}
