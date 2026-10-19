import SwiftUI

/// Sketch's flexible main card and 244 pt side card, sharing the taller content's height.
/// Measure at the actual column widths so wrapped translations determine the row height.
struct BatteryCardRow: Layout {
    let minimumHeight: CGFloat
    private let sideWidth: CGFloat = 244
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 776
        let widths = [max(0, width - sideWidth - spacing), sideWidth]
        let contentHeight = zip(subviews, widths).map {
            $0.sizeThatFits(ProposedViewSize(width: $1, height: nil)).height
        }.max() ?? 0
        return CGSize(width: width, height: max(minimumHeight, contentHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = [max(0, bounds.width - sideWidth - spacing), sideWidth]
        var x = bounds.minX
        for (subview, width) in zip(subviews, widths) {
            subview.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                          proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + spacing
        }
    }
}
