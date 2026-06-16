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
            let count = step.visual.cells.count
            let where_ = "\(lesson.id) step \(i + 1)"

            if count == 0 {
                issues.append("\(where_): visual has no cells")
            }

            for pointer in step.visual.pointers where pointer.index < 0 || pointer.index >= count {
                issues.append("\(where_): pointer '\(pointer.label)' index \(pointer.index) out of bounds (0..<\(count))")
            }

            for highlight in step.visual.highlights {
                if let index = highlight.index, index < 0 || index >= count {
                    issues.append("\(where_): highlight index \(index) out of bounds (0..<\(count))")
                }
                if let range = highlight.range {
                    if range.count != 2 || range[0] < 0 || range[1] >= count || range[0] > range[1] {
                        issues.append("\(where_): highlight range \(range) invalid for \(count) cells")
                    }
                }
            }

            if step.visual.style == .bars && step.visual.cells.contains(where: { $0.numericValue == nil }) {
                issues.append("\(where_): style 'bars' requires all cells to be numeric")
            }
        }

        return issues
    }
}
