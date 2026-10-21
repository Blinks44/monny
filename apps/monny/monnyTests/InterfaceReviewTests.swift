import AppKit
import SwiftUI
import Testing
@testable import monny

/// Render the actual views in both appearances; all battery-setting operations are injected.
@MainActor
struct InterfaceReviewTests {
    private let window = NSWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)

    @Test func olderMacOSExplainsAvailabilityInEveryLanguage() throws {
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let output = URL(filePath: "/private/tmp/monny-interface-review")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for language in ["en", "ru", "de", "fr", "es", "zh-Hans"] {
            for dark in [false, true] {
                let notice = NativeLimitControls(controller: ChargeLimitController(), supportsSystemChargeLimit: false)
                    .environment(\.locale, Locale(identifier: language))
                    .environment(\.colorScheme, dark ? .dark : .light)
                    .padding(16).frame(width: 328).background(Theme.surfaceOpaque)
                let view = NSHostingView(rootView: notice)
                view.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                view.frame = NSRect(x: 0, y: 0, width: 328, height: 260)
                view.layoutSubtreeIfNeeded()
                #expect(view.fittingSize.height <= 260, "Availability notice overflow: \(language)")
                try capture(view, to: output.appending(path: "older-os-\(language)-\(dark ? "dark" : "light").png"))
            }
        }
    }

    @Test func everyPageAndBatteryControlsFitAllLocalizations() async throws {
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let state = NativeChargeLimit.Snapshot(availableLimits: [80,85,90,95,100], configuredLimit: 80, enabled: true)
        let controller = ChargeLimitController(store: .init(operations: .init(read: { state }, setLimit: { _ in false }, setEnabled: { _ in false })))
        await controller.refresh()
        let battery = BatteryReading(level: 0.64, state: .charging, isFullyCharged: false, adapterWatts: 96, cycleCount: 213)
        let output = URL(filePath: "/private/tmp/monny-interface-review")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for language in ["en", "ru", "de", "fr", "es", "zh-Hans"] {
            for dark in [false, true] {
                let tab = BatteryTab(battery: battery, health: .init(maximumCapacity: 0.94), temperature: 33,
                    controller: controller, openSensors: {})
                    .environment(\.locale, Locale(identifier: language))
                    .environment(\.colorScheme, dark ? .dark : .light)
                    .padding(16).frame(width: 360).background(Theme.surfaceOpaque)
                let view = NSHostingView(rootView: tab)
                view.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                view.frame = NSRect(x: 0, y: 0, width: 360, height: 484)
                view.layoutSubtreeIfNeeded()
                #expect(view.fittingSize.height <= 484, "Battery overflow: \(language)")
                try capture(view, to: output.appending(path: "battery-\(language)-\(dark ? "dark" : "light").png"))
            }
        }
        let model = AppModel()
        for language in ["en", "ru", "de", "fr", "es", "zh-Hans"] {
            for dark in [false, true] {
                for tab in PopoverTab.allCases {
                    model.popoverTab = tab
                    let content = PopoverView(model: model)
                        .environment(\.locale, Locale(identifier: language))
                        .environment(\.colorScheme, dark ? .dark : .light)
                        .background(Theme.surfaceOpaque)
                    let view = NSHostingView(rootView: content)
                    view.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                    view.frame = NSRect(x: 0, y: 0, width: 360, height: 636)
                    try capture(view, to: output.appending(path: "popover-\(language)-\(tab)-\(dark ? "dark" : "light").png"))
                }
                for width in [900, 1040] {
                    for page in DashboardPage.allCases {
                        model.dashboardPage = page
                        let content = DashboardView(model: model)
                            .environment(\.locale, Locale(identifier: language))
                            .background(Theme.surfaceOpaque)
                            .environment(\.colorScheme, dark ? .dark : .light)
                        let view = NSHostingView(rootView: content)
                        view.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                        view.frame = NSRect(x: 0, y: 0, width: width, height: 700)
                        try capture(view, to: output.appending(path: "page-\(language)-\(page)-\(width)-\(dark ? "dark" : "light").png"))
                    }
                }
            }
        }
    }

    private func capture<Content: View>(_ view: NSHostingView<Content>, to url: URL) throws {
        window.setContentSize(view.frame.size)
        window.contentView = view
        view.layoutSubtreeIfNeeded()
        let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let data = try #require(bitmap.representation(using: .png, properties: [:]))
        try data.write(to: url)
    }
}
