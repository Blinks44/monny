import KeyboardShortcuts
import SwiftUI

/// Settings in the dashboard (Sketch `08 · Window · Settings`, `12 · Errors`, `13 · Update available`).
struct SettingsPage: View {
    let controller: ChargeLimitController
    @AppStorage(PreferenceKey.refreshInterval) private var refreshInterval = 2
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius
    @AppStorage(PreferenceKey.appearance) private var appearance = AppearancePreference.system
    @AppStorage(PreferenceKey.showsAlertBadge) private var showsAlertBadge = true
    @AppStorage(PreferenceKey.notifyChargeLimit) private var notifyChargeLimit = true
    @AppStorage(PreferenceKey.notifyHot) private var notifyHot = true
    @AppStorage(PreferenceKey.notifyLowBattery) private var notifyLowBattery = false
    @AppStorage(PreferenceKey.notifyMemoryPressure) private var notifyMemoryPressure = false
    @State private var loginItem = LoginItem()
    @State private var language = AppLanguage.current
    @State private var updates = UpdateChecker()
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spaceL) {
            VStack(spacing: 28) {
                general
                menuBar
                about
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            VStack(spacing: 28) {
                if SystemInfo.hasBattery { battery }
                notifications
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .task { await controller.refresh() }
    }

    private var general: some View {
        SettingsSection("General") {
            SettingsRow("Launch at login") {
                Toggle("Launch at login", isOn: Binding(get: { loginItem.isEnabled }, set: loginItem.setEnabled))
            }
            SettingsRow("Refresh rate") {
                PopupPicker(title: "Refresh rate", selection: $refreshInterval, options: [1, 2, 5].map { seconds in
                    (seconds, Text("Every \(Duration.seconds(seconds).formatted(.units(width: .narrow)))"))
                })
            }
            SettingsRow("Temperature unit") {
                PopupPicker(title: "Temperature unit", selection: $temperatureUnit, options: [
                    (.celsius, Text("°C Celsius")), (.fahrenheit, Text("°F Fahrenheit")),
                ])
            }
            SettingsRow("Appearance") {
                PopupPicker(title: "Appearance", selection: $appearance, options: [
                    (.system, Text("System")), (.light, Text("Light")), (.dark, Text("Dark")),
                ])
            }
            SettingsRow("Language", isLast: !language.needsRestart) {
                PopupPicker(title: "Language", selection: $language, options: AppLanguage.allCases.map { language in
                    (language, language.nativeName.map { Text(verbatim: $0) } ?? Text("System"))
                })
                .onChange(of: language) { _, language in language.select() }
            }
            if language.needsRestart {
                SettingsRow("Applies after Monny restarts", isLast: true) {
                    Button("Restart", action: AppLanguage.relaunch)
                        .buttonStyle(TintedButtonStyle())
                }
            }
        }
    }

    private var menuBar: some View {
        SettingsSection("Menu bar") {
            SettingsRow("Global shortcut") {
                // The library's recorder field at its 130 pt minimum, so long titles keep one line.
                KeyboardShortcuts.Recorder(for: .openDashboard)
                    .frame(width: 130)
            }
            SettingsRow("Show alert badge", subtitle: "Dot on the icon when something needs you", isLast: true) {
                Toggle("Show alert badge", isOn: $showsAlertBadge)
            }
        }
    }

    private var about: some View {
        SettingsSection("About") {
            updateRow
            SettingsRow("Privacy", subtitle: "No analytics · network only for updates", isLast: true) {
                EmptyView()
            }
        }
    }

    @ViewBuilder private var updateRow: some View {
        let version = "\(Bundle.main.shortVersion) (\(Bundle.main.buildNumber))"
        switch updates.status {
        case .available(let latest, let page):
            SettingsRow("Monny \(latest) is available", subtitle: "You have \(version)") {
                Button("Download…") { openURL(page) }
                    .buttonStyle(PrimaryButtonStyle())
            }
        case .failed(let offline):
            SettingsRow("Monny \(version)",
                        subtitle: offline ? "Couldn’t check for updates · offline" : "Couldn’t check for updates",
                        subtitleColor: Theme.statusDangerText) {
                Button("Try Again", action: checkForUpdates)
                    .buttonStyle(TintedButtonStyle())
            }
        case .idle, .checking, .upToDate:
            SettingsRow("Monny \(version)", subtitle: updates.status == .upToDate ? "You’re up to date" : nil) {
                HStack(spacing: Theme.spaceM) {
                    if updates.status == .checking { ProgressView().controlSize(.small) }
                    Button("Check for Updates", action: checkForUpdates)
                        .buttonStyle(TintedButtonStyle())
                        .disabled(updates.status == .checking)
                }
            }
        }
    }

    private func checkForUpdates() {
        Task { await updates.check() }
    }

    private var battery: some View {
        SettingsSection("Battery") {
            NativeLimitControls(controller: controller).padding(.vertical, 12)
        }
    }

    private var notifications: some View {
        SettingsSection("Notifications") {
            if SystemInfo.hasBattery { CheckboxRow("Charge limit reached", isOn: $notifyChargeLimit) }
            CheckboxRow("Mac is running hot", isOn: $notifyHot)
            if SystemInfo.hasBattery { CheckboxRow("Battery below 20%", isOn: $notifyLowBattery) }
            CheckboxRow("Memory pressure is high", isOn: $notifyMemoryPressure, isLast: true)
        }
    }
}

/// Overline header above a card of rows.
private struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceM) {
            Text(title)
                .textCase(.uppercase)
                .font(Theme.overline)
                .tracking(Theme.overlineTracking)
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) { content }
                .padding(.horizontal, Theme.spaceXL)
                .card(radius: Theme.radiusTile)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A 44 pt row: title, optional subtitle and a trailing control, with a separator below.
private struct SettingsRow<Control: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    var subtitleColor = Theme.textSecondary
    var isLast = false
    @ViewBuilder let control: Control

    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, subtitleColor: Color = Theme.textSecondary,
         isLast: Bool = false, @ViewBuilder control: () -> Control) {
        self.title = title
        self.subtitle = subtitle
        self.subtitleColor = subtitleColor
        self.isLast = isLast
        self.control = control()
    }

    var body: some View {
        HStack(spacing: Theme.spaceL) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.body).foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle).font(Theme.caption).foregroundStyle(subtitleColor)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Theme.spaceM)
            control
                .labelsHidden()
                .toggleStyle(SwitchStyle())
                .fixedSize()
        }
        .padding(.vertical, Theme.spaceM)
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) {
            if !isLast { Theme.fillSeparator.frame(height: 1) }
        }
    }
}

private struct CheckboxRow: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    var isLast = false

    init(_ title: LocalizedStringKey, isOn: Binding<Bool>, isLast: Bool = false) {
        self.title = title
        _isOn = isOn
        self.isLast = isLast
    }

    var body: some View {
        Toggle(isOn: $isOn) { Text(title).font(Theme.body).foregroundStyle(Theme.textPrimary) }
            .toggleStyle(CheckboxStyle())
            .padding(.vertical, Theme.spaceM)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .overlay(alignment: .bottom) {
                if !isLast { Theme.fillSeparator.frame(height: 1) }
            }
    }
}
