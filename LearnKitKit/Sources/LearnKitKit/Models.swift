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
    let format: LessonFormat       // "steps" (default, animated player) or "article" (scrollable reader)
    let overview: TrackOverview?   // the pattern intro, shown as the first page of the Track feed
    let lessons: [LessonRef]

    enum CodingKeys: String, CodingKey { case id, title, icon, format, overview, lessons }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        format = try c.decodeIfPresent(LessonFormat.self, forKey: .format) ?? .steps
        overview = try c.decodeIfPresent(TrackOverview.self, forKey: .overview)
        lessons = try c.decode([LessonRef].self, forKey: .lessons)
    }
}

/// A Track's intro page: what the pattern is, when to reach for it, the key idea.
struct TrackOverview: Codable, Equatable, Hashable, Sendable {
    let tagline: String
    let whenToUse: [String]
    let keyIdea: String
    let complexity: String?
}

/// How a Track's lessons are presented. `steps` is the animated snapshot player
/// (the default, and every DSA lesson); `article` is a scrollable long-form reader
/// for System Design content. See ADR 0009.
enum LessonFormat: String, Codable, Equatable, Hashable, Sendable {
    case steps, article
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
    let format: LessonFormat       // "steps" (default) or "article"; see ADR 0009
    let difficulty: Difficulty?
    let summary: String?
    let problem: String?
    let example: ProblemExample?
    let steps: [Step]              // populated for `steps` lessons
    let blocks: [Block]            // populated for `article` lessons

    enum CodingKeys: String, CodingKey {
        case schemaVersion, id, subject, track, title, format
        case difficulty, summary, problem, example, steps, blocks
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        id = try c.decode(String.self, forKey: .id)
        subject = try c.decode(String.self, forKey: .subject)
        track = try c.decode(String.self, forKey: .track)
        title = try c.decode(String.self, forKey: .title)
        format = try c.decodeIfPresent(LessonFormat.self, forKey: .format) ?? .steps
        difficulty = try c.decodeIfPresent(Difficulty.self, forKey: .difficulty)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        problem = try c.decodeIfPresent(String.self, forKey: .problem)
        example = try c.decodeIfPresent(ProblemExample.self, forKey: .example)
        steps = try c.decodeIfPresent([Step].self, forKey: .steps) ?? []
        blocks = try c.decodeIfPresent([Block].self, forKey: .blocks) ?? []
    }
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

// MARK: - Block: one unit of an `article` Lesson, chosen by its `type`

/// A block in an article-format Lesson. Like `Visual`, decoding dispatches on the
/// `type` field, so an article is an ordered list of mixed blocks and new block
/// kinds are added by extending this enum. v1 covers prose; `diagram` (embeds a
/// `Visual`), `table`, and `code` arrive in later phases. See ADR 0009.
enum Block: Codable, Equatable, Sendable {
    case heading(HeadingBlock)
    case paragraph(ParagraphBlock)
    case bullets(BulletsBlock)
    case callout(CalloutBlock)
    case diagram(DiagramBlock)

    private enum TypeKey: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: TypeKey.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "heading":   self = .heading(try HeadingBlock(from: decoder))
        case "paragraph": self = .paragraph(try ParagraphBlock(from: decoder))
        case "bullets":   self = .bullets(try BulletsBlock(from: decoder))
        case "callout":   self = .callout(try CalloutBlock(from: decoder))
        case "diagram":   self = .diagram(try DiagramBlock(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: c,
                debugDescription: "Unknown block type '\(type)'. Known types: heading, paragraph, bullets, callout, diagram.")
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .heading(let b):   try b.encode(to: encoder)
        case .paragraph(let b): try b.encode(to: encoder)
        case .bullets(let b):   try b.encode(to: encoder)
        case .callout(let b):   try b.encode(to: encoder)
        case .diagram(let b):   try b.encode(to: encoder)
        }
    }
}

/// A section heading. `level` is 1 (page section) or 2 (subsection); defaults to 2.
struct HeadingBlock: Codable, Equatable, Sendable {
    let type: String
    let text: String
    let level: Int?
}

struct ParagraphBlock: Codable, Equatable, Sendable {
    let type: String
    let text: String
}

/// A bullet (or, when `ordered`, numbered) list.
struct BulletsBlock: Codable, Equatable, Sendable {
    let type: String
    let items: [String]
    let ordered: Bool?
}

/// A tinted aside — a note, a tip, or a warning — with an optional bold title.
struct CalloutBlock: Codable, Equatable, Sendable {
    let type: String
    let kind: CalloutKind
    let title: String?
    let text: String
}

enum CalloutKind: String, Codable, Equatable, Sendable {
    case note, tip, warning
}

/// An article block that embeds a `Visual` — the vehicle for an `architecture`
/// diagram inside an article, with an optional caption beneath it. In principle it
/// can embed any primitive, but `architecture` is its purpose. See ADR 0010.
struct DiagramBlock: Codable, Equatable, Sendable {
    let type: String
    let visual: Visual
    let caption: String?
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
    case graph(GraphVisual)
    case hashmap(HashMapVisual)
    case intervals(IntervalsVisual)
    case rtree(RTreeVisual)
    case architecture(ArchitectureVisual)

