# NeetCode 150 — LearnKit Content Roadmap

_Status snapshot: 2026-06-22 — **COMPLETE, 150 / 150**. Source list: https://neetcode.io/practice/practice/neetcode150_

This is the master backlog for covering the NeetCode 150 as LearnKit Lessons.
Pick up **one checkbox at a time**; each is sized to be a single, self-contained
unit of work that does not need the rest of the list in context.

## How to read this

LearnKit renders every Visual from a **Primitive**. Today the renderer knows
exactly one: `array` (`style: cells | bars`) with `pointers` and `highlights`.
So each problem is tagged by what it needs before it can be authored:

- `[x]` **done** — already a Lesson in `Content/`
- `( )` 🟢 **array** — buildable now, no engine change. Just author JSON →
  `swift test` (ContentValidationTests) → atomic commit. This is the proven pipeline.
- `( )` 🟡 **\<primitive\>** — blocked until a new Primitive (schema + SwiftUI
  renderer + validator rule) is built. Tag names:
  - `grid` — 2-D matrix / DP table
  - `tree` — binary tree, BST (and later reused for heap, trie)
  - `list` — singly/doubly linked list nodes
  - `graph` — nodes + edges (directed/weighted)
  - `hashmap` — key→value map / set
  - `heap` — binary heap (array-backed; could approximate with `array`)
  - `rtree` — recursion / decision tree (backtracking)
  - `intervals` — intervals on a timeline

## Coverage summary

| Bucket | Count |
|---|---|
| ✅ Done | 150 / 150 |
| 🎉 Remaining | 0 |
| **Total** | **150** |

_Primitives shipped: `array`, `grid`, `tree`, `list`, `graph`, `hashmap`, `intervals`, `rtree`._
_No new primitives were needed for the final set: **heaps reuse `tree`** (a heap is a
complete binary tree) and **tries reuse `rtree`** (n-ary, each edge a letter)._

**All 150 are now shipped as Lessons in `Content/`.** The tables below are kept for
historical context — they describe the original build order, not remaining work.

Blocked work, by primitive that unlocked it (historical):

| Primitive | Unlocks |
|---|---|
| `grid` | 25 (matrices, 2-D DP, grid-graphs) |
| `tree` | 15 (Trees) |
| `graph` | 12 (Graphs + Advanced Graphs) |
| `list` | 10 (Linked List) |
| `heap` | 7 |
| `rtree` | 7 (Backtracking) |
| `hashmap` | 6 |
| `intervals` | 6 |
| `trie` (extends `tree`) | 3 |

---

# Task plan

Phases are ordered by return-on-effort and dependency. Finish a phase (or any
slice of it) before opening the next — that's what keeps context clean. Inside a
phase, every line is independently pick-up-able.

## Phase 1 — Array-only content (no engine changes)

45 lessons, all using the existing `array` primitive. Highest leverage: zero
Swift, pure authoring on the established pipeline. Grouped by destination track.

**Extend existing track: Sliding Window**
- [x] Longest Repeating Character Replacement (M) _(2026-06-21)_
- [x] Permutation in String (M) _(2026-06-21)_
- [x] Minimum Window Substring (H) _(2026-06-21)_
- [x] Sliding Window Maximum (H) _(2026-06-21)_

**Extend existing track: Stack**
- [x] Evaluate Reverse Polish Notation (M) _(2026-06-21)_
- [x] Car Fleet (M) _(2026-06-21)_
- [x] Largest Rectangle in Histogram (H) — `bars` _(2026-06-21)_

**Extend existing track: Binary Search**
- [x] Koko Eating Bananas (M) — binary search on the answer _(2026-06-21)_
- [x] Find Minimum in Rotated Sorted Array (M) _(2026-06-21)_
- [x] Median of Two Sorted Arrays (H) — two arrays + partition _(2026-06-22)_

**New track: Arrays & Hashing** (array-friendly members only)
- [x] Contains Duplicate (E) _(2026-06-21)_
- [x] Valid Anagram (E) — letter-count cancel _(2026-06-21)_
- [x] Encode and Decode Strings (M) — length-prefix _(2026-06-21)_
- [x] Product of Array Except Self (M) — prefix/suffix passes _(2026-06-21)_

**New track: 1-D Dynamic Programming**
- [x] Climbing Stairs (E) _(2026-06-21)_
- [x] Min Cost Climbing Stairs (E) _(2026-06-21)_
- [x] House Robber (M) _(2026-06-21)_
- [x] House Robber II (M) _(2026-06-21)_
- [x] Decode Ways (M) _(2026-06-21)_
- [x] Coin Change (M) _(2026-06-21)_
- [x] Word Break (M) _(2026-06-21)_
- [x] Longest Increasing Subsequence (M) _(2026-06-21)_
- [x] Partition Equal Subset Sum (M) — 1-D boolean dp _(2026-06-21)_
- [x] Longest Palindromic Substring (M) — expand-around-center _(2026-06-21)_
- [x] Palindromic Substrings (M) — expand-around-center _(2026-06-21)_

