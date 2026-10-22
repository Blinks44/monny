import SwiftUI

/// Popover AI: one card per tool with its plan windows (Sketch `11 · Popover · AI limits`,
/// `12 · States`, `13 · No tools`). The cards scroll so the popover keeps its height.
struct AILimitsTab: View {
    let monitor: AIUsageMonitor

    var body: some View {
        Group {
            if monitor.installed.isEmpty {
                NoAIToolsView()
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(monitor.installed, id: \.self) { tool in
                            AIToolCard(tool: tool, state: monitor.states[tool] ?? .init())
                        }
                        Text("The mark shows how much time is left in each period. A bar shorter than its mark runs out before the reset.")
                            .font(Theme.caption.weight(.regular))
                            .foregroundStyle(Theme.textTertiary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.automatic)
                // Card shadows reach past the scroll edges.
                .padding(.horizontal, -Theme.spaceXL)
                .contentMargins(.horizontal, Theme.spaceXL, for: .scrollContent)
            }
        }
    }
}

/// A tool's card: icon, name, plan and age, then its windows or why there are none.
private struct AIToolCard: View {
    let tool: AITool
    let state: AIUsageMonitor.ToolState

    var body: some View {
        // Relative times ("12 min ago", "Resets in 2 hr") move on without a new reading.
        TimelineView(.periodic(from: .now, by: 60)) { context in
            VStack(alignment: .leading, spacing: 0) {
                header(now: context.date)
                Theme.fillSeparator.frame(height: 1).padding(.vertical, 12)
                content(now: context.date)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
    }

    private func header(now: Date) -> some View {
        HStack(spacing: Theme.spaceL) {
            AIToolIcon(tool: tool)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: tool.name).font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary)
                subtitle.font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary).lineLimit(1)
            }
            Spacer(minLength: Theme.spaceM)
            if let usage = state.usage, state.problem?.hidesReading != true {
                usage.ageText(at: now)
                    .font(Theme.footnote.weight(.regular))
                    .foregroundStyle(usage.isStale(at: now) ? Theme.statusWarningText : Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: Text {
        if state.problem == .signedOut { return Text("Signed out") }
        if state.problem == .apiKey { return Text("\(tool.appName) · API key") }
        guard let plan = state.usage?.planText else { return Text(verbatim: tool.appName) }
        return Text("\(tool.appName) · \(plan)")
    }

    @ViewBuilder private func content(now: Date) -> some View {
        if state.problem == .signedOut {
            message(tool.signInHint)
        } else if state.problem == .apiKey {
            message("Signed in with an API key. API keys are billed per use and have no plan limits.")
        } else if let usage = state.usage {
            let isStale = usage.isStale(at: now)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(usage.windows, id: \.id) { window in
                    QuotaRow(window: window, tool: tool, isStale: isStale)
                }
                if let credits = usage.credits { CreditsRow(credits: credits, isStale: isStale) }
                if isStale { staleNote(usage) }
            }
        } else {
            switch state.problem {
            case .expired: message("The sign-in has expired. Use \(tool.appName) once to renew it.")
            case .unavailable: message("Couldn’t check the limits. Monny tries again in a few minutes.")
            case .signedOut, .apiKey, nil: message("Checking…")
            }
        }
    }

    /// "Last reading Sat 14:02 · use Codex to refresh".
    private func staleNote(_ usage: AIUsage) -> some View {
        let date = usage.date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
        let note = state.problem == .expired
            ? Text("Last reading \(date) · use \(tool.appName) to refresh")
            : Text("Last reading \(date) · Monny keeps trying")
        return note.font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary)
    }

    private func message(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(Theme.footnote.weight(.regular))
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
