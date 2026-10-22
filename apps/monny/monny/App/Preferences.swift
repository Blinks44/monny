import AppKit
import KeyboardShortcuts

/// `UserDefaults` keys and choices behind Settings. Views read them with `@AppStorage`.
enum PreferenceKey {
    static let refreshInterval = "refreshInterval"
    static let temperatureUnit = "temperatureUnit"
    static let appearance = "appearance"
    static let showsAlertBadge = "showsAlertBadge"
    static let notifyChargeLimit = "notifyChargeLimit"
    static let notifyHot = "notifyHot"
    static let notifyLowBattery = "notifyLowBattery"
    static let notifyMemoryPressure = "notifyMemoryPressure"
    static let notifyBusyApp = "notifyBusyApp"
    static let historyRange = "historyRange"
    /// Readings next to the status item (Settings › Menu bar), all off by default.
    static let menuBarCPU = "menuBarCPU"
    static let menuBarTemperature = "menuBarTemperature"
    static let menuBarBattery = "menuBarBattery"
    /// Settings › AI limits: plan limits of Claude Code, Codex, Cursor and Grok, off by default.
    static let showsAILimits = "showsAILimits"
    static let notifyAILimit = "notifyAILimit"
    static let aiHistoryRange = "aiHistoryRange"
    /// Tools found on this Mac but unchecked in Settings › AI limits (raw `AITool` values).
    static let aiHiddenTools = "aiHiddenTools"
}

enum TemperatureUnit: String, CaseIterable {
    case celsius, fahrenheit
}

enum AppearancePreference: String, CaseIterable {
    case system, light, dark

    var appearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

enum HistoryRange: String, CaseIterable {
    case minute, hour, day, week
}

extension KeyboardShortcuts.Name {
    /// Opens the dashboard from anywhere (SPEC §2); stored by the package in `UserDefaults`.
    static let openDashboard = Self("openDashboard", default: .init(.m, modifiers: [.option, .command]))
}

/// The app's own language (Settings › General), as System Settings › Language & Region ›
/// Applications sets it: `AppleLanguages` in Monny's defaults domain. Bundles read it at launch,
/// so a change applies after a restart.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, ru, de, fr, es
    case zhHans = "zh-Hans"

    var id: Self { self }

    /// Each language in its own name, as language lists conventionally show them.
    var nativeName: String? {
        switch self {
        case .system: nil
        case .en: "English"
        case .ru: "Русский"
        case .de: "Deutsch"
        case .fr: "Français"
        case .es: "Español"
        case .zhHans: "简体中文"
        }
    }

    private static let key = "AppleLanguages"

    static var current: AppLanguage {
        let languages = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?[key] as? [String]
        return languages?.first.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    func select() {
        if self == .system {
            UserDefaults.standard.removeObject(forKey: Self.key)
        } else {
            UserDefaults.standard.set([rawValue], forKey: Self.key)
        }
    }

    /// The localization this choice loads, to compare with the one running now.
    var localization: String? {
        guard self == .system else { return rawValue }
        let system = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?[Self.key] as? [String] ?? []
        return Bundle.preferredLocalizations(from: Bundle.main.localizations, forPreferences: system).first
    }

    /// True when the chosen language differs from the one Monny launched with.
    var needsRestart: Bool { localization != Bundle.main.preferredLocalizations.first }

    /// Quits and opens Monny again once this process has exited, so the new instance loads the
    /// saved history and never runs beside this one.
    static func relaunch() {
        let script = "while /bin/kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do /bin/sleep 0.2; done; /usr/bin/open \"$0\""
        let process = Process()
        process.executableURL = URL(filePath: "/bin/sh")
        process.arguments = ["-c", script, Bundle.main.bundlePath]
        guard (try? process.run()) != nil else { return }
        NSApp.terminate(nil)
    }
}
