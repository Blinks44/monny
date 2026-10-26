import SwiftUI

// Pieces shared by the popover AI tab and the window's AI usage page (Sketch DES-003 frames).

extension AITool {
    /// The service's name on cards and in notifications; not translated.
    var name: String {
        switch self {
        case .claude: "Claude"
        case .codex: "Codex"
        case .cursor: "Cursor"
        case .grok: "Grok"
        case .jetBrains: "JetBrains AI"
        case .copilot: "Copilot"
        case .cline: "ClinePass"
        case .codebuff: "Codebuff"
        case .amp: "Amp"
        case .augment: "Augment"
        case .nous: "Nous Portal"
        }
    }

    /// The tool Monny reads the sign-in of.
    var appName: String {
        switch self {
        case .claude: "Claude Code"
        case .codex: "Codex"
        case .cursor: "Cursor"
        case .grok: "Grok CLI"
        case .jetBrains: "JetBrains AI"
        case .copilot: "GitHub Copilot"
        case .cline: "Cline"
        case .codebuff: "Codebuff"
        case .amp: "Amp"
        case .augment: "Auggie"
        case .nous: "Hermes Agent"
        }
    }

    var color: Color {
        switch self {
        case .claude: Theme.aiClaude
        case .codex: Theme.aiCodex
        case .cursor: Theme.aiCursor
        case .grok: Theme.aiGrok
        case .jetBrains: Theme.aiJetBrains
        case .amp: Theme.aiAmp
        case .copilot, .cline, .codebuff, .augment, .nous: Theme.aiCodex
        }
    }

    /// The tile behind the service's mark, in the brand's own colors (user choice 2026-10-22).
    var iconColor: Color {
        switch self {
        case .claude: Theme.aiClaude
        case .codex, .grok: Theme.aiIconWhite
        case .cursor: Theme.aiIconBlack
        case .jetBrains, .copilot, .codebuff: Theme.aiIconBlack
        case .amp, .cline, .augment, .nous: Theme.aiIconWhite
        }
    }

    /// The service's mark in the asset catalog (sources in research/ai-usage-limits.md).
    var logo: ImageResource {
        switch self {
        case .claude: .aiClaude
        case .codex: .aiCodex
        case .cursor: .aiCursor
        case .grok: .aiGrok
        case .jetBrains: .aiJetBrains
        case .copilot: .aiCopilot
        case .cline: .aiCline
        case .codebuff: .aiCodebuff
        case .amp: .aiAmp
        case .augment: .aiAugment
        case .nous: .aiNous
        }
    }

    /// The window drawn in the quota history: the longest one each tool has.
    var historyMetric: HistoryMetric {
        switch self {
        case .claude: .claudeWeekly
        case .codex: .codexWeekly
        case .cursor: .cursorMonthly
        case .grok: .grokCredits
        case .jetBrains: .jetBrainsMonthly
        case .copilot: .copilotPremium
        case .cline: .clineMonthly
        case .codebuff: .codebuffWeekly
        case .amp: .ampMonthly
        case .augment: .augmentMonthly
        case .nous: .nousMonthly
        }
    }

    /// What to do when the sign-in is missing or rejected.
    var signInHint: LocalizedStringKey {
        switch self {
        case .claude: "Sign in to Claude Code with your Claude account to see its limits here."
        case .codex: "Sign in to Codex with your ChatGPT account to see its limits here."
        case .cursor: "Sign in to Cursor to see its included usage here."
        case .grok: "Sign in to the Grok CLI with your SuperGrok account to see its limits here."
        case .jetBrains: "Open a JetBrains IDE and use AI Assistant to make its quota available here."
        case .amp: "Sign in to the Amp CLI to see your allowances and individual balance here."
        case .augment: "Sign in with auggie login to see your monthly credits here."
        case .nous: "Sign in to Nous Portal in Hermes Agent to see your monthly allowance and balances here."
        case .cline: "Sign in with cline auth to see your ClinePass subscription limits here."
        case .codebuff: "Sign in with codebuff login to see your weekly limits and credit balance here."
        case .copilot: "Sign in to GitHub CLI with gh auth login to see Copilot limits here. Monny needs a CLI version that supports --no-refresh."
        }
    }
}

extension AIQuotaWindow.Kind {
    /// "5-hour window" and "Weekly" in the popover.
    var title: LocalizedStringKey {
        switch self {
        case .session: "5-hour window"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        }
    }

    /// "5 hours" and "Weekly" in the window's tiles and reset list.
    var shortTitle: LocalizedStringKey {
        switch self {
        case .session: "5 hours"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        }
    }
}

