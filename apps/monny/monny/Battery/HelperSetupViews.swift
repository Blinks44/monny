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
        case .notInstalled: "Charging is left to macOS"
        case .needsApproval: "Open System Settings, enable Monny in Login Items & Extensions, then return here. macOS may ask for your password again."
        case .connected:
            if canControlNativeLimit { "Turn on charge limit control when you need it." }
            else { "Update the battery helper to use charge limits." }
        case .incompatible: "The helper version doesn’t match Monny. Battery control remains off."
        case .failed:
            switch failure {
            case .installation: "The helper wasn’t installed. Try again."
            case .removal: "The helper couldn’t be removed. Charging control remains off. Try again."
            case .connection, nil: "The helper is registered but isn’t responding. Restart your Mac, or remove the helper and install it again."
            }
        }
    }
}

/// Shared status distinguishes a connected helper from explicitly enabled limit control.
struct BatteryHelperBanner: View {
    let helper: BatteryHelper

    var body: some View {
        Banner(kind: helper.nativeFailed || helper.state == .failed || helper.state == .incompatible ? .danger
               : .info,
               symbol: helper.nativeLimit != nil ? "battery.100percent" : "lock.fill",
               title: helper.nativeLimit != nil ? "Charge limit is on" : "Battery control is off",
               message: helper.nativeFailed ? "Couldn’t confirm charge control. Check macOS charging settings."
               : helper.nativeLimit != nil ? "The native charge limit is active."
               : helper.state == .connected && helper.canControlNativeLimit ? "Turn on charge limit control when you need it."
               : helper.state == .connected ? "Update the battery helper to use charge limits." : helper.explanation)
    }
}

struct BatteryHelperActions: View {
    let helper: BatteryHelper
    @State private var confirmsRemoval = false

    var body: some View {
        HStack(spacing: Theme.spaceM) {
            if helper.isBusy {
                ProgressView().controlSize(.small)
                    .accessibilityLabel(Text("Checking the battery helper…"))
                Text("Checking…").font(Theme.body).foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 0)
            } else if helper.registration == .requiresApproval {
                Button { SMAppService.openSystemSettingsLoginItems() } label: {
                    Label("Allow in macOS…", systemImage: "arrow.up.forward.app").frame(maxWidth: .infinity)
                }
                    .buttonStyle(PrimaryButtonStyle())
            } else if helper.canInstall {
                Button { Task { await helper.install() } } label: {
                    Label("Install Battery Helper…", systemImage: "lock.fill").frame(maxWidth: .infinity)
                }
                    .buttonStyle(PrimaryButtonStyle())
            } else if helper.state == .unavailable || helper.state == .checking {
                Button { } label: {
                    Label("Install Battery Helper…", systemImage: "lock.fill").frame(maxWidth: .infinity)
                }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(true)
            } else if helper.state != .connected {
                Button { Task { await helper.retryConnection() } } label: {
                    Label("Try Again", systemImage: "arrow.clockwise").frame(maxWidth: .infinity)
                }
                    .buttonStyle(PrimaryButtonStyle())
            }
            if helper.canRemove, !helper.isBusy {
                if helper.state == .connected {
                    Button("Uninstall Helper…") { confirmsRemoval = true }
                        .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button { confirmsRemoval = true } label: {
                        Image(systemName: "trash")
                            .font(Theme.bodyEmphasized)
                            .foregroundStyle(Theme.statusDangerText)
                            .frame(width: 32, height: 32)
                            .background(Theme.statusDangerBg, in: .circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Uninstall Helper…"))
                    .help(Text("Uninstall Helper…"))
                }
            }
        }
        .onChange(of: confirmsRemoval) { _, presented in helper.isPresentingRemovalConfirmation = presented }
        .onDisappear { if confirmsRemoval { helper.isPresentingRemovalConfirmation = false } }
        .alert("Uninstall the battery helper?", isPresented: $confirmsRemoval) {
            Button("Uninstall", role: .destructive) { Task { await helper.remove() } }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Charging goes back to macOS. The charge limit and charging modes will be unavailable until you install the helper again.")
        }
    }
}
