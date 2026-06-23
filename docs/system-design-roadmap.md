# System Design — LearnKit Content Roadmap

_Status snapshot: 2026-06-24 — **1 / ~55 lessons shipped**. Source syllabus:
https://www.educative.io/courses/grokking-the-system-design-interview (Grokking
Modern System Design Interview — 48 chapters / 212 platform lessons, curated below)._

This is the master backlog for building out the **System Design** subject as
LearnKit content. It mirrors `neetcode150-roadmap.md`: pick up **one checkbox at a
time**; each is sized to be a single, self-contained unit of work — **one lesson
file + its single manifest entry, committed together** (see CLAUDE.md), so every
commit's tree validates on its own.

## How to read this

System Design lessons use the **article** format (ADR 0009): an ordered list of
typed `blocks`, rendered as a scrollable `ArticleLessonView` — *not* the animated
step player. So unlike the DSA roadmap, the gating question isn't a data-structure
primitive, it's **whether the lesson needs an architecture diagram**.

- `[x]` **done** — already a lesson in `Content/system-design/`.
- `[ ]` 🟢 **prose-ready** — buildable **now** with the shipped article blocks
  (`heading`, `paragraph`, `bullets`, `callout`). No engine change. Author JSON →
  `swift test --package-path LearnKitKit` (ContentValidationTests) → atomic commit.
  This is the proven pipeline, same as `scaling-basics`.
- `[ ]` 🟡 **needs-diagram** — the lesson *works* as prose, but its marquee visual
  is an **architecture diagram**, which is blocked on the `architecture` primitive
  + `diagram` block (**ADR 0010 — accepted, not yet implemented**). Two ways to
  play each: ship a prose-only v1 now and add the diagram later, **or** build the
  primitive first and ship the lesson whole. Flagged so the choice is explicit.

> **Curation note.** The source course interleaves platform features that are
> *not* content topics: course logistics ("Course Structure"), interview
> meta/logistics, "Mock Interview" (Premium), "Let AI Evaluate…", per-chapter
> quizzes, and the marketing "Free System Design Lessons" chapter. Those are
> intentionally **omitted** here. What remains is the actual System Design
> material: concepts, building blocks, and end-to-end designs.

## Engine prerequisites (do before / alongside the 🟡 content)

These unblock every diagram-bearing lesson. Each is a normal "new primitive"
change per CLAUDE.md: schema + renderer + validator branch + tests + the ADR
already exists.

- [ ] **`architecture` primitive** — ninth `Visual` (ADR 0010): component nodes
      (`client|service|database|cache|queue|cdn|storage|lb|external`) at normalized
      `x,y`, directed/labeled connectors (`sync` solid / `async` dashed), optional
      tier/region groups. Renderer modeled on `GraphVisualView`. Add a
      `VisualRenderTests` case at 320×240.
- [ ] **`diagram` block** — article block that embeds a `Visual` (the delivery
      vehicle for `architecture` inside an article). Validator: embedded visual
      must itself validate.
- [ ] **`table` block** — for capacity-estimation numbers and SQL-vs-NoSQL style
      comparisons (ADR 0010 lists it as a later block).
- [ ] **`code` block** — for API sketches (REST/gRPC signatures). Optional; many
      lessons can use `bullets` instead.

## Coverage summary

| Track | Shipped | Planned | Format |
|---|---|---|---|
| Fundamentals | 1 | ~11 | article (mostly 🟢) |
| Building Blocks | 0 | ~18 | article (mostly 🟡 — diagram) |
| Designing Systems | 0 | ~16 | article (🟡 — diagram) |
| Interview Method | 0 | ~2 | article (🟢) |
| **Total** | **1** | **~47** | |

New tracks (Building Blocks, Designing Systems, Interview Method) each need an
`overview` block (tagline, whenToUse[], keyIdea) and an SF Symbol `icon` in the
manifest before their first lesson — see the System Design subject entry in
`Content/manifest.json` for the shape (note: System Design `overview` has no
`complexity` field).

---

# Track plan

## 1. Fundamentals  ·  `system-design/fundamentals`  ·  article

The conceptual bedrock — vocabulary and tradeoffs. Mostly prose; a couple could
gain a small diagram later but read fine without one.

- [x] **Scaling: Vertical vs Horizontal** — `scaling-basics` _(shipped)_
- [ ] 🟢 **Abstractions in System Design** — what we hide and why; the building-block mindset
- [ ] 🟢 **Remote Procedure Calls (RPC)** — network abstraction; call-a-function-on-another-machine, and where the abstraction leaks
- [ ] 🟢 **Consistency Models** — strong → eventual spectrum; what each guarantees and costs
- [ ] 🟢 **Failure Models** — fail-stop, crash, omission, Byzantine; what you design against
- [ ] 🟢 **Availability** — nines, MTBF/MTTR, why 99.9 vs 99.99 changes the design
- [ ] 🟢 **Reliability** — correctness over time; how it differs from availability
- [ ] 🟢 **Scalability** — load dimensions; the NFR view (broader than vertical/horizontal)
- [ ] 🟢 **Maintainability** — operability, simplicity, evolvability
- [ ] 🟢 **Fault Tolerance** — replication, checkpointing, failover; redundancy as the lever
- [ ] 🟢 **Back-of-the-Envelope Estimation** — QPS, storage, bandwidth math _(wants a `table` block; works as `bullets` until then)_
- [ ] 🟢 **CAP / PACELC Theorem** _(recommended addition — not its own chapter in the source, but the canonical framing the consistency content implies)_

## 2. Building Blocks  ·  `system-design/building-blocks`  ·  article

The reusable components every design composes. Each is the marquee
**architecture-diagram** lesson type → most are 🟡 (gated on ADR 0010), but each
can ship prose-first.

