import AppKit
import KeyboardShortcuts
import SwiftUI

enum OnboardingWindow {
    static let id = "onboarding"
    static let completedKey = "hasCompletedOnboarding"

    static var isNeeded: Bool { !UserDefaults.standard.bool(forKey: completedKey) }
}

/// First-launch window from Sketch page `03`: Welcome, Charge limit (`12`) and Ready. The
/// Charge limit step appears only when this Mac offers the native limit.
struct OnboardingView: View {
    let model: AppModel

    private enum Step { case welcome, chargeLimit, ready }

    @State private var step = Step.welcome
    @State private var launchAtLogin = true
    @AppStorage(OnboardingWindow.completedKey) private var completed = false
    @Environment(\.dismissWindow) private var dismissWindow

    private var offersChargeLimit: Bool { model.chargeLimit.setting != nil }
    private var steps: [Step] { offersChargeLimit ? [.welcome, .chargeLimit, .ready] : [.welcome, .ready] }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case .welcome: welcome
                case .chargeLimit: chargeLimit
                case .ready: ready
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            HStack(spacing: 20) {
                PageDots(count: steps.count, current: steps.firstIndex(of: step) ?? 0)
                Spacer()
                actions
            }
        }
        // The content sits below the hidden 32 pt title bar, which the window adds to its size:
        // 52 pt from the window top and 540 pt in all, as drawn.
        .padding(.top, 20)
        .padding([.horizontal, .bottom], 40)
        .frame(width: 600, height: 508)
        .background { WindowBackground() }
        .onDisappear { completed = true }
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 118, height: 118)
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            header("Welcome to Monny",
                   SystemInfo.hasBattery
                       ? "See what your Mac is doing, and keep its battery healthy while it stays plugged in."
                       : "See what your Mac is doing, right from the menu bar.")
            VStack(alignment: .leading, spacing: 20) {
                Feature(symbol: "waveform.path.ecg", color: Theme.metricCPU, title: "Stats in the menu bar",
                        detail: "CPU, memory, disk, network and temperatures, one click away.")
                if SystemInfo.hasBattery {
                    Feature(symbol: "battery.100percent", color: Theme.metricBattery, title: "Charge limit",
                            detail: "Stop charging at 80–100% with the charge limit built into macOS.")
                } else {
                    Feature(symbol: "thermometer.medium", color: Theme.metricHeat, title: "Sensors and history",
                            detail: "Temperatures, fan speed and up to 7 days of history.")
                }
                Feature(symbol: "lock", color: Theme.accentBrand, title: "Works offline",
                        detail: "All readings come from your Mac. No account, no analytics.")
            }
            .padding(.top, 26)
            .padding(.horizontal, 58)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var chargeLimit: some View {
        VStack(spacing: 0) {
            GlyphTile(symbol: "battery.100percent.bolt")
            header("Keep your battery healthy",
                   "Monny uses the charge limit built into macOS, the same setting as in Battery Settings.")
            VStack(alignment: .leading, spacing: 12) {
                CheckItem(title: "Stops charging at your limit", detail: "Choose 80, 85, 90, 95 or 100%")
                CheckItem(title: "Stays on when Monny is closed", detail: "macOS keeps it after quit, sleep and restart")
                CheckItem(title: "Change it any time", detail: "In Monny or in System Settings → Battery")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(width: 420, alignment: .leading)
            .card(radius: 18)
            .padding(.top, 28)
            if model.chargeLimit.failed {
                Text("Couldn’t confirm the charge limit. Check Battery Settings.")
                    .font(Theme.footnote)
                    .foregroundStyle(Theme.statusDangerText)
                    .padding(.top, Theme.spaceL)
            }
        }
    }

    private var ready: some View {
        VStack(spacing: 0) {
            GlyphTile(symbol: "checkmark")
            header("You’re all set", readyBody)
                .padding(.top, -8)
            MenuBarMock()
                .padding(.top, 24)
            VStack(spacing: 0) {
                SettingRow(title: "Launch Monny at login",
                           detail: "Recommended so Monny is always in your menu bar", isOn: $launchAtLogin)
                Divider().overlay(Theme.fillSeparator)
                SettingRow(title: "Check for updates automatically",
                           detail: "Monny asks before installing a new version", isOn: Binding(get: { model.updater.automaticallyChecksForUpdates },
                                         set: { model.updater.automaticallyChecksForUpdates = $0 }))
            }
            .padding(.horizontal, 16)
            .frame(width: 380)
            .card(radius: Theme.radiusTile)
            .padding(.top, 18)
        }
    }

    private var readyBody: LocalizedStringKey {
        if let shortcut = KeyboardShortcuts.getShortcut(for: .openDashboard) {
            "Monny lives in your menu bar. Click its icon or press \(shortcut.description) from anywhere."
        } else {
            "Monny lives in your menu bar. Click its icon to open it."
        }
    }

    private func header(_ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(body)
                .font(Theme.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 310)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 24)
    }

    // MARK: Actions

    @ViewBuilder private var actions: some View {
        switch step {
        case .welcome:
            Button("Continue") { advance() }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
        case .chargeLimit:
            Button("Not Now") { advance() }
                .buttonStyle(PlainLinkButtonStyle())
                .keyboardShortcut(.cancelAction)
            Button("Use 80% Limit") {
                Task {
                    await model.chargeLimit.set(limit: 80, enabled: true)
                    if !model.chargeLimit.failed { advance() }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .keyboardShortcut(.defaultAction)
            .disabled(model.chargeLimit.isBusy || model.chargeLimit.setting?.available.contains(80) != true)
        case .ready:
            Button("Open Monny") { finish() }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
        }
    }

    private func advance() {
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else { return }
        step = steps[index + 1]
    }

    /// Launch at login is registered here, by the user's own button press.
    private func finish() {
        let loginItem = LoginItem()
        if loginItem.isEnabled != launchAtLogin { loginItem.setEnabled(launchAtLogin) }
        completed = true
        dismissWindow(id: OnboardingWindow.id)
        model.showPopover()
    }
}

// MARK: - Pieces

private struct Feature: View {
    let symbol: String
    let color: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 36, height: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary)
                Text(detail).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CheckItem: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white, Theme.metricBattery)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.label).foregroundStyle(Theme.textPrimary)
                Text(detail).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SettingRow: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.label).foregroundStyle(Theme.textPrimary)
                Text(detail).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 12)
        }
        .toggleStyle(LabeledSwitchStyle())
        .padding(.vertical, 8)
        .frame(minHeight: 48)
    }
}

