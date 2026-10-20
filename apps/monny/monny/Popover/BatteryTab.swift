import SwiftUI

/// Battery readings and explicitly enabled, capability-gated native charge limits.
struct BatteryTab: View {
    let battery: BatteryReading?
    let health: BatteryHealth?
    /// °C from the SMC.
    let temperature: Double?
    let helper: BatteryHelper
    let openSensors: () -> Void

    var body: some View {
        if SystemInfo.hasBattery {
            VStack(spacing: Theme.spaceM) {
                BatteryHelperBanner(helper: helper)
                VStack(alignment: .leading, spacing: Theme.spaceL) {
                    if let battery {
                        BatteryStatusText(battery: battery).font(Theme.label).foregroundStyle(Theme.textSecondary)
                        HStack(alignment: .firstTextBaseline) {
                            Text(battery.level.percentText).font(Theme.display).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            BatteryGlyph(level: battery.level)
                        }
                    } else {
                        UnavailableValue(font: Theme.display)
                    }
                    BatteryFacts(battery: battery, health: health, temperature: temperature)
                        .font(Theme.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.spaceXL)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
                VStack(alignment: .leading, spacing: Theme.spaceL) {
                    if helper.state == .connected {
                        NativeLimitControls(helper: helper)
                        Divider()
                    }
                    HStack {
                        Text("Battery helper").font(Theme.headline).foregroundStyle(Theme.textPrimary)
                        Spacer(minLength: 0)
                        Chip(title: helper.statusTitle, kind: helper.state == .failed ? .danger : .neutral)
                    }
                    BatteryHelperActions(helper: helper)
                }
                .padding(Theme.spaceXL)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .task { await helper.refresh() }
        } else {
            NoBatteryView(openSensors: openSensors)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .card()
        }
    }
}

/// "Health 97% · 96 cycles · 32 °C", leaving out what macOS does not report.
private struct BatteryFacts: View {
    let battery: BatteryReading?
    let health: BatteryHealth?
    let temperature: Double?
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius

    var body: some View {
        let facts = [
            health.map { String(localized: "Health \($0.maximumCapacity.percentText)") },
            battery?.cycleCount.map { String(localized: "\($0) cycles") },
            temperature?.temperatureText(temperatureUnit),
        ].compactMap(\.self)
        Text(verbatim: facts.isEmpty ? " " : facts.joined(separator: " · "))
    }
}

/// Empty state for a Mac without a battery, shared by the popover and the window.
struct NoBatteryView: View {
    let openSensors: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "battery.100percent")
                .font(.system(size: 26))
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 64, height: 64)
                .background(Theme.fillTrack, in: .circle)
                .accessibilityHidden(true)
            Text("This Mac has no battery")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, Theme.spaceXL)
            Text("Charge limit and charging modes need a Mac with a battery. Everything else works as usual.")
                .font(Theme.footnote)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
                .padding(.top, 6)
            Button("Open Sensors", action: openSensors)
                .buttonStyle(SecondaryButtonStyle())
                .padding(.top, 18)
        }
        .padding(Theme.space3XL)
    }
}
