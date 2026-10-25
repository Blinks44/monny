import SwiftUI

/// A power reading and its quieter caption, aligned on their first baseline.
struct BatteryPowerValue: View {
    let watts: Double?
    let caption: LocalizedStringKey

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let watts {
                Text(watts.wattsText).font(Theme.metricS).foregroundStyle(Theme.textPrimary).monospacedDigit()
            } else {
                UnavailableValue(font: Theme.metricS)
            }
            Text(caption).font(Theme.footnote).foregroundStyle(Theme.textSecondary)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
