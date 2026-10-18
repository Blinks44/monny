import AppKit
import SwiftUI

/// Executable tokens of Monny.sketch: every Light/Dark Color Variable, the Monny text styles,
/// spacing, radii and elevation from page `04 · Foundations`. Sketch stays the source; change a
/// value in both places.
enum Theme {

    // Text
    static let textPrimary = Color(light: 0x1D1D1F, dark: 0xF5F5F7)
    static let textSecondary = Color(light: 0x6E6E73, dark: 0xA1A1A6)
    static let textTertiary = Color(light: 0x86868B, dark: 0x8E8E93)
    static let textOnAccent = Color(light: 0xFFFFFF, dark: 0xFFFFFF)

    // Surface
    static let surfacePanelTop = Color(light: 0xFFFFFF, 0.72, dark: 0x2A2A2E, 0.78)
    static let surfacePanelBottom = Color(light: 0xF7F7F9, 0.65, dark: 0x1C1C1E, 0.82)
    static let surfacePanelStroke = Color(light: 0xFFFFFF, 0.9, dark: 0xFFFFFF, 0.12)
    static let surfaceCard = Color(light: 0xFFFFFF, 0.78, dark: 0xFFFFFF, 0.05)
    static let surfaceCardStroke = Color(light: 0xFFFFFF, dark: 0xFFFFFF, 0.08)
    static let surfaceControl = Color(light: 0xFFFFFF, dark: 0xFFFFFF, 0.14)
    static let surfaceSidebarStart = Color(light: 0xF2F2F4, 0.85, dark: 0x2A2A2E, 0.7)
    static let surfaceSidebarEnd = Color(light: 0xF2F2F4, 0.85, dark: 0x2A2A2E, 0.7)
    static let surfaceOpaque = Color(light: 0xF5F5F7, dark: 0x1C1C1E)

    // Fill
    static let fillTrack = Color(light: 0x000000, 0.06, dark: 0xFFFFFF, 0.08)
    static let fillSeparator = Color(light: 0x000000, 0.06, dark: 0xFFFFFF, 0.07)
    static let fillTooltip = Color(light: 0x1D1D1F, 0.92, dark: 0xF5F5F7, 0.95)

    // Accent
    static let accentBrand = Color(light: 0x007AFF, dark: 0x0A84FF)
    static let accentIconGraphite = Color(light: 0x2C2D32, dark: 0x3A3B40)

    // Metric
    static let metricCPU = Color(light: 0x7C5CFF, dark: 0x9B82FF)
    static let metricCPULight = Color(light: 0xC09BFF, dark: 0xCDB4FF)
    static let metricCPUEfficiency = Color(light: 0xB9ADFF, dark: 0x6E62B8)
    static let metricMemory = Color(light: 0x0EA5A4, dark: 0x2DD4BF)
    static let metricMemoryLight = Color(light: 0x6EE7D2, dark: 0x99F6E4)
    static let metricDisk = Color(light: 0xF59E0B, dark: 0xFBBF24)
    static let metricDiskLight = Color(light: 0xFCD34D, dark: 0xFDE68A)
    static let metricNetwork = Color(light: 0x3B82F6, dark: 0x60A5FA)
    static let metricNetworkLight = Color(light: 0x8EC5FF, dark: 0xBFDBFE)
    static let metricUpload = Color(light: 0xC05BD6, dark: 0xE08AF0)
    static let metricBattery = Color(light: 0x22C55E, dark: 0x34D374)
    static let metricBatteryLight = Color(light: 0xB5F25C, dark: 0xC6F77A)
    static let metricHeat = Color(light: 0xFB923C, dark: 0xFDA05A)
    static let metricHeatHot = Color(light: 0xF43F5E, dark: 0xFB6F86)

    // Status
    static let statusSuccessText = Color(light: 0x16A34A, dark: 0x4ADE80)
    static let statusWarningText = Color(light: 0xE8590C, dark: 0xFDBA74)
    static let statusDanger = Color(light: 0xF43F5E, dark: 0xFB7185)
    static let statusSuccessBg = Color(light: 0x22C55E, 0.14, dark: 0x22C55E, 0.18)
    static let statusWarningBg = Color(light: 0xFB923C, 0.14, dark: 0xFB923C, 0.18)
    static let statusDangerText = Color(light: 0xE11D48, dark: 0xFB7185)
    static let statusDangerBg = Color(light: 0xF43F5E, 0.12, dark: 0xF43F5E, 0.18)
    static let statusInfoBg = Color(light: 0x007AFF, 0.1, dark: 0x0A84FF, 0.18)

    // State
    static let stateHover = Color(light: 0x000000, 0.04, dark: 0xFFFFFF, 0.06)
    static let statePressed = Color(light: 0x000000, 0.08, dark: 0xFFFFFF, 0.1)
    static let stateFocusRing = Color(light: 0x007AFF, 0.5, dark: 0x0A84FF, 0.6)

    // Shadow
    static let shadowTint = Color(light: 0x000000, dark: 0x000000)

    // Text styles (SF Pro, fixed sizes as drawn)
    static let display = Font.system(size: 32, weight: .bold)
    static let metricL = Font.system(size: 26, weight: .bold)
    static let title = Font.system(size: 24, weight: .bold)
    static let metricM = Font.system(size: 20, weight: .bold)
    static let metricS = Font.system(size: 16, weight: .bold)
    static let headline = Font.system(size: 14, weight: .semibold)
    static let bodyEmphasized = Font.system(size: 13, weight: .semibold)
    static let body = Font.system(size: 13)
    static let label = Font.system(size: 12, weight: .semibold)
    static let footnote = Font.system(size: 11, weight: .medium)
    static let caption = Font.system(size: 10, weight: .medium)
    static let overline = Font.system(size: 10, weight: .bold)
    static let overlineTracking: CGFloat = 0.6

    // Spacing (4 pt grid)
    static let spaceXS: CGFloat = 4
    static let spaceM: CGFloat = 8
    static let spaceL: CGFloat = 12
    static let spaceXL: CGFloat = 16
    static let space3XL: CGFloat = 24

    // Corner radii (continuous)
    static let radiusBar: CGFloat = 3
    static let radiusIcon: CGFloat = 7
    static let radiusControl: CGFloat = 12
    static let radiusTile: CGFloat = 16
    static let radiusCard: CGFloat = 20
    static let radiusWindow: CGFloat = 28
}

extension Color {
    /// An appearance-adaptive color from `0xRRGGBB` values.
    init(light: UInt32, _ lightOpacity: Double = 1, dark: UInt32, _ darkOpacity: Double = 1) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let hex = isDark ? dark : light
            return NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: isDark ? darkOpacity : lightOpacity)
        })
    }
}

extension View {
    /// `elev.control`: y 2 · blur 6 · 14 %.
    func controlElevation() -> some View { shadow(color: .black.opacity(0.14), radius: 3, y: 2) }

    /// `elev.card`: y 6 · blur 18 · 8 % (Sketch blur is twice the SwiftUI radius).
    func cardElevation() -> some View { shadow(color: .black.opacity(0.08), radius: 9, y: 6) }
}
