import KeyboardShortcuts
import SwiftUI

/// Settings in the dashboard (Sketch `17 · Window · Settings · Native`, `12 · Errors`).
struct SettingsPage: View {
    let controller: ChargeLimitController
    let updater: AppUpdater
    let aiUsage: AIUsageMonitor
    @AppStorage(PreferenceKey.refreshInterval) private var refreshInterval = 2
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius
    @AppStorage(PreferenceKey.appearance) private var appearance = AppearancePreference.system
    @AppStorage(PreferenceKey.showsAlertBadge) private var showsAlertBadge = true
    @AppStorage(PreferenceKey.menuBarCPU) private var menuBarCPU = false
    @AppStorage(PreferenceKey.menuBarTemperature) private var menuBarTemperature = false
    @AppStorage(PreferenceKey.menuBarBattery) private var menuBarBattery = false
    @AppStorage(PreferenceKey.notifyChargeLimit) private var notifyChargeLimit = true
    @AppStorage(PreferenceKey.notifyHot) private var notifyHot = true
    @AppStorage(PreferenceKey.notifyLowBattery) private var notifyLowBattery = false
    @AppStorage(PreferenceKey.notifyMemoryPressure) private var notifyMemoryPressure = false
    @AppStorage(PreferenceKey.notifyBusyApp) private var notifyBusyApp = false
    @AppStorage(PreferenceKey.showsAILimits) private var showsAILimits = false
    @AppStorage(PreferenceKey.notifyAILimit) private var notifyAILimit = false
    @State private var hiddenAITools = UserDefaults.standard.stringArray(forKey: PreferenceKey.aiHiddenTools) ?? []
    @State private var loginItem = LoginItem()
    @State private var language = AppLanguage.current

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spaceL) {
            VStack(spacing: 28) {
                general
                menuBar
                aiLimits
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            VStack(spacing: 28) {
                if SystemInfo.hasBattery { battery }
                notifications
                about
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
            SettingsRow("Show alert badge", subtitle: "Dot on the icon when something needs you") {
                Toggle("Show alert badge", isOn: $showsAlertBadge)
            }
            VStack(alignment: .leading, spacing: Theme.spaceM) {
                Text("Show in menu bar").font(Theme.body).foregroundStyle(Theme.textPrimary)
                // One reading per line: three labels in a row overflow in longer languages.
                VStack(alignment: .leading, spacing: Theme.spaceM) {
                    Toggle("CPU load", isOn: $menuBarCPU)
                    Toggle("Temperature", isOn: $menuBarTemperature)
                    if SystemInfo.hasBattery { Toggle("Battery level", isOn: $menuBarBattery) }
                }
                .font(Theme.body)
                .foregroundStyle(Theme.textPrimary)
                .toggleStyle(CheckboxStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Theme.spaceM)
        }
    }

    private var about: some View {
        SettingsSection("About") {
            updateRow
            automaticUpdatesRow
            SettingsRow("Privacy", subtitle: showsAILimits ? "No analytics · network only for updates and AI limits"
                                                           : "No analytics · network only for updates", isLast: true) {
                EmptyView()
            }
        }
    }

    private var updateRow: some View {
        let version = "\(Bundle.main.shortVersion) (\(Bundle.main.buildNumber))"
        return SettingsRow("Monny \(version)") {
            Button("Check for Updates", action: updater.checkForUpdates)
                .buttonStyle(TintedButtonStyle())
                .disabled(!updater.canCheckForUpdates)
        }
    }

    private var automaticUpdatesRow: some View {
        SettingsRow("Check for updates automatically", subtitle: "Monny asks before installing a new version") {
            Toggle("Check for updates automatically", isOn: Binding(get: { updater.automaticallyChecksForUpdates },
                                                                     set: { updater.automaticallyChecksForUpdates = $0 }))
        }
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
            CheckboxRow("An app keeps the Mac busy", isOn: $notifyBusyApp)
            if SystemInfo.hasBattery { CheckboxRow("Battery below 20%", isOn: $notifyLowBattery) }
            CheckboxRow("Memory pressure is high", isOn: $notifyMemoryPressure, isLast: !showsAILimits)
            if showsAILimits { CheckboxRow("AI limit is running low", isOn: $notifyAILimit, isLast: true) }
        }
    }

    private var aiLimits: some View {
        SettingsSection("AI limits") {
            SettingsRow("Show AI limits", subtitle: foundTools, isLast: !showsAILimits || aiUsage.detected.count < 2) {
                Toggle("Show AI limits", isOn: $showsAILimits)
            }
            // With more than one tool, each can be left out; unchecked tools are not read at all.
            if showsAILimits, aiUsage.detected.count > 1 {
                VStack(alignment: .leading, spacing: Theme.spaceM) {
                    ForEach(aiUsage.detected, id: \.self) { tool in
                        Toggle(isOn: shows(tool)) { Text(verbatim: tool.appName) }
                    }
                }
                .font(Theme.body)
                .foregroundStyle(Theme.textPrimary)
                .toggleStyle(CheckboxStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Theme.spaceM)
            }
        }
        .task { await aiUsage.refreshInstalled() }
    }

    /// "Found: Claude Code, Codex" from the tools' folders on this Mac.
    private var foundTools: LocalizedStringKey {
        let names = aiUsage.detected.map(\.appName)
        return names.isEmpty ? "No supported AI tools are set up on this Mac"
                             : "Found: \(names.formatted(.list(type: .and, width: .narrow)))"
    }

    private func shows(_ tool: AITool) -> Binding<Bool> {
        Binding(get: { !hiddenAITools.contains(tool.rawValue) }, set: { shows in
            var hidden = hiddenAITools
            if shows { hidden.removeAll { $0 == tool.rawValue } } else if !hidden.contains(tool.rawValue) { hidden.append(tool.rawValue) }
            UserDefaults.standard.set(hidden, forKey: PreferenceKey.aiHiddenTools)
            hiddenAITools = hidden
            Task { await aiUsage.refreshInstalled() }
        })
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
