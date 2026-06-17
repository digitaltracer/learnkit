import SwiftUI

/// Renders the `rtree` Primitive: an n-ary decision tree for backtracking. Leaves
/// take sequential columns; each internal node is centered over its children.
/// Edges carry the choice label that reached the child; nodes carry highlight
/// state (e.g. a pruned or accepted branch).
struct RTreeVisualView: View {
    let visual: RTreeVisual
    var palette: Palette = .standard

    private let maxNodeSize: CGFloat = 40
    private let minNodeSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let placed = placement(in: geo.size)
            ZStack {
                ForEach(placed.edges) { edge in
                    Path { p in
                        p.move(to: edge.from)
                        p.addLine(to: edge.to)
                    }
                    .stroke(palette.linkColor, lineWidth: 1.5)

                    if let label = edge.label {
                        Text(label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 3)
                            .background(Capsule().fill(.background))
                            .position(x: (edge.from.x + edge.to.x) / 2, y: (edge.from.y + edge.to.y) / 2)
                    }
                }

                ForEach(placed.nodes) { n in
                    RNodeView(text: n.value, state: n.state, size: placed.nodeSize, palette: palette)
                        .position(n.point)
                    if let label = n.pointer {
                        RPointerBadge(label: label, palette: palette)
                            .position(x: n.point.x, y: n.point.y - placed.nodeSize / 2 - 11)
                    }
                }
            }
        }
    }

    private func placement(in size: CGSize) -> PlacedRTree {
        var layout = RLayout()
        layout.build(visual.root)
        let cols = max(layout.totalCols, 1)
        let levels = max(layout.maxDepth, 1)
        let nodeSize = min(maxNodeSize, max(minNodeSize, size.width / CGFloat(cols + 1)))
        let topPad = nodeSize / 2 + 22
        let bottomPad = nodeSize / 2 + 8
        let usableH = max(size.height - topPad - bottomPad, 1)

        func point(col: Double, depth: Int) -> CGPoint {
            CGPoint(x: size.width * (CGFloat(col) + 0.5) / CGFloat(cols),
                    y: topPad + usableH * CGFloat(depth) / CGFloat(levels))
        }

        let nodes = layout.nodes.map {
            PlacedRNode(id: $0.id, value: $0.value, state: $0.state, pointer: $0.pointer,
                        point: point(col: $0.col, depth: $0.depth))
        }
        let edges = layout.edges.map {
            PlacedREdge(id: $0.id, label: $0.label,
                        from: point(col: $0.parentCol, depth: $0.parentDepth),
                        to: point(col: $0.childCol, depth: $0.childDepth))
        }
        return PlacedRTree(nodes: nodes, edges: edges, nodeSize: nodeSize)
    }
}

private struct PlacedRTree {
    let nodes: [PlacedRNode]
    let edges: [PlacedREdge]
    let nodeSize: CGFloat
}
private struct PlacedRNode: Identifiable {
    let id: String
    let value: String
    let state: HighlightState?
    let pointer: String?
    let point: CGPoint
}
private struct PlacedREdge: Identifiable {
    let id: String
    let label: String?
    let from: CGPoint
    let to: CGPoint
}

/// n-ary layout: a post-order walk gives leaves sequential columns and centers
/// each parent over the span of its children.
private struct RLayout {
    struct Node { let id: String; let value: String; let state: HighlightState?; let pointer: String?; let col: Double; let depth: Int }
    struct Edge { let id: String; let label: String?; let parentCol: Double; let parentDepth: Int; let childCol: Double; let childDepth: Int }

    private(set) var nodes: [Node] = []
    private(set) var edges: [Edge] = []
    private(set) var totalCols = 0
    private(set) var maxDepth = 0

    mutating func build(_ root: RNode?) {
        var counter = 0
        _ = place(root, path: "root", depth: 0, leafCounter: &counter)
        totalCols = counter
    }

    @discardableResult
    private mutating func place(_ node: RNode?, path: String, depth: Int, leafCounter: inout Int) -> Double? {
        guard let node else { return nil }
        maxDepth = max(maxDepth, depth)

        let myCol: Double
        if node.children.isEmpty {
            myCol = Double(leafCounter)
            leafCounter += 1
        } else {
            var childCols: [Double] = []
            for (i, child) in node.children.enumerated() {
                if let c = place(child, path: path + "-\(i)", depth: depth + 1, leafCounter: &leafCounter) {
                    childCols.append(c)
                }
            }
            myCol = childCols.isEmpty ? Double(leafCounter) : (childCols.reduce(0, +) / Double(childCols.count))
        }

        nodes.append(Node(id: path, value: node.value.display, state: node.state, pointer: node.pointer, col: myCol, depth: depth))
        for (i, child) in node.children.enumerated() {
            let childPath = path + "-\(i)"
            if let childNode = nodes.first(where: { $0.id == childPath }) {
                edges.append(Edge(id: childPath, label: child.edge,
                                  parentCol: myCol, parentDepth: depth,
                                  childCol: childNode.col, childDepth: depth + 1))
            }
        }
        return myCol
    }
}

private struct RNodeView: View {
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
                    .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.cellText)
                    .minimumScaleFactor(0.5)
                    .padding(2)
            )
            .frame(width: size, height: size)
    }
}

private struct RPointerBadge: View {
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
