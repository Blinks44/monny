import CoreGraphics
import Foundation

/// Selection uses stored buckets, never interpolated quota or an inferred reset event.
nonisolated enum AIQuotaHistory {
    struct Series: Identifiable {
        let tool: AITool
        let metric: HistoryMetric
        let points: [(date: Date, value: Double)]
        var id: AITool { tool }

        var period: AIQuotaWindow.Kind? {
            switch metric {
            case .claudeSession, .codexSession, .clineSession, .kimiSession, .openCodeSession,
                .alibabaTokenSession, .alibabaCodingSession:
                .session
            case .claudeWeekly, .codexWeekly, .clineWeekly, .codebuffWeekly, .kimiWeekly,
                .openCodeWeekly, .alibabaTokenWeekly, .alibabaCodingWeekly, .windsurfWeekly:
                .weekly
            case .cursorMonthly, .jetBrainsMonthly, .copilotPremium, .clineMonthly, .ampMonthly,
                .augmentMonthly, .nousMonthly, .kimiMonthly, .openCodeMonthly, .kiloMonthly,
                .kiroMonthly, .alibabaTokenMonthly, .alibabaCodingMonthly:
                .monthly
            default: nil
            }
        }
    }

    struct Selection: Equatable {
        let tool: AITool
        let metric: HistoryMetric
        let date: Date
        let value: Double
    }

    static func nearest(
        in series: [Series], to location: CGPoint, size: CGSize, domain: ClosedRange<Date>, current: Selection?
    ) -> Selection? {
        guard size.width > 0, size.height > 0,
            CGRect(origin: .zero, size: size).contains(location), domain.upperBound > domain.lowerBound
        else { return nil }
        let span = domain.upperBound.timeIntervalSince(domain.lowerBound)
        var best: Selection?
        var distance = Double.infinity
        for item in series {
            for point in item.points where domain.contains(point.date) && point.value.isFinite {
                let dx = point.date.timeIntervalSince(domain.lowerBound) / span * size.width - location.x
                let dy = (1 - point.value) * size.height - location.y
                let candidate = dx * dx + dy * dy
                if candidate < distance || (candidate == distance && item.tool == current?.tool) {
                    distance = candidate
                    best = Selection(tool: item.tool, metric: item.metric, date: point.date, value: point.value)
                }
            }
        }
        return best
    }

    static func resolved(_ selection: Selection?, in series: [Series]) -> Selection? {
        guard let selection,
            let item = series.first(where: { $0.tool == selection.tool && $0.metric == selection.metric }),
            let point = item.points.first(where: { $0.date == selection.date })
        else { return nil }
        return Selection(tool: item.tool, metric: item.metric, date: point.date, value: point.value)
    }

    /// Left/right move in recorded time; up/down change services at the closest recorded time.
    static func moved(_ current: Selection?, in series: [Series], time: Int = 0, service: Int = 0) -> Selection? {
        let available = series.filter { !$0.points.isEmpty }
        guard !available.isEmpty else { return nil }
        let current = resolved(current, in: available)
        let index = available.firstIndex { $0.tool == current?.tool } ?? 0
        let next = min(max(index + service, 0), available.count - 1)
        let item = available[next]
        let pointIndex: Int
        if let current {
            pointIndex =
                item.points.indices.min {
                    abs(item.points[$0].date.timeIntervalSince(current.date)) < abs(item.points[$1].date.timeIntervalSince(current.date))
                } ?? 0
        } else {
            pointIndex = item.points.count - 1
        }
        let point = item.points[min(max(pointIndex + (current == nil ? 0 : time), 0), item.points.count - 1)]
        return Selection(tool: item.tool, metric: item.metric, date: point.date, value: point.value)
    }

    /// Prefer above/right; flip near edges, keeping the tooltip inside the plot.
    static func tooltipCenter(point: CGPoint, size: CGSize, plot: CGRect) -> CGPoint {
        let inset: CGFloat = 12
        let x =
            point.x + inset + size.width <= plot.maxX - inset
            ? point.x + inset + size.width / 2 : point.x - inset - size.width / 2
        let y =
            point.y - inset - size.height >= plot.minY + inset
            ? point.y - inset - size.height / 2 : point.y + inset + size.height / 2
        return CGPoint(
            x: min(max(x, plot.minX + inset + size.width / 2), plot.maxX - inset - size.width / 2),
            y: min(max(y, plot.minY + inset + size.height / 2), plot.maxY - inset - size.height / 2)
        )
    }
}
