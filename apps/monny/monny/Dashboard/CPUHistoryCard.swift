import Charts
import SwiftUI

/// The CPU history card shared by Overview and CPU.
struct CPUHistoryCard: View {
    let tier: HistoryTier
    let range: HistoryRange
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius
    @Environment(\.locale) private var locale

    var body: some View {
        let end = Date.now
        let domain = end.addingTimeInterval(-tier.span)...end
        let load = series(.cpu, label: "CPU", color: Theme.metricCPU, domain: domain)
        let summary = summary(load.points)
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                CardHeader("CPU load & temperature", subtitle: summary)
                HStack(spacing: Theme.spaceL) {
                    ChartLegend(title: "Performance", color: Theme.metricCPU)
                    ChartLegend(title: "Efficiency", color: Theme.metricCPUEfficiency)
                    ChartLegend(title: "Temp", color: Theme.metricHeat)
                }
            }
            if load.points.count > 1 {
                CPUHistoryPlot(
                    range: range, domain: domain, step: tier.step, summary: summary, temperatureUnit: temperatureUnit,
                    load: load,
                    performance: series(.cpuPerformance, label: "Performance", color: Theme.metricCPU, domain: domain),
                    efficiency: series(.cpuEfficiency, label: "Efficiency", color: Theme.metricCPUEfficiency, domain: domain),
                    temperature: series(.cpuTemperature, label: "Temp", color: Theme.metricHeat, domain: domain)
                )
                .padding(.top, Theme.spaceL)
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

    private func series(
        _ metric: HistoryMetric, label: LocalizedStringKey, color: Color, domain: ClosedRange<Date>
    ) -> HistoryChart.Series {
        let points = tier.series(metric)
        let series = HistoryChart.Series(
            id: metric.rawValue, points: range == .week ? points.filter { domain.contains($0.date) } : points,
            color: color, label: label)
        return range == .week ? series.averagingByHour(step: tier.step, in: domain) : series
    }

    /// Keep the summary peak at the stored bucket resolution, even when the plot is rolled up.
    private func summary(_ points: [(date: Date, value: Double)]) -> Text {
        let name = range.historyPlotPeriodName
        guard let peak = points.max(by: { $0.value < $1.value }) else { return name }
        let average = points.map(\.value).reduce(0, +) / Double(points.count)
        return Text(
            "\(name) · avg \(average.percentText) · peak \(peak.value.percentText) at \(peak.date.formatted(range.timeFormat.locale(locale)))"
        )
    }
}

/// Hover state stays in the plot, so changing it does not rebuild the hourly buckets.
private struct CPUHistoryPlot: View {
    let range: HistoryRange
    let domain: ClosedRange<Date>
    let step: TimeInterval
    let summary: Text
    let temperatureUnit: TemperatureUnit
    let load: HistoryChart.Series
    let performance: HistoryChart.Series
    let efficiency: HistoryChart.Series
    let temperature: HistoryChart.Series
    @State private var hovered: Date?

    private var weekly: Bool { range == .week }

