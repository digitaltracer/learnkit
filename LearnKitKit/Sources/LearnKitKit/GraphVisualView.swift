import SwiftUI

/// Renders the `graph` Primitive: nodes placed at their explicit normalized
/// positions, joined by edges (optionally directed and/or weighted). Edges draw
/// behind nodes; a directed edge gets an arrowhead at its `to` end; a weighted
/// edge shows its weight on a small chip at the midpoint.
struct GraphVisualView: View {
    let visual: GraphVisual
    var palette: Palette = .standard

    private let nodeSize: CGFloat = 42

    var body: some View {
        GeometryReader { geo in
            let inset = nodeSize / 2 + 6
            let w = max(geo.size.width - inset * 2, 1)
            let h = max(geo.size.height - inset * 2, 1)

            ZStack(alignment: .topLeading) {
                ForEach(Array(visual.edges.enumerated()), id: \.offset) { _, edge in
                    if let a = visual.node(id: edge.from), let b = visual.node(id: edge.to) {
                        GraphEdgeView(
                            from: CGPoint(x: inset + CGFloat(a.x) * w, y: inset + CGFloat(a.y) * h),
                            to: CGPoint(x: inset + CGFloat(b.x) * w, y: inset + CGFloat(b.y) * h),
                            directed: edge.directed ?? false,
                            weight: edge.weight?.display,
                            radius: nodeSize / 2,
                            color: palette.fill(for: edge.state) == palette.fill(for: nil) ? palette.linkColor : palette.border(for: edge.state)
                        )
                    }
                }

                ForEach(Array(visual.nodes.enumerated()), id: \.offset) { _, node in
                    let p = CGPoint(x: inset + CGFloat(node.x) * w, y: inset + CGFloat(node.y) * h)
                    GraphNodeView(text: node.display, state: node.state, size: nodeSize, palette: palette)
                        .position(p)
                    if let label = node.pointer {
                        GraphPointerBadge(label: label, palette: palette)
                            .position(x: p.x, y: p.y - nodeSize / 2 - 11)
                    }
                }
            }
        }
    }
}

private struct GraphEdgeView: View {
    let from: CGPoint
    let to: CGPoint
    let directed: Bool
    let weight: String?
    let radius: CGFloat
    let color: Color

    var body: some View {
        // Trim both ends to the node boundary so the line meets the circles cleanly.
        let dx = to.x - from.x, dy = to.y - from.y
        let len = max(sqrt(dx * dx + dy * dy), 0.0001)
        let ux = dx / len, uy = dy / len
        let start = CGPoint(x: from.x + ux * radius, y: from.y + uy * radius)
        let end = CGPoint(x: to.x - ux * radius, y: to.y - uy * radius)

        ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: start)
                p.addLine(to: end)
            }
            .stroke(color, lineWidth: 1.8)

            if directed {
                ArrowHead(tip: end, ux: ux, uy: uy, color: color)
            }

            if let weight {
                Text(weight)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.background))
                    .position(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
            }
        }
    }
}

/// A filled triangular arrowhead at `tip`, pointing along the (ux,uy) direction.
private struct ArrowHead: View {
    let tip: CGPoint
    let ux: CGFloat
    let uy: CGFloat
    let color: Color

    var body: some View {
        let size: CGFloat = 9
        // The two base corners: step back from the tip, then offset perpendicular.
        let bx = tip.x - ux * size, by = tip.y - uy * size
        let px = -uy, py = ux        // perpendicular unit vector
        Path { p in
            p.move(to: tip)
            p.addLine(to: CGPoint(x: bx + px * size * 0.6, y: by + py * size * 0.6))
            p.addLine(to: CGPoint(x: bx - px * size * 0.6, y: by - py * size * 0.6))
            p.closeSubpath()
        }
        .fill(color)
    }
}

private struct GraphNodeView: View {
    let text: String
    let state: HighlightState?
    let size: CGFloat
    let palette: Palette

    var body: some View {
        Circle()
            .fill(palette.fill(for: state))
            .overlay(Circle().strokeBorder(palette.border(for: state), lineWidth: state == nil ? 1.5 : 2.5))
            .overlay(
                Text(text)
                    .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.cellText)
                    .minimumScaleFactor(0.5)
                    .padding(2)
            )
            .frame(width: size, height: size)
    }
}

private struct GraphPointerBadge: View {
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
