import XCTest
@testable import LearnKitKit

@MainActor
final class LessonProgressStoreTests: XCTestCase {

    func testPersistsProgressBetweenStoreInstances() {
        let suiteName = "LearnKitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = LessonProgressStore(defaults: defaults)
        store.recordStep(lessonID: "valid-palindrome", stepIndex: 3, stepCount: 8)

        let restored = LessonProgressStore(defaults: defaults)
        let record = restored.record(for: "valid-palindrome")

        XCTAssertEqual(record?.stepIndex, 3)
        XCTAssertEqual(record?.stepCount, 8)
        XCTAssertEqual(record?.completed, false)

        restored.markCompleted(lessonID: "valid-palindrome", stepCount: 8)
        let completed = LessonProgressStore(defaults: defaults)
        XCTAssertEqual(completed.record(for: "valid-palindrome")?.completed, true)

        defaults.removePersistentDomain(forName: suiteName)
    }
}
