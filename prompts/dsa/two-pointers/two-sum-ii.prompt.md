# Prompt — DSA / Two Pointers / Two Sum II

Use `prompts/lesson-generation.template.md` with these slots.

- Subject: `dsa`
- Track: `two-pointers`
- Lesson id: `two-sum-ii`
- Title: `Two Sum II`
- Difficulty: `medium`
- Problem: Given a **sorted** array of numbers and a target, find the two values that add up to the target. Teach the two-pointer technique: a pointer at each end; if the sum is too big move the right pointer left, if too small move the left pointer right, until they meet the target.
- Walkthrough example: `cells = [1, 3, 4, 6, 8, 11]`, target `10`. L starts at 0, R at 5. Sum 1+11=12 > 10 → move R left. 1+8=9 < 10 → move L right. 3+8=11 > 10 → move R left. 3+6=9 < 10 → move L right. 4+6=10 → found. Show the running sum vs. target in the captions and use `compare`/`match` highlights on the two pointed cells.
