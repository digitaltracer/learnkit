---
status: accepted
---

# Step visuals are a polymorphic `Visual`; the second Primitive is `grid`

Until now a Step's `visual` was hard-typed as the `array` Primitive — the only
shape the renderer knew. Covering the rest of the NeetCode 150 needs more shapes
(matrices, trees, linked lists, graphs, …), so we made the visual **polymorphic**
and added the first new one.

## Decision

- `Step.visual` is now a `Visual` enum with one case per Primitive
  (`array`, `grid`). Decoding peeks at the `visual.type` field and dispatches to
  that Primitive's spec. Adding a Primitive is: a new enum case, a new spec type,
  a `VisualView` case, a validator branch, and a schema `$def` added to the
  `step.visual` `oneOf` — no change to existing call sites or content.
- The new **`grid`** Primitive: `rows` of cells (each a string or number, like
  `array`), `pointers` addressed by `{label,row,col}`, and `highlights` that
  color either one cell (`row`+`col`) or a rectangular region (`rows` [r0,r1] +
  `cols` [c0,c1], inclusive). It reuses the existing `HighlightState` vocabulary
  and `Palette`, so colors and animation behavior match `array` exactly.
- This is **additive**: every existing `array` lesson is untouched and
  `schemaVersion` stays `1`. The two Primitives have disjoint required fields
  (`array` requires `cells` + `type:"array"`; `grid` requires `rows` +
  `type:"grid"`), so the schema `oneOf` matches exactly one branch.

We chose `grid` first because it is the single biggest unlock in the roadmap —
~25 problems: all matrix problems and the entire 2-D Dynamic Programming track
(the DP table is a grid). It also forces the polymorphism work once, cheaply,
before the structurally harder primitives (tree, graph) land.

## Consequences

- `GridVisualView` holds no animation of its own, mirroring `ArrayVisualView`:
  cells keyed by (row, col), pointers by label, so snapshot diffs animate when
  the parent swaps steps inside `withAnimation`.
- Grid pointers render as a small label badge pinned to the cell's top-left
  corner (not the array's down-arrow capsule), so the badge never occludes the
  centered value and two adjacent pointers don't collide vertically.
- The fixed 220pt visual band is shared with `array`; the grid fits itself
  inside it. Tall or large grids (many rows) get small cells — fine at the sizes
  these problems use (≤ ~8×8); revisit per-type band heights if a lesson needs it.
- `grid` covers DP **tables** too. Spiral Matrix (the first lesson) proves
  matrix traversal; the DP-table use is validated when the 2-D DP track is
  authored (Unique Paths first).
