import SwiftUI

/// Routes to one article-format Lesson. Carries the owning track (to resolve the
/// `LessonRef`) and the lesson id; registered on the root `NavigationStack`.
struct ArticleRoute: Hashable {
    let track: TrackNode
    let lessonID: String
}

/// An article-format Track: an optional overview header, then a scrollable
/// table-of-contents of its articles. Tapping a row pushes `ArticleLessonView`.
/// This is the System Design counterpart to `TrackFeedView` — a plain list, not
/// the two-axis paging feed.
struct ArticleTrackView: View {
    let track: TrackNode
    let bundle: Bundle

    @Environment(LessonProgressStore.self) private var progressStore
    @State private var items: [TOCItem] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let overview = track.overview {
                    ArticleTrackHeader(track: track, overview: overview)
                    Divider().padding(.vertical, 8)
                }
                ForEach(items) { item in
                    NavigationLink(value: ArticleRoute(track: track, lessonID: item.ref.id)) {
                        ArticleTOCRow(title: item.ref.title,
                                      summary: item.summary,
                                      completed: progressStore.record(for: item.ref.id)?.completed ?? false)
                    }
                    .buttonStyle(.plain)
                    if item.id != items.last?.id { Divider() }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(track.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            guard items.isEmpty else { return }
            items = track.lessons.map { ref in
                TOCItem(ref: ref, summary: (try? ContentStore.loadLesson(ref, bundle: bundle))?.summary)
            }
        }
    }

    private struct TOCItem: Identifiable {
        let ref: LessonRef
        let summary: String?
        var id: String { ref.id }
    }
}

/// An article-format Lesson rendered as a single scrolling page. This is a
/// **top-level** `ScrollView` reached by a push — deliberately NOT nested inside
/// the paging feed, which would crash the async renderer (see ADR 0009). Blocks
/// render top to bottom; a bottom button marks the article complete.
struct ArticleLessonView: View {
    let track: TrackNode
    let lessonID: String
    let bundle: Bundle

    @Environment(LessonProgressStore.self) private var progressStore
    @State private var lesson: Lesson?
    @State private var loadError: String?

    var body: some View {
        Group {
            if let lesson {
                ArticleReader(lesson: lesson)
            } else if let loadError {
                MessageView(systemImage: "exclamationmark.triangle",
                            title: "Couldn't load article",
                            message: loadError)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(lesson?.title ?? "")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { loadIfNeeded() }
    }

    private func loadIfNeeded() {
        guard lesson == nil, loadError == nil else { return }
        guard let ref = track.lessons.first(where: { $0.id == lessonID }) else {
            loadError = "This article is not part of the track."
            return
        }
        do {
            lesson = try ContentStore.loadLesson(ref, bundle: bundle)
        } catch {
            loadError = (error as? ContentError)?.errorDescription ?? error.localizedDescription
        }
    }
}

/// The scrollable body of an article. Extracted from `ArticleLessonView` so it can
/// be rendered directly (e.g. in tests); the enclosing view loads its lesson
/// asynchronously from the bundle, which an `ImageRenderer` snapshot won't trigger.
struct ArticleReader: View {
    let lesson: Lesson
    @Environment(LessonProgressStore.self) private var progressStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(lesson.title)
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
                if let summary = lesson.summary {
                    Text(summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(Array(lesson.blocks.enumerated()), id: \.offset) { _, block in
                    BlockView(block: block)
                }
                CompleteButton(lessonID: lesson.id)
                    .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            // Mark "started" so the article surfaces in Continue until it's finished.
            if progressStore.record(for: lesson.id) == nil {
                progressStore.recordStep(lessonID: lesson.id, stepIndex: 0, stepCount: 1)
            }
        }
    }
}

/// The bottom "mark complete" affordance; reflects and toggles completion.
private struct CompleteButton: View {
    let lessonID: String
    @Environment(LessonProgressStore.self) private var progressStore

    var body: some View {
        let done = progressStore.record(for: lessonID)?.completed ?? false
        Button {
            progressStore.markCompleted(lessonID: lessonID, stepCount: 1)
        } label: {
            Label(done ? "Completed" : "Mark as complete",
                  systemImage: done ? "checkmark.circle.fill" : "circle")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .learnKitGlassButton(prominent: !done)
        .disabled(done)
        .accessibilityHint(done ? "" : "Marks this article as read.")
    }
}

// MARK: - Block rendering

/// Renders one article `Block`. `body` is an implicit `@ViewBuilder`, so the
/// switch may return a different view per case.
private struct BlockView: View {
    let block: Block

    var body: some View {
        switch block {
        case .heading(let b):
            Text(b.text)
                .font((b.level ?? 2) == 1 ? .title2.bold() : .title3.bold())
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let b):
            Text(b.text)
                .font(.body)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        case .bullets(let b):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(b.items.enumerated()), id: \.offset) { i, item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text((b.ordered ?? false) ? "\(i + 1)." : "•")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(item)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        case .callout(let b):
            CalloutView(block: b)
        }
    }
}

/// A tinted aside box for a `callout` block.
private struct CalloutView: View {
    let block: CalloutBlock

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                if let title = block.title {
                    Text(title).font(.subheadline.weight(.semibold))
                }
                Text(block.text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch block.kind {
        case .note:    return "info.circle.fill"
        case .tip:     return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    private var tint: Color {
        switch block.kind {
        case .note:    return .blue
        case .tip:     return .green
        case .warning: return .orange
        }
    }
}

// MARK: - TOC pieces

private struct ArticleTrackHeader: View {
    let track: TrackNode
    let overview: TrackOverview

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if let icon = track.icon {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
                Text(track.title).font(.largeTitle.bold())
            }
            Text(overview.tagline)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(overview.keyIdea)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ArticleTOCRow: View {
    let title: String
    let summary: String?
    let completed: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(completed ? .green : .secondary)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                if let summary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(completed ? "Completed" : "")
    }
}
