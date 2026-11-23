import Foundation

/// A display-only summary of consecutive stored readings within an hour.
nonisolated struct HistoryHour {
    let hour: Range<Date>
    let coverage: Range<Date>
    let segment: Int
    let average: Double
    let peak: Double

    var date: Date { coverage.lowerBound.addingTimeInterval(coverage.upperBound.timeIntervalSince(coverage.lowerBound) / 2) }

    /// Align hours to the same clock as the stored ten-minute buckets. Split them at missing readings.
    static func summarize(
        _ series: [(date: Date, value: Double)], step: TimeInterval, in domain: ClosedRange<Date>
    ) -> [HistoryHour] {
        let samples = series.filter { domain.lowerBound <= $0.date && $0.date < domain.upperBound }
        var hours: [HistoryHour] = []
        var start = 0
        var segment = 0
        while start < samples.count {
            let first = samples[start].date
            let hourStart = Date(timeIntervalSinceReferenceDate: (first.timeIntervalSinceReferenceDate / 3_600).rounded(.down) * 3_600)
            let hourEnd = hourStart.addingTimeInterval(3_600)
            if start > 0, first.timeIntervalSince(samples[start - 1].date) > step { segment += 1 }

            var end = start + 1
            var sum = samples[start].value
            var peak = sum
            while end < samples.count, samples[end].date < hourEnd,
                samples[end].date.timeIntervalSince(samples[end - 1].date) <= step
            {
                sum += samples[end].value
                peak = max(peak, samples[end].value)
                end += 1
            }
            let coverageEnd = min(hourEnd, domain.upperBound, samples[end - 1].date.addingTimeInterval(step))
            hours.append(
                HistoryHour(
                    hour: hourStart..<hourEnd, coverage: first..<coverageEnd, segment: segment,
                    average: sum / Double(end - start), peak: peak))
            start = end
        }
        return hours
    }
}