**New track: Greedy**
- [x] Jump Game (M) _(2026-06-21)_
- [x] Jump Game II (M) _(2026-06-21)_
- [x] Gas Station (M) _(2026-06-21)_
- [x] Hand of Straights (M) _(2026-06-21)_
- [x] Merge Triplets to Form Target Triplet (M) _(2026-06-21)_
- [x] Partition Labels (M) _(2026-06-21)_
- [x] Valid Parenthesis String (M) _(2026-06-21)_

**New track: Bit Manipulation** (cells hold bits)
- [x] Single Number (E) _(2026-06-21)_
- [x] Number of 1 Bits (E) _(2026-06-21)_
- [x] Counting Bits (E) _(2026-06-21)_
- [x] Reverse Bits (E) _(2026-06-21)_
- [x] Missing Number (E) _(2026-06-21)_
- [x] Sum of Two Integers (M) _(2026-06-21)_
- [x] Reverse Integer (M) _(2026-06-21)_

**New track: Math & Geometry** (array-friendly members only)
- [x] Happy Number (E) — value sequence _(2026-06-21)_
- [x] Plus One (E) _(2026-06-21)_
- [x] Pow(x, n) (M) — caption-heavy; value sequence _(2026-06-21)_
- [x] Multiply Strings (M) — digit arrays _(2026-06-21)_

**Slots into Linked List / Backtracking but is array-renderable**
- [x] Find the Duplicate Number (M) — Floyd's cycle over array indices _(2026-06-21)_
- [x] Generate Parentheses (M) — string built step by step _(2026-06-21)_

## Phase 2 — `grid` primitive (biggest unlock: 25 lessons)

- [x] **Engine:** add `grid` primitive — `Visual` made polymorphic (dispatch on
      `type`), `GridVisual` spec (`rows`, `pointers` by row/col, `highlights` by
      cell or region), `GridVisualView` renderer, validator branch, schema
      `oneOf`, decode tests, ADR 0005. Reuses `HighlightState`/`Palette`. _(2026-06-17)_

Then author (each a checkbox):

_Math & Geometry (matrices)_
- [x] Rotate Image (M) _(2026-06-21)_
- [x] Spiral Matrix (M) — first grid lesson; proves matrix traversal _(2026-06-17)_
- [x] Set Matrix Zeroes (M) _(2026-06-21)_

_Binary Search / Arrays & Hashing on a grid_
- [x] Search a 2D Matrix (M) _(2026-06-21)_
- [x] Valid Sudoku (M) _(2026-06-22)_

_Graphs on a grid (BFS/DFS flood fill)_
- [x] Number of Islands (M) _(2026-06-21)_
- [x] Max Area of Island (M) _(2026-06-21)_
- [x] Pacific Atlantic Water Flow (M) _(2026-06-22)_
- [x] Surrounded Regions (M) _(2026-06-21)_
- [x] Rotting Oranges (M) _(2026-06-21)_
- [x] Walls and Gates (M) _(2026-06-22)_

_Backtracking on a grid_
- [x] Word Search (M) _(2026-06-21)_
- [x] N-Queens (H) _(2026-06-21)_

_Advanced graph on a grid_
- [x] Swim in Rising Water (H) _(2026-06-22)_

_New track: 2-D Dynamic Programming (DP table)_
- [x] Unique Paths (M) _(2026-06-21)_
- [x] Longest Common Subsequence (M) _(2026-06-21)_
- [x] Best Time to Buy and Sell Stock with Cooldown (M) _(2026-06-22)_
- [x] Coin Change II (M) _(2026-06-21)_
- [x] Target Sum (M) _(2026-06-22)_
- [x] Interleaving String (M) _(2026-06-22)_
- [x] Longest Increasing Path in a Matrix (H) _(2026-06-21)_
- [x] Distinct Subsequences (H) _(2026-06-22)_
- [x] Edit Distance (M) _(2026-06-21)_
- [x] Burst Balloons (H) _(2026-06-22)_
- [x] Regular Expression Matching (H) _(2026-06-22)_

## Phase 3 — `tree` primitive (Trees: 15)

