# Content

All learning content for LearnKit. This whole directory is **bundled into the app** (added to the Xcode project as a *folder reference*, the blue-folder kind, so the directory layout is preserved inside the app bundle). The app reads it offline at runtime; there is no server.

## Layout

```
Content/
├── manifest.json                     ← the index the app loads first: subjects → tracks → lessons (+ order)
├── _schema/
│   └── lesson.schema.json            ← JSON Schema for a Lesson file (validate generated files against this)
└── <subject>/<track>/<lesson>.json   ← one file per Lesson
    e.g. dsa/two-pointers/valid-palindrome.json
```

## How the app uses it

1. Load `manifest.json` → render the Subject / Track / Lesson lists.
2. When a user opens a Lesson, load its `file` (e.g. `dsa/two-pointers/valid-palindrome.json`).
3. Render `steps` one at a time; the user swipes through them. The renderer animates between Steps by diffing consecutive `visual` snapshots (e.g. a pointer whose `index` changed slides to its new cell).

## Rules

- A Lesson's `id` is kebab-case and **matches its filename** (`valid-palindrome` → `valid-palindrome.json`).
- A Lesson only appears in the app if it's listed in `manifest.json` **and** its file exists. Add new content by writing the file and adding a manifest entry.
- Every Step is a **complete snapshot**, never a delta. The exact fields depend on the Visual Primitive, but the Step must include the complete state needed to draw that moment. See ADR-0002 and the representative lesson files for examples.
- v1 supports these Primitives: `array`, `grid`, `tree`, `list`, `graph`, `hashmap`, `intervals`, and `rtree`. Adding another Primitive means extending the schema, models, validator, and SwiftUI renderer. It is not just a content change.

## Representative lessons

- `array`: `dsa/two-pointers/valid-palindrome.json`
- `grid`: `dsa/math-geometry/spiral-matrix.json`
- `tree`: `dsa/trees/invert-binary-tree.json`
- `list`: `dsa/linked-list/reverse-linked-list.json`
- `graph`: `dsa/graphs/clone-graph.json`
- `hashmap`: `dsa/arrays-hashing/two-sum.json`
- `intervals`: `dsa/intervals/merge-intervals.json`
- `rtree`: `dsa/backtracking/subsets.json`
