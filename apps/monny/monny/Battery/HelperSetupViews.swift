import ServiceManagement
import SwiftUI

extension BatteryHelper {
    var statusSubtitle: LocalizedStringKey {
        if let status { return "Helper version \(status.helperVersion)" }
        return "Charging is left to macOS"
    }

    var statusTitle: LocalizedStringKey {
        switch state {
        case .checking: "Checking…"
        case .unavailable, .failed: "Unavailable"
        case .notInstalled: "Not installed"
        case .needsApproval: "Needs approval"
        case .connected: "Connected"
        case .incompatible: "Update required"
        }
    }

    var explanation: LocalizedStringKey {
        switch state {
        case .checking: "Checking the battery helper…"
        case .unavailable: "Battery helper is not available in this build."
        case .notInstalled: "macOS manages charging. Battery controls are not available in this build."
        case .needsApproval: "Allow Monny in Login Items & Extensions, then try again."
        case .connected: "Helper connected. Charging controls are not available in this build."
        case .incompatible: "The helper version doesn’t match Monny. Battery control remains off."
        case .failed:
            switch failure {
            case .installation: "The helper wasn’t installed. Try again."
            case .removal: "The helper couldn’t be removed. Charging control remains off. Try again."
            case .connection, nil: "Couldn’t connect to the battery helper. Try again."
            }
        }
    }
}

/// Shared status in the popover, Battery window and Settings. Never implies that connecting
/// this status-only helper enables charging writes.
struct BatteryHelperBanner: View {
    let helper: BatteryHelper

    var body: some View {
        Banner(kind: helper.state == .failed || helper.state == .incompatible ? .danger : .info,
               symbol: "lock.fill", title: "Battery control is off", message: helper.explanation)
    }
}

struct BatteryHelperActions: View {
    let helper: BatteryHelper
    @State private var confirmsRemoval = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceM) {
            if helper.isBusy {
                ProgressView().controlSize(.small)
                    .accessibilityLabel(Text("Checking the battery helper…"))
            } else if helper.registration == .requiresApproval {
                Button("Open System Settings…") { SMAppService.openSystemSettingsLoginItems() }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Try Again") { Task { await helper.refresh() } }
                    .buttonStyle(TintedButtonStyle())
            } else if helper.canInstall {
                Button("Install Battery Helper…", systemImage: "lock.fill") { Task { await helper.install() } }
                    .buttonStyle(PrimaryButtonStyle())
            } else if helper.state == .unavailable || helper.state == .checking {
                Button("Install Battery Helper…", systemImage: "lock.fill") { }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(true)
            } else if helper.state != .connected {
                Button("Try Again") { Task { await helper.refresh() } }
                    .buttonStyle(TintedButtonStyle())
            }
            if helper.canRemove {
                Button("Uninstall Helper…") { confirmsRemoval = true }
                    .buttonStyle(PlainLinkButtonStyle())
            }
        }
        .alert("Uninstall the battery helper?", isPresented: $confirmsRemoval) {
            Button("Uninstall", role: .destructive) { Task { await helper.remove() } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Charging goes back to macOS. The charge limit and charging modes will be unavailable until you install the helper again.")
        }
    }
}
