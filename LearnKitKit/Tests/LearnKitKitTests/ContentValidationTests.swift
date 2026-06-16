import XCTest
@testable import LearnKitKit

/// Decodes and validates every Lesson the manifest points to, reading the real
/// files from the repo's Content/ directory. Located relative to this source
/// file (via #filePath) so it works regardless of the test's working directory.
final class ContentValidationTests: XCTestCase {

    private func contentDirectory() -> URL {
        URL(filePath: #filePath)         // .../LearnKitKit/Tests/LearnKitKitTests/ContentValidationTests.swift
            .deletingLastPathComponent() // LearnKitKitTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // LearnKitKit
            .deletingLastPathComponent() // learnkit (repo root)
            .appending(path: "Content")
    }

    func testEveryManifestLessonDecodesAndIsValid() throws {
        let content = contentDirectory()
        let manifestURL = content.appending(path: "manifest.json")
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: manifestURL))

        var validated = 0
        for subject in manifest.subjects {
            for track in subject.tracks {
                for ref in track.lessons {
                    let url = content.appending(path: ref.file)
                    // A manifest entry may list a lesson whose JSON isn't generated yet.
                    guard FileManager.default.fileExists(atPath: url.path) else { continue }

                    let lesson = try JSONDecoder().decode(Lesson.self, from: Data(contentsOf: url))
                    XCTAssertEqual(lesson.id, ref.id, "\(ref.file): id doesn't match manifest")
                    let issues = ContentValidator.issues(in: lesson)
                    XCTAssertTrue(issues.isEmpty, "\(ref.file):\n - " + issues.joined(separator: "\n - "))
                    validated += 1
                }
            }
        }

        XCTAssertGreaterThan(validated, 0, "No lessons were validated — check the Content path")
    }
}
