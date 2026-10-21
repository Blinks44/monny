import SwiftUI

/// Explains the native persistent setting and independent macOS optimization.
struct MacOSChargingGuidance: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceXL) {
            Text("macOS charging settings")
                .font(Theme.headline)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("Monny uses the macOS charge limit. You do not need to turn it off in System Settings first.")
            Text("Optimized Battery Charging can also delay charging. Monny does not change that setting.")
            Text("macOS manages charging. The limit stays set when Monny quits.")
                .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
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
