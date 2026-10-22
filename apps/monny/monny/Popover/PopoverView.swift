import KeyboardShortcuts
import SwiftUI

/// The menu bar popover (Sketch `01 · Popover`): header, tabs, the selected tab and the footer.
struct PopoverView: View {
    @Bindable var model: AppModel
    @AppStorage(PreferenceKey.refreshInterval) private var refreshInterval = 2
    @AppStorage(PreferenceKey.showsAILimits) private var showsAILimits = false
    /// The tabs take focus when the popover opens, so the arrow keys switch them right away.
    @FocusState private var tabsFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            SegmentedControl(title: "Section", selection: $model.popoverTab, options: tabs)
            .focused($tabsFocused)
            .padding(.horizontal, Theme.spaceXL)
            .padding(.bottom, Theme.spaceL)

            Group {
                switch model.popoverTab {
                case .overview: OverviewTab(snapshot: model.sampler.snapshot, history: model.sampler.history,
                                            open: { model.openDashboard($0) })
                case .battery: BatteryTab(battery: model.sampler.snapshot?.battery, health: model.sampler.batteryHealth,
                                           temperature: model.sampler.snapshot?.sensors?.battery,
                                          controller: model.chargeLimit,
                                          openSensors: { model.openDashboard(.sensors) })
                case .processes: ProcessesTab(sampler: model.sampler)
                case .ai: AILimitsTab(monitor: model.aiUsage)
                }
            }
            .padding(.horizontal, Theme.spaceXL)
            // One height for every tab, so the popover does not jump when switching.
            .frame(height: 484, alignment: .top)

            footer
        }
        .frame(width: 360)
        .defaultFocus($tabsFocused, true)
        .onChange(of: showsAILimits, initial: true) { _, shows in
            if !shows, model.popoverTab == .ai { model.popoverTab = .overview }
        }
        .onChange(of: model.isPopoverShown && model.popoverTab == .ai, initial: true) { _, isVisible in
            model.aiUsage.setVisible(.popover, isVisible)
        }
    }

    private var tabs: [(value: PopoverTab, label: LocalizedStringKey)] {
        var tabs: [(value: PopoverTab, label: LocalizedStringKey)] = [(.overview, "Overview"), (.battery, "Battery"), (.processes, "Processes")]
        if showsAILimits { tabs.append((.ai, "AI")) }
        return tabs
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: "Monny").font(Theme.metricS).foregroundStyle(Theme.textPrimary)
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
                    Text(verbatim: shortcut).font(.system(size: 12)).foregroundStyle(Theme.textTertiary)
                        .accessibilityLabel(Text("Shortcut \(shortcut)"))
                }
                Spacer(minLength: 0)
                if model.popoverTab == .processes {
                    Button("Activity Monitor \(Image(systemName: "arrow.up.right"))", action: openActivityMonitor)
                        .buttonStyle(PlainLinkButtonStyle())
                } else if model.popoverTab == .ai {
                    Text("Checked every 2 minutes")
                        .font(Theme.footnote)
                        .foregroundStyle(Theme.textTertiary)
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
