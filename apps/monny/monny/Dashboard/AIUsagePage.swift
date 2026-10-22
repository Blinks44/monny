import Charts
import SwiftUI

/// Window AI usage (Sketch `19 · Window · AI limits`): a tile per tool, the weekly quota left
/// over the chosen range, the next resets with a pace forecast, and the sources.
struct AIUsagePage: View {
    let monitor: AIUsageMonitor
    let history: History
    @AppStorage(PreferenceKey.aiHistoryRange) private var range = HistoryRange.week

    var body: some View {
        Group {
            if monitor.installed.isEmpty {
                NoAIToolsView().frame(height: 600).card()
            } else {
                // Readings age and windows reset between checks.
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    content(now: context.date)
                }
            }
        }
        .onAppear { monitor.setVisible(.dashboard, true) }
        .onDisappear { monitor.setVisible(.dashboard, false) }
    }

    private func content(now: Date) -> some View {
        let tools = monitor.installed
        return VStack(spacing: Theme.spaceL) {
            // Up to three tiles share a row, as drawn; four make two rows so labels keep their room.
            // Tiles of a row share the tallest one's height.
            let columns = tools.count > 3 ? 2 : max(tools.count, 1)
            Grid(horizontalSpacing: Theme.spaceL, verticalSpacing: Theme.spaceL) {
                ForEach(Array(stride(from: 0, to: tools.count, by: columns)), id: \.self) { start in
                    GridRow {
                        ForEach(tools[start..<min(start + columns, tools.count)], id: \.self) { tool in
                            AIToolTile(tool: tool, state: monitor.states[tool] ?? .init(), now: now)
                        }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: Theme.spaceL) {
                QuotaHistoryCard(tools: tools, tier: history.tier(range == .day ? .day : .week), range: range == .day ? .day : .week)
                NextResetsCard(states: tools.compactMap { tool in monitor.states[tool].map { (tool, $0) } }, now: now)
                    .frame(width: 244)
            }
            SourcesCard(tools: tools, states: monitor.states, now: now)
        }
    }
}

/// `KPI · Claude`: the tool's name in its color and each window with its bar and pace mark.
private struct AIToolTile: View {
    let tool: AITool
    let state: AIUsageMonitor.ToolState
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 6) {
                AIToolIcon(tool: tool, size: 18)
                Text(verbatim: tool.name)
            }
            .font(Theme.label)
            .foregroundStyle(tool == .claude || tool == .cursor ? tool.color : Theme.textPrimary)
            if let usage = state.usage, state.problem?.hidesReading != true {
                // 12 pt between a bar and the next label, as drawn in `KPI · Claude`.
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(usage.windows, id: \.id) { window in
                        QuotaRow(window: window, tool: tool, isStale: usage.isStale(at: now), isCompact: true)
                    }
                }
            } else {
                Text(state.problem == .signedOut ? tool.signInHint
                     : state.problem == .apiKey ? "Signed in with an API key, which has no plan limits." : "Checking…")
                    .font(Theme.footnote.weight(.regular))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.bottom, 14)
        // 116 pt as drawn; model limits add rows below.
        .frame(minHeight: 116, maxHeight: .infinity, alignment: .top)
        .card()
    }
}

/// "Quota left over 7 days": each tool's longest window, which jumps back to 100 % at each reset.
private struct QuotaHistoryCard: View {
    let tools: [AITool]
    let tier: HistoryTier
    let range: HistoryRange

    private var series: [(tool: AITool, points: [(date: Date, value: Double)])] {
        tools.map { ($0, tier.series($0.historyMetric)) }
    }

    var body: some View {
        let series = series
        VStack(alignment: .leading, spacing: Theme.spaceL) {
            CardHeader(range == .day ? "Quota left over 24 hours" : "Quota left over 7 days",
                       subtitle: Text("Weekly or monthly limits · refills at each reset")) {
                HStack(spacing: Theme.spaceL) {
                    ForEach(series.filter { $0.points.count > 1 }, id: \.tool) { item in
                        ChartLegend(title: LocalizedStringKey(item.tool.name), color: item.tool.color)
                    }
                }
            }
            if series.contains(where: { $0.points.count > 1 }) {
                chart(series)
            } else {
                CollectingHistoryContent().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .dashboardCard(height: 284)
    }

    private func chart(_ series: [(tool: AITool, points: [(date: Date, value: Double)])]) -> some View {
        Chart {
            ForEach(series, id: \.tool) { item in
                LinePlot(PlotPoint.series(item.tool.rawValue, item.points), x: .value("Time", \.date), y: .value("Left", \.value),
                         series: .value("Series", \.series))
                    .foregroundStyle(item.tool.color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                ForEach(Self.resets(in: item.points), id: \.self) { date in
                    RuleMark(x: .value("Reset", date), yStart: .value("Left", 0), yEnd: .value("Left", 1))
                        .foregroundStyle(item.tool.color.opacity(0.3))
                        .annotation(position: .top, spacing: 2, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            Text("\(item.tool.name) reset").font(Theme.caption.weight(.regular)).foregroundStyle(item.tool.color)
                        }
                }
            }
        }
        .chartPlotStyle { $0.clipped() }
        .chartXScale(domain: Date.now.addingTimeInterval(-tier.span)...Date.now)
        // Room above 100 % for the reset labels.
        .chartYScale(domain: 0...1.12)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: range == .day ? .dateTime.hour().minute() : .dateTime.weekday(.abbreviated)).font(Theme.caption.weight(.regular)).foregroundStyle(Theme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 0.33, 0.66, 1]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 3])).foregroundStyle(Theme.fillSeparator)
                AxisValueLabel {
                    if let fraction = value.as(Double.self) { Text(fraction == 0 ? "0" : fraction.percentText) }
                }
                .font(Theme.caption.weight(.regular))
                .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.top, Theme.spaceL)
        .accessibilityLabel(Text(range == .day ? "Quota left over 24 hours" : "Quota left over 7 days"))
    }

    /// Where the quota left jumps up: the window reset there.
    static func resets(in points: [(date: Date, value: Double)]) -> [Date] {
        zip(points, points.dropFirst()).compactMap { previous, point in point.value - previous.value > 0.25 ? point.date : nil }
    }
}

