# LearnKit

A micro-learning iPhone app. Users flip through short, visual, step-by-step walkthroughs that explain how to solve a problem or understand a concept — fast. The first subjects are DSA and System Design, but the model is built to extend to any subject.

## Language

**Subject**:
The top-level domain of knowledge a user is learning, e.g. "DSA" or "System Design". The extensibility axis — new subjects can be added without changing the model.
_Avoid_: Course, category, domain

**Track**:
A category or pattern within a Subject, e.g. "Two Pointers" or "Caching". Groups related Lessons and carries a short Overview of the pattern, shown above them.
_Avoid_: Module, section, pattern (in the data model — "pattern" stays a colloquial DSA word)

**Overview**:
A Track's short framing of its pattern — what it is and when it helps — shown inline above the Track's Lessons. Currently plain text; may later become a visual intro Lesson.
_Avoid_: Description, intro, summary (a Lesson's one-liner is its "summary", distinct from a Track's "overview")

**Lesson**:
One self-contained thing a user learns in a single sitting, e.g. "Valid Palindrome" or "Design a URL Shortener". The unit a user picks and opens.
_Avoid_: Problem, article, card, deck

**Step**:
The atomic micro-learning unit. An ordered position inside a Lesson consisting of exactly one Visual plus a short caption. A user advances through a Lesson one Step at a time. A Step is a self-contained *snapshot*: its Visual Spec is the complete state at that moment, not a delta from the previous Step. The app produces animation by diffing consecutive Steps.
_Avoid_: Slide, frame, page, panel

**Visual**:
The single diagram shown in a Step. Not a raster image — it is rendered natively in-app from a Visual Spec.
_Avoid_: Image, picture, graphic

**Visual Spec**:
The structured JSON that defines a Visual. Names one Primitive and supplies its data. This is what generation prompts produce and what the app stores and renders.
_Avoid_: Asset, image file, drawing

**Primitive**:
A reusable diagram type the renderer knows how to draw, e.g. "array", "binary-tree", "graph", "flow" (boxes-and-arrows). A Visual Spec is always exactly one Primitive plus its data. The set of Primitives is a small, deliberately-grown vocabulary; adding a genuinely new shape means adding a Primitive (schema + SwiftUI renderer), not just authoring content.
_Avoid_: Component, widget, shape, template
