import SwiftUI

/// Compact native text input with the search and clear affordances from Sketch frame `19`.
struct ProcessSearchField: View {
    @Binding var query: String
    @FocusState private var isFocused: Bool
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.textTertiary).accessibilityHidden(true)
            TextField("Search processes", text: $query)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .accessibilityLabel(Text("Search processes"))
            if !query.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill") {
                    query = ""
                    isFocused = true
                }
                .labelStyle(.iconOnly)
                .buttonStyle(StaticButtonStyle())
                .foregroundStyle(Theme.textTertiary)
            }
        }
        .font(Theme.body)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(Theme.fillTrack, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isFocused ? Theme.accentBrand : contrast == .increased ? Theme.textTertiary : .clear,
                              lineWidth: isFocused ? 2 : 1)
                .allowsHitTesting(false)
        }
    }
}