- [ ] 🟡 **DNS** — how a name resolves to an IP; hierarchy and caching
- [ ] 🟡 **Load Balancers** — L4 vs L7, global vs local, algorithms, health checks
- [ ] 🟡 **Databases: SQL vs NoSQL** — types and when each fits
- [ ] 🟡 **Database Replication** — leader/follower, sync vs async, read scaling
- [ ] 🟡 **Database Partitioning / Sharding** — horizontal/vertical, key choice, hotspots
- [ ] 🟡 **Key-Value Store** — consistent hashing, replication, versioning, fault detection
- [ ] 🟡 **Content Delivery Network (CDN)** — edge caching, push vs pull, invalidation
- [ ] 🟡 **Unique ID Generator (Sequencer)** — Snowflake-style IDs, causality, monotonicity
- [ ] 🟡 **Distributed Cache** — cache-aside vs write-through, eviction, Redis vs Memcached
- [ ] 🟡 **Distributed Messaging Queue** — at-least-once, ordering, consumer groups
- [ ] 🟡 **Publish-Subscribe** — topics, fan-out, decoupling producers from consumers
- [ ] 🟡 **Rate Limiter** — token bucket, leaky bucket, fixed/sliding window
- [ ] 🟡 **Blob / Object Store** — buckets, metadata, large-object handling
- [ ] 🟡 **Distributed Search** — inverted index, sharded index, scaling queries
- [ ] 🟡 **Distributed Logging** — log aggregation, ordering, retention
- [ ] 🟡 **Distributed Monitoring** — metrics pipeline, server- vs client-side errors, alerting
- [ ] 🟡 **Distributed Task Scheduler** — queues, workers, retries, dependencies
- [ ] 🟡 **Sharded Counters** — write-hotspot fan-out for high-throughput counts

## 3. Designing Systems (Case Studies)  ·  `system-design/designing-systems`  ·  article

End-to-end designs that compose the building blocks via the RESHADED approach.
All 🟡 — each is anchored by an architecture diagram (and usually capacity math).
Ordered roughly easy → hard, so author top-down.

- [ ] 🟡 **Design TinyURL** — URL shortener; encoding, redirect path, KV store _(good first design)_
- [ ] 🟡 **Design a Web Crawler** — frontier, politeness, dedup, scale-out
- [ ] 🟡 **Design a Rate-Limited API / Pastebin** _(optional warm-up reusing building blocks)_
- [ ] 🟡 **Design Twitter** — fan-out on write vs read, timeline, celebrity problem
- [ ] 🟡 **Design a Newsfeed System** — ranking, fan-out, feed generation
- [ ] 🟡 **Design Instagram** — media upload, feed, blob store + CDN
- [ ] 🟡 **Design YouTube** — upload/transcode pipeline, storage, streaming, CDN
- [ ] 🟡 **Design WhatsApp** — real-time messaging, delivery receipts, presence
- [ ] 🟡 **Design Typeahead / Autocomplete** — trie/prefix store, ranking, latency
- [ ] 🟡 **Design Uber** — geospatial matching, dispatch, surge, payments
- [ ] 🟡 **Design Google Maps** — road graph, routing, tiling, ETA
- [ ] 🟡 **Design a Proximity Service (Yelp)** — geo-indexing (geohash/quadtree), nearby search
- [ ] 🟡 **Design Quora** — Q&A feed, ranking, read-heavy serving
- [ ] 🟡 **Design Google Docs** — collaborative editing, OT/CRDT, concurrency
- [ ] 🟡 **Design a Payment System** — idempotency, ledgers, fraud, exactly-once
- [ ] 🟡 **Design a Code Deployment System** — artifact distribution, rollout, rollback
- [ ] 🟡 **Design a ChatGPT-style LLM System** _(modern; groups the AI-system chapters: serving, data infra, support bot, code assistant)_

## 4. Interview Method  ·  `system-design/interview-method`  ·  article

The *how* of answering — the framework, not logistics. Pure prose.

- [ ] 🟢 **The RESHADED Framework** — Requirements → Estimation → Storage → High-level → API → Detailed → Evaluate → Distinctive-features; the spine of every case study
- [ ] 🟢 **Non-Functional Requirements Checklist** — the questions to ask before designing (availability, consistency, latency, scale)

---

## Suggested build order

1. **Finish Fundamentals (🟢)** — pure prose, proven pipeline, grows the subject
   immediately with zero engine work. Knock these out one commit at a time.
2. **Author the Interview Method track (🟢)** — also prose; RESHADED becomes the
   reference the case studies lean on.
3. **Build the `architecture` primitive + `diagram` block (ADR 0010)** — the one
   engine investment that unlocks both remaining tracks. Land it with a render
   test before authoring content against it.
4. **Building Blocks (🟡)** — author against the new primitive, easiest first
   (DNS, Load Balancers) so the renderer is exercised on simple shapes before the
   fan-out-heavy ones.
5. **Designing Systems (🟡)** — last; each reuses building-block diagrams and the
   RESHADED spine, so they go faster once 1–4 exist. TinyURL first.

## Reminders (from CLAUDE.md)

- Articles scroll, so the one-screen layout caps don't apply — **but** an embedded
  `architecture` diagram still must fit its width and look right at 320×240. Keep
  diagrams to a handful of nodes; a wide diagram reads as broken.
- New track ⇒ add its `overview` + SF Symbol `icon` to the manifest in the **same
  commit** as its first lesson. New primitive ⇒ schema + renderer + validator
  branch + tests + ADR (0010 already written).
- Conventional Commits, **no `Co-Authored-By` trailer**. Prefixes: `feat(content)`
  for lessons, `feat(engine)` for the primitive/blocks, `docs` for this file.