- [x] **Engine:** add `tree` primitive — recursive `TreeNode` (final class),
      inline per-node `state`/`pointer` (no linear index to address), in-order
      layout in `TreeVisualView`, validator branch, schema recursion, ADR 0006.
      Reused later by `heap` and `trie`. _(2026-06-17)_

- [x] Invert Binary Tree (E) — first tree lesson; recursive child swap _(2026-06-17)_
- [x] Maximum Depth of Binary Tree (E) _(2026-06-21)_
- [x] Diameter of Binary Tree (E) _(2026-06-21)_
- [x] Balanced Binary Tree (E) _(2026-06-21)_
- [x] Same Tree (E) _(2026-06-22)_
- [x] Subtree of Another Tree (E) _(2026-06-22)_
- [x] Lowest Common Ancestor of a BST (M) _(2026-06-21)_
- [x] Binary Tree Level Order Traversal (M) _(2026-06-21)_
- [x] Binary Tree Right Side View (M) _(2026-06-21)_
- [x] Count Good Nodes in Binary Tree (M) _(2026-06-21)_
- [x] Validate Binary Search Tree (M) _(2026-06-21)_
- [x] Kth Smallest Element in a BST (M) _(2026-06-21)_
- [x] Construct Binary Tree from Preorder and Inorder Traversal (M) _(2026-06-21)_
- [x] Binary Tree Maximum Path Sum (H) _(2026-06-21)_
- [x] Serialize and Deserialize Binary Tree (H) _(2026-06-22)_

## Phase 4 — `list` primitive (Linked List: 10)

- [x] **Engine:** add `list` primitive — fixed node row (reuses array's
      index-addressed `Pointer`/`Highlight`), directed re-pointable `links`,
      straight arrows for neighbors + arcs for non-adjacent (cycles),
      `Palette.linkColor`, validator branch, schema, ADR 0007. _(2026-06-17)_

- [x] Reverse Linked List (E) — first list lesson; prv/cur arrow-flip pass _(2026-06-17)_
- [x] Merge Two Sorted Lists (E) _(2026-06-21)_
- [x] Linked List Cycle (E) _(2026-06-21)_
- [x] Reorder List (M) _(2026-06-21)_
- [x] Remove Nth Node From End of List (M) _(2026-06-21)_
- [x] Copy List With Random Pointer (M) _(2026-06-22)_
- [x] Add Two Numbers (M) _(2026-06-21)_
- [x] Reverse Nodes in K-Group (H) _(2026-06-21)_
- [x] Merge K Sorted Lists (H) — pairs with `heap` _(2026-06-22)_
- [x] LRU Cache (M) — pairs with `hashmap` (do after Phase 6) _(2026-06-22)_

## Phase 5 — `graph` primitive (Graphs + Advanced Graphs: 12)

- [x] **Engine:** add `graph` primitive — explicit normalized node positions
      (no auto-layout), edges referencing node ids, directed (computed
      arrowheads) + weighted, per-node/edge highlights, ADR 0008. _(2026-06-17)_

_Graphs_
- [x] Clone Graph (M) — first graph lesson; DFS visit/clone _(2026-06-17)_
- [x] Course Schedule (M) _(2026-06-21)_
- [x] Course Schedule II (M) _(2026-06-21)_
- [x] Graph Valid Tree (M) _(2026-06-21)_
- [x] Number of Connected Components in an Undirected Graph (M) _(2026-06-21)_
- [x] Redundant Connection (M) _(2026-06-21)_
- [x] Word Ladder (H) _(2026-06-21)_

_Advanced Graphs (weighted / topological)_
- [x] Network Delay Time (M) _(2026-06-21)_
- [x] Reconstruct Itinerary (H) _(2026-06-22)_
- [x] Min Cost to Connect Points (M) _(2026-06-21)_
- [x] Alien Dictionary (H) _(2026-06-22)_
- [x] Cheapest Flights Within K Stops (M) _(2026-06-21)_

## Phase 6 — `hashmap` primitive (Arrays & Hashing remainder: 6)

- [x] **Engine:** add `hashmap` primitive — key->value rows + optional lookup
      `probe` with hit/miss, ADR 0008. _(2026-06-17)_

- [x] Two Sum (E) — first hashmap lesson; complement lookup _(2026-06-17)_
- [x] Group Anagrams (M) _(2026-06-21)_
- [x] Top K Frequent Elements (M) — count + bucket sort _(2026-06-21)_
- [x] Longest Consecutive Sequence (M) _(2026-06-21)_
- [x] Time Based Key-Value Store (M) _(2026-06-21)_
- [x] Detect Squares (M) _(2026-06-21)_
- [x] _(LRU Cache shipped in the linked-list track)_ _(2026-06-22)_

## Phase 7 — Specialty primitives

