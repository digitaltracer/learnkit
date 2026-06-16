import SwiftUI

/// Renders the `array` Primitive in one of two styles:
/// - `.cells`: a row of boxed values (indices, characters, sorted numbers).
/// - `.bars`: vertical bars scaled to each cell's numeric value (heights, magnitudes).
///
/// The view holds no animation of its own. Because cells/bars are keyed by index
/// and pointers by label, when the parent swaps in a new snapshot inside a
/// `withAnimation` block, SwiftUI animates the deltas — a pointer sliding to a new
/// index, a cell changing color, a bar's highlight — which is the signature interaction.
struct ArrayVisualView: View {
    let visual: ArrayVisual
    var palette: Palette = .standard

    private let spacing: CGFloat = 8
    private let maxCellSize: CGFloat = 56
    private let minCellSize: CGFloat = 26

    var body: some View {
        GeometryReader { geo in
            let n = max(visual.cells.count, 1)
            let available = geo.size.width
            let raw = (available - spacing * CGFloat(n - 1)) / CGFloat(n)
            let cell = min(maxCellSize, max(minCellSize, raw))
            let totalWidth = CGFloat(n) * cell + CGFloat(n - 1) * spacing
            let firstCenterX = (available - totalWidth) / 2 + cell / 2

            ZStack(alignment: .topLeading) {
                if visual.style == .bars {
                    barsLayer(height: geo.size.height, cell: cell, firstCenterX: firstCenterX)
                } else {
                    cellsLayer(height: geo.size.height, cell: cell, firstCenterX: firstCenterX)
                }
                pointersLayer(height: geo.size.height, cell: cell, firstCenterX: firstCenterX, count: n)
            }
        }
        // Height is set by the caller (the lesson page gives it a fixed band); the
        // GeometryReader lays the cells/bars out within whatever it receives.
    }

    private func centerX(_ index: Int, cell: CGFloat, firstCenterX: CGFloat) -> CGFloat {
        firstCenterX + CGFloat(index) * (cell + spacing)
    }

    // MARK: Layers

    @ViewBuilder
    private func cellsLayer(height: CGFloat, cell: CGFloat, firstCenterX: CGFloat) -> some View {
        let rowY = height * 0.5
        ForEach(Array(visual.cells.enumerated()), id: \.offset) { index, value in
            CellView(text: value.display,
                     state: visual.highlightState(for: index),
                     size: cell,
                     palette: palette)
                .position(x: centerX(index, cell: cell, firstCenterX: firstCenterX), y: rowY)

            Text("\(index)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .position(x: centerX(index, cell: cell, firstCenterX: firstCenterX),
                          y: rowY + cell / 2 + 14)
        }
    }

    @ViewBuilder
    private func barsLayer(height: CGFloat, cell: CGFloat, firstCenterX: CGFloat) -> some View {
        let baselineY = height - 32
        let topInset: CGFloat = 48
        let areaHeight = max(baselineY - topInset, 10)
        let maxValue = max(visual.cells.compactMap(\.numericValue).max() ?? 1, 0.0001)

        ForEach(Array(visual.cells.enumerated()), id: \.offset) { index, value in
            let v = value.numericValue ?? 0
            let barHeight = max(CGFloat(v / maxValue) * areaHeight, 3)
            let x = centerX(index, cell: cell, firstCenterX: firstCenterX)
            let state = visual.highlightState(for: index)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(palette.fill(for: state))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(palette.border(for: state), lineWidth: state == nil ? 1 : 2)
                )
                .frame(width: cell, height: barHeight)
                .position(x: x, y: baselineY - barHeight / 2)

            Text(value.display)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .position(x: x, y: baselineY + 12)
        }
    }

    @ViewBuilder
    private func pointersLayer(height: CGFloat, cell: CGFloat, firstCenterX: CGFloat, count: Int) -> some View {
        let pointersY: CGFloat = visual.style == .bars ? 16 : height * 0.5 - cell / 2 - 22
        ForEach(visual.pointers, id: \.label) { pointer in
            let clamped = min(max(pointer.index, 0), count - 1)
            PointerView(label: pointer.label, palette: palette)
                .position(x: centerX(clamped, cell: cell, firstCenterX: firstCenterX), y: pointersY)
        }
    }
}

private struct CellView: View {
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

private struct PointerView: View {
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