extension AIQuotaWindow {
    /// "Claude", or "Claude Opus" for a model's own limit, in notification titles.
    func serviceName(_ tool: AITool) -> String {
        if let ampQuota { return "\(tool.name) · \(String(localized: ampQuota.label))" }
        if let copilotQuota { return "\(tool.name) · \(copilotQuota.name)" }
        return model.map { "\(tool.name) \($0)" } ?? tool.name
    }

    /// "5-hour window", or "Opus only · weekly" for a model's own limit.
    var title: Text { ampQuota.map { Text($0.label) } ?? copilotQuota.map { Text("\(Text($0.label)) · monthly") } ?? model.map { modelTitle($0) } ?? Text(kind.title) }

    /// "5 hours" in the window's tiles and reset list.
    var shortTitle: Text { ampQuota.map { Text($0.label) } ?? copilotQuota.map { Text($0.label) } ?? model.map { modelTitle($0) } ?? Text(kind.shortTitle) }

    private func modelTitle(_ model: String) -> Text {
        switch kind {
        case .session: Text("\(model) only · 5 hours")
        case .weekly: Text("\(model) only · weekly")
        case .monthly: Text("\(model) only · monthly")
        }
    }
}

extension AIUsage {
    /// "Pro" from the service's "pro"; plan names are not translated.
    var planText: Text? {
        guard let plan, !plan.isEmpty else { return nil }
        // "pro" → "Pro", "free_workspace" → "Free Workspace"; names already cased, such as
        // "SuperGrok", stay as they are.
        let name = plan.split(separator: "_").map { $0.contains(where: \.isUppercase) ? String($0) : $0.capitalized }.joined(separator: " ")
        return Text(verbatim: name)
    }

    /// "1 min ago", or "Just now" within the first minute.
    func ageText(at now: Date = .now) -> Text {
        if now.timeIntervalSince(date) < 60 { return Text("Just now") }
        return Text(date.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated)))
    }
}

extension Date {
    /// "13:02" within a day, "Mon 09:00" within a week, "Nov 3" further out.
    var resetClockText: String {
        let seconds = timeIntervalSinceNow
        if seconds < 86_400 { return formatted(.dateTime.hour().minute()) }
        if seconds < 6 * 86_400 { return formatted(.dateTime.weekday(.abbreviated).hour().minute()) }
        return formatted(.dateTime.month(.abbreviated).day())
    }

    /// "in 2 hours", for notifications.
    var resetText: String { formatted(.relative(presentation: .named, unitsStyle: .wide)) }
}

extension AIQuotaWindow {
    /// "Resets in 2 hr 38 min" within a day, "Resets Mon 09:00" further out.
    func resetLine(at now: Date = .now) -> Text? {
        guard let resetsAt else { return nil }
        let seconds = resetsAt.timeIntervalSince(now)
        if isExhausted {
            return seconds < 86_400
                ? Text("Available again in \(Duration.seconds(max(seconds, 60)).estimateText) · \(resetsAt.formatted(.dateTime.hour().minute()))")
                : Text("Available again \(resetsAt.resetClockText)")
        }
        return seconds < 86_400
            ? Text("Resets in \(Duration.seconds(max(seconds, 60)).estimateText)")
            : Text("Resets \(resetsAt.resetClockText)")
    }
}

/// The service's mark on its tile. A hairline keeps the white tiles apart from a white card.
struct AIToolIcon: View {
    let tool: AITool
    var size: CGFloat = 30

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
        Image(tool.logo).resizable().scaledToFit()
            .frame(width: size * (tool == .jetBrains ? 0.9 : 0.6), height: size * (tool == .jetBrains ? 0.9 : 0.6))
            .frame(width: size, height: size)
            .background(tool.iconColor, in: shape)
            .overlay { shape.strokeBorder(Theme.aiIconStroke) }
            .accessibilityHidden(true)
    }
}

/// A 6 pt bar of the quota left with a pace mark at the share of time left in the period.
/// Used up, the track turns red; a stale reading is drawn in gray.
struct QuotaBar: View {
    let window: AIQuotaWindow
    let color: Color
    var isStale = false

