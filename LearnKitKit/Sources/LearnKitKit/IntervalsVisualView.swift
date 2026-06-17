import SwiftUI

/// Renders the `intervals` Primitive: each interval is a horizontal bar on a
/// shared time axis, one per row, positioned by its [start, end] over the axis
/// range. Colored by highlight state; an axis line with end labels sits below.
struct IntervalsVisualView: View {
    let visual: IntervalsVisual
    var palette: Palette = .standard

    var body: some View {
        GeometryReader { geo in
            let lo = visual.lowerBound
            let hi = visual.upperBound
            let leftPad: CGFloat = 12
            let rightPad: CGFloat = 12
            let usableW = max(geo.size.width - leftPad - rightPad, 1)
            let axisY = geo.size.height - 22
            let rows = max(visual.rows.count, 1)
            let rowH = max((axisY - 8) / CGFloat(rows), 14)
            let barH = min(rowH * 0.62, 30)
            let x: (Double) -> CGFloat = { v in
                leftPad + usableW * CGFloat((v - lo) / (hi - lo))
            }

            ZStack(alignment: .topLeading) {
                // Axis line.
                Path { p in
                    p.move(to: CGPoint(x: leftPad, y: axisY))
                    p.addLine(to: CGPoint(x: geo.size.width - rightPad, y: axisY))
                }
                .stroke(palette.linkColor.opacity(0.5), lineWidth: 1)

                Text("\(trim(lo))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .position(x: x(lo), y: axisY + 12)
                Text("\(trim(hi))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .position(x: x(hi), y: axisY + 12)

                ForEach(Array(visual.rows.enumerated()), id: \.offset) { i, row in
                    let x0 = x(row.start)
                    let x1 = x(row.end)
                    let y = 8 + CGFloat(i) * rowH + rowH / 2
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(palette.fill(for: row.state))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(palette.border(for: row.state), lineWidth: row.state == nil ? 1 : 2)
                        )
                        .overlay(
                            Text(row.label ?? "\(trim(row.start)),\(trim(row.end))")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(palette.cellText)
                                .minimumScaleFactor(0.5)
                                .padding(.horizontal, 4)
                        )
                        .frame(width: max(x1 - x0, 10), height: barH)
                        .position(x: (x0 + x1) / 2, y: y)
                }
            }
        }
    }

    /// Drop a trailing ".0" so integer bounds read as "6" not "6.0".
    private func trim(_ v: Double) -> String {
        v.rounded() == v ? String(Int(v)) : String(v)
    }
}
