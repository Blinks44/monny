import AppKit
import Observation

/// Shows focus only to someone using the keyboard, like `:focus-visible` on the web: a key press
/// turns focus indicators on and a click turns them off. The popover tabs and the sidebar take
/// focus without the Keyboard navigation setting, so otherwise they would draw a ring after a click.
@Observable final class FocusVisibility {
    static let shared = FocusVisibility()

    private(set) var isVisible = false
    @ObservationIgnored private var monitor: Any?

    private init() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            // Command shortcuts are not navigation, so they leave the indicators as they are.
            let isNavigation = event.type == .keyDown && !event.modifierFlags.contains(.command)
            if event.type != .keyDown || isNavigation, self?.isVisible != isNavigation {
                self?.isVisible = isNavigation
            }
            return event
        }
    }
}
