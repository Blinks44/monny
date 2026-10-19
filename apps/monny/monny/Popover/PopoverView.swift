import KeyboardShortcuts
import SwiftUI

/// The menu bar popover (Sketch `01 · Popover`): header, tabs, the selected tab and the footer.
struct PopoverView: View {
    @Bindable var model: AppModel
    @AppStorage(PreferenceKey.refreshInterval) private var refreshInterval = 2

    var body: some View {
        VStack(spacing: 0) {
            header
            SegmentedControl(title: "Section", selection: $model.popoverTab, options: [
                (.overview, "Overview"), (.battery, "Battery"), (.processes, "Processes"),
            ])
            .padding(.horizontal, Theme.spaceXL)
            .padding(.bottom, Theme.spaceL)

            Group {
                switch model.popoverTab {
                case .overview: OverviewTab(snapshot: model.sampler.snapshot, history: model.sampler.history)
                case .battery: BatteryTab(battery: model.sampler.snapshot?.battery, health: model.sampler.batteryHealth,
                                           temperature: model.sampler.snapshot?.sensors?.battery,
                                          helper: model.batteryHelper,
                                          openSensors: { model.openDashboard(.sensors) })
                case .processes: ProcessesTab(sampler: model.sampler)
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
                if let shortcut = KeyboardShortcuts.Name.openDashboard.shortcut?.description {
                    Text(verbatim: shortcut).font(Theme.footnote).foregroundStyle(Theme.textTertiary)
                        .accessibilityLabel(Text("Shortcut \(shortcut)"))
                }
                Spacer(minLength: 0)
                if model.popoverTab == .processes {
                    Button("Activity Monitor \(Image(systemName: "arrow.up.right"))", action: openActivityMonitor)
                        .buttonStyle(PlainLinkButtonStyle())
                } else {
                    Text("Updated every \(Duration.seconds(refreshInterval).formatted(.units(width: .narrow)))")
                        .font(Theme.footnote)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 22)
            .frame(height: 36)
        }
        .padding(.top, Theme.spaceM)
    }

    private func openActivityMonitor() {
        model.closePopover()
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }
}
