import KeyboardShortcuts
import SwiftUI

/// Settings in the dashboard (Sketch `08 · Window · Settings`, `12 · Errors`, `13 · Update available`).
/// The battery helper status waits for battery control (PLAN phase 4).
struct SettingsPage: View {
    @AppStorage(PreferenceKey.refreshInterval) private var refreshInterval = 2
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius
    @AppStorage(PreferenceKey.appearance) private var appearance = AppearancePreference.system
    @AppStorage(PreferenceKey.showsAlertBadge) private var showsAlertBadge = true
    @AppStorage(PreferenceKey.defaultChargeLimit) private var chargeLimit = 80
    @AppStorage(PreferenceKey.sailingRange) private var sailingRange = 5
    @AppStorage(PreferenceKey.heatProtectionThreshold) private var heatThreshold = 35
    @AppStorage(PreferenceKey.notifyChargeLimit) private var notifyChargeLimit = true
    @AppStorage(PreferenceKey.notifyHot) private var notifyHot = true
    @AppStorage(PreferenceKey.notifyCalibration) private var notifyCalibration = true
    @AppStorage(PreferenceKey.notifyLowBattery) private var notifyLowBattery = false
    @AppStorage(PreferenceKey.notifyMemoryPressure) private var notifyMemoryPressure = false
    @State private var loginItem = LoginItem()
    @State private var language = AppLanguage.current
    @State private var updates = UpdateChecker()
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spaceL) {
            VStack(spacing: Theme.space3XL) {
                general
                menuBar
                about
            }
            VStack(spacing: Theme.space3XL) {
                if SystemInfo.hasBattery { battery }
                notifications
            }
        }
    }

    private var general: some View {
        SettingsSection("General") {
            SettingsRow("Launch at login") {
                Toggle("Launch at login", isOn: Binding(get: { loginItem.isEnabled }, set: loginItem.setEnabled))
            }
            SettingsRow("Refresh rate") {
                Picker("Refresh rate", selection: $refreshInterval) {
                    ForEach([1, 2, 5], id: \.self) { seconds in
                        Text("Every \(Duration.seconds(seconds).formatted(.units(width: .narrow)))").tag(seconds)
                    }
                }
            }
            SettingsRow("Temperature unit") {
                Picker("Temperature unit", selection: $temperatureUnit) {
                    Text("°C Celsius").tag(TemperatureUnit.celsius)
                    Text("°F Fahrenheit").tag(TemperatureUnit.fahrenheit)
                }
            }
            SettingsRow("Appearance") {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag(AppearancePreference.system)
                    Text("Light").tag(AppearancePreference.light)
                    Text("Dark").tag(AppearancePreference.dark)
                }
            }
            SettingsRow("Language", isLast: !language.needsRestart) {
                Picker("Language", selection: $language) {
                    ForEach(AppLanguage.allCases) { language in
                        if let name = language.nativeName {
                            Text(verbatim: name).tag(language)
                        } else {
                            Text("System").tag(language)
                        }
                    }
                }
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
                KeyboardShortcuts.Recorder(for: .openDashboard)
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
            SettingsRow("Default charge limit") {
                Picker("Default charge limit", selection: $chargeLimit) {
                    ForEach(Array(stride(from: 50, through: 100, by: 5)), id: \.self) { percent in
                        Text((Double(percent) / 100).formatted(.percent)).tag(percent)
                    }
                }
            }
            SettingsRow("Sailing range") {
                Picker("Sailing range", selection: $sailingRange) {
                    ForEach([0, 3, 5, 10], id: \.self) { percent in
                        Text((Double(percent) / 100).formatted(.percent)).tag(percent)
                    }
                }
            }
            SettingsRow("Heat protection above") {
                Picker("Heat protection above", selection: $heatThreshold) {
                    ForEach([30, 35, 40, 45], id: \.self) { celsius in
                        Text(Double(celsius).temperatureText(temperatureUnit)).tag(celsius)
                    }
                }
            }
            SettingsRow("Battery helper", subtitle: "Privileged helper for SMC charge control", isLast: true) {
                Chip(title: "Not installed", kind: .neutral)
            }
        }
    }

    private var notifications: some View {
        SettingsSection("Notifications") {
            CheckboxRow("Charge limit reached", isOn: $notifyChargeLimit)
            CheckboxRow("Mac is running hot", isOn: $notifyHot)
            CheckboxRow("Calibration finished", isOn: $notifyCalibration)
            CheckboxRow("Battery below 20%", isOn: $notifyLowBattery)
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
        VStack(alignment: .leading, spacing: 8) {
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
            Spacer(minLength: Theme.spaceM)
            control
                .labelsHidden()
                .toggleStyle(.switch)
                .fixedSize()
        }
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
            .toggleStyle(.checkbox)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .overlay(alignment: .bottom) {
                if !isLast { Theme.fillSeparator.frame(height: 1) }
            }
    }
}
