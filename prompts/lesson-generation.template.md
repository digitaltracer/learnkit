# LearnKit — Lesson generation prompt (reusable template)

Copy this, fill in the `{{...}}` slots, and run it against a capable LLM (Claude/GPT). It produces ONE Lesson file. Save the output to `Content/<subject>/<track>/<id>.json` and add a matching entry to `Content/manifest.json`. Validate against `Content/_schema/lesson.schema.json`.

---

You are generating ONE Lesson for **LearnKit**, a micro-learning iPhone app. A Lesson is a short, swipeable, visual walkthrough that teaches how to solve a problem in 2–3 minutes. Your entire output MUST be a single valid JSON object and nothing else — no markdown fences, no commentary.

## What to teach
- Subject: `{{SUBJECT}}`            (e.g. `dsa`)
- Track:   `{{TRACK}}`              (e.g. `two-pointers`)
- Lesson id: `{{ID}}`              (kebab-case; will be the filename)
- Title:   `{{TITLE}}`
- Difficulty: `{{DIFFICULTY}}`      (easy | medium | hard)
- Problem:  {{PROBLEM_STATEMENT}}
- Walkthrough example: {{EXAMPLE_INPUT}}   (pick/keep it SMALL so it fits a phone screen)

## Output schema (schemaVersion 1)
```json
{
  "schemaVersion": 1,
  "id": "<kebab-id>",
  "subject": "<subject>",
  "track": "<track>",
  "title": "<Title>",
  "difficulty": "easy|medium|hard",
  "summary": "<one sentence framing the approach>",
  "problem": "<one or two sentences: what the problem asks>",
  "example": { "input": "<small concrete input>", "output": "<expected output>" },
  "steps": [ { "caption": "<=160 chars", "visual": { ...one primitive visual... } } ]
}
```

Pick the smallest Primitive that makes the algorithm legible:

- `array`: one-dimensional arrays, strings, pointer scans, stacks, and numeric bars.
- `grid`: matrices, board traversal, 2-D dynamic programming tables.
- `tree`: binary trees, binary search trees, heaps, and tries when binary layout is enough.
- `list`: linked lists with re-pointable `next` links.
- `graph`: nodes and edges with explicit positions.
- `hashmap`: key-value lookups, sets, counts, and seen-index maps.
- `intervals`: ranges on a shared timeline.
- `rtree`: recursive/backtracking decision trees.

All primitives and fields are defined in `Content/_schema/lesson.schema.json`. A common `array` visual looks like:
```json
{
  "type": "array",
  "style": "cells",                                     // optional; "cells" (default) or "bars"
  "cells": [ /* numbers or strings — the FULL array at this step */ ],
  "pointers": [ { "label": "L", "index": 0 } ],         // optional; labels <=3 chars
  "highlights": [ { "index": 2, "state": "match" },     // optional; one cell...
                  { "range": [1, 3], "state": "active" } ] //   ...or an inclusive range
}
```
Allowed highlight `state` values: `compare`, `match`, `mismatch`, `done`, `active`.

`style`: use `"cells"` (default) for indices, characters, or sorted values. Use `"bars"` when the values represent **heights or magnitudes** and the intuition is visual (e.g. Container With Most Water, histograms) — bars are drawn scaled to each value. `"bars"` requires every cell to be numeric.

## Hard rules
1. Output a single valid JSON object. No trailing commas, no comments, no prose around it.
2. **6–10 steps for most lessons.** Each step = one `caption` (≤160 chars, plain teaching English, no code) + one complete visual snapshot. The schema allows 3–12 steps for unusually short or complex lessons.
3. **Snapshots, not deltas.** Each step's `visual` is the COMPLETE state at that moment. The app animates by diffing consecutive steps, so keep stable data identical between steps unless the data itself changes, and move pointers/active state realistically.
4. **Actually execute the algorithm** on the example and emit one curated snapshot per meaningful moment: introduce → place pointers → compare/act → move → … → conclude. Every pointer index and cell value must be correct at every step.
5. Step 1 introduces the example, usually with no pointer or only the starting active state. The final step states the conclusion/answer.
6. `id`, `subject`, `track`, `title`, `difficulty` must match the values given above. `id` must match the intended filename.
7. Validate against `Content/_schema/lesson.schema.json`, then run `swift test` in `LearnKitKit`.

Output the JSON object only.
