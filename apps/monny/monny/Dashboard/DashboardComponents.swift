import AppKit
import Charts
import SwiftUI

/// Card title, optional subtitle and a trailing accessory, as on every window card.
struct CardHeader<Trailing: View>: View {
    let title: Text
    var subtitle: Text?
    @ViewBuilder var trailing: Trailing

    init(_ title: LocalizedStringKey, subtitle: Text? = nil, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.init(title: Text(title), subtitle: subtitle, trailing: trailing)
    }

    /// For a name that is not translated, such as a volume's.
    init(title: Text, subtitle: Text? = nil, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                title.font(Theme.headline).foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                subtitle?.font(Theme.footnote.weight(.regular)).foregroundStyle(Theme.textSecondary).lineLimit(2)
            }
            Spacer(minLength: Theme.spaceL)
            trailing
        }
    }
}

extension View {
    /// The window card frame: 18 pt sides, 16 pt top, fixed height (Sketch rows are 284 and 176 pt).
    func dashboardCard(height: CGFloat) -> some View {
        padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: height, alignment: .top)
            .card()
    }
}

/// A label and a value with a hairline below (`Details` cards and battery facts).
struct FactRow: View {
    let title: LocalizedStringKey
    let value: Text?
    var valueColor = Theme.textPrimary
    var isLast = false
    /// 32 pt in the battery facts; 30 pt in the 176 pt `Details` cards, where four rows must fit.
    var height: CGFloat = 32

    var body: some View {
        HStack {
            Text(title).foregroundStyle(Theme.textSecondary)
            Spacer(minLength: Theme.spaceM)
            if let value {
                value.font(Theme.body.weight(.medium)).foregroundStyle(valueColor).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.8)
            } else {
                UnavailableValue(font: Theme.body)
            }
        }
        .font(Theme.body)
        .frame(height: height)
        .overlay(alignment: .bottom) {
            if !isLast { Theme.fillSeparator.frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
    }
}

/// The four leading processes with a bar for the sorted value and two value columns
/// (`Card · Processes` on Overview, CPU, Memory and Disk).
struct ProcessListCard: View {
    struct Row: Identifiable {
        let process: ProcessUsage
        /// The bar: the sorted value relative to the first row.
        let share: Double?
        let primary: String
        let secondary: String
        var id: pid_t { process.id }
    }

    let title: LocalizedStringKey
    let columns: (primary: LocalizedStringKey, secondary: LocalizedStringKey)
    let rows: [Row]
    let color: Color

    /// Sorts by `value` and keeps the top four.
    init(_ title: LocalizedStringKey, columns: (LocalizedStringKey, LocalizedStringKey), processes: [ProcessUsage],
         color: Color, value: (ProcessUsage) -> Double, primary: (ProcessUsage) -> String, secondary: (ProcessUsage) -> String) {
        self.title = title
        self.columns = columns
        self.color = color
        let top = processes.sorted { value($0) > value($1) }.prefix(4)
        let peak = top.first.map(value) ?? 0
        rows = top.map { Row(process: $0, share: peak > 0 ? value($0) / peak : nil, primary: primary($0), secondary: secondary($0)) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader(title) {
                HStack(spacing: 0) {
                    Text(columns.primary).frame(width: 70, alignment: .trailing)
                    Text(columns.secondary).frame(width: 80, alignment: .trailing)
                }
                .font(Theme.caption)
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 3)
            }
            .padding(.bottom, 10)
            if rows.isEmpty {
                Text("No readings yet").font(Theme.body).foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(rows) { ProcessListRow(row: $0, color: color) }
            }
        }
        .dashboardCard(height: 176)
    }
}

private struct ProcessListRow: View {
    let row: ProcessListCard.Row
    let color: Color

    var body: some View {
        let app = NSRunningApplication(processIdentifier: row.process.id)
        HStack(spacing: 10) {
            Group {
                if let icon = app?.icon {
                    Image(nsImage: icon).resizable()
                } else {
                    Image(systemName: "gearshape.fill").font(.system(size: 11)).foregroundStyle(Theme.textTertiary)
                        .frame(width: 24, height: 24)
                        .background(Theme.fillTrack, in: .rect(cornerRadius: 7, style: .continuous))
                }
            }
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
            Text(app?.localizedName ?? row.process.name)
                .font(Theme.body.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            CapsuleBar(fraction: row.share, color: color, height: 6)
                .frame(width: 130)
                .accessibilityHidden(true)
            Text(row.primary)
                .font(Theme.bodyEmphasized.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 70, alignment: .trailing)
            Text(row.secondary)
                .font(Theme.label.weight(.regular))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 80, alignment: .trailing)
        }
        .lineLimit(1)
        .monospacedDigit()
        .frame(height: 32)
        .accessibilityElement(children: .combine)
    }
}

