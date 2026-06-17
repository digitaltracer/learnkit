import Foundation

/// Structural checks for a Lesson beyond "it decodes". Because Lessons are
/// LLM-generated, these catch the common authoring mistakes — pointers or
/// highlights referencing cells that don't exist, empty lessons.
enum ContentValidator {
    static func issues(in lesson: Lesson) -> [String] {
        var issues: [String] = []

        if lesson.steps.isEmpty {
            issues.append("\(lesson.id): has no steps")
        }

        for (i, step) in lesson.steps.enumerated() {
            let where_ = "\(lesson.id) step \(i + 1)"
            switch step.visual {
            case .array(let v):     issues += arrayIssues(v, at: where_)
            case .grid(let v):      issues += gridIssues(v, at: where_)
            case .tree(let v):      issues += treeIssues(v, at: where_)
            case .list(let v):      issues += listIssues(v, at: where_)
            case .graph(let v):     issues += graphIssues(v, at: where_)
            case .hashmap:          break   // no index/reference constraints to check
            case .intervals(let v): issues += intervalIssues(v, at: where_)
            case .rtree(let v):     issues += rtreeIssues(v, at: where_)
            }
        }

        return issues
    }

    private static func arrayIssues(_ visual: ArrayVisual, at where_: String) -> [String] {
        var issues: [String] = []
        let count = visual.cells.count

        if count == 0 {
            issues.append("\(where_): visual has no cells")
        }

        for pointer in visual.pointers where pointer.index < 0 || pointer.index >= count {
            issues.append("\(where_): pointer '\(pointer.label)' index \(pointer.index) out of bounds (0..<\(count))")
        }

        for highlight in visual.highlights {
            if let index = highlight.index, index < 0 || index >= count {
                issues.append("\(where_): highlight index \(index) out of bounds (0..<\(count))")
            }
            if let range = highlight.range {
                if range.count != 2 || range[0] < 0 || range[1] >= count || range[0] > range[1] {
                    issues.append("\(where_): highlight range \(range) invalid for \(count) cells")
                }
            }
        }

        if visual.style == .bars && visual.cells.contains(where: { $0.numericValue == nil }) {
            issues.append("\(where_): style 'bars' requires all cells to be numeric")
        }

        return issues
    }

    private static func gridIssues(_ visual: GridVisual, at where_: String) -> [String] {
        var issues: [String] = []
        let rowCount = visual.rows.count

        if rowCount == 0 || visual.rows.allSatisfy(\.isEmpty) {
            issues.append("\(where_): grid has no cells")
            return issues
        }

        let colCount = visual.rows[0].count
        if visual.rows.contains(where: { $0.count != colCount }) {
            issues.append("\(where_): grid rows must all have the same length")
        }

        for p in visual.pointers where p.row < 0 || p.row >= rowCount || p.col < 0 || p.col >= colCount {
            issues.append("\(where_): pointer '\(p.label)' at (\(p.row),\(p.col)) out of bounds (\(rowCount)x\(colCount))")
        }

        for h in visual.highlights {
            if let row = h.row, let col = h.col {
                if row < 0 || row >= rowCount || col < 0 || col >= colCount {
                    issues.append("\(where_): highlight cell (\(row),\(col)) out of bounds (\(rowCount)x\(colCount))")
                }
            } else if let rows = h.rows, let cols = h.cols {
                let rowsBad = rows.count != 2 || rows[0] < 0 || rows[1] >= rowCount || rows[0] > rows[1]
                let colsBad = cols.count != 2 || cols[0] < 0 || cols[1] >= colCount || cols[0] > cols[1]
                if rowsBad || colsBad {
                    issues.append("\(where_): highlight region rows \(rows) cols \(cols) invalid for \(rowCount)x\(colCount)")
                }
            } else {
                issues.append("\(where_): highlight must set either row+col (one cell) or rows+cols (a region)")
            }
        }

        return issues
    }

    private static func treeIssues(_ visual: TreeVisual, at where_: String) -> [String] {
        var issues: [String] = []
        guard let root = visual.root else {
            issues.append("\(where_): tree has no root")
            return issues
        }
        walk(root, at: where_, into: &issues)
        return issues
    }

    private static func walk(_ node: TreeNode, at where_: String, into issues: inout [String]) {
        if let label = node.pointer, label.count > 3 {
            issues.append("\(where_): pointer label '\(label)' longer than 3 characters")
        }
        if let left = node.left { walk(left, at: where_, into: &issues) }
        if let right = node.right { walk(right, at: where_, into: &issues) }
    }

    private static func listIssues(_ visual: ListVisual, at where_: String) -> [String] {
        var issues: [String] = []
        let count = visual.nodes.count

        if count == 0 {
            issues.append("\(where_): list has no nodes")
        }

        for pointer in visual.pointers where pointer.index < 0 || pointer.index >= count {
            issues.append("\(where_): pointer '\(pointer.label)' index \(pointer.index) out of bounds (0..<\(count))")
        }

        for highlight in visual.highlights {
            if let index = highlight.index, index < 0 || index >= count {
                issues.append("\(where_): highlight index \(index) out of bounds (0..<\(count))")
            }
            if let range = highlight.range {
                if range.count != 2 || range[0] < 0 || range[1] >= count || range[0] > range[1] {
                    issues.append("\(where_): highlight range \(range) invalid for \(count) nodes")
                }
            }
        }

        for link in visual.links {
            if link.count != 2 || link[0] < 0 || link[0] >= count || link[1] < 0 || link[1] >= count {
                issues.append("\(where_): link \(link) out of bounds for \(count) nodes")
            }
        }

        return issues
    }

    private static func graphIssues(_ visual: GraphVisual, at where_: String) -> [String] {
        var issues: [String] = []

        if visual.nodes.isEmpty {
            issues.append("\(where_): graph has no nodes")
        }

        var ids = Set<String>()
        for node in visual.nodes {
            if node.id.isEmpty { issues.append("\(where_): a node has an empty id") }
            if !ids.insert(node.id).inserted { issues.append("\(where_): duplicate node id '\(node.id)'") }
            if let label = node.pointer, label.count > 3 {
                issues.append("\(where_): pointer label '\(label)' longer than 3 characters")
            }
        }

        for edge in visual.edges {
            if !ids.contains(edge.from) { issues.append("\(where_): edge from unknown node '\(edge.from)'") }
            if !ids.contains(edge.to) { issues.append("\(where_): edge to unknown node '\(edge.to)'") }
        }

        return issues
    }

    private static func intervalIssues(_ visual: IntervalsVisual, at where_: String) -> [String] {
        var issues: [String] = []

        if visual.rows.isEmpty {
            issues.append("\(where_): intervals has no rows")
        }
        for row in visual.rows where row.end < row.start {
            issues.append("\(where_): interval end \(row.end) is before start \(row.start)")
        }

        return issues
    }

    private static func rtreeIssues(_ visual: RTreeVisual, at where_: String) -> [String] {
        var issues: [String] = []
        guard let root = visual.root else {
            issues.append("\(where_): rtree has no root")
            return issues
        }
        walkRNode(root, at: where_, into: &issues)
        return issues
    }

    private static func walkRNode(_ node: RNode, at where_: String, into issues: inout [String]) {
        if let label = node.pointer, label.count > 3 {
            issues.append("\(where_): pointer label '\(label)' longer than 3 characters")
        }
        for child in node.children { walkRNode(child, at: where_, into: &issues) }
    }
}
