import SwiftUI

/// Owns process-list visibility and the popover's current search and sort choices.
struct ProcessesTab: View {
    let sampler: Sampler
    @State private var sort = ProcessSort.cpu
    @State private var query = ""

    private var showsNetworkList: Bool {
        guard sort == .network else { return false }
        if case .name = ProcessQuery(query) { return true }
        return false
    }

    var body: some View {
        ProcessList(processes: sampler.snapshot?.processes ?? [], busy: sampler.busyProcesses, networkAvailable: sampler.snapshot?.processNetworkAvailable, sort: $sort, query: $query,
                    refresh: { sampler.refreshProcesses() })
            .onAppear {
                sampler.setProcessListVisible(true)
                if showsNetworkList { sampler.setNetworkProcessListVisible(true) }
            }
            .onDisappear {
                sampler.setProcessListVisible(false)
                if showsNetworkList { sampler.setNetworkProcessListVisible(false) }
            }
            .onChange(of: showsNetworkList) { _, isVisible in
                sampler.setNetworkProcessListVisible(isVisible)
            }
    }
}