/// A line chart of history series with time and value axes and a tooltip under the pointer
/// (Network throughput, Sensors temperatures, Memory pressure).
struct HistoryChart: View {
    struct Series: Identifiable {
        let id: String
        let points: [(date: Date, value: Double)]
        let color: Color
        var filled = false
    }

    let series: [Series]
    let tier: HistoryTier
    let range: HistoryRange
    let yDomain: ClosedRange<Double>
    let yTicks: [Double]
    let format: (Double) -> String
    /// Colored horizontal zones behind the lines, such as pressure levels.
    var bands: [(range: ClosedRange<Double>, color: Color)] = []
    var showsAxes = true
    @State private var hovered: Date?

    var body: some View {
        Chart {
            ForEach(Array(bands.enumerated()), id: \.offset) { _, band in
                RectangleMark(yStart: .value("From", band.range.lowerBound), yEnd: .value("To", band.range.upperBound))
                    .foregroundStyle(band.color)
            }
            ForEach(series) { series in
                ForEach(Array(series.points.enumerated()), id: \.offset) { _, point in
                    if series.filled {
                        AreaMark(x: .value("Time", point.date), y: .value("Value", point.value), series: .value("Series", series.id))
                            .foregroundStyle(LinearGradient(colors: [series.color.opacity(0.3), series.color.opacity(0.02)],
                                                            startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.monotone)
                    }
                    LineMark(x: .value("Time", point.date), y: .value("Value", point.value), series: .value("Series", series.id))
                        .foregroundStyle(series.color)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                }
            }
            if let hovered {
                RuleMark(x: .value("Time", hovered))
                    .foregroundStyle(Theme.textTertiary.opacity(0.6))
                    .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                        tooltip(at: hovered)
                    }
            }
        }
        .chartPlotStyle { $0.clipped() }
        .chartXScale(domain: Date.now.addingTimeInterval(-tier.span)...Date.now)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            if showsAxes {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisValueLabel(format: range.timeFormat).font(Theme.caption.weight(.regular)).foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .chartYAxis {
            if showsAxes {
                AxisMarks(position: .leading, values: yTicks) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 3])).foregroundStyle(Theme.fillSeparator)
                    AxisValueLabel { if let number = value.as(Double.self) { Text(verbatim: format(number)) } }
                        .font(Theme.caption.weight(.regular))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .chartOverlay { proxy in
            Rectangle().fill(.clear).contentShape(.rect)
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location): hovered = proxy.value(atX: location.x, as: Date.self)
                    case .ended: hovered = nil
                    }
                }
        }
    }

    private func tooltip(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: date.formatted(range.timeFormat))
            ForEach(series) { series in
                if let nearest = series.points.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                    HStack(spacing: 5) {
                        Circle().fill(series.color).frame(width: 6, height: 6)
                        Text(verbatim: format(nearest.value))
                    }
                }
            }
        }
        .font(Theme.footnote.weight(.semibold))
        .foregroundStyle(Theme.surfaceOpaque)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.fillTooltip, in: .rect(cornerRadius: Theme.radiusControl, style: .continuous))
    }
}

/// A horizontal bar per day or hour (Network "This week").
struct PeriodBars: View {
    struct Bar: Identifiable {
        let date: Date
        let value: Double
        var id: Date { date }
    }

    let bars: [Bar]
    let unit: Calendar.Component
    let color: Color
    let label: Date.FormatStyle

    var body: some View {
        Chart(bars) { bar in
            BarMark(x: .value("Day", bar.date, unit: unit), y: .value("Value", bar.value), width: .ratio(0.6))
                .clipShape(.rect(cornerRadius: 6, style: .continuous))
                .foregroundStyle(Calendar.current.isDateInToday(bar.date) ? color : color.opacity(0.3))
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: unit)) { _ in
                AxisValueLabel(format: label, centered: true).font(Theme.caption).foregroundStyle(Theme.textTertiary)
            }
        }
    }
}
