import AppKit
import SwiftUI

/// Popover Processes: the top processes by CPU, memory or energy. Read-only.
struct ProcessesTab: View {
    let sampler: Sampler
    private var processes: [ProcessUsage]? { sampler.snapshot?.processes }
    private enum Sort: Hashable { case cpu, memory, energy }
    @State private var sort = Sort.cpu

    private var rows: [ProcessUsage] {
        let sorted: [ProcessUsage] = switch sort {
        case .cpu: (processes ?? []).sorted { $0.cpu > $1.cpu }
        case .memory: (processes ?? []).sorted { $0.memory > $1.memory }
        case .energy: (processes ?? []).sorted { $0.power > $1.power }
        }
        return Array(sorted.prefix(10))
    }

    var body: some View {
        VStack(spacing: Theme.spaceM) {
            Picker("Sort by", selection: $sort) {
                Text("CPU").tag(Sort.cpu)
                Text("Memory").tag(Sort.memory)
                Text("Energy").tag(Sort.energy)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            VStack(spacing: 0) {
                if rows.isEmpty {
                    Text("No readings yet")
                        .font(Theme.body)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(rows) { process in
                        ProcessRow(process: process, value: value(for: process))
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .card()

            HStack {
                if sort == .energy {
                    Text("Energy is an estimate").font(Theme.caption).foregroundStyle(Theme.textTertiary)
                }
                Spacer()
                Button("Open Activity Monitor") {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
                        NSWorkspace.shared.openApplication(at: url, configuration: .init())
                    }
                }
                .buttonStyle(PlainLinkButtonStyle())
            }
        }
        .onAppear { sampler.showsProcesses = true }
        .onDisappear { sampler.showsProcesses = false }
    }

    private func value(for process: ProcessUsage) -> String {
        switch sort {
        case .cpu: process.cpu.formatted(.percent.precision(.fractionLength(1)))
        case .memory: process.memory.memoryText
        case .energy: Measurement(value: process.power, unit: UnitPower.watts)
            .formatted(.measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(1))))
        }
    }
}

/// App icon and name (the app's own name for apps), then the sorted value.
private struct ProcessRow: View {
    let process: ProcessUsage
    let value: String

    var body: some View {
        let app = NSRunningApplication(processIdentifier: process.id)
        HStack(spacing: 10) {
            Group {
                if let icon = app?.icon {
                    Image(nsImage: icon).resizable()
                } else {
                    Image(systemName: "gearshape.fill").foregroundStyle(Theme.textTertiary)
                }
            }
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
            Text(app?.localizedName ?? process.name)
                .font(Theme.body)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: Theme.spaceM)
            Text(value).font(Theme.bodyEmphasized).foregroundStyle(Theme.textPrimary).monospacedDigit()
        }
        .padding(.horizontal, 14)
        .frame(height: 34)
        .accessibilityElement(children: .combine)
    }
}