    var body: some View {
        let temperaturePoints = temperature.plotPoints(step: step, scale: 0.01)
        let upper = max(1, ((temperaturePoints.map(\.value).max() ?? 1) * 5).rounded(.up) / 5)
        let loadTicks: [Double] = weekly ? [0, 0.25, 0.5, 0.75, 1] : [0, 0.33, 0.66, 1]
        Chart {
            loadPlot(performance, width: weekly ? 1.65 : 2.5, fillOpacity: 0.45)
            loadPlot(efficiency, width: 1.5, fillOpacity: 0.2)
            LinePlot(
                temperaturePoints, x: .value("Time", \.date), y: .value("Temperature", \.value),
                series: .value("Series", \.series)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Theme.metricHeat, weekly ? Theme.metricHeat : Theme.metricHeatHot], startPoint: .leading, endPoint: .trailing)
            )
            .lineStyle(StrokeStyle(lineWidth: weekly ? 1.5 : 2, lineCap: .round, dash: [4, 4]))
            .interpolationMethod(range.chartInterpolation)
            if weekly {
                PointPlot(PlotPoint.isolated(in: temperaturePoints), x: .value("Time", \.date), y: .value("Temperature", \.value))
                    .foregroundStyle(Theme.metricHeat)
                    .symbolSize(16)
            }
            if let hovered {
                if weekly {
                    hourlySelection(at: hovered)
                } else if let point = performance.points.min(by: {
                    abs($0.date.timeIntervalSince(hovered)) < abs($1.date.timeIntervalSince(hovered))
                }) {
                    RuleMark(x: .value("Time", point.date))
                        .foregroundStyle(Theme.textTertiary.opacity(0.6))
                    PointMark(x: .value("Time", point.date), y: .value("Load", point.value))
                        .symbolSize(70)
                        .foregroundStyle(Theme.metricCPU)
                        .annotation(position: .top, spacing: 8, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            sampleTooltip(at: point.date, performance: point.value)
                        }
                }
            }
        }
        .chartPlotStyle { $0.clipped() }
        .chartXScale(domain: domain)
        .chartYScale(domain: 0...upper)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: range.axisTimeFormat)
                    .font(Theme.caption.weight(.regular))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: loadTicks) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 3])).foregroundStyle(Theme.fillSeparator)
                AxisValueLabel {
                    if let fraction = value.as(Double.self) {
                        Text(weekly || fraction > 0 ? fraction.percentText : "0")
                    }
                }
                .font(Theme.caption.weight(.regular))
                .foregroundStyle(Theme.textTertiary)
            }
            if weekly, !temperaturePoints.isEmpty {
                AxisMarks(position: .trailing, values: upper > 1 ? [0.25, 0.5, 0.75, 1, upper] : [0.25, 0.5, 0.75, 1]) { value in
                    AxisValueLabel {
                        if let fraction = value.as(Double.self) {
                            Text(verbatim: (fraction * 100).temperatureText(temperatureUnit))
                        }
                    }
                    .font(Theme.caption.weight(.regular))
                    .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(.rect)
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            guard let anchor = proxy.plotFrame, geometry[anchor].contains(location) else {
                                hovered = nil
                                return
                            }
                            hovered = proxy.value(atX: location.x - geometry[anchor].minX, as: Date.self)
                        case .ended: hovered = nil
                        }
                    }
            }
        }
        .onChange(of: range) { hovered = nil }
        .accessibilityLabel(Text("CPU load & temperature"))
        .accessibilityValue(summary)
    }

    @ChartContentBuilder
    private func loadPlot(_ series: HistoryChart.Series, width: CGFloat, fillOpacity: Double) -> some ChartContent {
        let points = series.plotPoints(step: step)
        if !weekly {
            AreaPlot(points, x: .value("Time", \.date), y: .value("Load", \.value), series: .value("Series", \.series))
                .foregroundStyle(
                    LinearGradient(
                        colors: [series.color.opacity(fillOpacity), series.color.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                )
                .interpolationMethod(range.chartInterpolation)
        }
        LinePlot(points, x: .value("Time", \.date), y: .value("Load", \.value), series: .value("Series", \.series))
            .foregroundStyle(series.color)
            .lineStyle(StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            .interpolationMethod(range.chartInterpolation)
        if weekly {
            PointPlot(PlotPoint.isolated(in: points), x: .value("Time", \.date), y: .value("Load", \.value))
                .foregroundStyle(series.color)
                .symbolSize(16)
        }
    }

    @ChartContentBuilder
    private func hourlySelection(at date: Date) -> some ChartContent {
        let loads = [load, performance, efficiency].compactMap { $0.hourlyRow(at: date, format: { $0.percentText }) }
        let heat = temperature.hourlyRow(at: date, format: { $0.temperatureText(temperatureUnit) })
        let rows = loads + [heat].compactMap(\.self)
        if let selected = rows.first(where: { $0.id != load.id }) ?? rows.first {
            if selected.id != load.id {
                let plotValue = selected.id == temperature.id ? selected.hour.average / 100 : selected.hour.average
                PointMark(x: .value("Time", selected.hour.date), y: .value("Value", plotValue))
                    .symbolSize(40)
                    .foregroundStyle(selected.color)
            }
            RuleMark(x: .value("Time", selected.hour.date))
                .foregroundStyle(Theme.textTertiary.opacity(0.6))
                .annotation(position: .top, spacing: 8, overflowResolution: .init(x: .fit(to: .plot), y: .fit(to: .plot))) {
                    HourlyHistoryTooltip(rows: rows)
                }
        }
    }

    private func sampleTooltip(at date: Date, performance: Double) -> some View {
        let total = load.points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }?.value
        let celsius = temperature.points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }?.value
        return VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: "\(date.formatted(range.timeFormat))  ·  \((total ?? performance).percentText)")
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
    var wraps = false

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).font(Theme.footnote.weight(.semibold)).foregroundStyle(Theme.textSecondary)
        }
        .lineLimit(wraps ? nil : 1)
        .fixedSize(horizontal: !wraps, vertical: true)
    }
}

extension HistoryRange {
    var historyPlotPeriodName: Text { self == .week ? Text("Last 7 days · hourly averages") : periodName }

    /// "Last hour" for summaries.
    var periodName: Text {
        switch self {
        case .minute: Text("Last minute")
        case .hour: Text("Last hour")
        case .day: Text("Last 24 hours")
        case .week: Text("Last 7 days")
        }
    }

    /// Weekly ticks identify days; the time of day belongs in the sample tooltip.
    var axisTimeFormat: Date.FormatStyle {
        self == .week ? .dateTime.weekday(.abbreviated) : timeFormat
    }

    var chartInterpolation: InterpolationMethod { self == .week ? .linear : .monotone }

    /// Sample times in summaries and tooltips.
    var timeFormat: Date.FormatStyle {
        switch self {
        case .minute: .dateTime.hour().minute().second()
        case .hour, .day: .dateTime.hour().minute()
        case .week: .dateTime.weekday(.abbreviated).hour().minute()
        }
    }
}
