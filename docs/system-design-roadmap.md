# System Design — LearnKit Content Roadmap

_Status snapshot: 2026-09-26 — **55 lessons shipped** (the original 48, plus 7 extra case studies that ship with diagrams); the
`architecture` primitive + `diagram` block (ADR 0010) are now **built and verified**,
with the first diagram live in `load-balancers`. Remaining work is retrofitting
diagrams into the other 33 diagram-bearing lessons. Source syllabus:
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

## Engine prerequisites

These unblock every diagram-bearing lesson. Each is a normal "new primitive"
change per CLAUDE.md: schema + renderer + validator branch + tests + ADR.

- [x] **`architecture` primitive** — ninth `Visual` (ADR 0010): component nodes
      (`client|service|database|cache|queue|cdn|storage|lb|external`) at normalized
      `x,y`, directed/labeled connectors (`sync` solid / `async` dashed), optional
      tier/region groups. `ArchitectureVisualView` modeled on `GraphVisualView`
      (rounded-rect icon+label boxes, edge trimming, arrowheads). Covered by a
      `VisualRenderTests` case at 320×240 and decode tests. _(shipped)_
- [x] **`diagram` block** — article block embedding a `Visual`, rendered at a fixed
      band with an optional caption; validator recurses into the embedded visual.
      `ArticleRenderTests` exercises it. _(shipped)_
- [ ] **`table` block** — for capacity-estimation numbers and SQL-vs-NoSQL style
      comparisons (ADR 0010 lists it as a later block). Optional polish.
- [ ] **`code` block** — for API sketches (REST/gRPC signatures). Optional; many
      lessons can use `bullets` instead.

> **Authoring note (architecture diagrams).** Boxes are ~80pt wide; positions are
> hand-authored normalized `x,y` (no auto-layout). Keep nodes to **≤3 columns** at
> phone width and space columns ~0.35 apart so boxes don't overlap; put a labeled
> connector only where there's room between boxes (tight horizontal pairs crowd the
> label). Stack a tier vertically in one column. First real diagram lives in
> `building-blocks/load-balancers.json` as the reference.

## Coverage summary

| Track | Shipped | Planned | Format |
|---|---|---|---|
| Fundamentals | 12 | 0 | article (🟢, complete) |
| Building Blocks | 18 | 0 | article (prose v1 complete; diagrams pending) |
| Designing Systems | 23 | 0 | article (16 prose v1 with diagrams pending; 7 newer ones with diagrams) |
| Interview Method | 2 | 0 | article (🟢, complete) |
| **Total** | **55** | **0** | |

All four tracks now exist in `Content/manifest.json` with their `overview` +
SF Symbol `icon` (System Design `overview` has no `complexity` field). The only
remaining work is the **engine prerequisites** above: the 34 Building Blocks +
Designing Systems lessons shipped as **prose v1** — content complete, but the
marquee architecture **diagram** is still pending the `architecture` primitive
(ADR 0010) and should be
added to each in a later pass.

---

# Track plan

## 1. Fundamentals  ·  `system-design/fundamentals`  ·  article

The conceptual bedrock — vocabulary and tradeoffs. Mostly prose; a couple could
gain a small diagram later but read fine without one.

- [x] **Scaling: Vertical vs Horizontal** — `scaling-basics` _(shipped)_
- [x] **Abstractions in System Design** — what we hide and why; the building-block mindset _(shipped)_
- [x] **Remote Procedure Calls (RPC)** — network abstraction; call-a-function-on-another-machine, and where the abstraction leaks _(shipped)_
- [x] **Consistency Models** — strong → eventual spectrum; what each guarantees and costs _(shipped)_
- [x] **Failure Models** — fail-stop, crash, omission, Byzantine; what you design against _(shipped)_
- [x] **Availability** — nines, MTBF/MTTR, why 99.9 vs 99.99 changes the design _(shipped)_
- [x] **Reliability** — correctness over time; how it differs from availability _(shipped)_
- [x] **Scalability** — load dimensions; the NFR view (broader than vertical/horizontal) _(shipped)_
- [x] **Maintainability** — operability, simplicity, evolvability _(shipped)_
- [x] **Fault Tolerance** — replication, checkpointing, failover; redundancy as the lever _(shipped)_
- [x] **Back-of-the-Envelope Estimation** — QPS, storage, bandwidth math _(shipped; uses `bullets` for the number anchors — a `table` block is a later polish)_
- [x] **CAP and PACELC** — the consistency-vs-availability choice during a partition, and the latency tradeoff otherwise _(shipped)_

