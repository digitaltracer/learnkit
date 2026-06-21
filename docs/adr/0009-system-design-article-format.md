---
status: accepted
---

# System Design as a second lesson format: scrollable articles

System Design content is a different shape from DSA. A DSA lesson is a step-by-step
trace of a small mutating data structure, rendered as a **fixed-height,
non-scrolling page** in a vertical *paging* feed (ADR 0004) and kept on one screen
by the layout-budget caps. System Design is **architecture diagrams plus long-form
prose** — requirements, capacity math, tradeoffs, API sketches — content that is
intrinsically long and must **scroll**.

## The constraint

`LessonPage` is pinned to the viewport and `.clipped()`; the feed is a paging
`ScrollView`. **Nesting a `ScrollView` inside that paging feed crashes the SwiftUI
async renderer** (`EXC_BREAKPOINT` on `com.apple.SwiftUI.AsyncRenderer`) — see
CLAUDE.md. So "make a lesson scroll" is simply not available inside the existing
player. The fix is to route long content somewhere that is *not* nested in the
paging feed.

## Decisions

- **A per-lesson `format` discriminator** on `Lesson` (`"steps"` default |
  `"article"`), additive — `schemaVersion` stays `1`. `steps` becomes optional and
  a new optional `blocks: [Block]` carries article content. Old lessons (no
  `format`) decode and behave exactly as before.
- **An article is an ordered list of typed `Block`s**, decoded by a `type` field
  exactly like `Visual`. v1 prose blocks: `heading`, `paragraph`, `bullets`,
  `callout`. Later phases add `diagram` (embeds a `Visual` — see ADR 0010),
  `table`, and `code`.
- **Articles are NOT shown in the paging feed.** They get their own destination,
  `ArticleLessonView`, a **plain top-level `ScrollView`** reached by a
  `NavigationStack` push. Because it is top-level (never nested inside the paging
  feed) it scrolls freely with no crash risk — this is the entire reason a second
  renderer exists instead of retrofitting the player.
- **Routing branches on a `TrackNode.format`** (`"steps"` default | `"article"`):
  a `steps` track opens `TrackFeedView`; an `article` track opens a scrollable
  **table-of-contents** of its articles, each row pushing `ArticleLessonView`.
- **Progress reuses `LessonProgressStore`**: an article counts as one unit;
  reaching the end (scroll-to-bottom or a Done action) calls `markCompleted`. The
  catalog's completed/total counts and "Continue" keep working unchanged.
- **The one-screen budget caps (`LessonLayoutBudgetTests`) do not apply to
  articles** — they scroll. The validator instead enforces article-specific
  structure: non-empty `blocks`, exactly one of `steps`/`blocks` for the format,
  non-empty block text, a valid `callout` kind.

## Consequences

- One manifest, one catalog, one progress store — two renderers. Subjects are
  already collapsible on the home page, so DSA can fold away while System Design
  grows alongside it.
- The crash-prone "scroll inside the paging feed" path is never taken; articles
  live entirely outside the two-axis feed model.
- `Lesson` now carries two mutually-exclusive bodies (`steps` **xor** `blocks`);
  the validator must enforce the xor, since the type system can't.
- A "mixed" lesson (animated steps that also scroll) is explicitly out of scope —
  the two formats stay separate.
- A reference article exists at `Content/system-design/fundamentals/scaling-basics.json`,
  authored to this schema. It is intentionally **not** in `manifest.json` until the
  engine that loads it lands (next phase), so the current suite never decodes it.
