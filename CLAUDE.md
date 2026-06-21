# CLAUDE.md — LearnKit

## What this is
LearnKit is a SwiftUI iOS app (iOS 26, Liquid Glass) that teaches DSA through
bite-size, animated lessons. All content is **offline JSON** in `Content/`,
bundled into the app. Engine + UI live in the `LearnKitKit` Swift package; the
Xcode app shell is in `LearnKit/`.

- Content model: `manifest.json` → subjects → tracks (each with an `overview`
  block + SF Symbol `icon`) → lessons. Each lesson is a JSON file of 3–12
  **steps**; each step has a `caption` (≤160 chars) and one `visual`.
- A visual is one of 8 **primitives**: `array` (style `cells`|`bars`), `grid`,
  `tree`, `list`, `graph`, `hashmap`, `intervals`, `rtree`. Each renders from its
  own `*VisualView.swift`; `VisualView` dispatches on the type.
- Steps are **snapshots** (full state), not deltas; the player animates the diff
  between consecutive visuals.

## Build, validate, commit
- Run the suite / validate content: `swift test --package-path LearnKitKit`
  (fast — ~0.5s when only JSON changed). Green looks like
  `Executed 14 tests, with 0 failures`. Most lessons are asserted *inside* a
  single test, so judge by **0 failures**, not the number.
- `ContentValidationTests` decodes the real `Content/` directory and runs
  `ContentValidator` on the manifest plus every lesson it references. A manifest
  entry pointing at a missing file fails; a file *not* referenced by the manifest
  is simply never validated.
- Commits: **Conventional Commits**, and **never add a `Co-Authored-By` trailer**
  in this repo (every commit is authored "Adarsh"). Prefixes in use:
  `feat(content)`, `feat(engine)`, `feat(ui)`, `fix(ui)`, `chore(app)`, `test`,
  `docs`.
- Atomic unit for content: **one lesson file + its single manifest entry,
  committed together**, so every commit's tree validates on its own. Grow the
  manifest one entry at a time rather than adding a batch up front.

## Content invariants (enforced by ContentValidator)
- `schemaVersion: 1`; ids/subjects/tracks are kebab-case; a lesson's
  `id`/`title`/`difficulty` must match its manifest entry exactly.
- 3–12 steps; every caption ≤160 chars.
- Highlights: array/list set exactly one of `index` or `range`; grid sets
  `row+col` (one cell) or `rows+cols` (a region), never both; all indices in
  bounds.
- Pointer labels ≤3 chars, unique within a step, non-empty. `tree`/`rtree` need a
  `root`. `intervals`: `axisMin < axisMax`, `end >= start`. `bars` style requires
  all cells numeric.
- New track ⇒ add an `overview` (tagline, whenToUse[], keyIdea, complexity) and an
  SF Symbol `icon`. New primitive ⇒ schema + renderer + validator branch + tests +
  an ADR in `docs/adr/`.

## ⚠️ The one-screen rule (the recurring layout bug — read before any UI/content change)
**Symptom:** a visual overlaps the nav bar, a lesson's pieces look
misplaced/clipped, controls are cramped, or the *next* lesson bleeds into the
current screen.

**Root cause (now fixed — see "How it's handled now"):** the lesson *was* rendered
as a **fixed-height, non-scrolling page**.
`TrackFeedView.page(...)` pins each page to the viewport height and `.clipped()`;
inside, `LessonPage.player` is a `VStack` of `Spacer`s around a **hard-coded
`220`-pt visual band** (`VisualView(...).frame(height: 220)`), and
`InstructionView` renders **one line per caption sentence**. When a lesson's
intrinsic height (difficulty badge + title + multi-line `problem` + `example`
panel + 220-pt visual + multi-sentence caption + controls) exceeds the page, the
`Spacer`s collapse to 0, the content overflows, gets centered, and `.clipped()`
chops it — the header slides under the nav bar, cells ride to the top edge, and
during paging the neighbour shows through.

**Why it recurs:** there is **no guarantee or test that a lesson fits**.
`VisualRenderTests` only renders 2–3-cell sample visuals at a fixed 320×240 and
asserts "image is not empty" — it never renders a full `LessonPage` at a phone
size or checks fit. So every feature that grows a page (longer problem text, an
extra caption sentence, a taller/wider visual, more chrome) silently re-triggers
the overflow, invisibly in CI and only on-device.

**Rules when adding content or UI:**
1. Treat **one screen on the smallest supported device** as the height budget.
   The player must hold visual + caption + step controls without clipping.
2. **Captions are short.** Each sentence becomes its own line — prefer ≤2
   sentences and stay well under the 160-char cap; don't pack a paragraph in.
   `problem`/`example` is the long-form header text — don't rely on it being
   visible on the player step.
3. **Visuals fit a band, they don't demand one.** Keep arrays ≤ ~7 cells, grids
   small, trees/rtrees shallow and ≤ ~6 leaves. A wide visual both overflows
   horizontally *and* forces cells tiny — both read as "broken".
4. Renderers must **stay inside their given frame** — every `*VisualView` uses
   `GeometryReader` + `.position()`; derive positions from the size you're given,
   never assume more. A new renderer must look right at 320×240 **and** at a
   cramped height.
5. If you touch `LessonPage`/`TrackFeedView` height math, re-verify a worst-case
   lesson (long `problem` + multi-sentence caption + tall visual, e.g.
   `house-robber-ii`, `min-cost-climbing-stairs`) on the smallest device, and
   keep the page `.clipped()` so a neighbour can never peek.

**How it's handled now (keep it this way):** `LessonPage.player` makes the visual
the one elastic element — a band that scales with the available height, clamped
120–260 pt (`stepBody(visualHeight:)`), so it yields space to the caption and
controls when the screen is tight. Fonts are never scaled to the screen; they
stay on Dynamic Type. **Do not** reintroduce `ViewThatFits` or a nested
`ScrollView` in the player: nested inside the feed's paging `ScrollView` they
crash the SwiftUI async renderer (`EXC_BREAKPOINT` on
`com.apple.SwiftUI.AsyncRenderer`). The fit guarantee comes from the elastic band
plus the `LessonLayoutBudgetTests` caps, which keep content small enough to fit —
at the very largest Dynamic Type a long caption may clip at the page edge (the
feed's `.clipped()` contains it; no overlap, no crash). The caps:

> **array/list ≤ 8 cells · grid ≤ 7 cols / ≤ 24 cells · tree ≤ 15 nodes / depth ≤ 5
> · rtree ≤ 8 leaves / depth ≤ 5 · intervals ≤ 6 rows · caption ≤ 4 sentences.**

If a new lesson trips a cap, **shrink the example or tighten the caption — don't
raise the cap.** The caps are sized for the narrowest supported device; raising
one reopens the overflow this whole section exists to prevent.

## Pre-flight checklist (every change)
- [ ] `swift test --package-path LearnKitKit` is green (0 failures).
- [ ] New/edited lessons obey the content invariants (the validator catches most).
- [ ] Any lesson you touched **fits one screen** on the smallest device — no
      clipped header, no neighbour peeking (the one-screen rule above).
- [ ] Commit is conventional-prefixed with **no co-author trailer**; content
      commits pair the lesson file with its manifest entry.