Each sub-primitive is independent; do in any order.

**`heap` primitive (Heap / Priority Queue: 7)** — array-backed; could be
approximated with the `array` primitive (parent/child by index) if a full tree
view is too much.
- [x] **Engine:** `heap` primitive — reused the `tree` primitive (a heap is a complete binary tree); no new renderer _(2026-06-22)_
- [x] Kth Largest Element in a Stream (E) _(2026-06-22)_
- [x] Last Stone Weight (E) _(2026-06-22)_
- [x] K Closest Points to Origin (M) _(2026-06-22)_
- [x] Kth Largest Element in an Array (M) _(2026-06-22)_
- [x] Task Scheduler (M) _(2026-06-22)_
- [x] Design Twitter (M) _(2026-06-22)_
- [x] Find Median from Data Stream (H) — two heaps _(2026-06-22)_

**`rtree` primitive (Backtracking: 7)** — decision tree with prune highlights.
- [x] **Engine:** `rtree` primitive — n-ary decision tree, post-order layout,
      edge choice labels, ADR 0008. _(2026-06-17)_
- [x] Subsets (M) — first rtree lesson; include/skip decision tree _(2026-06-17)_
- [x] Combination Sum (M) _(2026-06-21)_
- [x] Combination Sum II (M) _(2026-06-21)_
- [x] Permutations (M) _(2026-06-21)_
- [x] Subsets II (M) _(2026-06-21)_
- [x] Palindrome Partitioning (M) _(2026-06-21)_
- [x] Letter Combinations of a Phone Number (M) _(2026-06-21)_

**`intervals` primitive (Intervals: 6)** — bars on a shared timeline.
- [x] **Engine:** `intervals` primitive — bars on a shared time axis, auto or
      pinned bounds, ADR 0008. _(2026-06-17)_
- [x] Insert Interval (M) _(2026-06-21)_
- [x] Merge Intervals (M) — first intervals lesson; sorted overlap sweep _(2026-06-17)_
- [x] Non-overlapping Intervals (M) _(2026-06-21)_
- [x] Meeting Rooms (E) _(2026-06-21)_
- [x] Meeting Rooms II (M) _(2026-06-21)_
- [x] Minimum Interval to Include Each Query (H) _(2026-06-21)_

**`trie` (extends `tree`) (Tries: 3)**
- [x] **Engine:** trie rendering — reused the `rtree` primitive (n-ary, edge = letter); no new renderer _(2026-06-22)_
- [x] Implement Trie (Prefix Tree) (M) _(2026-06-22)_
- [x] Design Add and Search Words Data Structure (M) _(2026-06-22)_
- [x] Word Search II (H) — needs `trie` + `grid` _(2026-06-22)_

---

# Already done (14 / 150)

These NeetCode 150 problems are live in `Content/`:

- **Two Pointers** (all 5): Valid Palindrome, Two Sum II, 3Sum, Container With Most Water, Trapping Rain Water
- **Sliding Window**: Best Time to Buy and Sell Stock, Longest Substring Without Repeating Characters
- **Stack**: Valid Parentheses, Min Stack, Daily Temperatures
- **Binary Search**: Binary Search, Search in Rotated Sorted Array
- **1-D DP**: Maximum Product Subarray _(currently in the `kadane` track)_
- **Greedy**: Maximum Subarray _(currently in the `kadane` track)_

# Bonus lessons already shipped (not in NeetCode 150)

Keep these — they're good pedagogy, just outside the 150: Remove Duplicates from
Sorted Array, Move Zeroes, Maximum Average Subarray (Sliding Window), First Bad
Version (Binary Search), Bubble/Selection/Insertion Sort (Sorting track), Running
Sum, Range Sum Query, Find Pivot Index (Prefix Sums track).

# Notes for whoever picks this up

- Authoring workflow is unchanged: write the lesson JSON, add the ref to
  `Content/manifest.json` (creating the track + overview if new), JSON-lint, run
  `swift test` so `ContentValidationTests` validates the new manifest entry, then
  one atomic commit per lesson or per small batch (no co-author trailer).
- New tracks need an `overview` block (tagline, whenToUse[], keyIdea, complexity)
  and an SF Symbol `icon`, matching the existing tracks.
- Every new **primitive** is a bigger unit: schema addition + SwiftUI renderer +
  validator rule + ContentValidationTests + an ADR in `docs/adr/`, and bump
  `schemaVersion` only if the change is breaking.
- Some 🟢 tags are pragmatic approximations of the "real" data structure (e.g.
  Valid Anagram via sort-compare, heap-as-array). If a faithful visual matters
  more than shipping early, bump that problem to its proper primitive phase.
