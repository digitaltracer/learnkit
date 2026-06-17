import SwiftUI

/// Renders the `tree` Primitive: a binary tree laid out with classic in-order
/// horizontal placement (x = in-order rank, y = depth), edges drawn behind the
/// nodes, and per-node highlight states + pointer badges.
///
/// Node identity is its path from the root ("root", "L", "RL", …), so a node
/// that stays in the same structural position across Steps animates in place
/// while its value/color crossfades when the parent swaps snapshots inside
/// `withAnimation`.
struct TreeVisualView: View {
    let visual: TreeVisual
    var palette: Palette = .standard

    private let maxNodeSize: CGFloat = 42
    private let minNodeSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let placed = placement(in: geo.size)
            ZStack {
                // Edges first, so nodes sit on top of the connecting lines.
                ForEach(placed.edges) { edge in
                    Path { p in
                        p.move(to: edge.from)
                        p.addLine(to: edge.to)
                    }
                    .stroke(palette.border(for: nil), lineWidth: 1.5)
                }

                ForEach(placed.nodes) { n in
                    TreeNodeView(text: n.value, state: n.state, size: placed.nodeSize, palette: palette)
                        .position(n.point)
                    if let label = n.pointer {
                        TreePointerBadge(label: label, palette: palette)
                            .position(x: n.point.x, y: n.point.y - placed.nodeSize / 2 - 11)
                    }
                }
            }
        }
        // Height is set by the caller (the lesson page gives it a fixed band).
    }

    /// Turns the abstract layout (columns + depths) into absolute points for the
    /// given size. A plain method, so the `body` result builder stays free of
    /// declarations.
    private func placement(in size: CGSize) -> PlacedTree {
        let layout = TreeLayout(root: visual.root)
        let cols = max(layout.totalCols, 1)
        let levels = max(layout.maxDepth, 1)
        let nodeSize = min(maxNodeSize, max(minNodeSize, size.width / CGFloat(cols + 1)))
        let topPad = nodeSize / 2 + 26      // room for a pointer badge above the root
        let bottomPad = nodeSize / 2 + 8
        let usableH = max(size.height - topPad - bottomPad, 1)

        func point(col: Int, depth: Int) -> CGPoint {
            CGPoint(x: size.width * (CGFloat(col) + 0.5) / CGFloat(cols),
                    y: topPad + usableH * CGFloat(depth) / CGFloat(levels))
        }

        let nodes = layout.nodes.map {
            PlacedNode(id: $0.id, value: $0.value, state: $0.state, pointer: $0.pointer,
                       point: point(col: $0.col, depth: $0.depth))
        }
        let edges = layout.edges.map {
            PlacedEdge(id: $0.id,
                       from: point(col: $0.parentCol, depth: $0.parentDepth),
                       to: point(col: $0.childCol, depth: $0.childDepth))
        }
        return PlacedTree(nodes: nodes, edges: edges, nodeSize: nodeSize)
    }
}

private struct PlacedTree {
    let nodes: [PlacedNode]
    let edges: [PlacedEdge]
    let nodeSize: CGFloat
}

private struct PlacedNode: Identifiable {
    let id: String
    let value: String
    let state: HighlightState?
    let pointer: String?
    let point: CGPoint
}

private struct PlacedEdge: Identifiable {
    let id: String
    let from: CGPoint
    let to: CGPoint
}

/// Flattens a binary tree into positioned nodes + edges. Columns come from an
/// in-order walk (left subtree, self, right subtree), which keeps subtrees from
/// overlapping; depth gives the row.
private struct TreeLayout {
    struct Node {
        let id: String
        let value: String
        let state: HighlightState?
        let pointer: String?
        let col: Int
        let depth: Int
    }
    struct Edge {
        let id: String
        let parentCol: Int
        let parentDepth: Int
        let childCol: Int
        let childDepth: Int
    }

    private(set) var nodes: [Node] = []
    private(set) var edges: [Edge] = []
    private(set) var totalCols = 0
    private(set) var maxDepth = 0

    init(root: TreeNode?) {
        var counter = 0
        _ = place(root, path: "root", depth: 0, counter: &counter)
        totalCols = counter
    }

    @discardableResult
    private mutating func place(_ node: TreeNode?, path: String, depth: Int, counter: inout Int) -> Int? {
        guard let node else { return nil }
        let leftCol = place(node.left, path: path + "L", depth: depth + 1, counter: &counter)
        let myCol = counter
        counter += 1
        maxDepth = max(maxDepth, depth)
        let rightCol = place(node.right, path: path + "R", depth: depth + 1, counter: &counter)

        nodes.append(Node(id: path, value: node.value.display, state: node.state,
                          pointer: node.pointer, col: myCol, depth: depth))
        if let leftCol {
            edges.append(Edge(id: path + "L", parentCol: myCol, parentDepth: depth,
                              childCol: leftCol, childDepth: depth + 1))
        }
        if let rightCol {
            edges.append(Edge(id: path + "R", parentCol: myCol, parentDepth: depth,
                              childCol: rightCol, childDepth: depth + 1))
        }
        return myCol
    }
}

private struct TreeNodeView: View {
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

private struct TreePointerBadge: View {
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
