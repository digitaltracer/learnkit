import SwiftUI

/// Dispatches a Step's `Visual` to the renderer for its Primitive. The single
/// place that knows the full set of primitives the app can draw — adding a
/// primitive means adding a case here and a `Visual` case.
struct VisualView: View {
    let visual: Visual
    var palette: Palette = .standard

    var body: some View {
        switch visual {
        case .array(let v): ArrayVisualView(visual: v, palette: palette)
        case .grid(let v):  GridVisualView(visual: v, palette: palette)
        }
    }
}

/// Renders the `grid` Primitive: a centered 2-D matrix of square cells, with
/// per-cell or per-region highlights and named pointers pinned to cells.
///
/// Like `ArrayVisualView`, it holds no animation of its own — cells are keyed by
/// (row, col) and pointers by label, so when the parent swaps in a new snapshot
/// inside `withAnimation`, SwiftUI animates the deltas (a pointer hopping cells,
/// a region changing color).
struct GridVisualView: View {
    let visual: GridVisual
    var palette: Palette = .standard

    private let spacing: CGFloat = 6
    private let maxCellSize: CGFloat = 52
    private let minCellSize: CGFloat = 22

    var body: some View {
        GeometryReader { geo in
            let cols = max(visual.colCount, 1)
            let rows = max(visual.rowCount, 1)
            let cellW = (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)
            let cellH = (geo.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            let cell = min(maxCellSize, max(minCellSize, min(cellW, cellH)))
            let gridW = CGFloat(cols) * cell + CGFloat(cols - 1) * spacing
            let gridH = CGFloat(rows) * cell + CGFloat(rows - 1) * spacing
            let originX = (geo.size.width - gridW) / 2
            let originY = (geo.size.height - gridH) / 2

            ZStack(alignment: .topLeading) {
                cellsLayer(cell: cell, originX: originX, originY: originY)
                pointersLayer(cell: cell, originX: originX, originY: originY)
            }
        }
        // Height is set by the caller (the lesson page gives it a fixed band);
        // the GeometryReader fits the matrix within whatever it receives.
    }

    private func cellCenter(row: Int, col: Int, cell: CGFloat, originX: CGFloat, originY: CGFloat) -> CGPoint {
        CGPoint(x: originX + CGFloat(col) * (cell + spacing) + cell / 2,
                y: originY + CGFloat(row) * (cell + spacing) + cell / 2)
    }

    @ViewBuilder
    private func cellsLayer(cell: CGFloat, originX: CGFloat, originY: CGFloat) -> some View {
        ForEach(Array(visual.rows.enumerated()), id: \.offset) { r, row in
            ForEach(Array(row.enumerated()), id: \.offset) { c, value in
                GridCellView(text: value.display,
                             state: visual.highlightState(row: r, col: c),
                             size: cell,
                             palette: palette)
                    .position(cellCenter(row: r, col: c, cell: cell, originX: originX, originY: originY))
            }
        }
    }

    @ViewBuilder
    private func pointersLayer(cell: CGFloat, originX: CGFloat, originY: CGFloat) -> some View {
        ForEach(visual.pointers, id: \.label) { p in
            let r = min(max(p.row, 0), max(visual.rowCount - 1, 0))
            let c = min(max(p.col, 0), max(visual.colCount - 1, 0))
            let center = cellCenter(row: r, col: c, cell: cell, originX: originX, originY: originY)
            // Pin the badge to the cell's top-left corner so it never hides the
            // centered value.
            GridPointerBadge(label: p.label, palette: palette)
                .position(x: center.x - cell / 2, y: center.y - cell / 2)
        }
    }
}

private struct GridCellView: View {
    let text: String
    let state: HighlightState?
    let size: CGFloat
    let palette: Palette

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(palette.fill(for: state))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(palette.border(for: state), lineWidth: state == nil ? 1 : 2)
            )
            .overlay(
                Text(text)
                    .font(.system(size: min(18, size * 0.44), weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.cellText)
                    .minimumScaleFactor(0.5)
                    .padding(2)
            )
            .frame(width: size, height: size)
    }
}

private struct GridPointerBadge: View {
    let label: String
    let palette: Palette

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(palette.pointerColor))
            .fixedSize()
    }
}