    private enum TypeKey: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: TypeKey.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "array":        self = .array(try ArrayVisual(from: decoder))
        case "grid":         self = .grid(try GridVisual(from: decoder))
        case "tree":         self = .tree(try TreeVisual(from: decoder))
        case "list":         self = .list(try ListVisual(from: decoder))
        case "graph":        self = .graph(try GraphVisual(from: decoder))
        case "hashmap":      self = .hashmap(try HashMapVisual(from: decoder))
        case "intervals":    self = .intervals(try IntervalsVisual(from: decoder))
        case "rtree":        self = .rtree(try RTreeVisual(from: decoder))
        case "architecture": self = .architecture(try ArchitectureVisual(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: c,
                debugDescription: "Unknown visual type '\(type)'. Known types: array, grid, tree, list, graph, hashmap, intervals, rtree, architecture.")
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .array(let v):        try v.encode(to: encoder)
        case .grid(let v):         try v.encode(to: encoder)
        case .tree(let v):         try v.encode(to: encoder)
        case .list(let v):         try v.encode(to: encoder)
        case .graph(let v):        try v.encode(to: encoder)
        case .hashmap(let v):      try v.encode(to: encoder)
        case .intervals(let v):    try v.encode(to: encoder)
        case .rtree(let v):        try v.encode(to: encoder)
        case .architecture(let v): try v.encode(to: encoder)
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

// MARK: - Visual: the `graph` Primitive

/// A general graph. Nodes carry explicit normalized positions (x,y in 0...1) so
/// the renderer is deterministic — no auto-layout. Edges reference node `id`s and
/// may be directed and/or weighted.
struct GraphVisual: Codable, Equatable, Sendable {
    let type: String
    let nodes: [GraphNode]
    let edges: [GraphEdge]

    enum CodingKeys: String, CodingKey { case type, nodes, edges }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        nodes = try c.decode([GraphNode].self, forKey: .nodes)
        edges = try c.decodeIfPresent([GraphEdge].self, forKey: .edges) ?? []
    }

    init(type: String = "graph", nodes: [GraphNode], edges: [GraphEdge] = []) {
        self.type = type
        self.nodes = nodes
        self.edges = edges
    }

    func node(id: String) -> GraphNode? { nodes.first { $0.id == id } }
}

struct GraphNode: Codable, Equatable, Sendable {
    let id: String
    let value: CellValue?
    let x: Double
    let y: Double
    let state: HighlightState?
    let pointer: String?

    /// What to draw inside the node — its `value` if given, else its `id`.
    var display: String { value?.display ?? id }
}

struct GraphEdge: Codable, Equatable, Sendable {
    let from: String
    let to: String
    let directed: Bool?
    let weight: CellValue?
    let state: HighlightState?
}

// MARK: - Visual: the `hashmap` Primitive

/// A key -> value map (or set). Rows are drawn in insertion order; an optional
/// `probe` shows a lookup in progress and whether it hit.
struct HashMapVisual: Codable, Equatable, Sendable {
    let type: String
    let entries: [HashEntry]
    let probe: HashProbe?

    enum CodingKeys: String, CodingKey { case type, entries, probe }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        entries = try c.decodeIfPresent([HashEntry].self, forKey: .entries) ?? []
        probe = try c.decodeIfPresent(HashProbe.self, forKey: .probe)
    }

    init(type: String = "hashmap", entries: [HashEntry] = [], probe: HashProbe? = nil) {
        self.type = type
        self.entries = entries
        self.probe = probe
    }
}

struct HashEntry: Codable, Equatable, Sendable {
    let key: CellValue
    let value: CellValue
    let state: HighlightState?
}

/// A lookup being performed against the map. `found` colors it as a hit or miss.
struct HashProbe: Codable, Equatable, Sendable {
    let key: CellValue
    let found: Bool?
}

// MARK: - Visual: the `intervals` Primitive

/// Intervals drawn as horizontal bars on a shared time axis, one per row.
struct IntervalsVisual: Codable, Equatable, Sendable {
    let type: String
    let rows: [IntervalRow]
    let axisMin: Double?
    let axisMax: Double?

    enum CodingKeys: String, CodingKey { case type, rows, axisMin, axisMax }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        rows = try c.decode([IntervalRow].self, forKey: .rows)
        axisMin = try c.decodeIfPresent(Double.self, forKey: .axisMin)
        axisMax = try c.decodeIfPresent(Double.self, forKey: .axisMax)
    }

    init(type: String = "intervals", rows: [IntervalRow], axisMin: Double? = nil, axisMax: Double? = nil) {
        self.type = type
        self.rows = rows
        self.axisMin = axisMin
        self.axisMax = axisMax
    }

    var lowerBound: Double { axisMin ?? min(rows.map(\.start).min() ?? 0, 0) }
    var upperBound: Double {
        let hi = axisMax ?? (rows.map(\.end).max() ?? 1)
        return hi > lowerBound ? hi : lowerBound + 1
    }
}

