import SwiftUI

/// Renders the `list` Primitive: nodes in a fixed left-to-right row joined by
/// directed `next` arrows. Neighboring links draw as a straight horizontal arrow
/// (direction shows which way `next` points — flipping these is how reversal
/// reads); non-adjacent links (e.g. a cycle's back-edge) draw as an arc above.
///
/// Like the other primitives it holds no animation of its own: nodes keyed by
/// index, pointers by label, so snapshot diffs animate when the parent advances
/// a step inside `withAnimation`.
struct ListVisualView: View {
    let visual: ListVisual
    var palette: Palette = .standard

    private let spacing: CGFloat = 30      // wide gaps so the arrows are legible
    private let maxCellSize: CGFloat = 54
    private let minCellSize: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let n = max(visual.nodes.count, 1)
            let available = geo.size.width
            let raw = (available - spacing * CGFloat(n - 1)) / CGFloat(n)
            let cell = min(maxCellSize, max(minCellSize, raw))
            let totalWidth = CGFloat(n) * cell + CGFloat(n - 1) * spacing
            let firstCenterX = (available - totalWidth) / 2 + cell / 2
            let rowY = geo.size.height * 0.5

            ZStack(alignment: .topLeading) {
                linksLayer(cell: cell, firstCenterX: firstCenterX, rowY: rowY)
                nodesLayer(cell: cell, firstCenterX: firstCenterX, rowY: rowY)
                pointersLayer(cell: cell, firstCenterX: firstCenterX, rowY: rowY, count: n)
            }
        }
    }

    private func centerX(_ index: Int, cell: CGFloat, firstCenterX: CGFloat) -> CGFloat {
        firstCenterX + CGFloat(index) * (cell + spacing)
    }

    // MARK: Layers

    @ViewBuilder
    private func nodesLayer(cell: CGFloat, firstCenterX: CGFloat, rowY: CGFloat) -> some View {
        ForEach(Array(visual.nodes.enumerated()), id: \.offset) { index, value in
            let x = centerX(index, cell: cell, firstCenterX: firstCenterX)
            ListNodeView(text: value.display,
                         state: visual.highlightState(for: index),
                         size: cell,
                         palette: palette)
                .position(x: x, y: rowY)

            Text("\(index)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .position(x: x, y: rowY + cell / 2 + 14)
        }
    }

    @ViewBuilder
    private func linksLayer(cell: CGFloat, firstCenterX: CGFloat, rowY: CGFloat) -> some View {
        let count = visual.nodes.count
        ForEach(Array(visual.resolvedLinks.enumerated()), id: \.offset) { _, link in
            if link.from >= 0, link.from < count, link.to >= 0, link.to < count {
                let fromX = centerX(link.from, cell: cell, firstCenterX: firstCenterX)
                let toX = centerX(link.to, cell: cell, firstCenterX: firstCenterX)
                if abs(link.to - link.from) == 1 {
                    StraightLink(fromX: fromX, toX: toX, rowY: rowY, cell: cell, color: palette.linkColor)
                } else {
                    ArcLink(fromX: fromX, toX: toX, rowY: rowY, cell: cell, color: palette.linkColor)
                }
            }
        }
    }

    @ViewBuilder
    private func pointersLayer(cell: CGFloat, firstCenterX: CGFloat, rowY: CGFloat, count: Int) -> some View {
        ForEach(visual.pointers, id: \.label) { pointer in
            let clamped = min(max(pointer.index, 0), count - 1)
            ListPointerView(label: pointer.label, palette: palette)
                .position(x: centerX(clamped, cell: cell, firstCenterX: firstCenterX),
                          y: rowY - cell / 2 - 22)
        }
    }
}

/// A straight horizontal `next` arrow between two neighboring nodes. The
/// arrowhead end shows the direction (right = forward, left = reversed).
private struct StraightLink: View {
    let fromX: CGFloat
    let toX: CGFloat
    let rowY: CGFloat
    let cell: CGFloat
    let color: Color

    var body: some View {
        let forward = toX > fromX
        let startX = forward ? fromX + cell / 2 + 3 : fromX - cell / 2 - 3
        let endX = forward ? toX - cell / 2 - 3 : toX + cell / 2 + 3
        ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: CGPoint(x: startX, y: rowY))
                p.addLine(to: CGPoint(x: endX, y: rowY))
            }
            .stroke(color, lineWidth: 1.5)

            Image(systemName: forward ? "arrowtriangle.right.fill" : "arrowtriangle.left.fill")
                .font(.system(size: 10))
                .foregroundStyle(color)
                .position(x: endX, y: rowY)
        }
    }
}

/// A curved `next` arrow for non-adjacent links (e.g. a cycle's back-edge),
/// arced above the row.
private struct ArcLink: View {
    let fromX: CGFloat
    let toX: CGFloat
    let rowY: CGFloat
    let cell: CGFloat
    let color: Color

    var body: some View {
        let topY = rowY - cell / 2 - 4
        let lift = min(max(abs(toX - fromX) * 0.35, 24), 70)
        ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: CGPoint(x: fromX, y: topY))
                p.addQuadCurve(to: CGPoint(x: toX, y: topY),
                               control: CGPoint(x: (fromX + toX) / 2, y: topY - lift))
            }
            .stroke(color, lineWidth: 1.5)

            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundStyle(color)
                .position(x: toX, y: topY)
        }
    }
}

private struct ListNodeView: View {
    let text: String
    let state: HighlightState?
    let size: CGFloat
    let palette: Palette

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(palette.fill(for: state))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(palette.border(for: state), lineWidth: state == nil ? 1 : 2)
            )
            .overlay(
                Text(text)
                    .font(.system(size: min(20, size * 0.42), weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.cellText)
                    .minimumScaleFactor(0.5)
                    .padding(2)
            )
            .frame(width: size, height: size)
    }
}

private struct ListPointerView: View {
    let label: String
    let palette: Palette

    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(palette.pointerColor))
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 9))
                .foregroundStyle(palette.pointerColor)
        }
        .fixedSize()
    }
}
