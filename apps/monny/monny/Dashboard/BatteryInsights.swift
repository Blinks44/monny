import SwiftUI

struct ChargingDiagnosisCard: View {
    let battery: BatteryReading
    let limit: Int?

    var body: some View {
        let diagnosis = ChargingDiagnosis(battery: battery, limit: limit)
        VStack(alignment: .leading, spacing: 8) {
            Text(battery.isUpdatingPower ? String(localized: "Updating power readings…") : diagnosis.title).font(Theme.headline)
                .accessibilityAddTraits(.isHeader)
            HStack {
                if let watts = battery.adapterWatts { Text("Adapter \(watts) W") }
                if let watts = battery.batteryPower {
                    Text("Battery \(watts.formatted(.number.precision(.fractionLength(0)).sign(strategy: .always()))) W")
                }
            }.font(Theme.body)
            Text(
                battery.isUpdatingPower
                    ? String(localized: "Waiting for fresh battery power data after the connection changed.") : diagnosis.explanation
            ).font(Theme.body).foregroundStyle(Theme.textSecondary)
            Link("Open Battery Settings…", destination: MacOSChargingGuidance.settingsURL).buttonStyle(PlainLinkButtonStyle())
                .padding(.top, 8)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(20).frame(maxWidth: .infinity, alignment: .leading).card()
    }
}

struct SleepBatteryCard: View {
    let history: SleepBatteryHistory
    @State private var showsRecent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last sleep").font(Theme.headline).accessibilityAddTraits(.isHeader)
            if history.recorder.isWaiting {
                Text("Updating sleep report…")
                Text("Waiting for the battery level to update before comparing readings.").foregroundStyle(Theme.textSecondary)
            } else if let report = history.reports.first {
                reportSummary(report)
            } else {
                Text("No sleep report yet")
                Text("Keep Monny running. A report appears after the next recorded sleep and wake.").foregroundStyle(Theme.textSecondary)
            }
            if !history.reports.isEmpty {
                DisclosureGroup("Recent sleep intervals", isExpanded: $showsRecent) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(history.reports) { report in
                            Divider()
                            reportSummary(report)
                        }
                    }.padding(.top, 8)
                }
            }
        }
        .font(Theme.body).fixedSize(horizontal: false, vertical: true)
        .padding(20).frame(maxWidth: .infinity, alignment: .leading).card()
    }

    private func reportSummary(_ report: SleepBatteryReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let points = report.pointsUsed {
                    if points == 0 { Text("No charge change") } else { Text("\(points) percentage points used") }
                } else if report.mayIncludeCharging && report.before != nil && report.after != nil {
                    Text("May include charging")
                } else {
                    Text("Sleep report unavailable")
                }
                Text(
                    Duration.seconds(report.end.timeIntervalSince(report.start)),
                    format: .units(allowed: [.hours, .minutes], width: .abbreviated))
            }.font(Theme.body)
            Text(
                report.start.formatted(.dateTime.month(.abbreviated).day().hour().minute()) + " → "
                    + report.end.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
            Text("Battery \(report.before?.percentText ?? "—") → \(report.after?.percentText ?? "—")")
            Text("Battery change between recorded sleep and wake. The cause is unknown.")
        }.foregroundStyle(Theme.textSecondary).accessibilityElement(children: .combine)
    }
}
