import SwiftUI

/// The app's root view. In your app target, set `LearnKitRootView()` as the
/// window's content. It loads the bundled manifest and presents the catalog.
public struct LearnKitRootView: View {
    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    @State private var progressStore = LessonProgressStore()
    @State private var manifest: Manifest?
    @State private var errorMessage: String?

    public var body: some View {
        NavigationStack {
            Group {
                if let manifest {
                    CatalogView(manifest: manifest, bundle: bundle)
                } else if let errorMessage {
                    MessageView(systemImage: "tray",
                                title: "No content",
                                message: errorMessage)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("LearnKit")
            .navigationDestination(for: TrackRoute.self) { route in
                TrackFeedView(track: route.track,
                              bundle: bundle,
                              initialLessonID: route.initialLessonID)
            }
        }
        .environment(progressStore)
        .task {
            guard manifest == nil, errorMessage == nil else { return }
            do {
                manifest = try ContentStore.loadManifest(bundle: bundle)
            } catch {
                errorMessage = (error as? ContentError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

struct TrackRoute: Hashable {
    let track: TrackNode
    let initialLessonID: String?
}

/// Home: a compact learning dashboard with resume, progress, search, and filters.
struct CatalogView: View {
    let manifest: Manifest
    let bundle: Bundle

    @Environment(LessonProgressStore.self) private var progressStore
    @State private var searchText = ""
    @State private var difficultyFilter: DifficultyFilter = .all
    /// Comma-joined ids of subjects the user has collapsed. Persisted so a
    /// collapsed subject stays collapsed across launches as more subjects (e.g.
    /// System Design) are added.
    @AppStorage("learnkit.collapsedSubjects") private var collapsedSubjectsRaw = ""

    var body: some View {
        List {
            if let item = continueItem {
                Section("Continue") {
                    NavigationLink(value: TrackRoute(track: item.track, initialLessonID: item.ref.id)) {
                        ContinueRow(item: item,
                                    progress: progressStore.record(for: item.ref.id))
                    }
                }
            }

            Section {
                Picker("Difficulty", selection: $difficultyFilter) {
                    ForEach(DifficultyFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            ForEach(filteredSubjects) { subject in
                let expanded = effectiveExpanded(subject.id)
                Section {
                    if expanded {
                        ForEach(subject.tracks) { track in
                            NavigationLink(value: TrackRoute(track: track, initialLessonID: nil)) {
                                TrackRow(track: track,
                                         completedCount: progressStore.completedCount(in: track.lessons))
                            }
                        }
                    }
                } header: {
                    SubjectHeader(
                        title: subject.title,
                        completed: progressStore.completedCount(in: subject.tracks.flatMap(\.lessons)),
                        total: subject.tracks.reduce(0) { $0 + $1.lessons.count },
                        isExpanded: expanded,
                        collapsible: !isFiltering
                    ) {
                        guard !isFiltering else { return }
                        withAnimation(.snappy) { toggleCollapse(subject.id) }
                    }
                }
            }

            if !matchingLessons.isEmpty {
                Section("Lessons") {
                    ForEach(matchingLessons) { item in
                        NavigationLink(value: TrackRoute(track: item.track, initialLessonID: item.ref.id)) {
                            LessonSearchRow(item: item,
                                            progress: progressStore.record(for: item.ref.id))
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search tracks and lessons")
        .overlay {
            if filteredSubjects.isEmpty && matchingLessons.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private var normalizedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// While searching or filtering by difficulty, subjects are always expanded
    /// so matches can't hide inside a collapsed subject.
    private var isFiltering: Bool {
        !normalizedSearch.isEmpty || difficultyFilter != .all
    }

    private var collapsedSubjects: Set<String> {
        Set(collapsedSubjectsRaw.split(separator: ",").map(String.init))
    }

    private func effectiveExpanded(_ subjectID: String) -> Bool {
        isFiltering || !collapsedSubjects.contains(subjectID)
    }

    private func toggleCollapse(_ subjectID: String) {
        var collapsed = collapsedSubjects
        if collapsed.contains(subjectID) {
            collapsed.remove(subjectID)
        } else {
            collapsed.insert(subjectID)
        }
        collapsedSubjectsRaw = collapsed.sorted().joined(separator: ",")
    }

    private var continueItem: CatalogLessonItem? {
        allLessons
            .compactMap { item -> (CatalogLessonItem, LessonProgressRecord)? in
                guard let record = progressStore.record(for: item.ref.id), !record.completed else { return nil }
                return (item, record)
            }
            .sorted { $0.1.updatedAt > $1.1.updatedAt }
            .first?
            .0
    }

    private var allLessons: [CatalogLessonItem] {
        manifest.subjects.flatMap { subject in
            subject.tracks.flatMap { track in
                track.lessons.map { ref in
                    CatalogLessonItem(subject: subject, track: track, ref: ref)
                }
            }
        }
    }

    private var filteredSubjects: [SubjectNode] {
        manifest.subjects.compactMap { subject in
            let tracks = subject.tracks.filter { trackMatches($0) }
            guard !tracks.isEmpty else { return nil }
            return SubjectNode(id: subject.id, title: subject.title, tracks: tracks)
        }
    }

    private var matchingLessons: [CatalogLessonItem] {
        guard !normalizedSearch.isEmpty || difficultyFilter != .all else { return [] }
        return allLessons.filter { item in
            lessonMatches(item.ref) && (normalizedSearch.isEmpty || item.ref.title.lowercased().contains(normalizedSearch))
        }
    }

    private func trackMatches(_ track: TrackNode) -> Bool {
        let searchMatches = normalizedSearch.isEmpty
            || track.title.lowercased().contains(normalizedSearch)
            || track.lessons.contains { $0.title.lowercased().contains(normalizedSearch) }
        let difficultyMatches = difficultyFilter == .all
            || track.lessons.contains { lessonMatches($0) }
        return searchMatches && difficultyMatches
    }

    private func lessonMatches(_ ref: LessonRef) -> Bool {
        switch difficultyFilter {
        case .all: return true
        case .easy: return ref.difficulty == .easy
        case .medium: return ref.difficulty == .medium
        case .hard: return ref.difficulty == .hard
        }
    }
}

private enum DifficultyFilter: String, CaseIterable, Identifiable {
    case all, easy, medium, hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

private struct CatalogLessonItem: Identifiable {
    let subject: SubjectNode
    let track: TrackNode
    let ref: LessonRef

    var id: String { "\(subject.id)/\(track.id)/\(ref.id)" }
}

private struct ContinueRow: View {
    let item: CatalogLessonItem
    let progress: LessonProgressRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Resume", systemImage: "play.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            Text(item.ref.title)
                .font(.headline)
            Text(item.track.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: progress?.fraction ?? 0)
                .accessibilityLabel("Lesson progress")
                .accessibilityValue(progressText)
            Text(progressText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .learnKitGlassPanel(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }

    private var progressText: String {
        guard let progress else { return "Not started" }
        if progress.completed { return "Complete" }
        return "Step \(progress.stepIndex + 1) of \(max(progress.stepCount, 1))"
    }
}

/// A collapsible subject section header: a leading disclosure chevron, the
/// subject title, and an at-a-glance completed/total count that stays visible
/// even when the subject is collapsed. The whole row is one tap target.
private struct SubjectHeader: View {
    let title: String
    let completed: Int
    let total: Int
    let isExpanded: Bool
    let collapsible: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .opacity(collapsible ? 1 : 0)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                    .textCase(nil)
                Spacer(minLength: 8)
                Text("\(completed)/\(total)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(completed) of \(total) lessons complete")
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(collapsible ? "Double tap to \(isExpanded ? "collapse" : "expand")" : "")
        .accessibilityAddTraits(.isButton)
    }
}

private struct TrackRow: View {
    let track: TrackNode
    let completedCount: Int

    var body: some View {
        HStack(spacing: 12) {
            if let icon = track.icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(track.title).font(.headline)
                    Spacer()
                    Text("\(completedCount)/\(track.lessons.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: progressValue)
                    .accessibilityLabel("Track progress")
                    .accessibilityValue("\(completedCount) of \(track.lessons.count) lessons complete")
                Text("\(track.lessons.count) lessons")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var progressValue: Double {
        guard !track.lessons.isEmpty else { return 0 }
        return Double(completedCount) / Double(track.lessons.count)
    }
}

private struct LessonSearchRow: View {
    let item: CatalogLessonItem
    let progress: LessonProgressRecord?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: progress?.completed == true ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(progress?.completed == true ? .green : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.ref.title)
                    .font(.headline)
                Text(item.track.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let difficulty = item.ref.difficulty {
                    Text(difficulty.rawValue.capitalized)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct MessageView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
    }
}
