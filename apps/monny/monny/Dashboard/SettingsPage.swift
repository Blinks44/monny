import SwiftUI

/// Settings in the dashboard (Sketch `08 · Window · Settings`). Controls that depend on later
/// phases (global shortcut, battery helper, update check) are shown disabled until they work.
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
            SettingsRow("Appearance", isLast: true) {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag(AppearancePreference.system)
                    Text("Light").tag(AppearancePreference.light)
                    Text("Dark").tag(AppearancePreference.dark)
                }
            }
        }
    }

    private var menuBar: some View {
        SettingsSection("Menu bar") {
            SettingsRow("Global shortcut") {
                Text(verbatim: "⌥⌘M")
                    .font(Theme.body)
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityLabel(Text("Option Command M"))
            }
            SettingsRow("Show alert badge", subtitle: "Dot on the icon when something needs you", isLast: true) {
                Toggle("Show alert badge", isOn: $showsAlertBadge)
            }
        }
    }

    private var about: some View {
        SettingsSection("About") {
            SettingsRow("Monny \(Bundle.main.shortVersion) (\(Bundle.main.buildNumber))") {
                Button("Check for Updates") { }
                    .buttonStyle(TintedButtonStyle())
                    .disabled(true)
            }
            SettingsRow("Privacy", subtitle: "No analytics · network only for updates", isLast: true) {
                EmptyView()
            }
        }
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
                        Text(Measurement(value: Double(celsius), unit: UnitTemperature.celsius)
                            .formatted(.measurement(width: .narrow, usage: temperatureUnit == .celsius ? .asProvided : .weather)))
                            .tag(celsius)
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
    var isLast = false
    @ViewBuilder let control: Control

    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, isLast: Bool = false,
         @ViewBuilder control: () -> Control) {
        self.title = title
        self.subtitle = subtitle
        self.isLast = isLast
        self.control = control()
    }

    var body: some View {
        HStack(spacing: Theme.spaceL) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.body).foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle).font(Theme.caption).foregroundStyle(Theme.textSecondary)
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