## 2. Building Blocks  ·  `system-design/building-blocks`  ·  article

The reusable components every design composes. Each is the marquee
**architecture-diagram** lesson type → still gated on ADR 0010 for the diagram,
but all shipped here as **prose v1** (content complete; diagram to be added once
the `architecture` primitive lands). All 18 are now authored.

- [x] **DNS** — how a name resolves to an IP; hierarchy and caching _(prose v1; diagram pending)_
- [x] **Load Balancers** — L4 vs L7, global vs local, algorithms, health checks _(✅ has architecture diagram — reference lesson)_
- [x] **Content Delivery Network (CDN)** — edge caching, push vs pull, invalidation _(prose v1; diagram pending)_
- [x] **Databases: SQL vs NoSQL** — types and when each fits _(prose v1; diagram pending)_
- [x] **Key-Value Store** — consistent hashing, replication, quorums, versioning, gossip _(prose v1; diagram pending)_
- [x] **Blob / Object Store** — buckets, metadata, large-object handling _(prose v1; diagram pending)_
- [x] **Database Replication** — leader/follower, sync vs async, read scaling _(prose v1; diagram pending)_
- [x] **Database Partitioning and Sharding** — horizontal/vertical, key choice, hotspots _(prose v1; diagram pending)_
- [x] **Distributed Cache** — cache-aside vs write-through, eviction, Redis vs Memcached _(prose v1; diagram pending)_
- [x] **Distributed Messaging Queue** — at-least-once, ordering, consumer groups _(prose v1; diagram pending)_
- [x] **Publish-Subscribe** — topics, fan-out, decoupling producers from consumers _(prose v1; diagram pending)_
- [x] **Rate Limiter** — token bucket, leaky bucket, fixed/sliding window _(prose v1; diagram pending)_
- [x] **Unique ID Generator** — Snowflake-style IDs, causality, monotonicity _(prose v1; diagram pending)_
- [x] **Sharded Counters** — write-hotspot fan-out for high-throughput counts _(prose v1; diagram pending)_
- [x] **Distributed Search** — inverted index, sharded index, scaling queries _(prose v1; diagram pending)_
- [x] **Distributed Logging** — log aggregation, correlation IDs, retention _(prose v1; diagram pending)_
- [x] **Distributed Monitoring** — metrics pipeline, golden signals, alerting _(prose v1; diagram pending)_
- [x] **Distributed Task Scheduler** — queues, workers, retries, dependencies _(prose v1; diagram pending)_

## 3. Designing Systems (Case Studies)  ·  `system-design/designing-systems`  ·  article

End-to-end designs that compose the building blocks via the RESHADED approach.
All shipped as **prose v1** (architecture diagram pending ADR 0010). Ordered
roughly easy → hard. The optional Pastebin warm-up was folded into TinyURL + Rate
Limiter rather than authored separately.

