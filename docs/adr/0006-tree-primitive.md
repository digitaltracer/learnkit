---
status: accepted
---

# The `tree` Primitive: inline per-node state, in-order layout

The third Primitive (after `array` and `grid`) draws a **binary tree** — the
basis for the 15-problem Trees track, and later reused for `heap` and `trie`.
It follows the polymorphic-`Visual` pattern set in ADR 0005.

## Decision

- **Recursive structure, not a flat array.** A node is `{ value, left?, right?,
  state?, pointer? }`, nested. `array`/`grid` style addressing (index, row/col)
  doesn't fit a tree — nodes have no natural linear position, and a flat
  level-order array wastes space and explodes for skewed trees. So highlights and
  pointers live **inline on each node** (`state`, `pointer`) rather than in a
  separate index-addressed list. The whole tree is still the full snapshot at a
  Step, consistent with the other primitives.
- `TreeNode` is a **`final class`** (a value type cannot recursively contain
  itself). Its stored properties are immutable and Sendable, so it conforms to
  `Sendable` without `@unchecked`; `Equatable` is hand-written.
- **In-order layout.** `TreeVisualView` assigns each node an x-column by an
  in-order walk (left subtree, self, right subtree) and a y-row by depth. This is
  the standard non-overlapping binary-tree layout and needs no width
  pre-measurement. Edges are drawn behind nodes; nodes are circles colored by the
  shared `HighlightState`/`Palette`; pointer labels render as a small badge above
  the node.
- Node render identity is the **path from the root** ("root", "L", "RL", …), so a
  node that keeps its structural position across Steps animates in place while its
  value/color crossfades — which makes the Invert animation (subtrees sliding
  across) read naturally.
- Additive: `schemaVersion` stays `1`; `treeVisual` joins the `step.visual`
  `oneOf` and is selected by `type:"tree"` (disjoint required fields from the
  other primitives).

## Consequences

- Because state is inline, an authoring tool re-emits the entire tree each Step.
  That's verbose in JSON but matches the snapshot model and keeps the renderer
  trivial (no diffing logic in content).
- The validator can't bounds-check (no indices); it checks the root exists and
  pointer labels are ≤ 3 chars, and otherwise trusts the structure.
- Layout is unweighted/symmetric; very deep skewed trees get tall and thin within
  the fixed 220pt band. Fine for the sizes these problems use; revisit if a
  lesson needs a larger or scrollable canvas.
