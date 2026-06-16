import Foundation

// MARK: - Manifest (the catalog index the app loads first)

struct Manifest: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let subjects: [SubjectNode]
}

struct SubjectNode: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let tracks: [TrackNode]
}

struct TrackNode: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let icon: String?              // optional SF Symbol name
    let overview: TrackOverview?   // the pattern intro, shown as the first page of the Track feed
    let lessons: [LessonRef]
}

/// A Track's intro page: what the pattern is, when to reach for it, the key idea.
struct TrackOverview: Codable, Equatable, Hashable, Sendable {
    let tagline: String
    let whenToUse: [String]
    let keyIdea: String
    let complexity: String?
}

/// A pointer to a Lesson file, as listed in the manifest.
struct LessonRef: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let difficulty: Difficulty?
    let file: String
}

// MARK: - Lesson (one bundled JSON file)

struct Lesson: Codable, Equatable, Identifiable, Sendable {
    let schemaVersion: Int
    let id: String
    let subject: String
    let track: String
    let title: String
    let difficulty: Difficulty?
    let summary: String?
    let problem: String?
    let example: ProblemExample?
    let steps: [Step]
}

/// A short problem statement and one concrete example, shown atop a Lesson.
struct ProblemExample: Codable, Equatable, Sendable {
    let input: String
    let output: String
    let note: String?
}

/// A self-contained snapshot: one Visual plus a caption.
struct Step: Codable, Equatable, Sendable {
    let caption: String
    let visual: ArrayVisual
}

enum Difficulty: String, Codable, Equatable, Hashable, Sendable {
    case easy, medium, hard
}

// MARK: - Visual: the `array` Primitive

struct ArrayVisual: Codable, Equatable, Sendable {
    let type: String
    let style: ArrayStyle
    let cells: [CellValue]
    let pointers: [Pointer]
    let highlights: [Highlight]

    enum CodingKeys: String, CodingKey { case type, style, cells, pointers, highlights }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        style = try c.decodeIfPresent(ArrayStyle.self, forKey: .style) ?? .cells
        cells = try c.decode([CellValue].self, forKey: .cells)
        pointers = try c.decodeIfPresent([Pointer].self, forKey: .pointers) ?? []
        highlights = try c.decodeIfPresent([Highlight].self, forKey: .highlights) ?? []
    }

    init(type: String = "array",
         style: ArrayStyle = .cells,
         cells: [CellValue],
         pointers: [Pointer] = [],
         highlights: [Highlight] = []) {
        self.type = type
        self.style = style
        self.cells = cells
        self.pointers = pointers
        self.highlights = highlights
    }

    /// The highlight state covering a given cell index, if any.
    func highlightState(for index: Int) -> HighlightState? {
        for highlight in highlights where highlight.covers(index) { return highlight.state }
        return nil
    }
}

/// How the `array` Primitive is drawn.
enum ArrayStyle: String, Codable, Equatable, Sendable {
    case cells   // boxed values (default) — for indices/characters/sorted values
    case bars    // vertical bars scaled to each cell's numeric value — for heights/magnitudes
}

struct Pointer: Codable, Equatable, Sendable {
    let label: String
    let index: Int
}

struct Highlight: Codable, Equatable, Sendable {
    let index: Int?
    let range: [Int]?
    let state: HighlightState

    /// True if this highlight applies to the given cell index.
    func covers(_ i: Int) -> Bool {
        if let index, index == i { return true }
        if let range, range.count == 2 {
            let lower = min(range[0], range[1])
            let upper = max(range[0], range[1])
            return (lower...upper).contains(i)
        }
        return false
    }
}

enum HighlightState: String, Codable, Equatable, Sendable {
    case compare, match, mismatch, done, active
}

// MARK: - CellValue (a cell is either a string or a number)

enum CellValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let d = try? c.decode(Double.self) { self = .number(d); return }
        throw DecodingError.dataCorruptedError(
            in: c, debugDescription: "A cell must be a string or a number")
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let d): try c.encode(d)
        }
    }

    /// What to draw inside the cell.
    var display: String {
        switch self {
        case .string(let s): return s
        case .number(let d): return d.rounded() == d ? String(Int(d)) : String(d)
        }
    }

    /// The numeric value, if this cell is a number (or a numeric string). Used by the `bars` style.
    var numericValue: Double? {
        switch self {
        case .number(let d): return d
        case .string(let s): return Double(s)
        }
    }
}
