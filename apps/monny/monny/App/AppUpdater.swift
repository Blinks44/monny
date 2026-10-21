import AppKit
import Sparkle

/// Sparkle checks the signed appcast of the latest GitHub release, then downloads, verifies and
/// installs updates with its standard windows after the user confirms (SPEC §7). Monny offers only
/// the command and the automatic-check preference, which Sparkle stores itself. No system profile
/// is sent.
@Observable final class AppUpdater {
    private(set) var canCheckForUpdates = false
    @ObservationIgnored private let controller: SPUStandardUpdaterController
    @ObservationIgnored private let presentation = UpdatePresentation()
    @ObservationIgnored private var observation: NSKeyValueObservation?

    /// Tests create the controller without starting scheduled checks.
    init(startsUpdater: Bool) {
        controller = SPUStandardUpdaterController(startingUpdater: startsUpdater, updaterDelegate: nil,
                                                  userDriverDelegate: presentation)
        observation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            MainActor.assumeIsolated { self?.canCheckForUpdates = updater.canCheckForUpdates }
        }
    }

    var automaticallyChecksForUpdates: Bool {
        get {
            access(keyPath: \.automaticallyChecksForUpdates)
            return controller.updater.automaticallyChecksForUpdates
        }
        set {
            withMutation(keyPath: \.automaticallyChecksForUpdates) {
                controller.updater.automaticallyChecksForUpdates = newValue
            }
        }
    }

    func checkForUpdates() { controller.checkForUpdates(nil) }
}

/// Monny has no Dock icon without its window, so a scheduled update window would open behind
/// other apps. Bring it forward; the app delegate removes the Dock icon again when it closes.
private final class UpdatePresentation: NSObject, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem,
                                                              andInImmediateFocus immediateFocus: Bool) -> Bool { true }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem,
                                                   state: SPUUserUpdateState) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }
}
