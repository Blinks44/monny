/// Turns monotonically increasing byte counters into per-second rates.
nonisolated struct RateCounter {
    private var previous: (values: [UInt64], time: ContinuousClock.Instant)?

    /// `nil` on the first call, or when a counter went backwards (an interface or disk was reset).
    mutating func rates(for values: [UInt64], at time: ContinuousClock.Instant = .now) -> [Double]? {
        defer { previous = (values, time) }
        guard let previous, previous.values.count == values.count else { return nil }
        let seconds = Double((time - previous.time).components.seconds)
            + Double((time - previous.time).components.attoseconds) / 1e18
        guard seconds > 0 else { return nil }
        var rates: [Double] = []
        for (old, new) in zip(previous.values, values) {
            guard new >= old else { return nil }
            rates.append(Double(new - old) / seconds)
        }
        return rates
    }
}
