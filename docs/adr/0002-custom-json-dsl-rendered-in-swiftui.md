---
status: proposed
---

# Visual Specs use a custom JSON DSL rendered natively in SwiftUI

A Visual Spec is JSON conforming to a small in-house schema of diagram Primitives (array, tree, graph, box-and-arrow flow, ...), drawn natively with SwiftUI `Canvas`. We rejected SVG and Mermaid.

We chose a custom DSL because it gives full control over pixels and colors (free dark mode / theming / accessibility), keeps the structured semantics needed to *animate* transitions between Steps (e.g. a pointer sliding from index 0 to 1 — the app's signature interaction), is far more reliable to generate from an LLM (JSON-against-a-schema vs. free-form SVG), and is tiny on disk (~1-2 KB per Step). The cost is building one SwiftUI renderer per Primitive, but the Primitive set is finite and reused across every Lesson.

## Consequences

- A new kind of Visual that no existing Primitive can express requires adding a Primitive (schema + renderer), not just authoring content. The Primitive set is a deliberate, slowly-growing vocabulary.
