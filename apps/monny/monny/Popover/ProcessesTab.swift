import SwiftUI

/// Owns process-list visibility and the popover's current search and sort choices.
struct ProcessesTab: View {
    let sampler: Sampler
    @State private var sort = ProcessSort.cpu
    @State private var query = ""

    var body: some View {
        ProcessList(processes: sampler.snapshot?.processes ?? [], busy: sampler.busyProcesses, sort: $sort, query: $query,
                    refresh: { sampler.refreshProcesses() })
            .onAppear { sampler.setProcessListVisible(true) }
            .onDisappear { sampler.setProcessListVisible(false) }
    }
}
