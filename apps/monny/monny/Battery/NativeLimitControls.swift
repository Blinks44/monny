import SwiftUI

/// The system charge-limit preference, shared by the popover and dashboard.
struct NativeLimitControls: View {
    let controller: ChargeLimitController
    var supportsSystemChargeLimit: Bool = {
        if #available(macOS 26.4, *) { return true }
        return false
    }()
    @State private var selection = 0.0

    private var limits: [Int] { controller.snapshot?.availableLimits ?? [80, 85, 90, 95, 100] }
    private var selectedLimit: Int { limits[min(max(Int(selection.rounded()), 0), limits.count - 1)] }

    var body: some View {
        Group {
            if supportsSystemChargeLimit {
                controls
            } else {
                Banner(kind: .info, symbol: "info.circle", title: "Charge limit requires macOS 26.4",
                    message: "Update macOS to use this feature. Battery monitoring remains available.")
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Charge limit").font(Theme.bodyEmphasized)
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
            .disabled(controller.snapshot == nil || controller.isBusy)
            .accessibilityValue(Text((Double(selectedLimit) / 100).percentText))
            HStack {
                ForEach(Array(limits.enumerated()), id: \.element) { index, limit in
                    if index > 0 { Spacer(minLength: 0) }
                    Text(limit, format: .number.grouping(.never))
                        .foregroundStyle(limit == selectedLimit ? Theme.statusSuccessText : Theme.textTertiary)
                }
            }
            .font(Theme.caption)
            HStack {
                Text("Use charge limit").font(Theme.body)
                Spacer()
                Toggle("Use charge limit", isOn: Binding(get: { controller.snapshot?.enabled ?? false }, set: { enabled in
                Task { await controller.set(limit: selectedLimit, enabled: enabled) }
            }))
                .labelsHidden().toggleStyle(SwitchStyle())
            }
            .disabled(controller.snapshot == nil || controller.isBusy)
            if controller.failed {
                Text("Couldn’t confirm the charge limit. Check Battery Settings.")
                    .font(Theme.footnote).foregroundStyle(Theme.statusDangerText).fixedSize(horizontal: false, vertical: true)
            } else if controller.snapshot == nil {
                Text("Charge limits require macOS 26.4 or later and supported hardware.")
                    .font(Theme.footnote).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .onAppear { sync() }
        .onChange(of: controller.snapshot) { _, _ in sync() }
    }

    private func sync() {
        selection = Double(limits.firstIndex(of: controller.snapshot?.configuredLimit ?? 80) ?? 0)
    }
}
