import AppKit
import SwiftUI

/// The borderless panel under the status item that hosts the popover content. `NSPopover`
/// always draws an arrow, while Sketch draws a rounded glass panel without one, as macOS 26
/// draws its own menu bar extras. It behaves like a transient popover or menu: a click outside
/// it or Escape closes it, and it fades in and out.
final class MenuBarPanel: NSPanel {
    /// Called once the panel has closed for any reason.
    var onClose: () -> Void = { }
    private var monitors: [Any] = []
    private var isClosing = false

    init<Content: View>(rootView: Content) {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        level = .popUpMenu
        isOpaque = false
        backgroundColor = .clear
        // `PanelChrome` draws the shadows from Sketch; the system shadow adds a dark rim.
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isReleasedWhenClosed = false
        animationBehavior = .none
        contentView = NSHostingView(rootView: PanelChrome { rootView })
    }

    override var canBecomeKey: Bool { true }

    /// Shows the panel centered under `button`, kept on the button's screen.
    func show(below button: NSStatusBarButton) {
        guard let buttonWindow = button.window, let screen = buttonWindow.screen, let contentView else { return }
        isClosing = false
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let size = contentView.fittingSize
        let insets = PanelChrome<EmptyView>.shadowInsets
        let panelWidth = size.width - insets.leading - insets.trailing
        let visible = screen.visibleFrame
        let gap: CGFloat = 6
        let panelX = min(max(anchor.midX - panelWidth / 2, visible.minX + gap), visible.maxX - panelWidth - gap)
        let top = anchor.minY - gap + insets.top
        setFrame(NSRect(x: panelX - insets.leading, y: top - size.height, width: size.width, height: size.height), display: true)

        alphaValue = 0
        makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            animator().alphaValue = 1
        }
        startMonitoring(ignoring: button)
    }

    /// Fades out like a menu, then orders out.
    override func close() {
        stopMonitoring()
        guard isVisible, !isClosing else { return }
        isClosing = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.finishClosing()
            }
        }
    }

    private func finishClosing() {
        // Reopened while fading out: `show` has already cleared the flag.
        guard isClosing else { return }
        isClosing = false
        super.close()
        alphaValue = 1
        onClose()
    }

    /// Visible and not fading out.
    var isShown: Bool { isVisible && !isClosing }

    override func cancelOperation(_ sender: Any?) { close() }

    /// Clicks in other apps close the panel; so do clicks in Monny's other windows and in the
    /// panel's transparent shadow margin. A click on the status item is left to its own action,
    /// which toggles the panel: closing on its mouse-down would let the mouse-up reopen it. The
    /// status item is checked by position, because its click can reach the global monitor too.
    private func startMonitoring(ignoring button: NSStatusBarButton) {
        stopMonitoring()
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self, weak button] _ in
            MainActor.assumeIsolated {
                guard let self, !Self.isMouse(on: button) else { return }
                self.close()
            }
        }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self, weak button] event in
            guard let self, !Self.isMouse(on: button) else { return event }
            if event.window !== self || !self.panelFrame.contains(NSEvent.mouseLocation) { self.close() }
            return event
        }) {
            monitors.append(local)
        }
    }

    private static func isMouse(on button: NSStatusBarButton?) -> Bool {
        guard let button, let window = button.window else { return false }
        return window.convertToScreen(button.convert(button.bounds, to: nil)).contains(NSEvent.mouseLocation)
    }

    /// The drawn panel in screen coordinates, without the shadow margin.
    private var panelFrame: NSRect {
        let insets = PanelChrome<EmptyView>.shadowInsets
        return NSRect(x: frame.minX + insets.leading, y: frame.minY + insets.bottom,
                      width: frame.width - insets.leading - insets.trailing,
                      height: frame.height - insets.top - insets.bottom)
    }

    private func stopMonitoring() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
    }
}
