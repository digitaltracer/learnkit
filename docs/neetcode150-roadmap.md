# NeetCode 150 — LearnKit Content Roadmap

_Status snapshot: 2026-06-17. Source list: https://neetcode.io/practice/practice/neetcode150_

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
| ✅ Done | 21 / 150 |
| 🟢 Buildable now (array only) | 45 |
| 🟡 Blocked on a new primitive | 84 |
| **Total** | **150** |

_Primitives shipped: `array`, `grid`, `tree`, `list`, `graph`, `hashmap`, `intervals`, `rtree`._
_All renderers the NeetCode 150 needs now exist — Heap and Tries reuse `tree`. The
rest is largely authoring (chore-work), one representative already proven per primitive._

Reaching **59 / 150 with zero engine work** is possible — that's Phase 1.

Blocked work, by primitive that unlocks it:

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
- [ ] Minimum Window Substring (H)
- [ ] Sliding Window Maximum (H)

**Extend existing track: Stack**
- [ ] Evaluate Reverse Polish Notation (M)
- [ ] Car Fleet (M)
- [ ] Largest Rectangle in Histogram (H) — `bars`

**Extend existing track: Binary Search**
- [x] Koko Eating Bananas (M) — binary search on the answer _(2026-06-21)_
- [ ] Find Minimum in Rotated Sorted Array (M)
- [ ] Median of Two Sorted Arrays (H) — two arrays + partition

**New track: Arrays & Hashing** (array-friendly members only)
- [x] Contains Duplicate (E) _(2026-06-21)_
- [x] Valid Anagram (E) — letter-count cancel _(2026-06-21)_
- [ ] Encode and Decode Strings (M) — length-prefix
- [x] Product of Array Except Self (M) — prefix/suffix passes _(2026-06-21)_

**New track: 1-D Dynamic Programming**
- [x] Climbing Stairs (E) _(2026-06-21)_
- [ ] Min Cost Climbing Stairs (E)
- [x] House Robber (M) _(2026-06-21)_
- [ ] House Robber II (M)
- [ ] Decode Ways (M)
- [x] Coin Change (M) _(2026-06-21)_
- [ ] Word Break (M)
- [ ] Longest Increasing Subsequence (M)
- [ ] Partition Equal Subset Sum (M) — 1-D boolean dp
- [ ] Longest Palindromic Substring (M) — expand-around-center
- [ ] Palindromic Substrings (M) — expand-around-center

**New track: Greedy**
- [x] Jump Game (M) _(2026-06-21)_
- [x] Jump Game II (M) _(2026-06-21)_
- [ ] Gas Station (M)
- [ ] Hand of Straights (M)
- [ ] Merge Triplets to Form Target Triplet (M)
- [ ] Partition Labels (M)
- [ ] Valid Parenthesis String (M)

**New track: Bit Manipulation** (cells hold bits)
- [ ] Single Number (E)
- [ ] Number of 1 Bits (E)
- [ ] Counting Bits (E)
- [ ] Reverse Bits (E)
- [ ] Missing Number (E)
- [ ] Sum of Two Integers (M)
- [ ] Reverse Integer (M)

**New track: Math & Geometry** (array-friendly members only)
- [ ] Happy Number (E) — value sequence
- [ ] Plus One (E)
- [ ] Pow(x, n) (M) — caption-heavy; value sequence
- [ ] Multiply Strings (M) — digit arrays

**Slots into Linked List / Backtracking but is array-renderable**
- [ ] Find the Duplicate Number (M) — Floyd's cycle over array indices
- [ ] Generate Parentheses (M) — string built step by step

## Phase 2 — `grid` primitive (biggest unlock: 25 lessons)

- [x] **Engine:** add `grid` primitive — `Visual` made polymorphic (dispatch on
      `type`), `GridVisual` spec (`rows`, `pointers` by row/col, `highlights` by
      cell or region), `GridVisualView` renderer, validator branch, schema
      `oneOf`, decode tests, ADR 0005. Reuses `HighlightState`/`Palette`. _(2026-06-17)_

Then author (each a checkbox):

_Math & Geometry (matrices)_
- [ ] Rotate Image (M)
- [x] Spiral Matrix (M) — first grid lesson; proves matrix traversal _(2026-06-17)_
- [ ] Set Matrix Zeroes (M)

_Binary Search / Arrays & Hashing on a grid_
- [ ] Search a 2D Matrix (M)
- [ ] Valid Sudoku (M)

_Graphs on a grid (BFS/DFS flood fill)_
- [ ] Number of Islands (M)
- [ ] Max Area of Island (M)
- [ ] Pacific Atlantic Water Flow (M)
- [ ] Surrounded Regions (M)
- [ ] Rotting Oranges (M)
- [ ] Walls and Gates (M)

_Backtracking on a grid_
- [ ] Word Search (M)
- [ ] N-Queens (H)

_Advanced graph on a grid_
- [ ] Swim in Rising Water (H)

_New track: 2-D Dynamic Programming (DP table)_
- [ ] Unique Paths (M)
- [ ] Longest Common Subsequence (M)
- [ ] Best Time to Buy and Sell Stock with Cooldown (M)
- [ ] Coin Change II (M)
- [ ] Target Sum (M)
- [ ] Interleaving String (M)
- [ ] Longest Increasing Path in a Matrix (H)
- [ ] Distinct Subsequences (H)
- [ ] Edit Distance (M)
- [ ] Burst Balloons (H)
- [ ] Regular Expression Matching (H)

