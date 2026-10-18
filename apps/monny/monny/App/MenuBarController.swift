import AppKit
import SwiftUI

/// The status item. A left click toggles the popover; a right click or Control-click opens the
/// menu. AppKit rather than `MenuBarExtra`: that scene offers either a menu or a window, not both,
/// and cannot draw the colored attention badge on a template icon.
final class MenuBarController: NSObject, NSPopoverDelegate, NSMenuDelegate {
    private let model: AppModel
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let menu = NSMenu()
    private let badge = NSView()
    private var defaultsObservation: NSObjectProtocol?

    init(model: AppModel) {
        self.model = model
        super.init()
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: PopoverView(model: model))
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
        guard let button = statusItem.button, !popover.isShown else { return }
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func closePopover() { popover.performClose(nil) }

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            closePopover()
            showMenu()
        } else if popover.isShown {
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

    // MARK: NSPopoverDelegate

    func popoverWillShow(_ notification: Notification) { statusItem.button?.highlight(true) }
    func popoverDidClose(_ notification: Notification) { statusItem.button?.highlight(false) }

    // MARK: NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let dashboard = item(String(localized: "Open Dashboard"), #selector(openDashboard))
        dashboard.keyEquivalent = "m"
        dashboard.keyEquivalentModifierMask = [.option, .command]
        menu.addItem(dashboard)
        let settings = item(String(localized: "Settings…"), #selector(openSettings))
        settings.keyEquivalent = ","
        menu.addItem(settings)

        if SystemInfo.hasBattery {
            // Battery commands need the helper, which arrives with battery control (PLAN phase 4).
            menu.addItem(.separator())
            menu.addItem(item(String(localized: "Pause Battery Control"), nil, enabled: false))
            menu.addItem(item(String(localized: "Charge to 100% Now"), nil, enabled: false))
            menu.addItem(item(String(localized: "Start Calibration…"), nil, enabled: false))
        }

        menu.addItem(.separator())
        menu.addItem(item(String(localized: "About Monny"), #selector(showAbout)))
        let quit = NSMenuItem(title: String(localized: "Quit Monny"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    private func item(_ title: String, _ action: Selector?, enabled: Bool = true) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        return item
    }

    @objc private func openDashboard() { model.openDashboard(nil) }
    @objc private func openSettings() { model.openDashboard(.settings) }

    @objc private func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
