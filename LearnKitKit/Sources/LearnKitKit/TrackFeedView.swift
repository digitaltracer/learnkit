import SwiftUI

/// A Track opened as a vertical feed: the Overview page first, then one page per
/// Lesson. Swipe up/down to move through the feed; inside a Lesson, tap or swipe
/// left/right to advance Steps. This is the two-axis model — vertical = lessons,
/// horizontal = steps.
struct TrackFeedView: View {
    let track: TrackNode
    let bundle: Bundle

    @State private var lessons: [Lesson] = []
    @State private var loadError: String?
    /// The page currently snapped into view. Two-way bound to the scroll position:
    /// it tracks swipes and, when the jump menu writes it, scrolls straight there.
    @State private var visibleID: String?

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
            if !lessons.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    jumpMenu
                }
            }
        }
        .task {
            guard lessons.isEmpty, loadError == nil else { return }
            lessons = track.lessons.compactMap { try? ContentStore.loadLesson($0, bundle: bundle) }
            if lessons.isEmpty && track.overview == nil {
                loadError = "No lessons or overview are available for this track yet."
            }
        }
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
                    ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                        page(LessonPage(lesson: lesson, hasNext: index < lessons.count - 1), proxy: proxy)
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

    /// Dropdown that jumps the feed straight to any lesson (or back to the
    /// Overview), so reaching a later lesson doesn't mean swiping past every one
    /// before it. Built as a Picker so the current page shows a checkmark.
    private var jumpMenu: some View {
        Menu {
            Picker("Jump to lesson", selection: jumpSelection) {
                if track.overview != nil {
                    Label("Overview", systemImage: "doc.text").tag(Self.overviewID)
                }
                ForEach(lessons, id: \.id) { lesson in
                    Text(lesson.title).tag(lesson.id)
                }
            }
        } label: {
            Label("Jump to lesson", systemImage: "list.bullet")
        }
    }

    private static let overviewID = "overview"

    /// The page shown when nothing has scrolled yet — the Overview if present,
    /// otherwise the first lesson.
    private var defaultID: String {
        track.overview != nil ? Self.overviewID : (lessons.first?.id ?? Self.overviewID)
    }

    /// Non-optional view over `visibleID` for the Picker: reading gives the current
    /// page; writing scrolls there via `.scrollPosition`.
    private var jumpSelection: Binding<String> {
        Binding(get: { visibleID ?? defaultID }, set: { visibleID = $0 })
    }

    /// One feed page sized to exactly the ScrollView's paging stride: the content
    /// fills the safe height, then a bottom pad equal to the home-indicator inset
    /// extends the page to the screen edge — keeping the controls above the
    /// indicator while making page height == stride so no neighbor can peek in.
    private func page(_ content: some View, proxy: GeometryProxy) -> some View {
        content
            .frame(width: proxy.size.width, height: proxy.size.height)
            .padding(.bottom, proxy.safeAreaInsets.bottom)
            .clipped()
    }
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
