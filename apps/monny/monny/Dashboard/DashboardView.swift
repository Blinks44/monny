import SwiftUI

/// The dashboard window (Sketch `02 · Window`): inset sidebar and the selected page.
struct DashboardView: View {
    @Bindable var model: AppModel
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(selection: $model.dashboardPage)
                .frame(width: 232)
            VStack(alignment: .leading, spacing: 0) {
                PageHeader(page: model.dashboardPage, collapse: collapse)
                ScrollView {
                    page.padding(.bottom, Theme.space3XL)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(.horizontal, Theme.space3XL)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 900, minHeight: 620)
        .background(Theme.surfaceOpaque)
        .ignoresSafeArea(.container, edges: .top)
        // An empty unified toolbar gives the window the tall titlebar of a sidebar app, so macOS
        // places the window buttons inside the sidebar panel.
        .toolbar {
            ToolbarItem(placement: .navigation) { Color.clear.frame(width: 1, height: 1) }
                .sharedBackgroundVisibility(.hidden)
        }
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .onAppear { model.sampler.setVisible(.dashboard, true) }
        .onDisappear { model.sampler.setVisible(.dashboard, false) }
    }

    @ViewBuilder private var page: some View {
        switch model.dashboardPage {
        case .overview: OverviewPage(snapshot: model.sampler.snapshot)
        case .battery where !SystemInfo.hasBattery:
            NoBatteryView(openSensors: { model.dashboardPage = .sensors })
                .frame(maxWidth: .infinity)
                .frame(height: 600)
                .card()
        case .settings: SettingsPage()
        default: CollectingHistoryCard()
        }
    }

    /// Back to the compact view: close the window and show the popover.
    private func collapse() {
        dismissWindow(id: DashboardWindow.id)
        model.showPopover()
    }
}

/// Page title, machine summary, time range and the collapse button.
private struct PageHeader: View {
    let page: DashboardPage
    let collapse: () -> Void
    @AppStorage(PreferenceKey.historyRange) private var range = HistoryRange.hour

    var body: some View {
        HStack(alignment: .center, spacing: Theme.spaceL) {
            VStack(alignment: .leading, spacing: 2) {
                Text(page.title).font(Theme.title).foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                subtitle.font(Theme.label.weight(.regular)).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: Theme.spaceXL)
            if page.showsTimeRange {
                Picker("Time range", selection: $range) {
                    Text("1m").tag(HistoryRange.minute)
                    Text("1h").tag(HistoryRange.hour)
                    Text("24h").tag(HistoryRange.day)
                    Text("7d").tag(HistoryRange.week)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 192)
            }
            IconButton(symbol: "arrow.down.right.and.arrow.up.left", label: "Show in the menu bar", action: collapse)
        }
        .padding(.top, 44)
        .padding(.bottom, Theme.spaceL)
    }

    private var subtitle: Text {
        if page == .settings {
            return Text("Version \(Bundle.main.shortVersion) (\(Bundle.main.buildNumber))")
        }
        let memory = SystemInfo.physicalMemory.formatted(.byteCount(style: .memory))
        return Text(verbatim: "\(SystemInfo.chipName) · \(memory) · macOS \(SystemInfo.osVersion)")
    }
}

extension DashboardPage {
    var title: LocalizedStringKey {
        switch self {
        case .overview: "Overview"
        case .cpu: "CPU"
        case .memory: "Memory"
        case .disk: "Disk"
        case .network: "Network"
        case .battery: "Battery"
        case .sensors: "Sensors"
        case .settings: "Settings"
        }
    }
}

extension Bundle {
    var shortVersion: String { object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "" }
    var buildNumber: String { object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "" }
}
