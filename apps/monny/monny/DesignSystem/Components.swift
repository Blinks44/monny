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

/// Small status capsule (`Chip/Success`, `Warning`, `Danger`, `Info`, `Neutral`).
struct Chip: View {
    enum Kind { case success, warning, danger, info, neutral }

    let title: LocalizedStringKey
    var symbol: String?
    var kind: Kind = .neutral

    private var colors: (text: Color, fill: Color) {
        switch kind {
        case .success: (Theme.statusSuccessText, Theme.statusSuccessBg)
        case .warning: (Theme.statusWarningText, Theme.statusWarningBg)
        case .danger: (Theme.statusDangerText, Theme.statusDangerBg)
        case .info: (Theme.accentBrand, Theme.statusInfoBg)
        case .neutral: (Theme.textSecondary, Theme.fillTrack)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if let symbol { Image(systemName: symbol).accessibilityHidden(true) }
            Text(title)
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

/// Circular gauge with a track; `nil` draws only the track, never a zero.
struct RingGauge: View {
    let fraction: Double?
    let color: Color
    var lineWidth: CGFloat = 8

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
