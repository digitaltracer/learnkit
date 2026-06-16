import Foundation

enum ContentError: LocalizedError {
    case notFound(String)
    case decodingFailed(path: String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notFound(let path):
            return "Couldn't find \(path) in the app bundle. Add the Content folder to the LearnKit target as a folder reference."
        case .decodingFailed(let path, let underlying):
            return "Couldn't read \(path): \(underlying.localizedDescription)"
        }
    }
}

/// Loads bundled JSON content. Stateless; reads from the app bundle by default.
enum ContentStore {
    static func loadManifest(bundle: Bundle = .main) throws -> Manifest {
        try decode("Content/manifest.json", as: Manifest.self, bundle: bundle)
    }

    static func loadLesson(_ ref: LessonRef, bundle: Bundle = .main) throws -> Lesson {
        try decode("Content/\(ref.file)", as: Lesson.self, bundle: bundle)
    }

    static func decode<T: Decodable>(_ path: String, as type: T.Type, bundle: Bundle) throws -> T {
        guard let url = resourceURL(for: path, in: bundle) else {
            throw ContentError.notFound(path)
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ContentError.decodingFailed(path: path, underlying: error)
        }
    }

    /// Resolves a bundle-relative path such as "Content/dsa/two-pointers/x.json".
    /// Works whether Content was added as a folder reference (subdirectories preserved)
    /// or as a group (files flattened into the bundle root).
    static func resourceURL(for path: String, in bundle: Bundle) -> URL? {
        let ns = path as NSString
        let ext = ns.pathExtension
        let withoutExt = ns.deletingPathExtension as NSString
        let name = withoutExt.lastPathComponent
        let subdirectory = withoutExt.deletingLastPathComponent

        if !subdirectory.isEmpty,
           let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return url
        }
        return bundle.url(forResource: name, withExtension: ext)
    }
}
