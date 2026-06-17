import XCTest
@testable import LearnKitKit

final class LessonDecodingTests: XCTestCase {

    func testDecodesLessonWithPointersAndHighlights() throws {
        let json = """
        {
          "schemaVersion": 1,
          "id": "valid-palindrome",
          "subject": "dsa",
          "track": "two-pointers",
          "title": "Valid Palindrome",
          "difficulty": "easy",
          "summary": "Two pointers from both ends.",
          "steps": [
            { "caption": "Intro", "visual": { "type": "array", "cells": ["r", "a", "r"] } },
            { "caption": "Compare ends", "visual": {
                "type": "array",
                "cells": ["r", "a", "r"],
                "pointers": [{ "label": "L", "index": 0 }, { "label": "R", "index": 2 }],
                "highlights": [{ "index": 0, "state": "match" }, { "index": 2, "state": "match" }]
            } }
          ]
        }
        """
        let lesson = try JSONDecoder().decode(Lesson.self, from: Data(json.utf8))

        XCTAssertEqual(lesson.id, "valid-palindrome")
        XCTAssertEqual(lesson.difficulty, .easy)
        XCTAssertEqual(lesson.steps.count, 2)

        guard case .array(let intro) = lesson.steps[0].visual else {
            return XCTFail("step 0 should decode as an array visual")
        }
        XCTAssertTrue(intro.pointers.isEmpty)         // omitted pointers default to []
        XCTAssertTrue(intro.highlights.isEmpty)

        guard case .array(let compare) = lesson.steps[1].visual else {
            return XCTFail("step 1 should decode as an array visual")
        }
        XCTAssertEqual(compare.cells.map(\.display), ["r", "a", "r"])
        XCTAssertEqual(compare.pointers.first?.label, "L")
        XCTAssertEqual(compare.highlightState(for: 0), .match)
        XCTAssertNil(compare.highlightState(for: 1))
    }

    func testDecodesGridVisualWithPointerAndRegion() throws {
        let json = """
        {
          "type": "grid",
          "rows": [[1, 2, 3], [4, 5, 6], [7, 8, 9]],
          "pointers": [{ "label": "cur", "row": 0, "col": 2 }],
          "highlights": [
            { "rows": [0, 0], "cols": [0, 2], "state": "active" },
            { "row": 2, "col": 2, "state": "done" }
          ]
        }
        """
        let visual = try JSONDecoder().decode(GridVisual.self, from: Data(json.utf8))

        XCTAssertEqual(visual.rowCount, 3)
        XCTAssertEqual(visual.colCount, 3)
        XCTAssertEqual(visual.pointers.first?.label, "cur")
        XCTAssertEqual(visual.highlightState(row: 0, col: 1), .active)  // inside the row region
        XCTAssertEqual(visual.highlightState(row: 2, col: 2), .done)    // single cell
        XCTAssertNil(visual.highlightState(row: 1, col: 1))
    }

    func testDecodesTreeVisualWithNestedNodesAndState() throws {
        let json = """
        {
          "type": "tree",
          "root": {
            "value": 4, "state": "active", "pointer": "cur",
            "left": { "value": 2 },
            "right": { "value": 7, "right": { "value": 9, "state": "done" } }
          }
        }
        """
        let visual = try JSONDecoder().decode(TreeVisual.self, from: Data(json.utf8))

        XCTAssertEqual(visual.root?.value.display, "4")
        XCTAssertEqual(visual.root?.state, .active)
        XCTAssertEqual(visual.root?.pointer, "cur")
        XCTAssertEqual(visual.root?.left?.value.display, "2")
        XCTAssertNil(visual.root?.left?.left)            // omitted children default to nil
        XCTAssertNil(visual.root?.left?.state)           // omitted state defaults to nil
        XCTAssertEqual(visual.root?.right?.right?.state, .done)
    }

    func testStepDispatchesVisualByType() throws {
        let json = """
        { "caption": "fill the grid", "visual": { "type": "grid", "rows": [[1, 2], [3, 4]] } }
        """
        let step = try JSONDecoder().decode(Step.self, from: Data(json.utf8))

        guard case .grid(let g) = step.visual else {
            return XCTFail("a step with a grid visual should decode as .grid")
        }
        XCTAssertEqual(g.rowCount, 2)
        XCTAssertEqual(g.colCount, 2)
        XCTAssertTrue(g.pointers.isEmpty)             // omitted pointers default to []
    }

    func testDecodesNumericCellsAndRangeHighlight() throws {
        let json = """
        { "type": "array", "cells": [3, 1, 4], "highlights": [{ "range": [0, 1], "state": "active" }] }
        """
        let visual = try JSONDecoder().decode(ArrayVisual.self, from: Data(json.utf8))

        XCTAssertEqual(visual.cells.map(\.display), ["3", "1", "4"])
        XCTAssertEqual(visual.highlightState(for: 0), .active)
        XCTAssertEqual(visual.highlightState(for: 1), .active)
        XCTAssertNil(visual.highlightState(for: 2))
    }
}
