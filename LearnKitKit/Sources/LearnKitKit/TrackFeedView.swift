import SwiftUI

/// A Track opened as a vertical feed: the Overview page first, then one page per
/// Lesson. Swipe up/down to move through the feed; inside a Lesson, tap or swipe
/// left/right to advance Steps. This is the two-axis model — vertical = lessons,
/// horizontal = steps.
struct TrackFeedView: View {
    let track: TrackNode
    let bundle: Bundle
    var initialLessonID: String? = nil

    @Environment(LessonProgressStore.self) private var progressStore
    @State private var lessons: [Lesson] = []
    @State private var loadFailures: [LessonLoadFailure] = []
    @State private var loadError: String?
    /// The page currently snapped into view. Two-way bound to the scroll position:
    /// it tracks swipes and, when the jump sheet writes it, scrolls straight there.
    @State private var visibleID: String?
    /// Whether the compact jump-to-lesson sheet is presented.
    @State private var showJumpSheet = false

    var body: some View {
        Group {
            if let loadError {
                MessageView(systemImage: "exclamationmark.triangle",
                            title: "Couldn't load track",
                            message: loadError)
            } else {
                feed
            }
        }
        .navigationTitle(track.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !lessons.isEmpty || !loadFailures.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button { showJumpSheet = true } label: {
                        Label("Jump to lesson", systemImage: "list.bullet")
                    }
                }
            }
        }
        .sheet(isPresented: $showJumpSheet) {
            JumpToLessonSheet(
                lessons: lessons,
                showOverview: track.overview != nil,
                overviewID: Self.overviewID,
                showFailures: !loadFailures.isEmpty,
                failuresID: Self.failuresID,
                currentID: visibleID ?? defaultID
            ) { id in
                showJumpSheet = false
                withAnimation(.easeInOut(duration: 0.35)) { visibleID = id }
            }
            .environment(progressStore)
        }
        .task {
            guard lessons.isEmpty, loadError == nil else { return }
            let loaded = Self.loadLessons(track.lessons, bundle: bundle)
            lessons = loaded.lessons
            loadFailures = loaded.failures
            if let initialLessonID, lessons.contains(where: { $0.id == initialLessonID }) {
                visibleID = initialLessonID
            }
            if lessons.isEmpty && loadFailures.isEmpty && track.overview == nil {
                loadError = "No lessons or overview are available for this track yet."
            }
        }
    }

    private static func loadLessons(_ refs: [LessonRef], bundle: Bundle) -> (lessons: [Lesson], failures: [LessonLoadFailure]) {
        var lessons: [Lesson] = []
        var failures: [LessonLoadFailure] = []

        for ref in refs {
            do {
                lessons.append(try ContentStore.loadLesson(ref, bundle: bundle))
            } catch {
                let message = (error as? ContentError)?.errorDescription ?? error.localizedDescription
                failures.append(LessonLoadFailure(ref: ref, message: message))
            }
        }

        return (lessons, failures)
    }

    private var feed: some View {
        // The paging ScrollView extends through the bottom safe-area inset to the
        // screen edge and pages by that full distance. So each page must be
        // (safe height + bottom inset) tall to match the stride exactly; sizing it
        // to just the safe height leaves every page short by the inset, which shows
        // the next page's top (a difficulty badge) in the bottom band.
        GeometryReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    if let overview = track.overview {
                        page(OverviewPage(track: track, overview: overview), proxy: proxy)
                            .id(Self.overviewID)
                    }
                    if !loadFailures.isEmpty {
                        page(LoadFailuresPage(failures: loadFailures), proxy: proxy)
                            .id(Self.failuresID)
                    }
                    ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                        page(LessonPage(lesson: lesson,
                                        hasNext: index < lessons.count - 1,
                                        startStepIndex: progressStore.currentStepIndex(for: lesson.id,
                                                                                       stepCount: lesson.steps.count)),
                             proxy: proxy)
                            .id(lesson.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $visibleID)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private static let overviewID = "overview"
    private static let failuresID = "content-issues"

    /// The page shown when nothing has scrolled yet — the Overview if present,
    /// otherwise the first lesson.
    private var defaultID: String {
        if track.overview != nil { return Self.overviewID }
        if !loadFailures.isEmpty { return Self.failuresID }
        return lessons.first?.id ?? Self.overviewID
    }

    /// One feed page sized to exactly the ScrollView's paging stride: the content
    /// fills the safe height, then a bottom pad equal to the home-indicator inset
    /// extends the page to the screen edge — keeping the controls above the
    /// indicator while making page height == stride so no neighbor can peek in.
    private func page(_ content: some View, proxy: GeometryProxy) -> some View {
        content
            .frame(width: proxy.size.width, height: proxy.size.height)
            .padding(.bottom, proxy.safeAreaInsets.bottom)
            // Opaque, so a page can never bleed into a neighbour: while a jump
            // scroll settles, or when content slides under the translucent nav
            // bar, you see this page's background — never the lesson behind it.
            .background(.background)
            .clipped()
    }
}

private struct LessonLoadFailure: Identifiable, Hashable {
    let ref: LessonRef
    let message: String

