---
status: accepted
---

# The final four primitives: `graph`, `hashmap`, `intervals`, `rtree`

Built as a batch, completing the Primitive vocabulary needed for the NeetCode 150.
All follow the polymorphic-`Visual` pattern (ADR 0005) and are additive
(`schemaVersion` stays `1`; each joins the `step.visual` `oneOf`, selected by its
`type`).

## Decisions

- **`graph`** — Nodes carry **explicit normalized positions** (`x`,`y` in 0…1);
  the renderer does no auto-layout (force-directed layout is hard to make stable
  and legible at this size, and authored positions read better). Edges reference
  node `id`s and may be `directed` (arrowhead computed from the edge vector,
  trimmed to the node radius) and/or `weight`ed (chip at the midpoint). Reuses
  `HighlightState` on both nodes and edges.
- **`hashmap`** — `entries` of `key -> value` rows in insertion order, plus an
  optional **`probe`** showing a lookup and whether it hit/missed. Pure stack
  layout, no geometry math. Entries may be empty (an empty map is a valid Step).
- **`intervals`** — Rows drawn as horizontal bars on a **shared time axis**;
  bounds default from the data (`min(0, smallest start)` … `largest end`) or can
  be pinned with `axisMin`/`axisMax` so bars stay put as intervals merge across
  Steps.
- **`rtree`** (recursion / decision tree) — An **n-ary** tree (vs `tree`'s
  binary). Layout is a post-order walk: leaves take sequential columns, each
  parent is centered over its children's span. Edges carry the **choice label**
  (`edge`) that reached the child. `RNode` is a `final class` like `TreeNode`
  (recursion); `children` defaults to `[]`.

## Consequences

- This **completes the primitive set** for the NeetCode 150 — the remaining
  categories (Heap, Tries) reuse `tree` rather than needing a new renderer, so the
  bulk of the 150 is now "author JSON + validate" chore-work.
- `graph` correctness depends on hand-authored positions; a lesson with sloppy
  coordinates will look cramped. Acceptable trade for deterministic, legible
  layouts; a future helper could snap common shapes (cycle, grid) to positions.
- Directed-edge arrowheads are computed for arbitrary angles, so `graph` already
  supports the directed/weighted Advanced Graphs problems, not just undirected
  ones.
- Validation is structural only (graph: unique ids + edges reference real nodes;
  intervals: end >= start; rtree: root present, label length). No index bounds,
  since these primitives aren't index-addressed.
