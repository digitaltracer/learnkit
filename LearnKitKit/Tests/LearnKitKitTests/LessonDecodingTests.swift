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

        let intro = lesson.steps[0].visual
        XCTAssertTrue(intro.pointers.isEmpty)         // omitted pointers default to []
        XCTAssertTrue(intro.highlights.isEmpty)

        let compare = lesson.steps[1].visual
        XCTAssertEqual(compare.cells.map(\.display), ["r", "a", "r"])
        XCTAssertEqual(compare.pointers.first?.label, "L")
        XCTAssertEqual(compare.highlightState(for: 0), .match)
        XCTAssertNil(compare.highlightState(for: 1))
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
