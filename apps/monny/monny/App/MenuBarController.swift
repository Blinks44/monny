import AppKit
import KeyboardShortcuts
import SwiftUI

/// The status item. A left click toggles the popover panel; a right click or Control-click opens
/// the menu. AppKit rather than `MenuBarExtra`: that scene offers either a menu or a window, not
/// both, and cannot draw the colored attention badge on a template icon.
final class MenuBarController: NSObject, NSMenuDelegate {
    private let model: AppModel
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let panel: MenuBarPanel
    private let menu = NSMenu()
    private let badge = NSView()
    private var defaultsObservation: NSObjectProtocol?

    init(model: AppModel) {
        self.model = model
        panel = MenuBarPanel(rootView: PopoverView(model: model))
        super.init()
        panel.onClose = { [weak self] in self?.popoverDidClose() }
        menu.autoenablesItems = false
        menu.delegate = self

        if let button = statusItem.button {
            button.image = NSImage(named: "MonnyMenuBar")
            button.setAccessibilityLabel("Monny")
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            addBadge(to: button)
            // A zero-size SwiftUI view gives AppKit the dashboard scene's `openWindow` at launch.
            button.addSubview(NSHostingView(rootView: DashboardWindowOpener()))
        }
        updateBadge()
        observeReadings()
        // The badge and readings preferences live in UserDefaults; Settings changes them while the app runs.
        defaultsObservation = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateBadge()
                self?.showReadings()
            }
        }
    }

    func showPopover() {
        guard let button = statusItem.button, !panel.isShown else { return }
        button.highlight(true)
        model.sampler.setVisible(.popover, true)
        model.isPopoverShown = true
        panel.show(below: button)
        // A nonactivating panel does not reliably trigger applicationDidBecomeActive.
        Task { await model.chargeLimit.refresh() }
    }

    func closePopover() { panel.close() }

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            closePopover()
            showMenu()
        } else if panel.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showMenu() {
        guard let button = statusItem.button else { return }
        // Top-left corner of the menu just below the button, like a status item's own menu.
        let origin = NSPoint(x: 0, y: button.isFlipped ? button.bounds.maxY + 5 : -5)
        menu.popUp(positioning: nil, at: origin, in: button)
    }

    // MARK: Badge

    /// The 7 pt dot for heat or danger. A subview keeps the icon itself a template image.
    private func addBadge(to button: NSStatusBarButton) {
        badge.wantsLayer = true
        badge.layer?.cornerRadius = 3.5
        badge.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(badge)
        // Anchored to the icon's square, which stays leading when readings follow it.
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 7),
            badge.heightAnchor.constraint(equalToConstant: 7),
            badge.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: NSStatusBar.system.thickness - 9),
            badge.topAnchor.constraint(equalTo: button.topAnchor, constant: 3),
        ])
    }

    private func updateBadge() {
        withObservationTracking {
            let enabled = UserDefaults.standard.object(forKey: PreferenceKey.showsAlertBadge) as? Bool ?? true
            badge.isHidden = !(model.needsAttention && enabled)
        } onChange: { [weak self] in
            Task { @MainActor in self?.updateBadge() }
        }
        badge.effectiveAppearance.performAsCurrentDrawingAppearance {
            badge.layer?.backgroundColor = NSColor(Theme.metricHeat).cgColor
        }
    }

    // MARK: Readings

    private func observeReadings() {
        withObservationTracking {
            showReadings()
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeReadings() }
        }
    }

    /// CPU load, CPU temperature and battery level after the icon, each when enabled in Settings.
    private func showReadings() {
        guard let button = statusItem.button else { return }
        let defaults = UserDefaults.standard
        let snapshot = model.sampler.snapshot
        var readings: [(symbol: String, text: String)] = []
        if defaults.bool(forKey: PreferenceKey.menuBarCPU) {
            readings.append(("cpu", snapshot?.cpu.map { $0.total.percentText } ?? "—"))
        }
        if defaults.bool(forKey: PreferenceKey.menuBarTemperature) {
            let unit = TemperatureUnit(rawValue: defaults.string(forKey: PreferenceKey.temperatureUnit) ?? "") ?? .celsius
            readings.append(("thermometer.medium", snapshot?.sensors?.cpu.map { $0.shortTemperatureText(unit) } ?? "—"))
        }
        if SystemInfo.hasBattery, defaults.bool(forKey: PreferenceKey.menuBarBattery) {
            let battery = snapshot?.battery
            readings.append((battery.map(Self.batterySymbol) ?? "battery.100percent", battery.map { $0.level.percentText } ?? "—"))
        }
        model.sampler.updatesMenuBar = !readings.isEmpty

        guard !readings.isEmpty else {
            statusItem.length = NSStatusItem.squareLength
            button.imagePosition = .imageOnly
            button.attributedTitle = NSAttributedString()
            button.setAccessibilityValue(nil)
            return
        }
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        let title = NSMutableAttributedString()
        for (index, reading) in readings.enumerated() {
            title.append(NSAttributedString(string: index == 0 ? " " : "  "))
            if let image = NSImage(systemSymbolName: reading.symbol, accessibilityDescription: nil)?
                .withSymbolConfiguration(symbolConfiguration) {
                let attachment = NSTextAttachment()
                attachment.image = image
                title.append(NSAttributedString(attachment: attachment))
            }
            title.append(NSAttributedString(string: " " + reading.text))
        }
        title.addAttributes([.font: font, .baselineOffset: 0], range: NSRange(location: 0, length: title.length))
        statusItem.length = NSStatusItem.variableLength
        button.imagePosition = .imageLeading
        button.attributedTitle = title
        button.setAccessibilityValue(readings.map(\.text).joined(separator: ", "))
    }

    private static func batterySymbol(_ battery: BatteryReading) -> String {
        if battery.state == .charging { return "battery.100percent.bolt" }
        let quarter = Int((battery.level * 4).rounded()) * 25
        return "battery.\(quarter)percent"
    }

    private func popoverDidClose() {
        statusItem.button?.highlight(false)
        model.sampler.setVisible(.popover, false)
        model.isPopoverShown = false
    }

    // MARK: NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let dashboard = item(String(localized: "Open Dashboard"), #selector(openDashboard))
        dashboard.setShortcut(for: .openDashboard)
        menu.addItem(dashboard)
        let settings = item(String(localized: "Settings…"), #selector(openSettings))
        settings.keyEquivalent = ","
        menu.addItem(settings)

        if SystemInfo.hasBattery {
            let chargeLimit = model.chargeLimit
            let setting = chargeLimit.isBusy ? nil : chargeLimit.setting
            menu.addItem(.separator())
            menu.addItem(item(String(localized: "Turn Off Charge Limit"), #selector(disableLimit),
                              enabled: setting?.isEnabled == true))
        }

        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Check for Updates"), #selector(checkForUpdates),
                          enabled: model.updater.canCheckForUpdates))
        let quit = NSMenuItem(title: String(localized: "Quit Monny"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    // While a menu tracks, hot-key events queue up and fire when it closes (KeyboardShortcuts docs).
    func menuWillOpen(_ menu: NSMenu) { KeyboardShortcuts.disable(.openDashboard) }
    func menuDidClose(_ menu: NSMenu) { KeyboardShortcuts.enable(.openDashboard) }

    private func item(_ title: String, _ action: Selector?, enabled: Bool = true) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        return item
    }

    @objc private func openDashboard() { model.openDashboard(nil) }
    @objc private func openSettings() { model.openDashboard(.settings) }

    @objc private func disableLimit() {
        Task { await model.chargeLimit.set(target: ChargeLimit.noLimit) }
    }

    @objc private func checkForUpdates() { model.updater.checkForUpdates() }
}
