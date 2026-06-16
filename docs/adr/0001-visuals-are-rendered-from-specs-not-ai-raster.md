---
status: proposed
---

# Visuals are rendered from specs, not AI-generated raster images

A Step's Visual is produced by generating a **structured diagram spec** (text/JSON) and rendering it in-app, rather than by generating a raster image (PNG) from a text-to-image model.

We chose this because the core content (DSA especially) requires *precise* technical state — exact array cell counts, legible digits, pointers on specific indices, consistent style across a sequence of Steps. AI raster generators reliably get these wrong (wrong counts, garbled labels, style drift step-to-step). Specs are pixel-accurate, crisp at any resolution, re-themeable (dark mode), tiny on disk, and consistent across a Lesson — and AI is good at producing structured specs from prompts, so the "generate it with a prompt" workflow is preserved; the prompts just target a spec format instead of a PNG.

## Considered Options

- **AI raster images (PNG)** — rejected: inaccurate for precise technical diagrams, style drift across a sequence.
- **Hand-authored diagrams (Figma/Excalidraw)** — rejected for now: highest quality but fully manual, no prompt-driven generation, doesn't scale.
- **Hybrid (rendered DSA + raster System Design)** — rejected for now: two pipelines to maintain.
