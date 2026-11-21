import SwiftUI
import UniformTypeIdentifiers

struct AIToolSettingsRow: View {
    let tool: AITool
    let isShown: Binding<Bool>
    let previousTool: AITool?
    let nextTool: AITool?
    let move: (AITool, AITool) -> Void
    @State private var isDropTarget = false

    private static let dragType = UTType(exportedAs: "blinks44.monny.ai-tool", conformingTo: .data)

    var body: some View {
        HStack(spacing: Theme.spaceXS) {
            Toggle(isOn: isShown) { Text(verbatim: tool.appName) }
            Spacer(minLength: Theme.spaceM)
            Menu {
                Button("Move up", systemImage: "arrow.up") {
                    if let previousTool { move(tool, previousTool) }
                }
                .disabled(previousTool == nil)
                Button("Move down", systemImage: "arrow.down") {
                    if let nextTool { move(tool, nextTool) }
                }
                .disabled(nextTool == nil)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel("Reorder \(tool.appName)")

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 24, height: 26)
                .contentShape(Rectangle())
                .onDrag(dragProvider)
                .help("Drag to reorder")
                .accessibilityHidden(true)
        }
        .frame(minHeight: 26)
        .background(
            isDropTarget ? Theme.accentBrand.opacity(0.16) : .clear,
            in: RoundedRectangle(cornerRadius: Theme.radiusIcon)
        )
        .contentShape(Rectangle())
        .onDrop(of: [Self.dragType], isTargeted: $isDropTarget, perform: acceptDrop)
    }

    private func dragProvider() -> NSItemProvider {
        let provider = NSItemProvider()
        let data = Data(tool.rawValue.utf8)
        provider.registerDataRepresentation(for: Self.dragType, visibility: .ownProcess) { completion in
            completion(data, nil)
            return nil
        }
        return provider
    }

    private func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadDataRepresentation(for: Self.dragType) { data, _ in
            guard let data, let rawValue = String(data: data, encoding: .utf8), let source = AITool(rawValue: rawValue)
            else { return }
            Task { @MainActor in move(source, tool) }
        }
        return true
    }
}
