import Charts
import SwiftUI

/// Sketch window frame 24: quiet history with one bounded, named sample tooltip.
struct AIQuotaHistoryChart: View {
    let series: [AIQuotaHistory.Series]
    let range: HistoryRange
    let domain: ClosedRange<Date>
    @State private var selection: AIQuotaHistory.Selection?
    @State private var tooltipSize = CGSize(width: 176, height: 66)
    @FocusState private var isFocused: Bool
    @Environment(\.locale) private var locale

    private var selected: AIQuotaHistory.Selection? {
        guard let point = AIQuotaHistory.resolved(selection, in: series), domain.contains(point.date) else { return nil }
        return point
    }

    private var selectableSeries: [AIQuotaHistory.Series] {
        series.map { .init(tool: $0.tool, metric: $0.metric, points: $0.points.filter { domain.contains($0.date) }) }
    }

    var body: some View {
        Chart {
            ForEach(series) { item in
                if item.points.count == 1, let point = item.points.first {
                    PointMark(x: .value("Time", point.date), y: .value("Left", point.value))
                        .foregroundStyle(item.tool.color)
                } else {
                    LinePlot(
                        PlotPoint.series(item.tool.rawValue, item.points), x: .value("Time", \.date), y: .value("Left", \.value),
                        series: .value("Series", \.series)
                    )
                    .foregroundStyle(item.tool.color)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
            if let selected, domain.contains(selected.date) {
                RuleMark(x: .value("Time", selected.date))
                    .foregroundStyle(Theme.textTertiary.opacity(0.5))
                PointMark(x: .value("Time", selected.date), y: .value("Left", selected.value))
                    .foregroundStyle(selected.tool.color)
                    .symbolSize(28)
            }
        }
        .chartPlotStyle { $0.clipped() }
        .chartXScale(domain: domain)
        .chartYScale(domain: 0...1)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: range == .day ? .dateTime.hour().minute() : .dateTime.weekday(.abbreviated))
                    .font(Theme.caption.weight(.regular)).foregroundStyle(Theme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 0.33, 0.66, 1]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 3])).foregroundStyle(Theme.fillSeparator)
                AxisValueLabel {
                    if let fraction = value.as(Double.self) { Text(fraction == 0 ? "0" : fraction.percentText) }
                }
                .font(Theme.caption.weight(.regular)).foregroundStyle(Theme.textTertiary)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let anchor = proxy.plotFrame {
                    let plot = geometry[anchor]
                    Rectangle().fill(.clear).contentShape(.rect)
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                selection = AIQuotaHistory.nearest(
                                    in: series, to: CGPoint(x: location.x - plot.minX, y: location.y - plot.minY),
                                    size: plot.size, domain: domain, current: selection)
                            case .ended: selection = nil
                            }
                        }
                    if let selected, domain.contains(selected.date),
                        let x = proxy.position(forX: selected.date), let y = proxy.position(forY: selected.value)
                    {
                        tooltip(selected)
                            .frame(width: min(176, max(0, plot.width - 24)), alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .onGeometryChange(for: CGSize.self) {
                                $0.size
                            } action: {
                                tooltipSize = $0
                            }
                            .position(
                                AIQuotaHistory.tooltipCenter(
                                    point: CGPoint(x: plot.minX + x, y: plot.minY + y), size: tooltipSize, plot: plot)
                            )
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .focusable()
        .focused($isFocused)
        .onChange(of: isFocused) { _, focused in
            if focused { move() } else { selection = nil }
        }
        .onChange(of: range) { selection = nil }
        .onMoveCommand { direction in
            switch direction {
            case .left: move(time: -1)
            case .right: move(time: 1)
            case .up: move(service: -1)
            case .down: move(service: 1)
            @unknown default: break
            }
        }
        .onKeyPress(.escape) {
            selection = nil
            return .handled
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(range == .day ? "Quota left over 24 hours" : "Quota left over 7 days"))
        .accessibilityValue(accessibleValue)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(time: 1)
            case .decrement: move(time: -1)
            @unknown default: break
            }
        }
        .accessibilityAction(named: Text("Next service")) { move(service: 1) }
        .accessibilityAction(named: Text("Previous service")) { move(service: -1) }
    }

    private func move(time: Int = 0, service: Int = 0) {
        selection = AIQuotaHistory.moved(selected, in: selectableSeries, time: time, service: service)
    }

    private func title(_ point: AIQuotaHistory.Selection) -> Text {
        if let period = series.first(where: { $0.tool == point.tool && $0.metric == point.metric })?.period {
            Text("\(point.tool.name) · \(Text(period.shortTitle))")
        } else {
            Text(verbatim: point.tool.name)
        }
    }

    private func tooltip(_ point: AIQuotaHistory.Selection) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            title(point).fontWeight(.semibold)
            Text(point.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
            Text("\(point.value.formatted(.percent.precision(.fractionLength(0)).locale(locale))) left")
        }
        .font(Theme.footnote.weight(.regular))
        .foregroundStyle(Theme.surfaceOpaque)
        .padding(.horizontal, 10).padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fillTooltip, in: .rect(cornerRadius: Theme.radiusControl, style: .continuous))
    }

    private var accessibleValue: Text {
        if let point = selected ?? AIQuotaHistory.moved(nil, in: selectableSeries) {
            title(point) + Text(" ")
                + Text(point.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                + Text(" ") + Text("\(point.value.formatted(.percent.precision(.fractionLength(0)).locale(locale))) left")
        } else {
            Text("Collecting data…")
        }
    }
}
