import SwiftUI

/// Inset sidebar panel: the monitor pages, then Settings at the bottom.
struct Sidebar: View {
    @Binding var selection: DashboardPage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MONITOR")
                .font(Theme.overline)
                .tracking(Theme.overlineTracking)
                .foregroundStyle(Theme.textSecondary)
                .padding(.leading, 12)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)
            ForEach(DashboardPage.allCases.filter { $0 != .settings }, id: \.self) { page in
                SidebarButton(page: page, isSelected: selection == page) { selection = page }
            }
            Spacer(minLength: Theme.spaceXL)
            SidebarButton(page: .settings, isSelected: selection == .settings) { selection = .settings }
        }
        .padding(.horizontal, 8)
        .padding(.top, 52)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                .fill(Theme.surfaceSidebarStart)
                .strokeBorder(Theme.surfacePanelStroke)
        }
        .padding(8)
    }
}

private struct SidebarButton: View {
    let page: DashboardPage
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                icon
                Text(page.title)
                    .font(isSelected ? Theme.bodyEmphasized : Theme.body)
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .frame(height: 34)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surfaceControl).controlElevation()
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.stateHover)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { isHovered = $0 }
    }

    @ViewBuilder private var icon: some View {
        if let color = page.color {
            Image(systemName: page.symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(color.gradient, in: .rect(cornerRadius: 6, style: .continuous))
                .accessibilityHidden(true)
        } else {
            Image(systemName: page.symbol)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 22, height: 22)
                .accessibilityHidden(true)
        }
    }
}

extension DashboardPage {
    var symbol: String {
        switch self {
        case .overview: "waveform.path.ecg"
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .disk: "internaldrive"
        case .network: "network"
        case .battery: "battery.100percent"
        case .sensors: "thermometer.medium"
        case .settings: "gearshape"
        }
    }

    /// The metric color of the page's icon tile; Settings has none.
    var color: Color? {
        switch self {
        case .overview: Theme.accentIconGraphite
        case .cpu: Theme.metricCPU
        case .memory: Theme.metricMemory
        case .disk: Theme.metricDisk
        case .network: Theme.metricNetwork
        case .battery: Theme.metricBattery
        case .sensors: Theme.metricHeatHot
        case .settings: nil
        }
    }
}
