import Charts
import SwiftUI

/// "CPU load & temperature" (Sketch `Card · CPU history`): Performance and Efficiency load as
/// areas, CPU temperature as a dashed line, and a tooltip under the pointer. Temperature shares
/// the 0–100 axis, read as °C, so no second axis is needed.
struct CPUHistoryCard: View {
    let tier: HistoryTier
    let range: HistoryRange
    @State private var hovered: Date?
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var performance: [(date: Date, value: Double)] { tier.series(.cpuPerformance) }
    private var efficiency: [(date: Date, value: Double)] { tier.series(.cpuEfficiency) }
    private var temperature: [(date: Date, value: Double)] { tier.series(.cpuTemperature) }
    private var load: [(date: Date, value: Double)] { tier.series(.cpu) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if load.count > 1 {
                chart.padding(.top, Theme.spaceL)
            } else {
                CollectingHistoryContent().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 284)
        .card()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            CardHeader("CPU load & temperature", subtitle: summary)
            HStack(spacing: Theme.spaceL) {
                ChartLegend(title: "Performance", color: Theme.metricCPU)
                ChartLegend(title: "Efficiency", color: Theme.metricCPUEfficiency)
                ChartLegend(title: "Temp", color: Theme.metricHeat)
            }
        }
    }

    /// "Last hour · avg 27% · peak 88% at 10:29".
    private var summary: Text {
        let name = range.periodName
        guard let peak = load.max(by: { $0.value < $1.value }) else { return name }
        let average = load.map(\.value).reduce(0, +) / Double(load.count)
        return Text("\(name) · avg \(average.percentText) · peak \(peak.value.percentText) at \(peak.date.formatted(range.timeFormat))")
    }

    // Vectorized plots: one mark per series instead of one per point, redrawn every sample.
    @ChartContentBuilder private var loadPlots: some ChartContent {
        AreaPlot(PlotPoint.series("P", performance), x: .value("Time", \.date), y: .value("Load", \.value),
                 series: .value("Series", \.series))
            .foregroundStyle(LinearGradient(colors: [Theme.metricCPU.opacity(0.45), Theme.metricCPU.opacity(0.08)],
                                            startPoint: .top, endPoint: .bottom))
            .interpolationMethod(.monotone)
        LinePlot(PlotPoint.series("P", performance), x: .value("Time", \.date), y: .value("Load", \.value),
                 series: .value("Series", \.series))
            .foregroundStyle(Theme.metricCPU)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.monotone)
        AreaPlot(PlotPoint.series("E", efficiency), x: .value("Time", \.date), y: .value("Load", \.value),
                 series: .value("Series", \.series))
            .foregroundStyle(Theme.metricCPUEfficiency.opacity(0.2))
            .interpolationMethod(.monotone)
        LinePlot(PlotPoint.series("E", efficiency), x: .value("Time", \.date), y: .value("Load", \.value),
                 series: .value("Series", \.series))
            .foregroundStyle(Theme.metricCPUEfficiency)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .interpolationMethod(.monotone)
    }

    /// Temperature shares the 0...1 load scale: 100 °C is the top.
    private var temperaturePlot: some ChartContent {
        LinePlot(PlotPoint.series("T", temperature, scale: 0.01), x: .value("Time", \.date), y: .value("Load", \.value),
                 series: .value("Series", \.series))
            .foregroundStyle(LinearGradient(colors: [Theme.metricHeat, Theme.metricHeatHot], startPoint: .leading, endPoint: .trailing))
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4]))
            .interpolationMethod(.monotone)
    }

    private var chart: some View {
        Chart {
            loadPlots
            temperaturePlot
            if let point = hoveredPoint {
                RuleMark(x: .value("Time", point.date))
                    .foregroundStyle(Theme.textTertiary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                PointMark(x: .value("Time", point.date), y: .value("Load", point.value))
                    .symbolSize(70)
                    .foregroundStyle(Theme.metricCPU)
                    .annotation(position: .top, spacing: 8, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        tooltip(for: point.date, load: point.value)
                    }
            }
        }
        // Monotone curves do not overshoot the data, and the plot is clipped like the Sketch frame.
        .chartPlotStyle { $0.clipped() }
        .chartXScale(domain: Date.now.addingTimeInterval(-tier.span)...Date.now)
        .chartYScale(domain: 0...1)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: range.timeFormat)
                    .font(Theme.caption.weight(.regular))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 0.33, 0.66, 1]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 3])).foregroundStyle(Theme.fillSeparator)
                AxisValueLabel {
                    if let fraction = value.as(Double.self) {
                        Text(fraction == 0 ? "0" : fraction.percentText)
                    }
                }
                .font(Theme.caption.weight(.regular))
                .foregroundStyle(Theme.textTertiary)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(.rect)
                    .onContinuousHover { phase in
                        // The pointer is in overlay coordinates; the plot starts after the y axis labels.
                        switch phase {
                        case .active(let location):
                            let plotX = proxy.plotFrame.map { geometry[$0].minX } ?? 0
                            hovered = proxy.value(atX: location.x - plotX, as: Date.self)
                        case .ended: hovered = nil
                        }
                    }
            }
        }
        .animation(reduceMotion ? nil : .default, value: load.count)
        .accessibilityLabel(Text("CPU load & temperature"))
        .accessibilityValue(summary)
    }

    /// The P-core load nearest to the pointer.
    private var hoveredPoint: (date: Date, value: Double)? {
        guard let hovered else { return nil }
        return performance.min { abs($0.date.timeIntervalSince(hovered)) < abs($1.date.timeIntervalSince(hovered)) }
    }

    private func tooltip(for date: Date, load: Double) -> some View {
        let total = self.load.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }?.value
        let celsius = temperature.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }?.value
        return VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: "\(date.formatted(range.timeFormat))  ·  \((total ?? load).percentText)")
            if let celsius { Text(verbatim: celsius.temperatureText(temperatureUnit)) }
        }
        .font(Theme.footnote.weight(.semibold))
        .foregroundStyle(Theme.surfaceOpaque)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.fillTooltip, in: .rect(cornerRadius: Theme.radiusControl, style: .continuous))
    }
}

/// A colored dot and a series name.
struct ChartLegend: View {
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).font(Theme.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
        }
        .lineLimit(1)
        .fixedSize()
    }
}

extension HistoryRange {
    /// "Last hour" for summaries.
    var periodName: Text {
        switch self {
        case .minute: Text("Last minute")
        case .hour: Text("Last hour")
        case .day: Text("Last 24 hours")
        case .week: Text("Last 7 days")
        }
    }

    /// Axis and tooltip times: clock time, with the weekday for the week.
    var timeFormat: Date.FormatStyle {
        switch self {
        case .minute: .dateTime.hour().minute().second()
        case .hour, .day: .dateTime.hour().minute()
        case .week: .dateTime.weekday(.abbreviated).hour()
        }
    }
}
