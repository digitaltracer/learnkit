import SwiftUI
import XCTest
@testable import LearnKitKit

#if os(macOS)
import AppKit
#endif

/// The article-reader counterpart to `VisualRenderTests`: render the scrollable
/// article body to an image and assert it isn't empty — the automated proxy for
/// "the reader compiles and draws all four prose block kinds without crashing"
/// (we can't eyeball it without a simulator; see ADR 0009).
@MainActor
final class ArticleRenderTests: XCTestCase {

    func testArticleReaderRendersNonEmptyImage() throws {
        let json = """
        {
          "schemaVersion": 1,
          "id": "scaling-basics",
          "subject": "system-design",
          "track": "fundamentals",
          "title": "Scaling: Vertical vs Horizontal",
          "format": "article",
          "summary": "Two fundamental ways to add capacity.",
          "blocks": [
            { "type": "paragraph", "text": "When a system runs out of capacity, you scale up or scale out." },
            { "type": "heading", "text": "Scaling up" },
            { "type": "bullets", "items": ["Simplest path", "One source of truth"] },
            { "type": "callout", "kind": "warning", "title": "The ceiling", "text": "There is a largest machine money can buy." }
          ]
        }
        """
        let lesson = try JSONDecoder().decode(Lesson.self, from: Data(json.utf8))

        let renderer = ImageRenderer(content:
            ArticleReader(lesson: lesson)
                .environment(LessonProgressStore())
                .frame(width: 390, height: 844)
        )

        #if os(macOS)
        let image = try XCTUnwrap(renderer.nsImage, "article reader produced no image")
        #else
        let image = try XCTUnwrap(renderer.uiImage, "article reader produced no image")
        #endif
        XCTAssertGreaterThan(image.size.width, 0, "article reader image width")
        XCTAssertGreaterThan(image.size.height, 0, "article reader image height")
    }
}
