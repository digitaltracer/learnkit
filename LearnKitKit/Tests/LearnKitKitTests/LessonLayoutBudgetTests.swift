import XCTest
@testable import LearnKitKit

/// Guards the "one-screen rule" (see CLAUDE.md): a lesson must fit a single phone
/// screen without clipping or horizontal overflow. The renderer is now elastic —
/// the visual band scales with available height and the player scrolls as a last
/// resort — but a visual that is too *wide* (too many cells) or a caption with too
/// many lines still reads as broken. These caps keep authored content inside what
/// the smallest supported device can show comfortably.
///
/// If a new lesson trips a cap, the fix is to shrink the example (fewer cells, a
/// smaller tree) or tighten the caption — not to raise the cap.
final class LessonLayoutBudgetTests: XCTestCase {

    // Width-bound (cells must stay readable side by side on the narrowest device).
    private let maxArrayCells = 8
    private let maxGridColumns = 7
    private let maxGridCells = 24
    private let maxTreeNodes = 15
    private let maxTreeDepth = 5
    private let maxRTreeLeaves = 8
    private let maxRTreeDepth = 5
    private let maxIntervalRows = 6
    // Height-bound (each sentence renders on its own line in the instruction area).
    private let maxCaptionSentences = 4

    private func contentDirectory() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Content")
    }

    func testEveryLessonFitsTheLayoutBudget() throws {
        let content = contentDirectory()
        let manifest = try JSONDecoder().decode(Manifest.self,
                                                from: Data(contentsOf: content.appending(path: "manifest.json")))
        var issues: [String] = []

        for subject in manifest.subjects {
            for track in subject.tracks {
                for ref in track.lessons {
                    let url = content.appending(path: ref.file)
                    guard FileManager.default.fileExists(atPath: url.path) else { continue }
                    let lesson = try JSONDecoder().decode(Lesson.self, from: Data(contentsOf: url))
                    issues += budgetIssues(in: lesson)
                }
            }
        }

        XCTAssertTrue(issues.isEmpty,
                      "Lessons exceed the one-screen layout budget:\n - " + issues.joined(separator: "\n - "))
    }

    private func budgetIssues(in lesson: Lesson) -> [String] {
        var issues: [String] = []
        for (i, step) in lesson.steps.enumerated() {
            let at = "\(lesson.id) step \(i + 1)"

            let sentences = sentenceCount(step.caption)
            if sentences > maxCaptionSentences {
                issues.append("\(at): caption has \(sentences) sentences (max \(maxCaptionSentences))")
            }

            switch step.visual {
            case .array(let v):
                if v.cells.count > maxArrayCells {
                    issues.append("\(at): array has \(v.cells.count) cells (max \(maxArrayCells))")
                }
            case .list(let v):
                if v.nodes.count > maxArrayCells {
                    issues.append("\(at): list has \(v.nodes.count) nodes (max \(maxArrayCells))")
                }
            case .grid(let v):
                if v.colCount > maxGridColumns {
                    issues.append("\(at): grid has \(v.colCount) columns (max \(maxGridColumns))")
                }
                let cells = v.rows.reduce(0) { $0 + $1.count }
                if cells > maxGridCells {
                    issues.append("\(at): grid has \(cells) cells (max \(maxGridCells))")
                }
            case .tree(let v):
                let s = treeStats(v.root)
                if s.nodes > maxTreeNodes { issues.append("\(at): tree has \(s.nodes) nodes (max \(maxTreeNodes))") }
                if s.depth > maxTreeDepth { issues.append("\(at): tree depth \(s.depth) (max \(maxTreeDepth))") }
            case .rtree(let v):
                let s = rtreeStats(v.root)
                if s.leaves > maxRTreeLeaves { issues.append("\(at): rtree has \(s.leaves) leaves (max \(maxRTreeLeaves))") }
                if s.depth > maxRTreeDepth { issues.append("\(at): rtree depth \(s.depth) (max \(maxRTreeDepth))") }
            case .intervals(let v):
                if v.rows.count > maxIntervalRows {
                    issues.append("\(at): intervals has \(v.rows.count) rows (max \(maxIntervalRows))")
                }
            case .graph, .hashmap:
                break
            }
        }
        return issues
    }

    /// Mirrors `InstructionView`: split on sentence-ending punctuation followed by a
    /// space, so the count matches the number of lines actually rendered.
    private func sentenceCount(_ caption: String) -> Int {
        var count = 0
        var current = ""
        let chars = Array(caption)
        for (i, ch) in chars.enumerated() {
            current.append(ch)
            if ch == "." || ch == "!" || ch == "?" {
                let next = i + 1 < chars.count ? chars[i + 1] : " "
                if next == " " {
                    if !current.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
                    current = ""
                }
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty { count += 1 }
        return max(count, 1)
    }

    private func treeStats(_ node: TreeNode?) -> (nodes: Int, depth: Int) {
        guard let node else { return (0, 0) }
        let l = treeStats(node.left)
        let r = treeStats(node.right)
        return (1 + l.nodes + r.nodes, 1 + max(l.depth, r.depth))
    }

    private func rtreeStats(_ node: RNode?) -> (leaves: Int, depth: Int) {
        guard let node else { return (0, 0) }
        if node.children.isEmpty { return (1, 1) }
        var leaves = 0
        var depth = 0
        for child in node.children {
            let s = rtreeStats(child)
            leaves += s.leaves
            depth = max(depth, s.depth)
        }
        return (leaves, 1 + depth)
    }
}
