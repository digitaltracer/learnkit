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
    let visual: Visual
}

enum Difficulty: String, Codable, Equatable, Hashable, Sendable {
    case easy, medium, hard
}

// MARK: - Visual: one Primitive per Step, chosen by its `type`

/// A Step's diagram. Each case wraps one Primitive's spec; decoding dispatches on
/// the `type` field, so a Lesson can mix primitives across its Steps and new
/// primitives are added by extending this enum (not by changing every call site).
enum Visual: Codable, Equatable, Sendable {
    case array(ArrayVisual)
    case grid(GridVisual)
    case tree(TreeVisual)
    case list(ListVisual)

    private enum TypeKey: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: TypeKey.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "array": self = .array(try ArrayVisual(from: decoder))
        case "grid":  self = .grid(try GridVisual(from: decoder))
        case "tree":  self = .tree(try TreeVisual(from: decoder))
        case "list":  self = .list(try ListVisual(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: c,
                debugDescription: "Unknown visual type '\(type)'. Known types: array, grid, tree, list.")
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .array(let v): try v.encode(to: encoder)
        case .grid(let v):  try v.encode(to: encoder)
        case .tree(let v):  try v.encode(to: encoder)
        case .list(let v):  try v.encode(to: encoder)
        }
    }
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

// MARK: - Visual: the `grid` Primitive

/// A 2-D matrix of cells — for matrices (rotate, spiral, search) and DP tables.
/// Like `array`, every Step carries the full state; the app animates the diff
/// between consecutive Steps (a pointer hopping cells, a region changing color).
struct GridVisual: Codable, Equatable, Sendable {
    let type: String
    let rows: [[CellValue]]
    let pointers: [GridPointer]
    let highlights: [GridHighlight]

    enum CodingKeys: String, CodingKey { case type, rows, pointers, highlights }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        rows = try c.decode([[CellValue]].self, forKey: .rows)
        pointers = try c.decodeIfPresent([GridPointer].self, forKey: .pointers) ?? []
        highlights = try c.decodeIfPresent([GridHighlight].self, forKey: .highlights) ?? []
    }

    init(type: String = "grid",
         rows: [[CellValue]],
         pointers: [GridPointer] = [],
         highlights: [GridHighlight] = []) {
        self.type = type
        self.rows = rows
        self.pointers = pointers
        self.highlights = highlights
    }

    var rowCount: Int { rows.count }
    var colCount: Int { rows.map(\.count).max() ?? 0 }

    /// The highlight state covering a given cell, if any.
    func highlightState(row: Int, col: Int) -> HighlightState? {
        for h in highlights where h.covers(row: row, col: col) { return h.state }
        return nil
    }
}

/// A named pointer sitting on one grid cell.
struct GridPointer: Codable, Equatable, Sendable {
    let label: String
    let row: Int
    let col: Int
}

/// A color state on one cell (`row` + `col`) or a rectangular region
/// (`rows` [r0,r1] and `cols` [c0,c1], both inclusive).
struct GridHighlight: Codable, Equatable, Sendable {
    let row: Int?
    let col: Int?
    let rows: [Int]?
    let cols: [Int]?
    let state: HighlightState

    /// True if this highlight applies to the given cell.
    func covers(row r: Int, col c: Int) -> Bool {
        if let row, let col { return row == r && col == c }
        if let rows, let cols, rows.count == 2, cols.count == 2 {
            let r0 = min(rows[0], rows[1]), r1 = max(rows[0], rows[1])
            let c0 = min(cols[0], cols[1]), c1 = max(cols[0], cols[1])
            return (r0...r1).contains(r) && (c0...c1).contains(c)
        }
        return false
    }
}

// MARK: - Visual: the `tree` Primitive

/// A binary tree. Unlike `array`/`grid`, nodes have no natural linear index, so
/// each node carries its own optional highlight `state` and `pointer` label
/// inline — the whole tree is still the full state at this Step.
struct TreeVisual: Codable, Equatable, Sendable {
    let type: String
    let root: TreeNode?

    enum CodingKeys: String, CodingKey { case type, root }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        root = try c.decodeIfPresent(TreeNode.self, forKey: .root)
    }

    init(type: String = "tree", root: TreeNode?) {
        self.type = type
        self.root = root
    }
}

/// One binary-tree node. A recursive value type can't contain itself, so this is
/// a `final class`; its stored properties are all immutable and Sendable.
/// Children are omitted when absent.
final class TreeNode: Codable, Equatable, Sendable {
    let value: CellValue
    let state: HighlightState?
    let pointer: String?
    let left: TreeNode?
    let right: TreeNode?

    init(value: CellValue,
         state: HighlightState? = nil,
         pointer: String? = nil,
         left: TreeNode? = nil,
         right: TreeNode? = nil) {
        self.value = value
        self.state = state
        self.pointer = pointer
        self.left = left
        self.right = right
    }

    static func == (lhs: TreeNode, rhs: TreeNode) -> Bool {
        lhs.value == rhs.value && lhs.state == rhs.state && lhs.pointer == rhs.pointer
            && lhs.left == rhs.left && lhs.right == rhs.right
    }
}

// MARK: - Visual: the `list` Primitive

/// A linked list: values in fixed left-to-right positions, joined by directed
/// `links` (next-pointers) that can be re-pointed between Steps — which is how
/// reversal / rewiring animates. Reuses `Pointer` and `Highlight` (index-addressed,
/// exactly like `array`).
struct ListVisual: Codable, Equatable, Sendable {
    let type: String
    let nodes: [CellValue]
    let links: [[Int]]
    let pointers: [Pointer]
    let highlights: [Highlight]

    enum CodingKeys: String, CodingKey { case type, nodes, links, pointers, highlights }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        nodes = try c.decode([CellValue].self, forKey: .nodes)
        links = try c.decodeIfPresent([[Int]].self, forKey: .links) ?? []
        pointers = try c.decodeIfPresent([Pointer].self, forKey: .pointers) ?? []
        highlights = try c.decodeIfPresent([Highlight].self, forKey: .highlights) ?? []
    }

    init(type: String = "list",
         nodes: [CellValue],
         links: [[Int]] = [],
         pointers: [Pointer] = [],
         highlights: [Highlight] = []) {
        self.type = type
        self.nodes = nodes
        self.links = links
        self.pointers = pointers
        self.highlights = highlights
    }

    /// The `next`-pointers. When `links` is omitted, the list is a simple
    /// consecutive forward chain (0->1->2->…).
    var resolvedLinks: [(from: Int, to: Int)] {
        if links.isEmpty {
            return (0..<max(nodes.count - 1, 0)).map { (from: $0, to: $0 + 1) }
        }
        return links.compactMap { $0.count == 2 ? (from: $0[0], to: $0[1]) : nil }
    }

    /// The highlight state covering a given node index, if any.
    func highlightState(for index: Int) -> HighlightState? {
        for h in highlights where h.covers(index) { return h.state }
        return nil
    }
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
