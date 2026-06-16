import SwiftUI

/// The app's root view. In your app target, set `LearnKitRootView()` as the
/// window's content. It loads the bundled manifest and presents the catalog.
public struct LearnKitRootView: View {
    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

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
                    ProgressView("Loading…")
                }
            }
            .navigationTitle("LearnKit")
        }
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

/// Home: Subjects as sections, each listing its Tracks. Tapping a Track opens its feed.
struct CatalogView: View {
    let manifest: Manifest
    let bundle: Bundle

    var body: some View {
        List {
            ForEach(manifest.subjects) { subject in
                Section(subject.title) {
                    ForEach(subject.tracks) { track in
                        NavigationLink(value: track) { TrackRow(track: track) }
                    }
                }
            }
        }
        .navigationDestination(for: TrackNode.self) { track in
            TrackFeedView(track: track, bundle: bundle)
        }
    }
}

private struct TrackRow: View {
    let track: TrackNode

    var body: some View {
        HStack(spacing: 12) {
            if let icon = track.icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title).font(.headline)
                Text("\(track.lessons.count) lessons")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
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