    var body: some View {
        let timeLeft = window.timeLeft()
        GeometryReader { proxy in
            Capsule().fill(window.isExhausted ? Theme.statusDangerBg : Theme.fillTrack)
                .overlay(alignment: .leading) {
                    Capsule().fill(isStale ? Theme.textTertiary : color).frame(width: proxy.size.width * window.left)
                }
                .overlay(alignment: .leading) {
                    if let timeLeft, !window.isExhausted, !isStale {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Theme.aiPaceMark)
                            .stroke(Theme.aiPaceMarkStroke, lineWidth: 1)
                            .frame(width: 2, height: 14)
                            .offset(x: min(max(proxy.size.width * timeLeft - 1, 0), proxy.size.width - 2))
                    }
                }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

/// One limit: name and chip, quota left, bar and reset line (popover cards and window tiles).
struct QuotaRow: View {
    let window: AIQuotaWindow
    let tool: AITool
    var isStale = false
    /// The window tiles put the reset time into the label line and drop the line below.
    var isCompact = false

    var body: some View {
        let hasReset = window.hasReset()
        VStack(alignment: .leading, spacing: isCompact ? 5 : 6) {
            HStack(spacing: Theme.spaceM) {
                label
                // The window tiles show the state by the value's color alone, as drawn.
                if tool != .copilot, tool != .amp, !isStale, !isCompact, !hasReset { stateChip }
                Spacer(minLength: Theme.spaceM)
                value(hasReset: hasReset)
            }
            // One height with or without the 18 pt chip, so rows keep their rhythm; the window tiles
            // have no chip and use the 14 pt line drawn there.
            .frame(height: isCompact ? 14 : 18)
            if hasReset {
                Capsule().fill(Theme.fillTrack).frame(height: 6)
            } else {
                QuotaBar(window: window, color: tool.color, isStale: isStale)
            }
            // Copilot's longer labels leave no room for the chip beside them.
            if tool == .copilot || tool == .amp, !isStale, !isCompact, !hasReset { stateChip }
            if !isCompact, tool == .amp, !hasReset, let dollars = dollarsText {
                dollars.font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary).lineLimit(1)
            }
            if !isCompact, let line = footer(hasReset: hasReset) {
                line.font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary).lineLimit(1)
            } else if isCompact, !hasReset, let dollars = dollarsText {
                // Cursor's tile adds the amounts under its one bar (`KPI · Cursor`).
                dollars.font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    .padding(.top, 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue(hasReset: hasReset))
    }

    @ViewBuilder private var stateChip: some View {
        if window.isExhausted {
            Chip(title: "Limit reached", kind: .danger, isSmall: true).fixedSize()
        } else if window.isRunningLow {
            Chip(title: "Running low", kind: .warning, isSmall: true).fixedSize()
        }
    }

    @ViewBuilder private var label: some View {
        if tool == .copilot, !isCompact, let quota = window.copilotQuota {
            ViewThatFits(in: .horizontal) {
                window.title.fixedSize()
                Text(quota.label).fixedSize()
            }
            .font(Theme.footnote.weight(.medium)).foregroundStyle(Theme.textPrimary)
        } else if isCompact, let resetsAt = window.resetsAt, !window.hasReset() {
            Text("\(window.shortTitle) · resets \(resetsAt.resetClockText)")
                .font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary).lineLimit(1)
        } else if !isCompact, tool != .amp, let dollars = dollarsText {
            Text("\(window.title) · \(dollars)")
                .font(Theme.footnote.weight(.medium)).foregroundStyle(Theme.textPrimary).lineLimit(1)
        } else {
            (isCompact ? window.shortTitle : title)
                .font(Theme.footnote.weight(isCompact ? .regular : .medium))
                .foregroundStyle(isCompact ? Theme.textSecondary : Theme.textPrimary)
                .lineLimit(1)
        }
    }

    private var title: Text {
        guard tool == .jetBrains, window.model == nil else { return window.title }
        if !isStale, !window.hasReset(), window.isRunningLow || window.isExhausted { return Text(window.kind.title) }
        return Text("AI credits · monthly")
    }

    @ViewBuilder private func value(hasReset: Bool) -> some View {
        if hasReset {
            UnavailableValue(font: Theme.bodyEmphasized)
        } else {
            Text("\(window.left.percentText) left")
                .font(isCompact ? Theme.bodyEmphasized.weight(.semibold) : Theme.bodyEmphasized.weight(.bold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
        }
    }

    /// "$12.40 of $20 left" for Cursor's included usage.
    private var dollarsText: Text? {
        guard let used = window.dollarsUsed, let limit = window.dollarsLimit else { return nil }
        let currency = FloatingPointFormatStyle<Double>.Currency(code: "USD")
        return Text("\(max(limit - used, 0).formatted(currency)) of \(limit.formatted(currency.precision(.fractionLength(0...2)))) left")
    }

    private var valueColor: Color {
        if isStale { return Theme.textTertiary }
        if window.isExhausted { return Theme.statusDangerText }
        return window.isRunningLow ? Theme.statusWarningText : Theme.textPrimary
    }

    private func footer(hasReset: Bool) -> Text? {
        hasReset ? Text("Window has reset since the last reading") : window.resetLine()
    }

    private func accessibilityValue(hasReset: Bool) -> Text {
        guard !hasReset else { return Text("Window has reset since the last reading") }
        // The chip is part of the value, as VoiceOver does not see its color.
        let left = window.isRunningLow && !isStale
            ? Text("\(Text("Running low")), \(Text("\(window.left.percentText) left"))")
            : Text("\(window.left.percentText) left")
        guard let reset = window.resetLine() else { return left }
        return Text("\(left), \(reset)")
    }
}

/// "No AI tools found" with Hide AI Limits (Sketch `13 · Popover · AI limits · No tools`).
struct NoAIToolsView: View {
    @AppStorage(PreferenceKey.showsAILimits) private var showsAILimits = false

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "asterisk")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 48, height: 48)
                .background(Theme.fillTrack, in: .rect(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
            Text("No AI tools found")
                .font(Theme.bodyEmphasized)
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, Theme.spaceL)
            Text("Monny shows usage limits for supported AI tools set up on this Mac.")
                .font(Theme.footnote.weight(.regular))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
                .padding(.top, 6)
            Button("Hide AI Limits") { showsAILimits = false }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.top, Theme.spaceXL)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// "Credits · 1,250 left" at the end of the Codex card, when the account has credits.
struct CreditsRow: View {
    let credits: Double
    var title: LocalizedStringKey = "Credits"
    var isStale = false

    var body: some View {
        HStack {
            Text(title).font(Theme.footnote.weight(.medium)).foregroundStyle(Theme.textPrimary)
            Spacer(minLength: Theme.spaceM)
            Group {
                if credits.isInfinite {
                    Text("Unlimited")
                } else {
                    Text("\(credits.formatted(.number.precision(.fractionLength(0...2)))) left")
                }
            }
            .font(Theme.bodyEmphasized.weight(.bold))
            .foregroundStyle(isStale ? Theme.textTertiary : Theme.textPrimary)
            .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

extension CopilotQuota {
    var label: LocalizedStringResource {
        switch self {
        case .premium: "Premium requests"
        case .chat: "Chat"
        case .completions: "Code completions"
        }
    }

    var name: String { String(localized: label) }
}

/// Unmetered Copilot data never implies a remaining balance or a percentage ceiling.
struct CopilotDetails: View {
    let usage: AIUsage

    var body: some View {
        ForEach(usage.unlimitedCopilotQuotas ?? [], id: \.self) { quota in
            HStack {
                Text(quota.label)
                Spacer(minLength: Theme.spaceM)
                Text("Unlimited")
            }
            .font(Theme.footnote.weight(.medium))
            .foregroundStyle(usage.isStale() ? Theme.textTertiary : Theme.textPrimary)
            .accessibilityElement(children: .combine)
        }
        if let credits = usage.creditsUsed {
            HStack {
                Text("Credits used")
                Spacer(minLength: Theme.spaceM)
                Text(credits, format: .number.precision(.fractionLength(0...2))).monospacedDigit()
            }
            .font(Theme.footnote.weight(.medium))
            .foregroundStyle(usage.isStale() ? Theme.textTertiary : Theme.textPrimary)
            .accessibilityElement(children: .combine)
        }
        if usage.windows.isEmpty && usage.unlimitedCopilotQuotas?.isEmpty != false {
            Text("GitHub does not report a quota limit for this plan.")
                .font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension AmpQuota {
    var label: LocalizedStringResource {
        switch self {
        case .free: "Free allowance"
        case .agent: "Agent usage"
        case .other: "Other usage"
        case .orb: "Orb usage"
        }
    }
}

/// Balances reported in USD, separate from generic tool credits and subscription windows.
struct AIDollarBalances: View {
    let usage: AIUsage
    @Environment(\.locale) private var locale

    var body: some View {
        if let value = usage.balanceUSD { row("Balance", value: value) }
        if let value = usage.topUpUSD { row("Top-up balance", value: value) }
    }

    private func row(_ title: LocalizedStringKey, value: Decimal) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: Theme.spaceM)
            Text(value, format: .currency(code: "USD").locale(locale)).monospacedDigit()
        }
        .font(Theme.footnote.weight(.medium))
        .foregroundStyle(usage.isStale() ? Theme.textTertiary : Theme.textPrimary)
        .accessibilityElement(children: .combine)
    }
}
