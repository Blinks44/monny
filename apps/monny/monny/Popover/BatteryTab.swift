import SwiftUI

struct BatteryTab: View {
    let battery: BatteryReading?
    let health: BatteryHealth?
    let temperature: Double?
    let controller: ChargeLimitController
    let openSensors: () -> Void
    @State private var showsGuidance = false

    var body: some View {
        if SystemInfo.hasBattery {
            VStack(spacing: 10) {
                BatteryHero(battery: battery, health: health, temperature: temperature,
                            limit: controller.activeLimit)
                VStack(alignment: .leading, spacing: 12) {
                    NativeLimitControls(controller: controller)
                    Button("macOS charging settings") { showsGuidance = true }
                        .buttonStyle(PlainLinkButtonStyle())
                        .popover(isPresented: $showsGuidance) { MacOSChargingGuidance() }
                }
                .padding(16).card()
                Text("macOS manages charging. The limit stays set when Monny quits.")
                    .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16)
            }
        } else {
            NoBatteryView(openSensors: openSensors).frame(maxWidth: .infinity, maxHeight: .infinity).card()
        }
    }
}

/// Sketch Battery hero: 328 × 178, with a 72-point gauge and separate limit marker.
struct BatteryHero: View {
    let battery: BatteryReading?
    let health: BatteryHealth?
    let temperature: Double?
    let limit: Int?
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                if let battery {
                    HStack(spacing: 6) {
                        Image(systemName: battery.state == .onBattery ? "battery.75percent" : "bolt.fill")
                        if battery.state != .onBattery, let watts = battery.adapterWatts {
                            Text("Power Adapter · \(watts) W")
                        } else { Text(battery.state == .onBattery ? "On battery" : "On adapter") }
                    }
                    .font(Theme.label).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    Spacer(minLength: 0)
                    Chip(title: battery.state == .charging ? "Charging" : battery.state == .onBattery ? "On battery" : "Not charging",
                         symbol: battery.state == .charging ? "bolt.fill" : battery.state == .onBattery ? nil : "pause.fill",
                         kind: battery.state == .onBattery ? .neutral : .success)
                } else { Text("Collecting data…").font(Theme.label).foregroundStyle(Theme.textSecondary) }
            }
            .frame(height: 22)
            BatteryLevelGauge(level: battery?.level, limit: limit)
                .padding(.top, 12)
            facts
                .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                .padding(.top, 3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 178, alignment: .topLeading)
        .card()
    }

    private var facts: Text {
        let values: [Text] = [
            health.map { Text("Health \($0.maximumCapacity.percentText)") },
            battery?.cycleCount.map { Text("\($0) cycles") },
            temperature.map { Text($0.temperatureText(temperatureUnit)) }
        ].compactMap { $0 }
        return values.enumerated().reduce(Text("")) { result, item in
            result + (item.offset == 0 ? Text("") : Text(verbatim: " · ")) + item.element
        }
    }
}

struct BatteryLevelGauge: View {
    let level: Double?
    let limit: Int?
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width - 8
            let marker = width * Double(limit ?? 100) / 100
            let labelPosition = min(max(marker, 36), width - 36)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20).fill(Theme.fillTrack)
                    .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.textTertiary.opacity(contrast == .increased ? 1 : 0.28), lineWidth: 1.5) }
                    .frame(width: width, height: 72)
                if let level {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [Theme.metricBattery.opacity(0.55), Theme.metricBattery], startPoint: .top, endPoint: .bottom))
                        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.4)) }
                        .frame(width: max(0, (width - 8) * min(max(level, 0), 1)), height: 64).offset(x: 4, y: 4)
                }
                Text(level?.percentText ?? "—").font(Theme.display).foregroundStyle(level == nil ? Theme.textTertiary : Theme.textOnAccent)
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 1).offset(x: 22, y: 17)
                RoundedRectangle(cornerRadius: 1).fill(Theme.textTertiary.opacity(0.3))
                    .frame(width: 5, height: 24).offset(x: width + 3, y: 24)
                if let limit {
                    Path { path in path.move(to: .init(x: marker, y: -5)); path.addLine(to: .init(x: marker, y: 76)) }
                        .stroke(Theme.textSecondary, style: .init(lineWidth: 1.5, lineCap: .round, dash: [2, 3]))
                    Text("Limit \((Double(limit) / 100).percentText)")
                        .font(Theme.caption.weight(.semibold)).foregroundStyle(Theme.textInverse)
                        .padding(.horizontal, 6).padding(.vertical, 3).background(Theme.textPrimary, in: .capsule)
                        .fixedSize().position(x: labelPosition, y: 88)
                }
            }
        }
        .frame(height: limit == nil ? 72 : 96)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Battery level"))
        .accessibilityValue(Text(level?.percentText ?? String(localized: "Unavailable")))
    }
}

struct NoBatteryView: View {
    let openSensors: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "battery.100percent").font(.system(size: 26)).foregroundStyle(Theme.textTertiary).accessibilityHidden(true)
            Text("This Mac has no battery").font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.textPrimary)
            Text("Charge limits require a Mac with a battery. Monitoring works as usual.")
                .font(Theme.footnote).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
            Button("Open Sensors", action: openSensors).buttonStyle(SecondaryButtonStyle())
        }.padding(24)
    }
}
