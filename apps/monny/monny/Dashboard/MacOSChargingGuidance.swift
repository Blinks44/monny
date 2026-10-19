import SwiftUI

/// Manual setup guidance, not a claim that Monny can read or change macOS charging settings.
struct MacOSChargingGuidance: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceXL) {
            Text("macOS charging settings")
                .font(Theme.headline)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("Monitoring works with macOS charging settings on. Before using Monny’s charging controls, avoid competing charging targets:")
            VStack(alignment: .leading, spacing: Theme.spaceM) {
                Label("Turn off Optimized Battery Charging.", systemImage: "1.circle")
                Label("Set the macOS Charge Limit to 100%, if available.", systemImage: "2.circle")
            }
            Text("In System Settings → Battery, click the info button next to Charging or Battery Health. Monny does not check or change these settings.")
                .font(Theme.footnote)
                .foregroundStyle(Theme.textSecondary)
            Text("When you stop using Monny’s charging controls, you can turn macOS charging features back on.")
                .font(Theme.footnote)
                .foregroundStyle(Theme.textSecondary)
            Link("Open Battery Settings…", destination: Self.settingsURL)
                .buttonStyle(SecondaryButtonStyle())
        }
        .font(Theme.body)
        .foregroundStyle(Theme.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(20)
        .frame(width: 360, alignment: .leading)
    }

    private static let settingsURL = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension") ?? URL(filePath: "/System/Applications/System Settings.app")
}
