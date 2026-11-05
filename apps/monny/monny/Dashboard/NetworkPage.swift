import SwiftUI

/// Shared system throughput, grouped process rates and recorded daily traffic.
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
                KPICard(
                    title: "Download", symbol: "arrow.down", color: Theme.metricNetwork, value: network?.download.rateText,
                    detail: peak(tier.series(.download)), points: tier.series(.download))
                KPICard(
                    title: "Upload", symbol: "arrow.up", color: Theme.metricUpload, value: network?.upload.rateText,
                    detail: peak(tier.series(.upload)), points: tier.series(.upload))
                KPICard(
                    title: "Today", symbol: "calendar", color: Theme.metricMemory,
                    value: today.map { Int64($0.down + $0.up).storageText },
                    detail: today.map { Text(verbatim: "↓ \(Int64($0.down).storageText) · ↑ \(Int64($0.up).storageText)") },
                    points: nil)
                KPICard(
                    title: "Signal", symbol: "wifi", color: Theme.metricCPU,
                    value: info?.wifi.map { "\($0.rssi) dBm" },
                    detail: info.map { $0.wifi.map { SignalQuality(rssi: $0.rssi).text } ?? Text("Not on Wi-Fi") },
                    points: nil)
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                ThroughputCard(tier: tier, range: range)
                ConnectionCard(info: info).frame(width: 244)
            }
            if sampler.snapshot?.processNetworkAvailable == false {
                Text("Process network usage is unavailable.")
                    .font(Theme.body).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ProcessListCard(
                "Top processes by network", columns: ("Download", "Upload"),
                processes: ProcessSort.network.rows(in: sampler.snapshot?.processes ?? [], matching: "", limit: 4),
                color: Theme.metricNetwork, value: { $0.network.map { $0.download + $0.upload } ?? -1 },
                primary: { $0.network?.download.rateText ?? "—" },
                secondary: { $0.network?.upload.rateText ?? "—" })
            WeekCard(week: sampler.history.week)
        }
        .onAppear {
            sampler.setProcessListVisible(true)
            sampler.setNetworkProcessListVisible(true)
        }
        .onDisappear {
            sampler.setProcessListVisible(false)
            sampler.setNetworkProcessListVisible(false)
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
        // "signal.fair": the thermal state's "Fair" is a different word in other languages.
        if rssi >= -55 {
            Text("Excellent")
        } else if rssi >= -67 {
            Text("Good")
        } else if rssi >= -75 {
            Text("signal.fair")
        } else {
            Text("Weak")
        }
    }

    var color: Color {
        if rssi >= -67 { Theme.statusSuccessText } else if rssi >= -75 { Theme.statusWarningText } else { Theme.statusDangerText }
    }
}

private struct ThroughputCard: View {
    let tier: HistoryTier
    let range: HistoryRange

    var body: some View {
        let down = tier.series(.download)
        let up = tier.series(.upload)
        let top = max((down + up).map(\.value).max() ?? 1, 1)
        VStack(alignment: .leading, spacing: 12) {
            CardHeader("Throughput", subtitle: summary(down: down, up: up)) {
                HStack(spacing: Theme.spaceL) {
                    ChartLegend(title: "Download", color: Theme.metricNetwork)
                    ChartLegend(title: "Upload", color: Theme.metricUpload)
                }
            }
            if down.count > 1 {
                HistoryChart(
                    series: [
                        .init(id: "down", points: down, color: Theme.metricNetwork, filled: true),
                        .init(id: "up", points: up, color: Theme.metricUpload),
                    ],
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
                .padding(.bottom, 6)
            if let wifi = info?.wifi {
                FactRow(
                    title: "Signal", value: Text("\(wifi.rssi) dBm · \(SignalQuality(rssi: wifi.rssi).text)"),
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

/// Daily estimates from recorded 10-minute history buckets; unobserved days stay unavailable.
struct WeekCard: View {
    let week: HistoryTier
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        let days = DailyTraffic.days(in: week, calendar: calendar)
        let peak = days.compactMap(\.total).max() ?? 0
        VStack(alignment: .leading, spacing: 8) {
            CardHeader("Last 7 days", subtitle: Text("Estimated traffic recorded while Monny is running."))
            Grid(alignment: .trailing, horizontalSpacing: 16, verticalSpacing: 0) {
                GridRow {
                    Text("Day").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Download")
                    Text("Upload")
                    Text("Total")
                }
                .font(Theme.caption).foregroundStyle(Theme.textSecondary)
                .padding(.vertical, 8)
                ForEach(days) { day in
                    GridRow {
                        HStack(spacing: 12) {
                            Text(day.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(locale))
                                .frame(minWidth: 96, alignment: .leading)
                            CapsuleBar(fraction: day.total.map { peak > 0 ? $0 / peak : 0 }, color: Theme.metricNetwork, height: 6)
                                .frame(maxWidth: .infinity)
                                .accessibilityHidden(true)
                        }
                        Text(day.download.map { Int64($0).storageText } ?? "—")
                        Text(day.upload.map { Int64($0).storageText } ?? "—")
                        Text(day.total.map { "≈ " + Int64($0).storageText } ?? "—")
                            .font(Theme.bodyEmphasized)
                    }
                    .font(Theme.body).foregroundStyle(Theme.textPrimary).monospacedDigit()
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(day.date, format: .dateTime.weekday(.wide).day().month(.wide).locale(locale)))
                    .accessibilityValue(
                        Text(
                            "Download: \(day.download.map { Int64($0).storageText } ?? "—"); upload: \(day.upload.map { Int64($0).storageText } ?? "—"); total: \(day.total.map { Int64($0).storageText } ?? "—")"
                        ))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
