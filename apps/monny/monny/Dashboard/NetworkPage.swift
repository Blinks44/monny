import SwiftUI

/// Window Network (Sketch `05 · Window · Network`). Per-process network and open connections
/// have no public source (SPEC §3), so the process card and the Connections KPI are left out;
/// the week's totals take the bottom row.
struct NetworkPage: View {
    let sampler: Sampler
    @AppStorage(PreferenceKey.historyRange) private var range = HistoryRange.hour
    @State private var info: NetworkInfo?

    private var network: NetworkRates? { sampler.snapshot?.network }

    var body: some View {
        let tier = sampler.history.tier(range)
        let today = transferredToday
        VStack(spacing: Theme.spaceL) {
            HStack(spacing: Theme.spaceL) {
                KPICard(title: "Download", symbol: "arrow.down", color: Theme.metricNetwork, value: network?.download.rateText,
                        detail: peak(tier.series(.download)), points: tier.series(.download))
                KPICard(title: "Upload", symbol: "arrow.up", color: Theme.metricUpload, value: network?.upload.rateText,
                        detail: peak(tier.series(.upload)), points: tier.series(.upload))
                KPICard(title: "Today", symbol: "calendar", color: Theme.metricMemory,
                        value: today.map { Int64($0.down + $0.up).storageText },
                        detail: today.map { Text(verbatim: "↓ \(Int64($0.down).storageText) · ↑ \(Int64($0.up).storageText)") },
                        points: nil)
                KPICard(title: "Signal", symbol: "wifi", color: Theme.metricCPU,
                        value: info?.wifi.map { "\($0.rssi) dBm" },
                        detail: info.map { $0.wifi.map { SignalQuality(rssi: $0.rssi).text } ?? Text("Not on Wi-Fi") },
                        points: nil)
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                ThroughputCard(tier: tier, range: range)
                ConnectionCard(info: info).frame(width: 244)
            }
            WeekCard(week: sampler.history.week)
        }
        .task {
            // Interface details change rarely; read them off the main actor every 10 s while shown.
            while !Task.isCancelled {
                info = await Task.detached(priority: .utility) { NetworkInfo.read() }.value
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    private func peak(_ points: [(date: Date, value: Double)]) -> Text? {
        points.map(\.value).max().map { Text("peak \($0.rateText)") }
    }

    /// Bytes since midnight from the 24 h tier: each 1-minute average rate × 60 s.
    private var transferredToday: (down: Double, up: Double)? {
        let day = sampler.history.day
        let midnight = Calendar.current.startOfDay(for: .now)
        let down = day.series(.download).filter { $0.date >= midnight }
        guard !down.isEmpty else { return nil }
        let up = day.series(.upload).filter { $0.date >= midnight }
        return (down.map(\.value).reduce(0, +) * day.step, up.map(\.value).reduce(0, +) * day.step)
    }
}

/// RSSI bands as macOS's Wi-Fi menu describes them.
struct SignalQuality {
    let rssi: Int

    var text: Text {
        if rssi >= -55 { Text("Excellent") } else if rssi >= -67 { Text("Good") } else if rssi >= -75 { Text("Fair") } else { Text("Weak") }
    }

    var color: Color {
        if rssi >= -67 { Theme.statusSuccessText } else if rssi >= -75 { Theme.statusWarningText } else { Theme.statusDangerText }
    }
}

private struct ThroughputCard: View {
    let tier: HistoryTier
    let range: HistoryRange

    var body: some View {
        let down = tier.series(.download), up = tier.series(.upload)
        let top = max((down + up).map(\.value).max() ?? 1, 1)
        VStack(alignment: .leading, spacing: 12) {
            CardHeader("Throughput", subtitle: summary(down: down, up: up)) {
                HStack(spacing: Theme.spaceL) {
                    ChartLegend(title: "Download", color: Theme.metricNetwork)
                    ChartLegend(title: "Upload", color: Theme.metricUpload)
                }
            }
            if down.count > 1 {
                HistoryChart(series: [.init(id: "down", points: down, color: Theme.metricNetwork, filled: true),
                                      .init(id: "up", points: up, color: Theme.metricUpload)],
                             tier: tier, range: range, yDomain: 0...top * 1.1,
                             yTicks: [0, top / 3, top * 2 / 3, top], format: { $0.rateText })
            } else {
                CollectingHistoryContent().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .dashboardCard(height: 284)
    }

    /// "Last hour · ↓ avg 1.1 MB/s · ↑ avg 180 KB/s".
    private func summary(down: [(date: Date, value: Double)], up: [(date: Date, value: Double)]) -> Text {
        guard !down.isEmpty, !up.isEmpty else { return range.periodName }
        let averageDown = down.map(\.value).reduce(0, +) / Double(down.count)
        let averageUp = up.map(\.value).reduce(0, +) / Double(up.count)
        return Text("\(range.periodName) · ↓ avg \(averageDown.rateText) · ↑ avg \(averageUp.rateText)")
    }
}

/// The primary connection: Wi-Fi details when it is Wi-Fi, then addresses.
private struct ConnectionCard: View {
    let info: NetworkInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CardHeader(info?.isWiFi == false ? "Connection" : "Wi-Fi", subtitle: subtitle)
            Spacer(minLength: 0)
            if let wifi = info?.wifi {
                FactRow(title: "Signal", value: Text("\(wifi.rssi) dBm · \(SignalQuality(rssi: wifi.rssi).text)"),
                        valueColor: SignalQuality(rssi: wifi.rssi).color)
                FactRow(title: "Link rate", value: Text("\(Int(wifi.transmitRate.rounded())) Mb/s"))
            }
            FactRow(title: "Local IP", value: info?.localAddress.map { Text(verbatim: $0) })
            FactRow(title: "Router", value: info?.router.map { Text(verbatim: $0) })
            FactRow(title: "DNS", value: info?.dns.first.map { Text(verbatim: $0) }, isLast: true)
        }
        .dashboardCard(height: 284)
    }

    /// "5 GHz · channel 44 · 802.11ax" or the interface name.
    private var subtitle: Text? {
        guard let info else { return nil }
        guard let wifi = info.wifi else { return info.interface.map { Text(verbatim: $0) } }
        var parts: [String] = []
        if let band = wifi.band { parts.append(band) }
        if let channel = wifi.channel { parts.append(String(localized: "channel \(channel)")) }
        if let phy = wifi.phyMode { parts.append(phy) }
        return Text(verbatim: parts.joined(separator: " · "))
    }
}

/// Daily totals over the last seven days from the 7 d tier (10-minute averages × 600 s).
private struct WeekCard: View {
    let week: HistoryTier

    private var days: [PeriodBars.Bar] {
        let calendar = Calendar.current
        var totals: [Date: Double] = [:]
        for metric in [HistoryMetric.download, .upload] {
            for point in week.series(metric) {
                totals[calendar.startOfDay(for: point.date), default: 0] += point.value * week.step
            }
        }
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
            .map { PeriodBars.Bar(date: $0, value: totals[$0] ?? 0) }
    }

    var body: some View {
        let days = days
        let total = days.map(\.value).reduce(0, +)
        VStack(alignment: .leading, spacing: 10) {
            CardHeader("This week", subtitle: total > 0 ? Text("\(Int64(total).storageText) total") : Text("Collecting history…"))
            PeriodBars(bars: days, unit: .day, color: Theme.metricNetwork, label: .dateTime.weekday(.abbreviated))
        }
        .dashboardCard(height: 176)
    }
}