/// `SwitchStyle` with its label on the leading side, as in Settings rows.
private struct LabeledSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(SwitchStyle())
                .labelsHidden()
        }
    }
}

/// The 96 pt green tile with a white symbol (`Icon glyph` on `App icon` in frames `12` and `03`).
private struct GlyphTile: View {
    let symbol: String

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        Image(systemName: symbol)
            .font(.system(size: 40, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 96, height: 96)
            .background(Theme.metricBattery.gradient, in: shape)
            .overlay { shape.strokeBorder(.white.opacity(0.4)) }
            .shadow(color: .black.opacity(0.18), radius: 8, y: 6)
            .accessibilityHidden(true)
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Theme.accentBrand : Theme.textPrimary.opacity(0.15))
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Step \(current + 1) of \(count)"))
    }
}

/// A menu bar with Monny's icon highlighted and a “Monny lives here” callout below it.
private struct MenuBarMock: View {
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                Text(verbatim: "Finder   File   Edit")
                Spacer()
                Image("MonnyMenuBar")
                    .renderingMode(.template)
                    .frame(width: 34, height: 24)
                    .background(Theme.accentBrand.opacity(0.15), in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.accentBrand.opacity(0.4)) }
                Image(systemName: "wifi")
                    .padding(.leading, 14)
                Spacer()
                Text(Date.now, format: .dateTime.weekday().hour().minute())
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 16)
            .frame(width: 380, height: 34)
            .card(radius: Theme.radiusControl)
            Text("Monny lives here")
                .font(Theme.label)
                .foregroundStyle(Theme.textInverse)
                .padding(.horizontal, 16)
                .frame(height: 30)
                .background(Theme.fillTooltip, in: .rect(cornerRadius: 10))
                .shadow(color: .black.opacity(0.2), radius: 7, y: 6)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Monny lives here"))
    }
}
