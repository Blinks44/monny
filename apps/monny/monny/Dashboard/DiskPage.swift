import AppKit
import SwiftUI

/// Window Disk (Sketch `04 · Window · Disk`). A category breakdown needs a full scan, which
/// Monny does not do, so the startup volume card shows its used/free split instead.
struct DiskPage: View {
    let sampler: Sampler
    @AppStorage(PreferenceKey.historyRange) private var range = HistoryRange.hour
    @AppStorage(PreferenceKey.temperatureUnit) private var temperatureUnit = TemperatureUnit.celsius

    private var disk: DiskUsage? { sampler.snapshot?.disk }
    private var ssd: SSDHealth? { sampler.ssdHealth }

    var body: some View {
        let tier = sampler.history.tier(range)
        VStack(spacing: Theme.spaceL) {
            HStack(spacing: Theme.spaceL) {
                KPICard(title: "Free", symbol: "internaldrive", color: Theme.metricDisk, value: disk?.free.storageText,
                        detail: disk.map { Text("of \($0.total.storageText) · \($0.usedFraction.percentText) used") }, points: nil)
                KPICard(title: "Read", symbol: "arrow.down", color: Theme.metricNetwork, value: disk?.readRate?.rateText,
                        detail: peak(tier.series(.diskRead)), points: tier.series(.diskRead))
                KPICard(title: "Write", symbol: "arrow.up", color: Theme.metricUpload, value: disk?.writeRate?.rateText,
                        detail: peak(tier.series(.diskWrite)), points: tier.series(.diskWrite))
                KPICard(title: "SSD health", symbol: ssd?.isVerified == false ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                        color: ssd?.isVerified == false ? Theme.statusDanger : Theme.metricBattery,
                        value: ssd?.health.percentText,
                        detail: ssd.map { Text("wear \($0.wear.percentText) · \($0.isVerified ? Text("verified") : Text("failing"))") },
                        points: nil)
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                VolumesCard(volumes: disk?.volumes ?? [])
                StartupVolumeCard(volume: disk?.volumes.first { $0.url.path == "/" }).frame(width: 244)
            }
            HStack(alignment: .top, spacing: Theme.spaceL) {
                ProcessListCard("Top processes by disk activity", columns: ("Read", "Written"),
                                processes: sampler.snapshot?.processes ?? [], color: Theme.metricDisk,
                                value: { $0.diskRead + $0.diskWrite },
                                primary: { $0.diskRead.rateText }, secondary: { $0.diskWrite.rateText })
                SSDHealthCard(health: ssd, temperature: sampler.snapshot?.sensors?.ssd, unit: temperatureUnit)
                    .frame(width: 244)
            }
        }
        .onAppear { sampler.setProcessListVisible(true) }
        .onDisappear { sampler.setProcessListVisible(false) }
    }

    private func peak(_ points: [(date: Date, value: Double)]) -> Text? {
        points.map(\.value).max().map { Text("peak \($0.rateText)") }
    }
}

extension DiskUsage.Volume {
    var symbol: String { isNetwork ? "network" : isInternal ? "internaldrive.fill" : "externaldrive.fill" }
    var color: Color { isNetwork ? Theme.metricCPU : isInternal ? Theme.metricDisk : Theme.metricNetwork }

    /// "APFS · internal".
    var kindText: Text {
        let place = isNetwork ? Text("network") : isInternal ? Text("internal") : Text("external")
        guard let format else { return place }
        return Text("\(format) · \(place)")
    }
}

/// Mounted volumes with free space; a click reveals one in Finder.
private struct VolumesCard: View {
    let volumes: [DiskUsage.Volume]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader("Volumes", subtitle: Text("\(volumes.count) mounted · click a volume to reveal it in Finder"))
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(volumes) { volume in
                        Button { NSWorkspace.shared.activateFileViewerSelecting([volume.url]) } label: {
                            VolumeRow(volume: volume)
                        }
                        .buttonStyle(StaticButtonStyle())
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .dashboardCard(height: 284)
    }
}

private struct VolumeRow: View {
    let volume: DiskUsage.Volume

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: volume.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(volume.color.gradient, in: .rect(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(volume.name).font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary).lineLimit(1)
                    Spacer()
                    Text("\(volume.free.storageText) free of \(volume.total.storageText)")
                        .font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary).monospacedDigit()
                }
                volume.kindText.font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                CapsuleBar(fraction: volume.usedFraction, color: volume.color, height: 8).padding(.top, 4)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// The startup volume's used share as a ring.
private struct StartupVolumeCard: View {
    let volume: DiskUsage.Volume?

    var body: some View {
        VStack(spacing: 0) {
            CardHeader(title: volume.map { Text(verbatim: $0.name) } ?? Text("Startup disk"),
                       subtitle: volume.map { Text("\(($0.total - $0.free).storageText) used") })
            Spacer(minLength: 8)
            RingGauge(fraction: volume?.usedFraction, color: Theme.metricDisk, diameter: 108, lineWidth: 14)
                .overlay {
                    VStack(spacing: 0) {
                        if let volume {
                            Text(volume.usedFraction.percentText).font(Theme.metricL).foregroundStyle(Theme.textPrimary)
                        } else {
                            UnavailableValue(font: Theme.metricL)
                        }
                        Text("used").font(Theme.footnote).foregroundStyle(Theme.textTertiary)
                    }
                }
            Spacer(minLength: 8)
            if let volume {
                VStack(spacing: 6) {
                    legend("Used", (volume.total - volume.free).storageText, Theme.metricDisk)
                    legend("Free", volume.free.storageText, Theme.fillTrack)
                }
            }
        }
        .dashboardCard(height: 284)
    }

    private func legend(_ title: LocalizedStringKey, _ value: String, _ color: Color) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 9, height: 9)
            Text(title).font(Theme.footnote).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).font(Theme.footnote.weight(.semibold)).foregroundStyle(Theme.textPrimary).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

/// NVMe SMART status of the internal SSD; "Failing" when the drive reports a critical warning.
private struct SSDHealthCard: View {
    let health: SSDHealth?
    let temperature: Double?
    let unit: TemperatureUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CardHeader("SSD health").padding(.bottom, 6)
            FactRow(title: "S.M.A.R.T.", value: health.map { $0.isVerified ? Text("Verified") : Text("Failing") },
                    valueColor: health?.isVerified == false ? Theme.statusDangerText : Theme.statusSuccessText, height: 30)
            FactRow(title: "Wear level", value: health.map { Text($0.wear.percentText) }, height: 30)
            FactRow(title: "Data written", value: health.map { Text($0.bytesWritten.storageText) }, height: 30)
            FactRow(title: "Temperature", value: temperature.map { Text($0.temperatureText(unit)) }, isLast: true, height: 30)
        }
        .dashboardCard(height: 176)
    }
}