## Phase 3 — `tree` primitive (Trees: 15)

- [x] **Engine:** add `tree` primitive — recursive `TreeNode` (final class),
      inline per-node `state`/`pointer` (no linear index to address), in-order
      layout in `TreeVisualView`, validator branch, schema recursion, ADR 0006.
      Reused later by `heap` and `trie`. _(2026-06-17)_

- [x] Invert Binary Tree (E) — first tree lesson; recursive child swap _(2026-06-17)_
- [x] Maximum Depth of Binary Tree (E) _(2026-06-21)_
- [x] Diameter of Binary Tree (E) _(2026-06-21)_
- [x] Balanced Binary Tree (E) _(2026-06-21)_
- [ ] Same Tree (E)
- [ ] Subtree of Another Tree (E)
- [x] Lowest Common Ancestor of a BST (M) _(2026-06-21)_
- [x] Binary Tree Level Order Traversal (M) _(2026-06-21)_
- [ ] Binary Tree Right Side View (M)
- [ ] Count Good Nodes in Binary Tree (M)
- [ ] Validate Binary Search Tree (M)
- [ ] Kth Smallest Element in a BST (M)
- [ ] Construct Binary Tree from Preorder and Inorder Traversal (M)
- [ ] Binary Tree Maximum Path Sum (H)
- [ ] Serialize and Deserialize Binary Tree (H)

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
- [ ] Copy List With Random Pointer (M)
- [ ] Add Two Numbers (M)
- [ ] Reverse Nodes in K-Group (H)
- [ ] Merge K Sorted Lists (H) — pairs with `heap`
- [ ] LRU Cache (M) — pairs with `hashmap` (do after Phase 6)

## Phase 5 — `graph` primitive (Graphs + Advanced Graphs: 12)

- [x] **Engine:** add `graph` primitive — explicit normalized node positions
      (no auto-layout), edges referencing node ids, directed (computed
      arrowheads) + weighted, per-node/edge highlights, ADR 0008. _(2026-06-17)_

_Graphs_
- [x] Clone Graph (M) — first graph lesson; DFS visit/clone _(2026-06-17)_
- [ ] Course Schedule (M)
- [ ] Course Schedule II (M)
- [ ] Graph Valid Tree (M)
- [ ] Number of Connected Components in an Undirected Graph (M)
- [ ] Redundant Connection (M)
- [ ] Word Ladder (H)

_Advanced Graphs (weighted / topological)_
- [ ] Network Delay Time (M)
- [ ] Reconstruct Itinerary (H)
- [ ] Min Cost to Connect Points (M)
- [ ] Alien Dictionary (H)
- [ ] Cheapest Flights Within K Stops (M)

## Phase 6 — `hashmap` primitive (Arrays & Hashing remainder: 6)

- [x] **Engine:** add `hashmap` primitive — key->value rows + optional lookup
      `probe` with hit/miss, ADR 0008. _(2026-06-17)_

- [x] Two Sum (E) — first hashmap lesson; complement lookup _(2026-06-17)_
- [x] Group Anagrams (M) _(2026-06-21)_
- [x] Top K Frequent Elements (M) — count + bucket sort _(2026-06-21)_
- [ ] Longest Consecutive Sequence (M)
- [ ] Time Based Key-Value Store (M)
- [ ] Detect Squares (M)
- [ ] _(then revisit LRU Cache from Phase 4)_

## Phase 7 — Specialty primitives

Each sub-primitive is independent; do in any order.

**`heap` primitive (Heap / Priority Queue: 7)** — array-backed; could be
approximated with the `array` primitive (parent/child by index) if a full tree
view is too much.
- [ ] **Engine:** `heap` primitive (or array-as-heap convention)
- [ ] Kth Largest Element in a Stream (E)
- [ ] Last Stone Weight (E)
- [ ] K Closest Points to Origin (M)
- [ ] Kth Largest Element in an Array (M)
- [ ] Task Scheduler (M)
- [ ] Design Twitter (M)
- [ ] Find Median from Data Stream (H) — two heaps

**`rtree` primitive (Backtracking: 7)** — decision tree with prune highlights.
- [x] **Engine:** `rtree` primitive — n-ary decision tree, post-order layout,
      edge choice labels, ADR 0008. _(2026-06-17)_
- [x] Subsets (M) — first rtree lesson; include/skip decision tree _(2026-06-17)_
- [ ] Combination Sum (M)
- [ ] Combination Sum II (M)
- [ ] Permutations (M)
- [ ] Subsets II (M)
- [ ] Palindrome Partitioning (M)
- [ ] Letter Combinations of a Phone Number (M)

**`intervals` primitive (Intervals: 6)** — bars on a shared timeline.
- [x] **Engine:** `intervals` primitive — bars on a shared time axis, auto or
      pinned bounds, ADR 0008. _(2026-06-17)_
- [ ] Insert Interval (M)
- [x] Merge Intervals (M) — first intervals lesson; sorted overlap sweep _(2026-06-17)_
- [ ] Non-overlapping Intervals (M)
- [ ] Meeting Rooms (E)
- [ ] Meeting Rooms II (M)
- [ ] Minimum Interval to Include Each Query (H)

**`trie` (extends `tree`) (Tries: 3)**
- [ ] **Engine:** trie rendering (reuse `tree`)
- [ ] Implement Trie (Prefix Tree) (M)
- [ ] Design Add and Search Words Data Structure (M)
- [ ] Word Search II (H) — needs `trie` + `grid`

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
