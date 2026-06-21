---
status: accepted
---

# The `architecture` primitive (system-design diagrams)

System Design articles need architecture diagrams: labeled component boxes
(client, load balancer, service, cache, database, queue, CDN, object store) joined
by labeled, directed connectors, sometimes grouped into tiers or regions. This is
the marquee visual of the System Design subject. It is implemented *after* the
article-prose scaffold (ADR 0009); the decision is documented here up front so the
schema is fixed before content authoring begins.

## Decisions

- **`architecture` joins the `Visual` enum** as a ninth primitive (ADR 0005's
  polymorphic-`Visual` pattern), so it inherits `VisualView` dispatch, a
  `ContentValidator` branch, and `VisualRenderTests`. A System Design article
  shows one via a **`diagram` block that embeds a `Visual`** — so a diagram block
  can in principle embed any primitive, but `architecture` is its purpose.
- **Component nodes**: `id`, `title`, optional `subtitle`, a `kind`
  (`client|service|database|cache|queue|cdn|storage|lb|external`) that drives
  shape / tint / SF-Symbol, and **explicit normalized `x`,`y` in 0…1** —
  deterministic, **no auto-layout**, exactly the call made for `graph`
  (force-directed layout is hard to keep stable and legible at this size;
  hand-authored positions read better).
- **Connectors**: `from`, `to`, optional `label` ("read" / "async" / "gRPC"),
  `directed` (default `true`), `style` (`sync` → solid / `async` → dashed), and an
  optional `state` (reuse `HighlightState`).
- **Groups** (optional): a labeled rounded-rectangle backing a set of node `id`s —
  a tier or a region.
- **The renderer is modeled on `GraphVisualView`** — the same normalized-position
  placement, edge-trimming, and arrowhead geometry — with rounded-rect icon+label
  nodes, edge labels, and group backings instead of plain circles. Reusing proven
  layout math is deliberate: new SwiftUI layout can't be visually verified without
  a simulator, so we minimize novel geometry and lean on render-to-image tests.

## Consequences

- Validation is **structural only**: unique node `id`s, positions in 0…1,
  connectors and group members reference real nodes. No index bounds (it is not
  index-addressed), same as `graph` / `rtree`.
- Diagram correctness depends on hand-authored positions; sloppy coordinates look
  cramped — an acceptable trade for deterministic, legible layouts (same as
  `graph`). A future helper could snap common shapes (tiered, fan-out) to grids.
- A **legibility cap** (a new test, *not* the one-screen budget): `architecture`
  ≤ ~12 nodes and a small group count, so a single diagram stays readable.
  Articles scroll, so this guards diagram legibility, not page fit.
- Because diagrams live only in articles (which scroll), a wide diagram may scroll
  **horizontally within its own block**. Horizontal-in-vertical nesting is not the
  paging-feed crash case (ADR 0009) and is allowed.
