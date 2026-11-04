import AppKit
import SwiftUI

/// Search, sorting and visible grouped process rows from one shared sampler snapshot. A PID,
/// port or local URL in the search field switches to `ProcessLookupList`.
struct ProcessList: View {
    let processes: [ProcessUsage]
    var busy = BusyProcesses()
    var networkAvailable: Bool? = nil
    @Binding var sort: ProcessSort
    @Binding var query: String
    var refresh: () -> Void = { }
    @State private var confirmation: ProcessTerminationRequest?
    @State private var failure: ProcessActionFailure?
    @State private var isEnding = false
    @State private var terminator = ProcessTerminator()

    var body: some View {
        let lookup = ProcessQuery(query)
        VStack(spacing: 10) {
            HStack(spacing: Theme.spaceM) {
                ProcessSearchField(query: $query)
                if case .name = lookup {
                    PopupPicker(title: "Sort by", selection: $sort, options: [
                        (.cpu, Text("CPU")), (.memory, Text("Memory")), (.energy, Text("Energy")), (.network, Text("Network")),
                    ])
                }
            }
            if case .name(let name) = lookup {
                let attention = name.isEmpty ? busy.attention(in: processes, now: .now) : []
                if !attention.isEmpty {
                    NeedsAttentionCard(items: attention, isEnding: isEnding,
                                       quit: { request(for: $0).map { end($0, force: false) } },
                                       forceQuit: { confirmation = request(for: $0) },
                                       show: { query = String($0) })
                }
                if sort == .network, networkAvailable == false {
                    Text("Process network usage is unavailable.")
                        .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                }
                list(limit: (attention.isEmpty ? 9 : 8 - attention.count) - (sort == .network && networkAvailable == false ? 1 : 0))
            } else {
                ProcessLookupList(query: lookup, processes: processes, refresh: refresh, show: { query = String($0) })
            }
        }
        .alert(LocalizedStringResource("Force quit “\(confirmation?.target.name ?? "")”?"), item: $confirmation) { request in
            Button("Cancel", role: .cancel) { }
            Button("Force Quit", role: .destructive) { end(request, force: true) }
        } message: { _ in
            Text("Unsaved changes will be lost.")
        }
        .alert(LocalizedStringResource("Couldn’t quit “\(failure?.name ?? "")”"), item: $failure) { _ in
            Button("OK", role: .cancel) { }
        } message: { failure in
            Text(failure.reason.message)
        }
    }

    /// A Needs attention row ends only its own process, never the app it is grouped under.
    private func request(for process: ProcessUsage) -> ProcessTerminationRequest? {
        var single = process
        single.app = nil
        return ProcessTerminationRequest(row: single, processes: [])
    }

    private func list(limit: Int) -> some View {
        Group {
            let rows = sort.rows(in: processes, matching: query, limit: limit)
            let top = rows.first.map(value(of:)) ?? 0
            VStack(spacing: 0) {
                if rows.isEmpty {
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Collecting data…")
                            .font(Theme.body).foregroundStyle(Theme.textTertiary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 8) {
                            Text("No processes match “\(query.trimmingCharacters(in: .whitespacesAndNewlines))”")
                                .font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary)
                                .lineLimit(3)
                            Text("Monny lists apps and processes running under your account.")
                                .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, process in
                        if index > 0 { Theme.fillSeparator.frame(height: 1).padding(.leading, 42) }
                        ProcessRow(process: process, value: valueText(of: process), detail: detail(of: process),
                                   share: top > 0 ? value(of: process) / top : nil, color: color,
                                   secondaryValue: sort == .network ? process.network.map { "↑ " + $0.upload.rateText } ?? "—" : nil)
                            .contentShape(.rect)
                            .contextMenu {
                                if let request = ProcessTerminationRequest(row: process, processes: processes) {
                                    Button("Quit") { end(request, force: false) }
                                    .disabled(isEnding)
                                    Button(LocalizedStringResource("process.forceQuit.menu", defaultValue: "Force Quit…")) {
                                        confirmation = request
                                    }
                                        .disabled(isEnding)
                                }
                            }
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .card()
        }
    }

    private func end(_ request: ProcessTerminationRequest, force: Bool) {
        guard !isEnding else { return }
        isEnding = true
        Task {
            do {
                try await terminator.terminate(request, force: force)
            } catch {
                failure = ProcessActionFailure(name: request.target.name,
                                               reason: error as? ProcessTerminationFailure ?? .denied)
            }
            refresh()
            isEnding = false
        }
    }

    private var color: Color {
        switch sort {
        case .cpu: Theme.metricCPU
        case .memory: Theme.metricMemory
        case .network: Theme.metricNetwork
        case .energy: Theme.metricBattery
        }
    }

    private func value(of process: ProcessUsage) -> Double {
        switch sort {
        case .cpu: process.cpu
        case .memory: Double(process.memory)
        case .network: process.network.map { $0.download + $0.upload } ?? 0
        case .energy: process.power
        }
    }

    private func valueText(of process: ProcessUsage) -> String {
        switch sort {
        case .cpu: process.cpu.formatted(.percent.precision(.fractionLength(1)))
        case .memory: process.memory.memoryText
        case .network: process.network.map { "↓ " + $0.download.rateText } ?? "—"
        // Energy is the kernel's estimate, so it is marked as approximate.
        case .energy: "≈ " + Measurement(value: process.power, unit: UnitPower.watts)
            .formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(1))))
        }
    }

    /// The second line: memory (or CPU when sorted by memory), then how many processes an app
    /// sums or that a process belongs to no app.
    private func detail(of process: ProcessUsage) -> String {
        let first = sort == .memory ? process.cpu.formatted(.percent.precision(.fractionLength(1))) : process.memory.memoryText
        if process.app == nil { return "\(first) · " + String(localized: "system", comment: "A process that belongs to no app") }
        guard process.count > 1 else { return first }
        return "\(first) · " + String(localized: "\(process.count) processes")
    }
}

struct ProcessActionFailure {
    let name: String
    let reason: ProcessTerminationFailure
}

/// App icon, name and detail line, then the sorted value with its share of the top row.
private struct ProcessRow: View {
    let process: ProcessUsage
    let value: String
    let detail: String
    let share: Double?
    let color: Color
    var secondaryValue: String? = nil

    var body: some View {
        let app = NSRunningApplication(processIdentifier: process.id)
        HStack(spacing: Theme.spaceL) {
            Group {
                if let icon = app?.icon {
                    Image(nsImage: icon).resizable()
                } else {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(Theme.fillTrack, in: .rect(cornerRadius: 8, style: .continuous))
                }
            }
            .frame(width: 30, height: 30)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(app?.localizedName ?? process.name)
                    .font(Theme.bodyEmphasized)
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(Theme.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
            }
            .lineLimit(1)
            Spacer(minLength: Theme.spaceM)
            VStack(alignment: .trailing, spacing: 6) {
                Text(value).font(Theme.bodyEmphasized.weight(.bold)).foregroundStyle(Theme.textPrimary).monospacedDigit()
                    .accessibilityLabel(secondaryValue == nil ? Text(verbatim: value) : Text("Download") + Text(verbatim: ": " + value))
                if let secondaryValue {
                    Text(secondaryValue).font(Theme.footnote).foregroundStyle(Theme.textSecondary).monospacedDigit()
                        .accessibilityLabel(Text("Upload") + Text(verbatim: ": " + secondaryValue))
                } else {
                    CapsuleBar(fraction: share, color: color, height: 4)
                        .frame(width: 50)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(height: 47)
        .accessibilityElement(children: .combine)
    }
}
