import AppKit
import Charts
import SwiftUI

/// The white rounded card used by every popover and window section.
struct CardBackground: ViewModifier {
    var radius = Theme.radiusCard
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content.background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Theme.surfaceCard)
                .strokeBorder(contrast == .increased ? Theme.textTertiary : Theme.surfaceCardStroke)
                .cardElevation()
        }
    }
}

extension View {
    func card(radius: CGFloat = Theme.radiusCard) -> some View { modifier(CardBackground(radius: radius)) }
}

/// A metric's symbol and name in its metric color, as on every card header.
struct MetricLabel: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color

    var body: some View {
        Label { Text(title) } icon: { Image(systemName: symbol) }
            .labelStyle(SpacedLabelStyle())
            .font(Theme.label)
            .foregroundStyle(color)
    }
}

private struct SpacedLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.accessibilityHidden(true)
            configuration.title
        }
    }
}

/// Small status capsule (`Chip/Success`, `Warning`, `Danger`, `Info`, `Neutral`, `Memory`).
struct Chip: View {
    enum Kind { case success, warning, danger, info, neutral, memory }

    let title: Text
    var symbol: String?
    var kind: Kind = .neutral

    init(title: LocalizedStringKey, symbol: String? = nil, kind: Kind = .neutral) {
        self.init(title: Text(title), symbol: symbol, kind: kind)
    }

    /// For a formatted value such as a temperature.
    init(title: Text, symbol: String? = nil, kind: Kind = .neutral) {
        self.title = title
        self.symbol = symbol
        self.kind = kind
    }

    private var colors: (text: Color, fill: Color) {
        switch kind {
        case .success: (Theme.statusSuccessText, Theme.statusSuccessBg)
        case .warning: (Theme.statusWarningText, Theme.statusWarningBg)
        case .danger: (Theme.statusDangerText, Theme.statusDangerBg)
        case .info: (Theme.accentBrand, Theme.statusInfoBg)
        case .neutral: (Theme.textSecondary, Theme.fillTrack)
        case .memory: (Theme.metricMemory, Theme.metricMemory.opacity(0.14))
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol).accessibilityHidden(true) }
            title
        }
        .font(Theme.footnote.weight(.semibold))
        .foregroundStyle(colors.text)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(colors.fill, in: .capsule)
    }
}

/// Tinted banner with an icon tile, a title and one line of explanation (`Banner/*`).
struct Banner: View {
    enum Kind { case warning, danger, info }

    let kind: Kind
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    private var tint: Color {
        switch kind {
        case .warning: Theme.metricHeat
        case .danger: Theme.statusDanger
        case .info: Theme.accentBrand
        }
    }

    private var fill: Color {
        switch kind {
        case .warning: Theme.statusWarningBg
        case .danger: Theme.statusDangerBg
        case .info: Theme.statusInfoBg
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(tint.gradient, in: .rect(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary)
                Text(message).font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(fill, in: .rect(cornerRadius: Theme.radiusTile, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.radiusTile, style: .continuous).strokeBorder(tint.opacity(0.25))
        }
        .accessibilityElement(children: .combine)
    }
}

/// 32 pt round button with a symbol, used in the popover header and the window toolbar.
struct IconButton: View {
    let symbol: String
    let label: LocalizedStringKey
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 32, height: 32)
                .background(isHovered ? Theme.stateHover : .clear, in: .circle)
                .background(Theme.surfaceControl, in: .circle)
                .controlElevation()
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .help(Text(label))
        .accessibilityLabel(Text(label))
        .onHover { isHovered = $0 }
    }
}

/// Circular gauge with a track; `nil` draws only the track, never a zero. As in Sketch, the stroke
/// is centered on a circle of `diameter`, so the view is `diameter + lineWidth` wide.
struct RingGauge: View {
    let fraction: Double?
    let color: Color
    var diameter: CGFloat = 68
    var lineWidth: CGFloat = 9

    var body: some View {
        ZStack {
            Circle().stroke(Theme.fillTrack, lineWidth: lineWidth)
            if let fraction {
                Circle()
                    .trim(from: 0, to: min(max(fraction, 0), 1))
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: diameter, height: diameter)
        .padding(lineWidth / 2)
    }
}

/// Horizontal capsule bar with a track; `nil` draws only the track.
struct CapsuleBar: View {
    let fraction: Double?
    let color: Color
    var height: CGFloat = 10

