# Content

All learning content for LearnKit. This whole directory is **bundled into the app** (added to the Xcode project as a *folder reference* — the blue-folder kind — so the directory layout is preserved inside the app bundle). The app reads it offline at runtime; there is no server.

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
- Every Step is a **complete snapshot** (full `cells` + all `pointers` + all `highlights`), never a delta. See ADR-0002 and `valid-palindrome.json` as the reference example.
- v1 supports exactly one Primitive: `array`. Adding a new Primitive (e.g. `tree`, `flow`) means extending the schema *and* writing a SwiftUI renderer for it — it is not just a content change.
