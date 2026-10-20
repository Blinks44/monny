import SwiftUI

/// Supported native limits only. A saved preference never starts hardware control.
struct NativeLimitControls: View {
    let helper: BatteryHelper
    @AppStorage(PreferenceKey.defaultChargeLimit) private var savedLimit = 80
    @State private var selection = 0.0

    private var limits: [Int] { helper.nativeLimits.isEmpty ? [80, 85, 90, 95, 100] : helper.nativeLimits }
    private var selectedLimit: Int { limits[min(max(Int(selection.rounded()), 0), limits.count - 1)] }
    private var unavailable: Bool { !helper.canControlNativeLimit || helper.nativeBusy || helper.isBusy }

    private var guidance: LocalizedStringKey {
        helper.canControlNativeLimit
            ? "The previous macOS settings are restored when control stops."
            : "Update the battery helper to use charge limits."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spaceM) {
            Toggle("Control charge limit", isOn: Binding(get: { helper.nativeLimit != nil }, set: { enabled in
                Task {
                    if enabled { await helper.setNativeLimit(selectedLimit) }
                    else { await helper.stopNativeLimit() }
                }
            }))
            .toggleStyle(.switch)
            .font(Theme.bodyEmphasized)
            .disabled(unavailable)
            HStack {
                Text("Charge limit").font(Theme.body)
                Spacer()
                Text((Double(selectedLimit) / 100).percentText)
                    .font(Theme.bodyEmphasized).foregroundStyle(Theme.metricBattery)
            }
            Slider(value: $selection, in: 0...Double(max(1, limits.count - 1)), step: 1) { Text("Charge limit") }
                onEditingChanged: { editing in
                    guard !editing else { return }
                    savedLimit = selectedLimit
                    if helper.nativeLimit != nil { Task { await helper.setNativeLimit(selectedLimit) } }
                }
                .labelsHidden()
                .tint(Theme.metricBattery)
                .disabled(unavailable)
                .accessibilityValue(Text((Double(selectedLimit) / 100).percentText))
            HStack {
                Text((Double(limits.first ?? 80) / 100).percentText)
                Spacer()
                Text((Double(limits.last ?? 100) / 100).percentText)
            }
            .font(Theme.caption).foregroundStyle(Theme.textTertiary)
            Text(guidance)
                .font(Theme.footnote).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { syncSelection() }
        .onChange(of: helper.nativeLimit) { _, limit in if limit != nil { syncSelection() } }
        .onChange(of: helper.nativeLimits) { _, _ in syncSelection() }
    }

    private func syncSelection() {
        let current = helper.nativeLimit ?? savedLimit
        selection = Double(limits.firstIndex(of: current) ?? 0)
    }
}
