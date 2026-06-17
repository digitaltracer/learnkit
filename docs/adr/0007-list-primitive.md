---
status: accepted
---

# The `list` Primitive: a fixed node row with directed, re-pointable links

The fourth Primitive draws a **linked list** — the basis for the 10-problem
Linked List track. It follows the polymorphic-`Visual` pattern (ADR 0005).

## Decision

- Nodes are values in a **fixed left-to-right row**, addressed by index — so the
  `list` primitive **reuses `array`'s `Pointer` and `Highlight`** types verbatim
  (pointers by index, highlights by index/range). Same authoring vocabulary,
  less code.
- The `next`-pointers are explicit directed **`links`** (`[from, to]` index
  pairs). Omitting `links` defaults to a consecutive forward chain. Keeping node
  positions fixed while re-pointing links between Steps is what makes reversal /
  rewiring animate clearly: the arrow flips direction in place rather than nodes
  jumping around.
- Rendering: neighboring links (`|to - from| == 1`) draw as a **straight
  horizontal arrow** whose arrowhead shows direction (right = forward, left =
  reversed). Non-adjacent links draw as an **arc above** the row, for a cycle's
  back-edge. Arrow color is a new `Palette.linkColor` (also intended for tree /
  graph edges).
- Additive: `schemaVersion` stays `1`; `listVisual` joins the `step.visual`
  `oneOf`, selected by `type:"list"`.

## Consequences

- The representative (Reverse Linked List) only uses straight arrows, so that
  path is fully exercised. The arc path (cycles, merge interleaving) renders a
  curved line with a basic arrowhead; precise arrowhead orientation on arcs is a
  polish follow-up for when Linked List Cycle / Merge Two Lists are authored.
- "null" (prev before the head, a tail's next) isn't drawn as a node — it's
  carried in the caption and by the absence of an outgoing link. Good enough for
  the prev/curr/next reversal story; revisit if a lesson needs an explicit nil
  cap.
- Because nodes stay in place and only links move, a list whose logical order
  diverges from its display order (after reversal) is read via arrow direction,
  not left-to-right position — which is exactly the insight these problems teach.
