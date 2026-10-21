import SwiftUI

/// The system charge-limit preference, shared by the popover, Battery page and Settings.
struct NativeLimitControls: View {
    let controller: ChargeLimitController
    @State private var selection = 0.0

    private var limits: [Int] { controller.setting?.available ?? [80, 85, 90, 95, 100] }
    private var selectedLimit: Int { limits[min(max(Int(selection.rounded()), 0), limits.count - 1)] }
    private var isDisabled: Bool { controller.setting == nil || controller.isBusy }

    var body: some View {
        if ChargeLimit.isSupportedOS {
            controls
        } else {
            Banner(kind: .info, symbol: "info.circle", title: "Charge limit requires macOS 26.4",
                   message: "Update macOS to use this feature. Battery monitoring remains available.")
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            // As in Sketch `16 · Battery · Native limit control`: the switch first, then the target.
            HStack {
                Text("Use charge limit").font(Theme.bodyEmphasized)
                Spacer()
                Toggle("Use charge limit", isOn: Binding(get: { controller.setting?.isEnabled ?? false }, set: { enabled in
                    Task { await controller.set(limit: selectedLimit, enabled: enabled) }
                }))
                .labelsHidden().toggleStyle(SwitchStyle())
            }
            .disabled(isDisabled)
            HStack {
                Text("Charge limit").font(Theme.body)
                Spacer()
                Text((Double(selectedLimit) / 100).percentText)
                    .font(Theme.metricS).foregroundStyle(Theme.statusSuccessText)
            }
            Slider(value: $selection, in: 0...Double(max(1, limits.count - 1)), step: 1) {
                Text("Charge limit")
            } onEditingChanged: { editing in
                guard !editing else { return }
                Task { await controller.set(limit: selectedLimit, enabled: true) }
            }
            .labelsHidden().tint(Theme.metricBattery)
            .disabled(isDisabled)
            .accessibilityValue(Text((Double(selectedLimit) / 100).percentText))
            HStack {
                ForEach(Array(limits.enumerated()), id: \.element) { index, limit in
                    if index > 0 { Spacer(minLength: 0) }
                    Text(limit, format: .number.grouping(.never))
                        .foregroundStyle(limit == selectedLimit ? Theme.statusSuccessText : Theme.textTertiary)
                }
            }
            .font(Theme.caption)
            .accessibilityHidden(true)
            if controller.failed {
                Text("Couldn’t confirm the charge limit. Check Battery Settings.")
                    .font(Theme.footnote).foregroundStyle(Theme.statusDangerText).fixedSize(horizontal: false, vertical: true)
            } else if controller.hasRead, controller.setting == nil {
                Text("Charge limits require macOS 26.4 or later and supported hardware.")
                    .font(Theme.footnote).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .onAppear(perform: sync)
        .onChange(of: controller.setting) { sync() }
    }

    /// Follows the system value, including changes made in System Settings.
    private func sync() {
        selection = Double(limits.firstIndex(of: controller.setting?.limit ?? 80) ?? 0)
    }
}
