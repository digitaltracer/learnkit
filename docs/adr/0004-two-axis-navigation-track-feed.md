---
status: proposed
---

# A Track is a vertical feed (Overview → Lessons); Steps are the horizontal axis

The catalog lists **Tracks**, not Lessons. Opening a Track presents a **vertical paged feed**: the first page is the Track's Overview (what the pattern is, when to use it, the key idea), and each subsequent page is one Lesson. Swiping up/down moves through the feed; inside a Lesson, tap or swipe left/right advances the Steps. Two axes: vertical = move through the track, horizontal = move through a lesson's steps.

We chose this over a flat catalog that lists every Lesson inline because: (1) it **scales** — 16 patterns × many lessons never becomes one giant scroll; each Track is a self-contained feed; (2) the **Overview gets a full page** to actually teach "when do I reach for this," instead of crowding a list header; (3) the vertical feed matches the familiar, low-friction "next thing" gesture, while horizontal steps preserve the sense of an ordered progression within a lesson (see the gesture-semantics reasoning that led here). The per-Lesson "cover" screen from the Tier 2 build was retired — in a feed an extra Start tap per lesson is friction, and the Overview page now does the framing.

## Consequences

- Entering a Track eagerly loads all its Lesson files to build the feed pages (fine at current scale; revisit if a Track grows very large).
- A vertical paging ScrollView wraps each Lesson's horizontal step gesture; horizontal swipes must not be captured by vertical paging. Tap-to-advance and Next/Back are the reliable primary controls; horizontal swipe is a secondary affordance.