    var body: some View {
        Capsule()
            .fill(Theme.fillTrack)
            .overlay(alignment: .leading) {
                if let fraction {
                    GeometryReader { proxy in
                        Capsule().fill(color.gradient).frame(width: proxy.size.width * min(max(fraction, 0), 1))
                    }
                }
            }
            .frame(height: height)
    }
}

/// The em dash shown for a value Monny cannot read yet or at all.
struct UnavailableValue: View {
    var font: Font = Theme.metricM

    var body: some View {
        Text(verbatim: "—").font(font).foregroundStyle(Theme.textTertiary)
            .accessibilityLabel(Text("Unavailable"))
    }
}

// MARK: - Buttons

/// Accent capsule for the one primary action (`Button/Primary`, `Button/Large Primary` with `.large`).
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.controlSize) private var controlSize

    func makeBody(configuration: Configuration) -> some View {
        let isLarge = controlSize == .large
        configuration.label
            .font(isLarge ? Theme.headline : Theme.bodyEmphasized)
            .foregroundStyle(Theme.textOnAccent)
            .padding(.horizontal, isLarge ? 20 : 14)
            .frame(height: isLarge ? 40 : 32)
            .background(Theme.accentBrand.gradient, in: .capsule)
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .contentShape(.capsule)
    }
}

/// White raised capsule for secondary actions (`Button/Secondary`).
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.bodyEmphasized)
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(Theme.surfaceControl, in: .capsule)
            .controlElevation()
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45)
            .contentShape(.capsule)
    }
}

/// Soft accent capsule (`Button/Tinted`) and soft red capsule (`Button/Destructive`).
struct TintedButtonStyle: ButtonStyle {
    var isDestructive = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.bodyEmphasized)
            .foregroundStyle(isDestructive ? Theme.statusDangerText : Theme.accentBrand)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(isDestructive ? Theme.statusDangerBg : Theme.statusInfoBg, in: .capsule)
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.45)
            .contentShape(.capsule)
    }
}

/// Accent text without a background (`Button/Plain`), for links such as Open Dashboard.
struct PlainLinkButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.bodyEmphasized)
            .foregroundStyle(Theme.accentBrand)
            .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.45)
            .contentShape(.rect)
    }
}

// MARK: - Selection controls

/// One-of-many control drawn as in Sketch: `.tabs` is the popover's section switcher (a recessed
/// capsule track with a raised selected pill), `.chips` the row of separate sort capsules with a
/// dark selected one. VoiceOver and keyboard users get a standard segmented picker.
struct SegmentedControl<Value: Hashable>: View {
    enum Style { case tabs, chips }

    let title: LocalizedStringKey
    @Binding var selection: Value
    let options: [(value: Value, label: LocalizedStringKey)]
    var style = Style.tabs
    /// Outer height of `.tabs`: 34 pt in the popover, 32 pt in the window toolbar.
    var height: CGFloat = 34
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: style == .tabs ? 0 : 6) {
            ForEach(options, id: \.value) { option in
                segment(option.value, label: option.label)
            }
        }
        .padding(style == .tabs ? 3 : 0)
        .background {
            if style == .tabs {
                Capsule().fill(Theme.fillTrack.shadow(.inner(color: .black.opacity(0.08), radius: 1.5, y: 1)))
            }
        }
        .accessibilityRepresentation {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.value) { Text($0.label).tag($0.value) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func segment(_ value: Value, label: LocalizedStringKey) -> some View {
        let isSelected = value == selection
        return Button {
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) { selection = value }
        } label: {
            Text(label)
                .font(style == .tabs ? Theme.label : Theme.footnote.weight(.semibold))
                .foregroundStyle(foreground(isSelected))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: style == .tabs ? height - 6 : 24)
                .background { pill(isSelected) }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    private func foreground(_ isSelected: Bool) -> Color {
        switch style {
        case .tabs: isSelected ? Theme.textPrimary : Theme.textSecondary
        case .chips: isSelected ? Theme.textInverse : Theme.textSecondary
        }
    }

    @ViewBuilder
    private func pill(_ isSelected: Bool) -> some View {
        switch style {
        case .tabs:
            if isSelected {
                Capsule()
                    .fill(Theme.surfaceControl)
                    .shadow(color: .black.opacity(0.06), radius: 0.5)
                    .controlElevation()
                    .matchedGeometryEffect(id: "selection", in: namespace)
            }
        case .chips:
            Capsule().fill(isSelected ? Theme.textPrimary : Theme.fillTrack)
        }
    }
}