- [x] **Design TinyURL** — URL shortener; base62 encoding, redirect path, KV store _(prose v1; diagram pending)_
- [x] **Design a Web Crawler** — frontier, politeness, dedup, scale-out _(prose v1; diagram pending)_
- [x] **Design Twitter** — fan-out on write vs read, timeline, celebrity problem _(prose v1; diagram pending)_
- [x] **Design a Newsfeed System** — generation (fan-out) vs ranking, pagination _(prose v1; diagram pending)_
- [x] **Design Instagram** — media plane (blob + CDN) vs metadata plane, feed _(prose v1; diagram pending)_
- [x] **Design YouTube** — upload/transcode pipeline, storage, streaming, CDN _(prose v1; diagram pending)_
- [x] **Design WhatsApp** — real-time messaging, store-and-forward, presence _(prose v1; diagram pending)_
- [x] **Design Typeahead Suggestion** — trie/prefix store, offline top-k, latency _(prose v1; diagram pending)_
- [x] **Design Uber** — geospatial matching, write-heavy locations, dispatch _(prose v1; diagram pending)_
- [x] **Design Google Maps** — road graph, routing, tiling, ETA, traffic _(prose v1; diagram pending)_
- [x] **Design a Proximity Service (Yelp)** — geo-indexing (geohash/quadtree/S2) _(prose v1; diagram pending)_
- [x] **Design Quora** — Q&A feed, answer ranking, read-heavy serving _(prose v1; diagram pending)_
- [x] **Design Google Docs** — collaborative editing, OT vs CRDT, concurrency _(prose v1; diagram pending)_
- [x] **Design a Payment System** — idempotency, double-entry ledger, exactly-once _(prose v1; diagram pending)_
- [x] **Design a Code Deployment System** — artifact distribution, canary, rollback _(prose v1; diagram pending)_
- [x] **Design a ChatGPT-style System** — GPU serving, token streaming, context _(prose v1; diagram pending; folds in the source's AI-system chapters)_

Additional case studies beyond the source syllabus. Each ships with its diagram and
the full outline: Requirements, Scale (worked numbers), API, Data model, High-level
design, deep dives, and Bottlenecks and tradeoffs.

- [x] **Design Dropbox** — content-hashed chunking, dedup, per-folder journal sync, conflicted copies _(with diagram)_
- [x] **Design a Notification System** — priority and channel queues, retries, idempotent delivery, preferences _(with diagram)_
- [x] **Design Ticketmaster** — conditional seat holds with expiry, virtual waiting room, no double-selling _(with diagram)_
- [x] **Design an Ad Click Aggregator** — event-time windows, watermarks, exactly-once counting, batch reconciliation _(with diagram)_
- [x] **Design Slack** — per-gateway channel fan-out, ordering, reconnect catch-up, presence _(with diagram)_
- [x] **Design a Real-Time Leaderboard** — sorted sets for rank in O(log n), tie-breaks, sharding options _(with diagram)_
- [x] **Design a Stock Exchange** — price-time matching, sequencer and journal, deterministic replay, hot standby _(with diagram)_

## 4. Interview Method  ·  `system-design/interview-method`  ·  article

The *how* of answering — the framework, not logistics. Pure prose.

- [x] **The RESHADED Framework** — Requirements → Estimation → Storage → High-level → API → Detailed → Evaluate → Distinctive-features; the spine of every case study _(shipped)_
- [x] **Non-Functional Requirements Checklist** — the questions to ask before designing (availability, consistency, latency, scale) _(shipped)_

---

## What's left

All 48 lessons are authored and validating, and the `architecture` primitive +
`diagram` block are now built and verified. Remaining work:

1. ✅ **Build the `architecture` primitive + `diagram` block (ADR 0010)** — done;
   `load-balancers` carries the first real diagram as the reference.
2. **Retrofit diagrams into the remaining 33 prose-v1 lessons** — add a `diagram`
   block to each Building Blocks and Designing Systems lesson (load-balancers is
   done). Per-lesson edit, no new prose; easiest shapes first. Follow the authoring
   note above so boxes don't overlap.
3. **Optional polish** — `table` block for the capacity-estimation numbers
   (currently rendered as `bullets`), and a `code` block for API sketches.

## Reminders (from CLAUDE.md)

- Articles scroll, so the one-screen layout caps don't apply — **but** an embedded
  `architecture` diagram still must fit its width and look right at 320×240. Keep
  diagrams to a handful of nodes; a wide diagram reads as broken.
- New track ⇒ add its `overview` + SF Symbol `icon` to the manifest in the **same
  commit** as its first lesson. New primitive ⇒ schema + renderer + validator
  branch + tests + ADR (0010 already written).
- Conventional Commits, **no `Co-Authored-By` trailer**. Prefixes: `feat(content)`
  for lessons, `feat(engine)` for the primitive/blocks, `docs` for this file.
