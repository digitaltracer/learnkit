import Foundation

/// Structural checks for a Lesson beyond "it decodes". Because Lessons are
/// LLM-generated, these catch the common authoring mistakes — pointers or
/// highlights referencing cells that don't exist, empty lessons.
enum ContentValidator {
    static func issues(in manifest: Manifest) -> [String] {
        var issues: [String] = []

        if manifest.schemaVersion != 1 {
            issues.append("manifest: schemaVersion \(manifest.schemaVersion) is unsupported")
        }
        if manifest.subjects.isEmpty {
            issues.append("manifest: has no subjects")
        }

        var subjectIDs = Set<String>()
        for subject in manifest.subjects {
            if !isKebabCase(subject.id) {
                issues.append("manifest: subject id '\(subject.id)' must be kebab-case")
            }
            if subject.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append("manifest: subject '\(subject.id)' has an empty title")
            }
            if !subjectIDs.insert(subject.id).inserted {
                issues.append("manifest: duplicate subject id '\(subject.id)'")
            }

            var trackIDs = Set<String>()
            for track in subject.tracks {
                if !isKebabCase(track.id) {
                    issues.append("manifest: track id '\(track.id)' must be kebab-case")
                }
                if track.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append("manifest: track '\(track.id)' has an empty title")
                }
                if !trackIDs.insert(track.id).inserted {
                    issues.append("manifest: duplicate track id '\(track.id)' in subject '\(subject.id)'")
                }

                var lessonIDs = Set<String>()
                for ref in track.lessons {
                    if !isKebabCase(ref.id) {
                        issues.append("manifest: lesson id '\(ref.id)' must be kebab-case")
                    }
                    if ref.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        issues.append("manifest: lesson '\(ref.id)' has an empty title")
                    }
                    if ref.file.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        issues.append("manifest: lesson '\(ref.id)' has an empty file path")
                    }
                    if !lessonIDs.insert(ref.id).inserted {
                        issues.append("manifest: duplicate lesson id '\(ref.id)' in track '\(track.id)'")
                    }
                }
            }
        }

        return issues
    }

    static func issues(in lesson: Lesson) -> [String] {
        issues(in: lesson, manifestRef: nil)
    }

    static func issues(in lesson: Lesson, manifestRef ref: LessonRef) -> [String] {
        issues(in: lesson, manifestRef: Optional(ref))
    }

    private static func issues(in lesson: Lesson, manifestRef ref: LessonRef?) -> [String] {
        var issues: [String] = []

        if lesson.schemaVersion != 1 {
            issues.append("\(lesson.id): schemaVersion \(lesson.schemaVersion) is unsupported")
        }
        if !isKebabCase(lesson.id) {
            issues.append("\(lesson.id): id must be kebab-case")
        }
        if !isKebabCase(lesson.subject) {
            issues.append("\(lesson.id): subject '\(lesson.subject)' must be kebab-case")
        }
        if !isKebabCase(lesson.track) {
            issues.append("\(lesson.id): track '\(lesson.track)' must be kebab-case")
        }
        if lesson.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("\(lesson.id): title is empty")
        }
        if let ref {
            if lesson.id != ref.id {
                issues.append("\(ref.file): lesson id '\(lesson.id)' doesn't match manifest id '\(ref.id)'")
            }
            if lesson.title != ref.title {
                issues.append("\(ref.file): lesson title '\(lesson.title)' doesn't match manifest title '\(ref.title)'")
            }
            if lesson.difficulty != ref.difficulty {
                issues.append("\(ref.file): lesson difficulty doesn't match manifest difficulty")
            }
        }

        switch lesson.format {
        case .steps:
            issues += stepsIssues(lesson)
        case .article:
            if !lesson.steps.isEmpty {
                issues.append("\(lesson.id): an article lesson must not set steps")
            }
            issues += articleIssues(lesson)
        }

        return issues
    }

    /// Validates a `steps`-format lesson: the 3...12 step count, per-caption length,
    /// and each step's visual. (An article must not carry steps.)
    private static func stepsIssues(_ lesson: Lesson) -> [String] {
        var issues: [String] = []

        if !lesson.blocks.isEmpty {
            issues.append("\(lesson.id): a steps lesson must not set blocks")
        }
        if !(3...12).contains(lesson.steps.count) {
            issues.append("\(lesson.id): has \(lesson.steps.count) steps; expected 3...12")
        }

        for (i, step) in lesson.steps.enumerated() {
            let where_ = "\(lesson.id) step \(i + 1)"
            if step.caption.count > 160 {
                issues.append("\(where_): caption is \(step.caption.count) characters; expected <=160")
            }
            issues += visualIssues(step.visual, at: where_)
        }

        return issues
    }

    /// Validates one `Visual`, dispatching to the per-primitive checker. Shared by
    /// `steps` lessons and the article `diagram` block, which embeds a Visual.
    private static func visualIssues(_ visual: Visual, at where_: String) -> [String] {
        switch visual {
        case .array(let v):        return arrayIssues(v, at: where_)
        case .grid(let v):         return gridIssues(v, at: where_)
        case .tree(let v):         return treeIssues(v, at: where_)
        case .list(let v):         return listIssues(v, at: where_)
        case .graph(let v):        return graphIssues(v, at: where_)
        case .hashmap:             return []   // no index/reference constraints to check
        case .intervals(let v):    return intervalIssues(v, at: where_)
        case .rtree(let v):        return rtreeIssues(v, at: where_)
        case .architecture(let v): return architectureIssues(v, at: where_)
        }
    }

    /// Validates an `article`-format lesson: non-empty blocks and non-empty block
    /// content. Articles scroll, so there is no step-count or one-screen budget.
    private static func articleIssues(_ lesson: Lesson) -> [String] {
        var issues: [String] = []

        if lesson.blocks.isEmpty {
            issues.append("\(lesson.id): article has no blocks")
        }

        for (i, block) in lesson.blocks.enumerated() {
            let where_ = "\(lesson.id) block \(i + 1)"
            switch block {
            case .heading(let b):
                if isBlank(b.text) { issues.append("\(where_): heading text is empty") }
                if let level = b.level, !(1...2).contains(level) {
                    issues.append("\(where_): heading level \(level) must be 1 or 2")
                }
            case .paragraph(let b):
                if isBlank(b.text) { issues.append("\(where_): paragraph text is empty") }
            case .bullets(let b):
                if b.items.isEmpty {
                    issues.append("\(where_): bullets has no items")
                }
                if b.items.contains(where: isBlank) {
                    issues.append("\(where_): a bullet item is empty")
                }
            case .callout(let b):
                if isBlank(b.text) { issues.append("\(where_): callout text is empty") }
            case .diagram(let b):
                issues += visualIssues(b.visual, at: "\(where_) diagram")
            }
        }

        return issues
    }

    private static func isBlank(_ s: String) -> Bool {
        s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        issues += duplicateLabelIssues(visual.pointers.map(\.label), kind: "pointer", at: where_)

        for highlight in visual.highlights {
            let hasIndex = highlight.index != nil
            let hasRange = highlight.range != nil
            if hasIndex == hasRange {
                issues.append("\(where_): highlight must set exactly one of index or range")
            }
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
        issues += duplicateLabelIssues(visual.pointers.map(\.label), kind: "pointer", at: where_)

        for h in visual.highlights {
            let hasCell = h.row != nil || h.col != nil
            let hasRegion = h.rows != nil || h.cols != nil
            if hasCell && hasRegion {
                issues.append("\(where_): highlight must set row+col or rows+cols, not both")
            }
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
            } else if h.row != nil || h.col != nil || h.rows != nil || h.cols != nil {
                issues.append("\(where_): highlight must set complete row+col or rows+cols coordinates")
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
        issues += duplicateLabelIssues(visual.pointers.map(\.label), kind: "pointer", at: where_)

        for highlight in visual.highlights {
            let hasIndex = highlight.index != nil
            let hasRange = highlight.range != nil
            if hasIndex == hasRange {
                issues.append("\(where_): highlight must set exactly one of index or range")
            }
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
            if node.x < 0 || node.x > 1 || node.y < 0 || node.y > 1 {
                issues.append("\(where_): node '\(node.id)' position (\(node.x),\(node.y)) must be in 0...1")
            }
            if let label = node.pointer, label.count > 3 {
                issues.append("\(where_): pointer label '\(label)' longer than 3 characters")
            }
        }
        issues += duplicateLabelIssues(visual.nodes.compactMap(\.pointer), kind: "pointer", at: where_)

        for edge in visual.edges {
            if !ids.contains(edge.from) { issues.append("\(where_): edge from unknown node '\(edge.from)'") }
            if !ids.contains(edge.to) { issues.append("\(where_): edge to unknown node '\(edge.to)'") }
        }

        return issues
    }

    /// Structural checks for the `architecture` Primitive (like `graph`): unique
    /// non-empty node ids, normalized positions, non-empty titles, and connectors
    /// and group members that reference real nodes. No index bounds — it is not
    /// index-addressed. See ADR 0010.
    private static func architectureIssues(_ visual: ArchitectureVisual, at where_: String) -> [String] {
        var issues: [String] = []

        if visual.nodes.isEmpty {
            issues.append("\(where_): architecture has no nodes")
        }

        var ids = Set<String>()
        for node in visual.nodes {
            if node.id.isEmpty { issues.append("\(where_): a node has an empty id") }
            if !ids.insert(node.id).inserted { issues.append("\(where_): duplicate node id '\(node.id)'") }
            if isBlank(node.title) { issues.append("\(where_): node '\(node.id)' has an empty title") }
            if node.x < 0 || node.x > 1 || node.y < 0 || node.y > 1 {
                issues.append("\(where_): node '\(node.id)' position (\(node.x),\(node.y)) must be in 0...1")
            }
        }

        for c in visual.connectors {
            if !ids.contains(c.from) { issues.append("\(where_): connector from unknown node '\(c.from)'") }
            if !ids.contains(c.to) { issues.append("\(where_): connector to unknown node '\(c.to)'") }
        }

        for (i, group) in visual.groups.enumerated() {
            for member in group.nodes where !ids.contains(member) {
                issues.append("\(where_): group \(i + 1) references unknown node '\(member)'")
            }
        }

        return issues
    }

    private static func intervalIssues(_ visual: IntervalsVisual, at where_: String) -> [String] {
        var issues: [String] = []

        if visual.rows.isEmpty {
            issues.append("\(where_): intervals has no rows")
        }
        if let axisMin = visual.axisMin, let axisMax = visual.axisMax, axisMin >= axisMax {
            issues.append("\(where_): axisMin \(axisMin) must be less than axisMax \(axisMax)")
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

    private static func duplicateLabelIssues(_ labels: [String], kind: String, at where_: String) -> [String] {
        var issues: [String] = []
        var seen = Set<String>()
        for label in labels {
            if label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append("\(where_): \(kind) label is empty")
            }
            if label.count > 3 {
                issues.append("\(where_): \(kind) label '\(label)' longer than 3 characters")
            }
            if !seen.insert(label).inserted {
                issues.append("\(where_): duplicate \(kind) label '\(label)'")
            }
        }
        return issues
    }

    private static func isKebabCase(_ value: String) -> Bool {
        value.range(of: #"^[a-z0-9]+(?:-[a-z0-9]+)*$"#, options: .regularExpression) != nil
    }
}
