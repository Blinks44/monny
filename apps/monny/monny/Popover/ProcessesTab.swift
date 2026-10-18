import AppKit
import SwiftUI

/// Popover Processes: top processes by the chosen resource. Read-only; the list arrives with
/// the sampler (CORE-001).
struct ProcessesTab: View {
    private enum Sort: Hashable { case cpu, memory, energy, network }
    @State private var sort = Sort.cpu

    var body: some View {
        VStack(spacing: Theme.spaceM) {
            Picker("Sort by", selection: $sort) {
                Text("CPU").tag(Sort.cpu)
                Text("Memory").tag(Sort.memory)
                Text("Energy").tag(Sort.energy)
                Text("Network").tag(Sort.network)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text("No readings yet")
                .font(Theme.body)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .card()

            HStack {
                Spacer()
                Button("Open Activity Monitor") {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
                        NSWorkspace.shared.openApplication(at: url, configuration: .init())
                    }
                }
                .buttonStyle(PlainLinkButtonStyle())
            }
        }
    }
}
