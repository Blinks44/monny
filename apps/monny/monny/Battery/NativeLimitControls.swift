import SwiftUI

/// The system charge limit and Optimized Battery Charging, shared by the popover, Battery page and Settings.
struct NativeLimitControls: View {
    let controller: ChargeLimitController
    @State private var selection = 0.0
    /// The switch position chosen while macOS applies it, so the switch moves at once.
    @State private var optimizedChoice: Bool?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var limits: [Int] { controller.setting?.available ?? [80, 85, 90, 95, 100] }
    private var selectedLimit: Int { limits[min(max(Int(selection.rounded()), 0), limits.count - 1)] }
    private var isDisabled: Bool { controller.setting == nil }

    var body: some View {
        if ChargeLimit.isSupportedOS {
            controls
        } else {
            Banner(symbol: "info.circle", title: "Charge limit requires macOS 26.4",
                   message: "Update macOS to use this feature. Battery monitoring remains available.")
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 10) {
            // As in Sketch `16 · Battery · Native limit control`: the target first, 100% means no limit.
            HStack {
                Text("Charge limit").font(Theme.body)
                Spacer()
                valueText.font(Theme.metricS).foregroundStyle(Theme.statusSuccessText)
            }
            Slider(value: $selection, in: 0...Double(max(1, limits.count - 1)), step: 1) {
                Text("Charge limit")
            } onEditingChanged: { editing in
                guard !editing else { return }
                apply { await controller.set(target: selectedLimit) }
            }
            .labelsHidden().tint(Theme.metricBattery)
            .disabled(isDisabled)
            // Busy blocks input without the dimmed disabled look, which would flash on every change.
            .allowsHitTesting(!controller.isBusy)
            .accessibilityValue(valueText)
            HStack {
                ForEach(Array(limits.enumerated()), id: \.element) { index, limit in
                    if index > 0 { Spacer(minLength: 0) }
                    Text(limit, format: .number.grouping(.never))
                        .foregroundStyle(limit == selectedLimit ? Theme.statusSuccessText : Theme.textTertiary)
                }
            }
            .font(Theme.caption)
            .accessibilityHidden(true)
            if let isOptimized = controller.setting?.isOptimized {
                HStack {
                    Text("Optimized Battery Charging").font(Theme.body)
                    Spacer()
                    Toggle("Optimized Battery Charging", isOn: Binding(get: { optimizedChoice ?? isOptimized }, set: { isOn in
                        optimizedChoice = isOn
                        apply { await controller.setOptimized(isOn) }
                    }))
                    .labelsHidden().toggleStyle(SwitchStyle())
                }
                .padding(.top, 4)
                .allowsHitTesting(!controller.isBusy)
            }
            if controller.failed {
                Text("Couldn’t confirm the setting. Check Battery Settings.")
                    .font(Theme.footnote).foregroundStyle(Theme.statusDangerText).fixedSize(horizontal: false, vertical: true)
            } else if controller.hasRead, controller.setting == nil {
                Text("Charge limit isn’t available on this Mac.")
                    .font(Theme.footnote).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .onAppear(perform: sync)
        .onChange(of: controller.setting) { sync() }
    }

    private var valueText: Text {
        selectedLimit == ChargeLimit.noLimit ? Text("No limit") : Text((Double(selectedLimit) / 100).percentText)
    }

    /// Syncs afterwards: a failed change can leave the setting as it was, which `onChange` misses.
    private func apply(_ change: @escaping () async -> Void) {
        Task {
            await change()
            sync()
            // Shows the confirmed value; moves the switch back if macOS kept the old one.
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) { optimizedChoice = nil }
        }
    }

    /// Follows the system value, including changes made in System Settings.
    private func sync() {
        selection = Double(limits.firstIndex(of: controller.setting?.target ?? 80) ?? 0)
    }
}