struct IntervalRow: Codable, Equatable, Sendable {
    let start: Double
    let end: Double
    let label: String?
    let state: HighlightState?
}

// MARK: - Visual: the `rtree` Primitive (recursion / decision tree)

/// An n-ary decision tree — for backtracking. Each node is a partial state; the
/// `edge` label is the choice that reached it from its parent.
struct RTreeVisual: Codable, Equatable, Sendable {
    let type: String
    let root: RNode?

    enum CodingKeys: String, CodingKey { case type, root }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        root = try c.decodeIfPresent(RNode.self, forKey: .root)
    }

    init(type: String = "rtree", root: RNode?) {
        self.type = type
        self.root = root
    }
}

/// One decision-tree node. Recursive, so a `final class` (like `TreeNode`).
final class RNode: Codable, Equatable, Sendable {
    let value: CellValue
    let edge: String?
    let state: HighlightState?
    let pointer: String?
    let children: [RNode]

    init(value: CellValue,
         edge: String? = nil,
         state: HighlightState? = nil,
         pointer: String? = nil,
         children: [RNode] = []) {
        self.value = value
        self.edge = edge
        self.state = state
        self.pointer = pointer
        self.children = children
    }

    enum CodingKeys: String, CodingKey { case value, edge, state, pointer, children }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        value = try c.decode(CellValue.self, forKey: .value)
        edge = try c.decodeIfPresent(String.self, forKey: .edge)
        state = try c.decodeIfPresent(HighlightState.self, forKey: .state)
        pointer = try c.decodeIfPresent(String.self, forKey: .pointer)
        children = try c.decodeIfPresent([RNode].self, forKey: .children) ?? []
    }

    static func == (lhs: RNode, rhs: RNode) -> Bool {
        lhs.value == rhs.value && lhs.edge == rhs.edge && lhs.state == rhs.state
            && lhs.pointer == rhs.pointer && lhs.children == rhs.children
    }
}

// MARK: - Visual: the `architecture` Primitive (system-design diagrams)

/// A system-design architecture diagram: labeled component boxes joined by
/// directed, labeled connectors, optionally grouped into tiers or regions. Like
/// `graph`, nodes carry explicit normalized positions (x,y in 0...1) — deterministic
/// placement, no auto-layout. This is the marquee System Design visual. See ADR 0010.
struct ArchitectureVisual: Codable, Equatable, Sendable {
    let type: String
    let nodes: [ArchNode]
    let connectors: [ArchConnector]
    let groups: [ArchGroup]

    enum CodingKeys: String, CodingKey { case type, nodes, connectors, groups }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        nodes = try c.decode([ArchNode].self, forKey: .nodes)
        connectors = try c.decodeIfPresent([ArchConnector].self, forKey: .connectors) ?? []
        groups = try c.decodeIfPresent([ArchGroup].self, forKey: .groups) ?? []
    }

    init(type: String = "architecture",
         nodes: [ArchNode],
         connectors: [ArchConnector] = [],
         groups: [ArchGroup] = []) {
        self.type = type
        self.nodes = nodes
        self.connectors = connectors
        self.groups = groups
    }

    func node(id: String) -> ArchNode? { nodes.first { $0.id == id } }
}

/// One component box. `kind` drives its tint and SF Symbol; `x,y` are normalized
/// 0...1. `title` is the component name, `subtitle` an optional qualifier.
struct ArchNode: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    let kind: ArchKind
    let x: Double
    let y: Double
    let state: HighlightState?

    enum CodingKeys: String, CodingKey { case id, title, subtitle, kind, x, y, state }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
        kind = try c.decodeIfPresent(ArchKind.self, forKey: .kind) ?? .service
        x = try c.decode(Double.self, forKey: .x)
        y = try c.decode(Double.self, forKey: .y)
        state = try c.decodeIfPresent(HighlightState.self, forKey: .state)
    }

    init(id: String,
         title: String,
         subtitle: String? = nil,
         kind: ArchKind = .service,
         x: Double,
         y: Double,
         state: HighlightState? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.x = x
        self.y = y
        self.state = state
    }
}

/// The role of a component box, which the renderer maps to a tint and SF Symbol.
enum ArchKind: String, Codable, Equatable, Sendable {
    case client, service, database, cache, queue, cdn, storage, lb, external
}

/// A connector between two component boxes. Directed by default; `sync` draws a
/// solid line, `async` a dashed one.
struct ArchConnector: Codable, Equatable, Sendable {
    let from: String
    let to: String
    let label: String?
    let directed: Bool?
    let style: ArchConnectorStyle?
    let state: HighlightState?
}

enum ArchConnectorStyle: String, Codable, Equatable, Sendable {
    case sync, async
}

/// A labeled rounded-rectangle backing a set of node `id`s — a tier or a region.
struct ArchGroup: Codable, Equatable, Sendable {
    let label: String?
    let nodes: [String]
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
