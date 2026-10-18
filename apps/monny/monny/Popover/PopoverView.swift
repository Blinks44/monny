import SwiftUI

/// The menu bar popover (Sketch `01 · Popover`): header, tabs, the selected tab and the footer.
struct PopoverView: View {
    @Bindable var model: AppModel
    @AppStorage(PreferenceKey.refreshInterval) private var refreshInterval = 2

    var body: some View {
        VStack(spacing: 0) {
            header
            Picker("Section", selection: $model.popoverTab) {
                Text("Overview").tag(PopoverTab.overview)
                Text("Battery").tag(PopoverTab.battery)
                Text("Processes").tag(PopoverTab.processes)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, Theme.spaceXL)
            .padding(.bottom, Theme.spaceL)

            Group {
                switch model.popoverTab {
                case .overview: OverviewTab()
                case .battery: BatteryTab(openSensors: { model.openDashboard(.sensors) })
                case .processes: ProcessesTab()
                }
            }
            .padding(.horizontal, Theme.spaceXL)
            // One height for every tab, so the popover does not jump when switching.
            .frame(height: 484, alignment: .top)

            footer
        }
        .frame(width: 360)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: "Monny").font(Theme.headline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    Text("\(SystemInfo.shortChipName) · up \(SystemInfo.uptimeText(ProcessInfo.processInfo.systemUptime))")
                        .font(Theme.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            IconButton(symbol: "macwindow", label: "Open Dashboard") { model.openDashboard(nil) }
            IconButton(symbol: "gearshape", label: "Settings") { model.openDashboard(.settings) }
        }
        .padding(.horizontal, Theme.spaceXL)
        .padding(.top, Theme.spaceXL)
        .padding(.bottom, Theme.spaceL)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Theme.fillSeparator.frame(height: 1).padding(.horizontal, Theme.spaceXL)
            HStack(spacing: 6) {
                Button("Open Dashboard") { model.openDashboard(nil) }
                    .buttonStyle(PlainLinkButtonStyle())
                Text(verbatim: "⌥⌘M").font(Theme.footnote).foregroundStyle(Theme.textTertiary)
                    .accessibilityLabel(Text("Shortcut Option Command M"))
                Spacer(minLength: 0)
                Text("Updated every \(Duration.seconds(refreshInterval).formatted(.units(width: .narrow)))")
                    .font(Theme.footnote)
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 22)
            .frame(height: 36)
        }
        .padding(.top, Theme.spaceM)
    }
}
