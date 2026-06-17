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
            case .array(let v): issues += arrayIssues(v, at: where_)
            case .grid(let v):  issues += gridIssues(v, at: where_)
            case .tree(let v):  issues += treeIssues(v, at: where_)
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
}
