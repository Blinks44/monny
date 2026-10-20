import AppKit
import SwiftUI
import Testing
@testable import monny

@MainActor
struct NativeLimitLayoutTests {
    @Test func nativeControlFitsPopoverInAllLanguages() async throws {
        var status = HelperStatus.current
        status.nativeLimitSessionAvailable = true
        status.nativeLimitSessionVersion = HelperContract.nativeLimitSessionVersion
        status.nativeChargeLimit = .available(.init(availableLimits: [80, 85, 90, 95, 100], configuredLimit: 85, enabled: true))
        let response = status
        let helper = BatteryHelper(operations: .init(
            signingIdentity: { .certificate(String(repeating: "a", count: 40)) },
            registration: { .enabled }, register: {}, unregister: {}, request: { _, _ in response }))
        await helper.refresh()
        #expect(helper.canControlNativeLimit)
        for language in ["en", "ru", "de", "fr", "es", "zh-Hans"] {
            let content = NativeLimitControls(helper: helper)
                .environment(\.locale, Locale(identifier: language))
                .padding(16).frame(width: 328).background(Theme.surfaceOpaque)
            let view = NSHostingView(rootView: content)
            view.frame = NSRect(x: 0, y: 0, width: 328, height: 220)
            let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = view
            view.layoutSubtreeIfNeeded()
            #expect(view.fittingSize.height <= 230, "Native controls overflow the popover: \(language)")
            let battery = BatteryReading(level: 0.85, state: .onAdapter, isFullyCharged: false,
                adapterWatts: 65, cycleCount: 100)
            let tab = NSHostingView(rootView: BatteryTab(battery: battery,
                health: .init(maximumCapacity: 0.95), temperature: 32,
                helper: helper, openSensors: {}).environment(\.locale, Locale(identifier: language)))
            tab.frame = NSRect(x: 0, y: 0, width: 328, height: 484)
            tab.layoutSubtreeIfNeeded()
            #expect(tab.fittingSize.height <= 484, "Battery tab overflows the fixed popover: \(language), \(tab.fittingSize.height)")
            if language == "en" || language == "ru", let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: bitmap)
                if let data = bitmap.representation(using: .png, properties: [:]) {
                    try data.write(to: URL(filePath: "/tmp/monny-native-controls-\(language).png"))
                }
            }
            window.close()
        }
    }
}