/// "Next resets" in local time, then a pace forecast when a window would run out first.
private struct NextResetsCard: View {
    let states: [(tool: AITool, state: AIUsageMonitor.ToolState)]
    let now: Date

    private var rows: [(tool: AITool, window: AIQuotaWindow)] {
        states.flatMap { tool, state -> [(tool: AITool, window: AIQuotaWindow)] in
            guard let usage = state.usage, !usage.isStale(at: now) else { return [] }
            return usage.windows.filter { $0.model == nil && !$0.hasReset(at: now) && $0.resetsAt != nil }.map { (tool, $0) }
        }
        .sorted { ($0.window.resetsAt ?? .distantFuture) < ($1.window.resetsAt ?? .distantFuture) }
        // The card has room for four rows next to the forecast.
        .prefix(4).map(\.self)
    }

    var body: some View {
        let rows = rows
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("Next resets", subtitle: Text("Local time"))
                .padding(.bottom, 6)
            if rows.isEmpty {
                Text("Resets appear after the first reading.")
                    .font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary)
                    .padding(.top, 6)
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text("\(row.tool.name) · \(Text(row.window.kind.shortTitle))").foregroundStyle(Theme.textSecondary)
                    Spacer(minLength: Theme.spaceM)
                    Text(verbatim: row.window.resetsAt?.resetClockText ?? "").font(Theme.body.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary).monospacedDigit()
                }
                .font(Theme.body)
                .frame(height: 28)
                .overlay(alignment: .bottom) {
                    if index < rows.count - 1 { Theme.fillSeparator.frame(height: 1) }
                }
                .accessibilityElement(children: .combine)
            }
            Spacer(minLength: Theme.spaceM)
            if let forecast = forecast(rows) { forecast }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 284, alignment: .top)
        .card()
    }

    /// The window that runs out soonest before its reset at the average pace so far.
    private func forecast(_ rows: [(tool: AITool, window: AIQuotaWindow)]) -> AnyView? {
        let soonest = rows.compactMap { row in row.window.runsOut(at: now).map { (row.tool, row.window, $0) } }
            .min { $0.2 < $1.2 }
        guard let (tool, window, date) = soonest, let resetsAt = window.resetsAt else { return nil }
        let time = date.resetClockText
        let margin = Duration.seconds(resetsAt.timeIntervalSince(date))
            .formatted(.units(allowed: [.days, .hours, .minutes], width: .wide, maximumUnitCount: 1))
        let body = window.kind == .session
            ? Text("At this pace the 5-hour limit runs out around \(time), about \(margin) before it resets. Estimate.")
            : Text("At this pace the weekly limit runs out around \(time), about \(margin) before it resets. Estimate.")
        return AnyView(VStack(alignment: .leading, spacing: 4) {
            Text("\(tool.name) is ahead of pace").font(Theme.footnote.weight(.semibold)).foregroundStyle(Theme.statusWarningText)
                .fixedSize(horizontal: false, vertical: true)
            body.font(Theme.caption.weight(.regular)).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.statusWarningBg, in: .rect(cornerRadius: Theme.radiusControl, style: .continuous))
        .accessibilityElement(children: .combine))
    }
}

/// "Sources": each tool whose sign-in Monny reads, its plan, last reading and connection state.
private struct SourcesCard: View {
    let tools: [AITool]
    let states: [AITool: AIUsageMonitor.ToolState]
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceL) {
            CardHeader("Sources")
            ForEach(tools, id: \.self) { tool in
                let state = states[tool] ?? .init()
                HStack(spacing: Theme.spaceL) {
                    AIToolIcon(tool: tool, size: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: tool.appName).font(Theme.body.weight(.medium)).foregroundStyle(Theme.textPrimary)
                        detail(state).font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: Theme.spaceM)
                    status(state)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func detail(_ state: AIUsageMonitor.ToolState) -> Text {
        guard let usage = state.usage else { return Text("No reading yet") }
        guard let plan = usage.planText else { return usage.ageText(at: now) }
        return Text("\(plan) · \(usage.ageText(at: now))")
    }

    @ViewBuilder private func status(_ state: AIUsageMonitor.ToolState) -> some View {
        switch state.problem {
        case .signedOut: Chip(title: "Signed out", kind: .warning)
        case .apiKey: Chip(title: "API key")
        case .expired: Chip(title: "Sign-in expired", kind: .warning)
        // A rate limit or a network hiccup does not matter while the last reading is fresh.
        case .unavailable where state.usage.map({ !$0.isStale(at: now) }) ?? false:
            Chip(title: "Connected", symbol: "checkmark.circle.fill", kind: .success)
        case .unavailable: Chip(title: "Couldn’t check", kind: .danger)
        case nil:
            if state.usage == nil {
                Chip(title: "Checking…")
            } else {
                Chip(title: "Connected", symbol: "checkmark.circle.fill", kind: .success)
            }
        }
    }
}
