import SwiftUI

/// Renders the `architecture` Primitive: labeled component boxes at their explicit
/// normalized positions, joined by directed/labeled connectors, optionally backed
/// by tier/region groups. Modeled on `GraphVisualView` — same normalized-position
/// placement, edge trimming, and arrowhead geometry — but with rounded-rect
/// icon+label nodes, edge labels, group backings, and dashed `async` connectors.
/// Positions are hand-authored (no auto-layout) for deterministic, legible output.
/// See ADR 0010.
struct ArchitectureVisualView: View {
    let visual: ArchitectureVisual
    var palette: Palette = .standard

    private let nodeWidth: CGFloat = 80
    private let nodeHeight: CGFloat = 46

    var body: some View {
        GeometryReader { geo in
            let insetX = nodeWidth / 2 + 8
            let insetY = nodeHeight / 2 + 14   // headroom for group labels and connector chips
            let w = max(geo.size.width - insetX * 2, 1)
            let h = max(geo.size.height - insetY * 2, 1)
            let center: (ArchNode) -> CGPoint = { node in
                CGPoint(x: insetX + CGFloat(node.x) * w, y: insetY + CGFloat(node.y) * h)
            }

            ZStack(alignment: .topLeading) {
                // Groups sit behind everything.
                ForEach(Array(visual.groups.enumerated()), id: \.offset) { _, group in
                    let members = group.nodes.compactMap { visual.node(id: $0) }
                    if let rect = boundingRect(of: members, center: center) {
                        ArchGroupBacking(label: group.label, rect: rect)
                    }
                }

                // Connectors behind nodes.
                ForEach(Array(visual.connectors.enumerated()), id: \.offset) { _, c in
                    if let a = visual.node(id: c.from), let b = visual.node(id: c.to) {
                        ArchConnectorView(
                            from: center(a),
                            to: center(b),
                            halfSize: CGSize(width: nodeWidth / 2, height: nodeHeight / 2),
                            directed: c.directed ?? true,
                            dashed: (c.style ?? .sync) == .async,
                            label: c.label,
                            color: c.state == nil ? palette.linkColor : palette.border(for: c.state)
                        )
                    }
                }

                // Nodes on top.
                ForEach(Array(visual.nodes.enumerated()), id: \.offset) { _, node in
                    ArchNodeView(node: node, size: CGSize(width: nodeWidth, height: nodeHeight), palette: palette)
                        .position(center(node))
                }
            }
        }
    }

    /// The padded rectangle enclosing a group's member boxes, in view coordinates.
    private func boundingRect(of nodes: [ArchNode], center: (ArchNode) -> CGPoint) -> CGRect? {
        guard !nodes.isEmpty else { return nil }
        let halfW = nodeWidth / 2, halfH = nodeHeight / 2
        var minX = CGFloat.greatestFiniteMagnitude, minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude, maxY = -CGFloat.greatestFiniteMagnitude
        for node in nodes {
            let p = center(node)
            minX = min(minX, p.x - halfW); maxX = max(maxX, p.x + halfW)
            minY = min(minY, p.y - halfH); maxY = max(maxY, p.y + halfH)
        }
        let pad: CGFloat = 12
        return CGRect(x: minX - pad, y: minY - pad - 6,
                      width: (maxX - minX) + pad * 2, height: (maxY - minY) + pad * 2 + 6)
    }
}

// MARK: - Connector

private struct ArchConnectorView: View {
    let from: CGPoint
    let to: CGPoint
    let halfSize: CGSize
    let directed: Bool
    let dashed: Bool
    let label: String?
    let color: Color

    var body: some View {
        let dx = to.x - from.x, dy = to.y - from.y
        let len = max(sqrt(dx * dx + dy * dy), 0.0001)
        let ux = dx / len, uy = dy / len
        // Trim each end to the box boundary so the line meets the rectangle cleanly.
        let tFrom = boundaryDistance(ux: ux, uy: uy, half: halfSize)
        let tTo = boundaryDistance(ux: ux, uy: uy, half: halfSize)
        let start = CGPoint(x: from.x + ux * tFrom, y: from.y + uy * tFrom)
        let end = CGPoint(x: to.x - ux * tTo, y: to.y - uy * tTo)

        ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: start)
                p.addLine(to: end)
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.8, dash: dashed ? [5, 4] : []))

            if directed {
                ArchArrowHead(tip: end, ux: ux, uy: uy, color: color)
            }

            if let label {
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.background))
                    .position(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
            }
        }
    }

    /// Distance from a box center to its edge along the unit direction (ux,uy).
    private func boundaryDistance(ux: CGFloat, uy: CGFloat, half: CGSize) -> CGFloat {
        let tx = ux == 0 ? .greatestFiniteMagnitude : half.width / abs(ux)
        let ty = uy == 0 ? .greatestFiniteMagnitude : half.height / abs(uy)
        return min(tx, ty)
    }
}

/// A filled triangular arrowhead at `tip`, pointing along (ux,uy).
private struct ArchArrowHead: View {
    let tip: CGPoint
    let ux: CGFloat
    let uy: CGFloat
    let color: Color

    var body: some View {
        let size: CGFloat = 9
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

// MARK: - Node

private struct ArchNodeView: View {
    let node: ArchNode
    let size: CGSize
    let palette: Palette

    var body: some View {
        let tint = ArchStyle.color(for: node.kind)
        let highlighted = node.state != nil
        let fill = highlighted ? palette.fill(for: node.state) : tint.opacity(0.14)
        let stroke = highlighted ? palette.border(for: node.state) : tint.opacity(0.55)

        VStack(spacing: 2) {
            Image(systemName: ArchStyle.symbol(for: node.kind))
                .font(.system(size: 14))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(node.title)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.cellText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
            if let subtitle = node.subtitle {
                Text(subtitle)
                    .font(.system(size: 8.5, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, 6)
        .frame(width: size.width, height: size.height)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(fill))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(stroke, lineWidth: highlighted ? 2.5 : 1.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(node.subtitle.map { "\(node.title), \($0)" } ?? node.title)
    }
}

// MARK: - Group backing

private struct ArchGroupBacking: View {
    let label: String?
    let rect: CGRect

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        ZStack(alignment: .topLeading) {
            shape
                .fill(Color.secondary.opacity(0.05))
                .overlay(shape.strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.4)))
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            if let label {
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.background))
                    .position(x: rect.minX + 28, y: rect.minY + 2)
            }
        }
    }
}

// MARK: - Kind → tint + symbol

private enum ArchStyle {
    static func color(for kind: ArchKind) -> Color {
        switch kind {
        case .client:   return .blue
        case .service:  return .purple
        case .database: return .green
        case .cache:    return .orange
        case .queue:    return .teal
        case .cdn:      return .cyan
        case .storage:  return .brown
        case .lb:       return .indigo
        case .external: return .gray
        }
    }

    static func symbol(for kind: ArchKind) -> String {
        switch kind {
        case .client:   return "person.crop.circle.fill"
        case .service:  return "gearshape.fill"
        case .database: return "cylinder.fill"
        case .cache:    return "bolt.fill"
        case .queue:    return "tray.full.fill"
        case .cdn:      return "globe"
        case .storage:  return "externaldrive.fill"
        case .lb:       return "arrow.triangle.branch"
        case .external: return "cloud.fill"
        }
    }
}
