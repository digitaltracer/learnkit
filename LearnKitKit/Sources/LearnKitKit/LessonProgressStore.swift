import Foundation
import Observation

struct LessonProgressRecord: Codable, Equatable, Sendable {
    var lessonID: String
    var stepIndex: Int
    var stepCount: Int
    var completed: Bool
    var updatedAt: Date

    var fraction: Double {
        guard stepCount > 0 else { return completed ? 1 : 0 }
        if completed { return 1 }
        return min(max(Double(stepIndex + 1) / Double(stepCount), 0), 1)
    }
}

@MainActor
@Observable
final class LessonProgressStore {
    private static let defaultsKey = "learnkit.lesson-progress.v1"

    private(set) var records: [String: LessonProgressRecord]

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let encoder = JSONEncoder()
    @ObservationIgnored private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? decoder.decode([String: LessonProgressRecord].self, from: data) {
            records = decoded
        } else {
            records = [:]
        }
    }

    func record(for lessonID: String) -> LessonProgressRecord? {
        records[lessonID]
    }

    func progressFraction(for lessonID: String, stepCount: Int) -> Double {
        guard let record = records[lessonID] else { return 0 }
        if record.completed { return 1 }
        let count = max(record.stepCount, stepCount)
        guard count > 0 else { return 0 }
        return min(max(Double(record.stepIndex + 1) / Double(count), 0), 1)
    }

    func completedCount(in lessons: [LessonRef]) -> Int {
        lessons.filter { records[$0.id]?.completed == true }.count
    }

    func currentStepIndex(for lessonID: String, stepCount: Int) -> Int {
        guard stepCount > 0, let record = records[lessonID], !record.completed else { return 0 }
        return min(max(record.stepIndex, 0), stepCount - 1)
    }

    func recordStep(lessonID: String, stepIndex: Int, stepCount: Int) {
        guard stepCount > 0 else { return }
        let clamped = min(max(stepIndex, 0), stepCount - 1)
        records[lessonID] = LessonProgressRecord(
            lessonID: lessonID,
            stepIndex: clamped,
            stepCount: stepCount,
            completed: false,
            updatedAt: Date()
        )
        save()
    }

    func markCompleted(lessonID: String, stepCount: Int) {
        let lastStep = max(stepCount - 1, 0)
        records[lessonID] = LessonProgressRecord(
            lessonID: lessonID,
            stepIndex: lastStep,
            stepCount: stepCount,
            completed: true,
            updatedAt: Date()
        )
        save()
    }

    func reset(lessonID: String, stepCount: Int) {
        records[lessonID] = LessonProgressRecord(
            lessonID: lessonID,
            stepIndex: 0,
            stepCount: stepCount,
            completed: false,
            updatedAt: Date()
        )
        save()
    }

    func resetAll() {
        records = [:]
        save()
    }

    private func save() {
        guard let data = try? encoder.encode(records) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}