/// The popover panel as drawn in Sketch (`Popover glass`): the system blur behind the window,
/// the translucent gradient, a 1 pt inside hairline and two soft shadows outside the shape.
/// `shadowInsets` is the room the shadows need around the panel.
struct PanelChrome<Content: View>: View {
    static var shadowInsets: EdgeInsets { EdgeInsets(top: 8, leading: 32, bottom: 56, trailing: 32) }

    @ViewBuilder var content: Content
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.radiusPanel, style: .continuous)
        content
            .background {
                shape.fill(LinearGradient(colors: [Theme.surfacePanelTop, Theme.surfacePanelBottom],
                                          startPoint: .top, endPoint: .bottom))
            }
            .background { BehindWindowBlur(cornerRadius: Theme.radiusPanel) }
            .clipShape(shape)
            .overlay { shape.strokeBorder(contrast == .increased ? Theme.textTertiary : Theme.surfacePanelStroke) }
            .background { shadow(of: shape) }
            .padding(Self.shadowInsets)
    }

    /// Shadows only outside the shape, so they never darken the translucent glass.
    private func shadow(of shape: RoundedRectangle) -> some View {
        ZStack {
            // Sketch spread −8 pt: the larger shadow is cast by a shape inset by 8 pt.
            shape.inset(by: 8).fill(.black).shadow(color: Theme.shadowPanelAmbient, radius: 30, y: 24)
            shape.fill(.black).shadow(color: Theme.shadowPanelKey, radius: 3, y: 2)
        }
        .mask {
            Rectangle().padding(-80)
                .overlay { shape.blendMode(.destinationOut) }
                .compositingGroup()
        }
    }
}

/// `NSVisualEffectView` blurring what is behind the window. Its mask image clips the material
/// to the panel's continuous corners; a layer corner radius would leave square material corners.
struct BehindWindowBlur: NSViewRepresentable {
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        view.maskImage = Self.mask(cornerRadius: cornerRadius)
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) { }

    /// A stretchable rounded rectangle; continuous corners reach about 1.53 × the radius.
    private static func mask(cornerRadius: CGFloat) -> NSImage {
        let inset = (cornerRadius * 1.6).rounded(.up)
        let size = NSSize(width: inset * 2 + 1, height: inset * 2 + 1)
        let image = NSImage(size: size, flipped: false) { rect in
            let path = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect).cgPath
            NSColor.black.setFill()
            NSBezierPath(cgPath: path).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        image.resizingMode = .stretch
        return image
    }
}

// MARK: - Charts

/// One series of a sparkline: a line in its metric color, optionally with a soft area below.
struct SparklineSeries: Identifiable {
    let id: String
    let points: [(date: Date, value: Double)]
    let color: Color
    var filled = false
}

/// Axis-less mini chart shared by the cards (`Card · Network` in Sketch). The series share one
/// y scale; the newest point of the first series gets a live dot. Fewer than two points draw
/// nothing, so a fresh history never shows a flat zero line.
struct Sparkline: View {
    let series: [SparklineSeries]

    var body: some View {
        Chart {
            ForEach(series) { series in
                ForEach(Array(series.points.enumerated()), id: \.offset) { _, point in
                    if series.filled {
                        AreaMark(x: .value("Time", point.date), y: .value("Value", point.value), series: .value("Series", series.id))
                            .foregroundStyle(LinearGradient(colors: [series.color.opacity(0.3), series.color.opacity(0)],
                                                            startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                    }
                    LineMark(x: .value("Time", point.date), y: .value("Value", point.value), series: .value("Series", series.id))
                        .foregroundStyle(series.color)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                }
            }
            if let first = series.first, first.points.count > 1, let last = first.points.last {
                PointMark(x: .value("Time", last.date), y: .value("Value", last.value))
                    .symbolSize(40)
                    .foregroundStyle(first.color)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartYScale(domain: 0...max(series.flatMap { $0.points.map(\.value) }.max() ?? 1, 1))
        .opacity(series.contains { $0.points.count > 1 } ? 1 : 0)
        .accessibilityHidden(true)
    }
}
