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

    func testDecodesListVisualWithLinksDefaultingForward() throws {
        let withLinks = """
        {
          "type": "list",
          "nodes": [1, 2, 3, 4],
          "links": [[1, 0], [2, 1], [3, 2]],
          "pointers": [{ "label": "cur", "index": 3 }],
          "highlights": [{ "range": [0, 2], "state": "done" }]
        }
        """
        let v = try JSONDecoder().decode(ListVisual.self, from: Data(withLinks.utf8))
        XCTAssertEqual(v.nodes.map(\.display), ["1", "2", "3", "4"])
        XCTAssertEqual(v.pointers.first?.label, "cur")
        XCTAssertEqual(v.highlightState(for: 1), .done)
        XCTAssertEqual(v.resolvedLinks.map(\.from), [1, 2, 3])
        XCTAssertEqual(v.resolvedLinks.map(\.to), [0, 1, 2])

        // Omitted links default to a consecutive forward chain.
        let noLinks = #"{ "type": "list", "nodes": [9, 8, 7] }"#
        let chain = try JSONDecoder().decode(ListVisual.self, from: Data(noLinks.utf8))
        XCTAssertEqual(chain.resolvedLinks.map(\.from), [0, 1])
        XCTAssertEqual(chain.resolvedLinks.map(\.to), [1, 2])
    }

    func testDecodesGraphVisualWithNodesAndEdges() throws {
        let json = """
        {
          "type": "graph",
          "nodes": [
            { "id": "1", "x": 0.2, "y": 0.2, "state": "done" },
            { "id": "2", "value": 2, "x": 0.8, "y": 0.2, "pointer": "cur" }
          ],
          "edges": [ { "from": "1", "to": "2", "directed": true, "weight": 5 } ]
        }
        """
        let v = try JSONDecoder().decode(GraphVisual.self, from: Data(json.utf8))
        XCTAssertEqual(v.nodes.count, 2)
        XCTAssertEqual(v.node(id: "1")?.state, .done)
        XCTAssertEqual(v.node(id: "2")?.display, "2")
        XCTAssertEqual(v.node(id: "2")?.pointer, "cur")
        XCTAssertEqual(v.edges.first?.directed, true)
        XCTAssertEqual(v.edges.first?.weight?.display, "5")
    }

    func testDecodesHashMapVisualWithProbe() throws {
        let json = """
        {
          "type": "hashmap",
          "entries": [ { "key": 2, "value": 0, "state": "match" } ],
          "probe": { "key": 2, "found": true }
        }
        """
        let v = try JSONDecoder().decode(HashMapVisual.self, from: Data(json.utf8))
        XCTAssertEqual(v.entries.first?.key.display, "2")
        XCTAssertEqual(v.entries.first?.state, .match)
        XCTAssertEqual(v.probe?.found, true)

        // entries and probe both default away when omitted.
        let empty = try JSONDecoder().decode(HashMapVisual.self, from: Data(#"{ "type": "hashmap" }"#.utf8))
        XCTAssertTrue(empty.entries.isEmpty)
        XCTAssertNil(empty.probe)
    }

    func testDecodesIntervalsVisualWithDefaultBounds() throws {
        let json = #"{ "type": "intervals", "rows": [ { "start": 1, "end": 3 }, { "start": 8, "end": 10, "state": "done" } ] }"#
        let v = try JSONDecoder().decode(IntervalsVisual.self, from: Data(json.utf8))
        XCTAssertEqual(v.rows.count, 2)
        XCTAssertEqual(v.lowerBound, 0)     // min(0, smallest start)
        XCTAssertEqual(v.upperBound, 10)    // largest end
        XCTAssertEqual(v.rows[1].state, .done)
    }

    func testDecodesRTreeVisualWithChildrenAndEdges() throws {
        let json = """
        {
          "type": "rtree",
          "root": {
            "value": "[]",
            "children": [
              { "value": "[1]", "edge": "+1", "state": "active" },
              { "value": "[]", "edge": "-1" }
            ]
          }
        }
        """
        let v = try JSONDecoder().decode(RTreeVisual.self, from: Data(json.utf8))
        XCTAssertEqual(v.root?.children.count, 2)
        XCTAssertEqual(v.root?.children.first?.edge, "+1")
        XCTAssertEqual(v.root?.children.first?.state, .active)
        XCTAssertTrue(v.root?.children.last?.children.isEmpty ?? false)   // omitted children default to []
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

    func testDecodesArticleFormatWithProseBlocks() throws {
        let json = """
        {
          "schemaVersion": 1,
          "id": "scaling-basics",
          "subject": "system-design",
          "track": "fundamentals",
          "title": "Scaling",
          "format": "article",
          "summary": "Two ways to add capacity.",
          "blocks": [
            { "type": "paragraph", "text": "Intro." },
            { "type": "heading", "text": "Scaling up", "level": 2 },
            { "type": "bullets", "items": ["a", "b"], "ordered": true },
            { "type": "callout", "kind": "warning", "title": "Ceiling", "text": "Costs climb." }
          ]
        }
        """
        let lesson = try JSONDecoder().decode(Lesson.self, from: Data(json.utf8))

        XCTAssertEqual(lesson.format, .article)
        XCTAssertTrue(lesson.steps.isEmpty)            // an article carries no steps
        XCTAssertEqual(lesson.blocks.count, 4)

        guard case .paragraph(let p) = lesson.blocks[0] else { return XCTFail("block 0 should be a paragraph") }
        XCTAssertEqual(p.text, "Intro.")
        guard case .heading(let h) = lesson.blocks[1] else { return XCTFail("block 1 should be a heading") }
        XCTAssertEqual(h.level, 2)
        guard case .bullets(let b) = lesson.blocks[2] else { return XCTFail("block 2 should be bullets") }
        XCTAssertEqual(b.items, ["a", "b"])
        XCTAssertEqual(b.ordered, true)
        guard case .callout(let c) = lesson.blocks[3] else { return XCTFail("block 3 should be a callout") }
        XCTAssertEqual(c.kind, .warning)
        XCTAssertEqual(c.title, "Ceiling")
    }

    func testStepsFormatDefaultsWhenOmitted() throws {
        let json = """
        {
          "schemaVersion": 1, "id": "x", "subject": "dsa", "track": "two-pointers", "title": "X",
          "steps": [ { "caption": "a", "visual": { "type": "array", "cells": [1] } } ]
        }
        """
        let lesson = try JSONDecoder().decode(Lesson.self, from: Data(json.utf8))

        XCTAssertEqual(lesson.format, .steps)          // absent format defaults to steps
        XCTAssertTrue(lesson.blocks.isEmpty)           // absent blocks default to []
        XCTAssertEqual(lesson.steps.count, 1)
    }

    func testRejectsUnknownBlockType() {
        let json = #"{ "type": "video", "src": "x" }"#
        XCTAssertThrowsError(try JSONDecoder().decode(Block.self, from: Data(json.utf8)))
    }
}
