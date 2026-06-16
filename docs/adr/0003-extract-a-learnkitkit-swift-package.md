---
status: proposed
---

# Core logic lives in a LearnKitKit Swift package; the app target holds only UI

The Codable models, the bundled-content loader, and the Visual rendering engine (Primitive renderers + step-diff animation) live in a local Swift package, `LearnKitKit`, with its own Tests target. The `LearnKit` iOS app target depends on the package and contains only SwiftUI app/UI code. This mirrors `pipeline`'s `PipelineKit` split.

We chose this because the architecture (see ADR-0001, ADR-0002) centers on a *growing engine* of Primitive renderers driven by structured specs — pure, deterministic logic that is the app's core asset and benefits most from isolation, a stable `public` API, and unit tests. Testing matters more than usual here because content is LLM-generated and must be validated (JSON decodes, pointer indices in bounds, Primitives render correctly), and a package Tests target is the natural home for that. The same engine is also the dependency for likely future targets — a widget, an App Clip, an iPad/macOS build, and a CI content-validator — none of which can import an app target. The upfront Xcode wiring cost was the only argument against, and the owner has chosen the better long-run structure over a faster start.

## Note

This supersedes an earlier draft of ADR-0003 that recommended a single app target for the MVP; that recommendation was driven by reducing beginner friction, a constraint the owner has explicitly set aside.
