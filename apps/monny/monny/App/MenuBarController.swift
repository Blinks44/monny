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
        panel.keepsPopoverOpen = { [weak model] in
            model?.chargeLimit.isBusy == true
        }
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
        // The badge preference lives in UserDefaults; Settings changes it while the app runs.
        defaultsObservation = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateBadge() }
        }
    }

    func showPopover() {
        guard let button = statusItem.button, !panel.isShown else { return }
        button.highlight(true)
        model.sampler.setVisible(.popover, true)
        panel.show(below: button)
        // A nonactivating panel does not reliably trigger applicationDidBecomeActive.
        if SystemInfo.hasBattery { Task { await model.chargeLimit.refresh() } }
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
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 7),
            badge.heightAnchor.constraint(equalToConstant: 7),
            badge.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -2),
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

    private func popoverDidClose() {
        statusItem.button?.highlight(false)
        model.sampler.setVisible(.popover, false)
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
            menu.addItem(.separator())
            menu.addItem(item(String(localized: "Turn Off Charge Limit"), #selector(disableLimit),
                              enabled: model.chargeLimit.snapshot?.enabled == true && !model.chargeLimit.isBusy))
            menu.addItem(item(String(localized: "Set Limit to 100%"), #selector(fullLimit),
                              enabled: model.chargeLimit.snapshot != nil && !model.chargeLimit.isBusy))
        }

        menu.addItem(.separator())
        menu.addItem(item(String(localized: "About Monny"), #selector(showAbout)))
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
        guard let snapshot = model.chargeLimit.snapshot else { return }
        Task { await model.chargeLimit.set(limit: snapshot.configuredLimit, enabled: false) }
    }
    @objc private func fullLimit() {
        Task { await model.chargeLimit.set(limit: 100, enabled: true) }
    }

    @objc private func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
