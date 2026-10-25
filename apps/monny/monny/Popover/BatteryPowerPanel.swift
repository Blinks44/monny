import SwiftUI

/// Sketch `17`/`18`: adapter capacity and power split, or battery draw and macOS's time left.
struct BatteryPowerPanel: View {
    let battery: BatteryReading?

    var body: some View {
        let power = BatteryPowerBreakdown(battery: battery)
        Group {
            if battery?.state == .onBattery {
                let draw = BatteryPowerValue(watts: power.macWatts, caption: "from battery")
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        draw
                        Spacer(minLength: 0)
                        if let time = battery?.timeToEmpty {
                            Text("\(time.estimateText) left").fixedSize()
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        draw
                        if let time = battery?.timeToEmpty { Text("\(time.estimateText) left") }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12).padding(.vertical, 12)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        BatteryPowerValue(watts: power.totalWatts, caption: "in use")
                        Spacer(minLength: 0)
                        if let watts = power.adapterWatts {
                            Text("Adapter \(watts.wattsText)").fixedSize()
                        }
                    }
                    if let fractions = power.fractions {
                        GeometryReader { proxy in
                            HStack(spacing: 0) {
                                Capsule().fill(Theme.metricDisk).frame(width: proxy.size.width * fractions.mac)
                                Capsule().fill(Theme.metricBattery).frame(width: proxy.size.width * fractions.battery)
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(height: 8)
                        .background(Theme.fillTrack, in: .capsule)
                        .accessibilityHidden(true)
                    }
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle().fill(Theme.metricDisk).frame(width: 7, height: 7).accessibilityHidden(true)
                            if let watts = power.macWatts { Text("Mac \(watts.wattsText)") }
                            else { Text("Mac"); UnavailableValue(font: Theme.caption) }
                        }
                        if battery?.state == .charging, power.chargingWatts == nil || (power.chargingWatts ?? 0) >= 1 {
                            HStack(spacing: 4) {
                                Circle().fill(Theme.metricBattery).frame(width: 7, height: 7).accessibilityHidden(true)
                                if let watts = power.chargingWatts { Text("Battery +\(watts.wattsText)") }
                                else { Text("Battery"); UnavailableValue(font: Theme.caption) }
                            }
                        }
                    }
                    .font(Theme.caption)
                }
                .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 4)
            }
        }
        .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fillTrack, in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
