import SwiftUI

/// Popover Battery. Without the helper (not built yet, PLAN phase 4) battery control is off:
/// the banner explains it and the level stays unavailable until readings exist.
struct BatteryTab: View {
    let openSensors: () -> Void

    var body: some View {
        if SystemInfo.hasBattery {
            VStack(spacing: Theme.spaceM) {
                Banner(kind: .danger, symbol: "lock.fill", title: "Battery control is off",
                       message: "Install the helper to limit and pause charging")
                VStack(alignment: .leading, spacing: Theme.spaceL) {
                    UnavailableValue(font: Theme.display)
                    Text("Health · cycles · temperature").font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.spaceXL)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
                Button("Install Battery Helper…", systemImage: "lock.fill") { }
                    .buttonStyle(PrimaryButtonStyle())
                    .controlSize(.large)
                    .disabled(true)
                    .padding(.top, Theme.spaceM)
                Text("Asks for your admin password once. Only controls charging.")
                    .font(Theme.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        } else {
            NoBatteryView(openSensors: openSensors)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .card()
        }
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