    var id: String { ref.id }
}

/// The first page of a Track feed: what the pattern is and when to use it.
private struct OverviewPage: View {
    let track: TrackNode
    let overview: TrackOverview

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                if let icon = track.icon {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                }
                Text(track.title).font(.largeTitle.bold())
            }

            Text(overview.tagline)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Label("When to use it", systemImage: "checklist").font(.headline)
                ForEach(overview.whenToUse, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.subheadline)
                        Text(item)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Key idea", systemImage: "lightbulb").font(.headline)
                Text(overview.keyIdea)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let complexity = overview.complexity {
                Label(complexity, systemImage: "speedometer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                Image(systemName: "chevron.up")
                Text("Swipe up to start").font(.footnote)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// A feed page shown when one or more manifest entries failed to load.
private struct LoadFailuresPage: View {
    let failures: [LessonLoadFailure]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Content issues", systemImage: "exclamationmark.triangle")
                .font(.largeTitle.bold())
                .foregroundStyle(.orange)

            Text("\(failures.count) lesson \(failures.count == 1 ? "file" : "files") could not be loaded. The rest of the track is still available.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(failures) { failure in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(failure.ref.title)
                            .font(.headline)
                        Text(failure.ref.file)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text(failure.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                Image(systemName: "chevron.up")
                Text("Swipe up to continue").font(.footnote)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// A compact sheet listing the track's pages — Overview, any content issues, then
/// every lesson with its difficulty dot and progress — so you can jump straight to
/// one. Replaces the system Menu, which couldn't be made compact, small-font, or
/// smoothly animated. Presented as a content-sized sheet for a clean slide-in.
private struct JumpToLessonSheet: View {
    let lessons: [Lesson]
    let showOverview: Bool
    let overviewID: String
    let showFailures: Bool
    let failuresID: String
    let currentID: String
    let onSelect: (String) -> Void

    @Environment(LessonProgressStore.self) private var progressStore

    var body: some View {
        VStack(spacing: 0) {
            Text("Jump to lesson")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.top, 18)
                .padding(.bottom, 12)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if showOverview {
                            JumpRow(title: "Overview",
                                    leading: .symbol("doc.text"),
                                    trailing: .none,
                                    isCurrent: currentID == overviewID) { onSelect(overviewID) }
                                .id(overviewID)
                            rowDivider
                        }
                        if showFailures {
                            JumpRow(title: "Content issues",
                                    leading: .symbol("exclamationmark.triangle", tint: .orange),
                                    trailing: .none,
                                    isCurrent: currentID == failuresID) { onSelect(failuresID) }
                                .id(failuresID)
                            rowDivider
                        }
                        ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                            JumpRow(title: lesson.title,
                                    leading: .difficulty(lesson.difficulty),
                                    trailing: marker(for: lesson),
                                    isCurrent: currentID == lesson.id) { onSelect(lesson.id) }
                                .id(lesson.id)
                            if index < lessons.count - 1 { rowDivider }
                        }
                    }
                }
                .onAppear { proxy.scrollTo(currentID, anchor: .center) }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .presentationCornerRadius(28)
        #endif
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 46)
    }

    private func marker(for lesson: Lesson) -> JumpRow.Trailing {
        guard let record = progressStore.record(for: lesson.id) else { return .none }
        if record.completed { return .completed }
        let fraction = progressStore.progressFraction(for: lesson.id, stepCount: lesson.steps.count)
        return fraction > 0 ? .progress(fraction) : .none
    }
}

/// One row in the jump sheet: a leading marker (difficulty dot or symbol), the
/// title at a compact size, and a trailing state (the current page, a completion
/// check, or a progress ring).
private struct JumpRow: View {
    enum Leading { case symbol(String, tint: Color = .secondary); case difficulty(Difficulty?) }
    enum Trailing { case none, completed, progress(Double) }

    let title: String
    let leading: Leading
    let trailing: Trailing
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                leadingView.frame(width: 18)
                Text(title)
                    .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent ? Color.accentColor : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                trailingView
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 16)
            .background(isCurrent ? Color.accentColor.opacity(0.12) : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var leadingView: some View {
        switch leading {
        case let .symbol(name, tint):
            Image(systemName: name).font(.system(size: 15)).foregroundStyle(tint)
        case let .difficulty(difficulty):
            Circle().fill(color(for: difficulty)).frame(width: 9, height: 9)
        }
    }

    @ViewBuilder private var trailingView: some View {
        if isCurrent {
            Text("now")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
        } else {
            switch trailing {
            case .none:
                EmptyView()
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.green)
            case let .progress(fraction):
                ProgressRing(fraction: fraction).frame(width: 15, height: 15)
            }
        }
    }

    private func color(for difficulty: Difficulty?) -> Color {
        switch difficulty {
        case .easy:   return .green
        case .medium: return .orange
        case .hard:   return .red
        case nil:     return .secondary
        }
    }
}

/// A small ring filled to `fraction` — the in-progress marker in the jump sheet.
private struct ProgressRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.25), lineWidth: 2)
            Circle()
                .trim(from: 0, to: max(0, min(fraction, 1)))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
