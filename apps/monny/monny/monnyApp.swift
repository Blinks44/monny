import AppKit
import KeyboardShortcuts
import SwiftUI

@main
struct monnyApp: App {
    @NSApplicationDelegateAdaptor(MonnyAppDelegate.self) private var delegate

    var body: some Scene {
        Window("Monny", id: DashboardWindow.id) {
            DashboardView(model: delegate.model)
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1040, height: 700)
        // Monny lives in the menu bar; the dashboard opens on request, not at launch or login.
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        Window("Welcome to Monny", id: OnboardingWindow.id) {
            OnboardingView(model: delegate.model)
                .windowMinimizeBehavior(.disabled)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(OnboardingWindow.isNeeded && !MonnyAppDelegate.runningTests ? .presented : .suppressed)
        .restorationBehavior(.disabled)
    }
}

enum DashboardWindow {
    static let id = "dashboard"
}

final class MonnyAppDelegate: NSObject, NSApplicationDelegate {
    private(set) lazy var model = AppModel()
    private var menuBar: MenuBarController?
    /// Opens the dashboard scene; set by the first SwiftUI view that has `openWindow`.
    fileprivate static var openWindow: (() -> Void)?

    static var runningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.runningTests else { return }
        // No Dock icon until a window opens (proposal for SPEC §9, matching Rebind). The first
        // launch opens onboarding, which must come to the front like any app window.
        NSApp.setActivationPolicy(OnboardingWindow.isNeeded ? .regular : .accessory)
        let menuBar = MenuBarController(model: model)
        self.menuBar = menuBar
        model.showPopover = { [weak menuBar] in menuBar?.showPopover() }
        model.closePopover = { [weak menuBar] in menuBar?.closePopover() }
        model.openDashboard = { [weak self] page in self?.openDashboard(page) }
        applyAppearance()
        if OnboardingWindow.isNeeded { NSApp.activate() }
        KeyboardShortcuts.onKeyUp(for: .openDashboard) { [weak self] in self?.openDashboard(nil) }
        Task { [model] in
            await model.sampler.history.load()
            model.start()
        }

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(windowDidOpen), name: NSWindow.didBecomeMainNotification, object: nil)
        center.addObserver(self, selector: #selector(windowWillClose), name: NSWindow.willCloseNotification, object: nil)
        center.addObserver(self, selector: #selector(applyAppearance), name: UserDefaults.didChangeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(systemDidWake),
                                                         name: NSWorkspace.didWakeNotification, object: nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard !Self.runningTests else { return }
        model.sampler.history.save(synchronously: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationDidBecomeActive(_ notification: Notification) {
        guard !Self.runningTests else { return }
        Task { await model.chargeLimit.refresh() }
    }

    @objc private func systemDidWake() {
        guard !Self.runningTests else { return }
        Task { await model.chargeLimit.refresh() }
    }

    /// Opening Monny again from Finder or Spotlight while it runs shows the dashboard.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        openDashboard(nil)
        return false
    }

    private func openDashboard(_ page: DashboardPage?) {
        if let page { model.dashboardPage = page }
        model.closePopover()
        // Become a regular app first: switching the policy after the window opens deactivates
        // the app, and the window can stay behind other apps. The rest waits one run-loop turn
        // so the policy change and the closing menu or popover settle.
        if NSApp.activationPolicy() != .regular { NSApp.setActivationPolicy(.regular) }
        DispatchQueue.main.async {
            NSApp.activate()
            if let window = Self.dashboardWindow {
                if window.isMiniaturized { window.deminiaturize(nil) }
                window.makeKeyAndOrderFront(nil)
            } else {
                Self.openWindow?()
            }
        }
    }

    private static var dashboardWindow: NSWindow? {
        NSApp.windows.first { $0.identifier?.rawValue.hasPrefix(DashboardWindow.id) == true && $0.canBecomeMain }
    }

    @objc private func windowDidOpen(_ notification: Notification) { updateDockIcon() }

    @objc private func windowWillClose(_ notification: Notification) {
        updateDockIcon(closing: notification.object as? NSWindow)
    }

    /// A Dock icon only while the dashboard is open, so ⌘Tab reaches it.
    private func updateDockIcon(closing: NSWindow? = nil) {
        let hasWindow = NSApp.windows.contains {
            $0 !== closing && $0.canBecomeMain && !($0 is NSPanel) && ($0.isVisible || $0.isMiniaturized)
        }
        let policy: NSApplication.ActivationPolicy = hasWindow ? .regular : .accessory
        guard NSApp.activationPolicy() != policy else { return }
        NSApp.setActivationPolicy(policy)
        if hasWindow { NSApp.activate() }
    }

    @objc private func applyAppearance() {
        let raw = UserDefaults.standard.string(forKey: PreferenceKey.appearance) ?? ""
        let appearance = (AppearancePreference(rawValue: raw) ?? .system).appearance
        if NSApp.appearance != appearance { NSApp.appearance = appearance }
    }

    /// Lets AppKit code open the dashboard scene, which only SwiftUI views can do.
    fileprivate static func register(openWindow: @escaping () -> Void) {
        if Self.openWindow == nil { Self.openWindow = openWindow }
    }
}

/// Hands `openWindow` to the app delegate. The status item hosts it, so the action exists
/// before the dashboard has ever been shown.
struct DashboardWindowOpener: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear.frame(width: 0, height: 0).accessibilityHidden(true)
            .onAppear { MonnyAppDelegate.register { openWindow(id: DashboardWindow.id) } }
    }
}
