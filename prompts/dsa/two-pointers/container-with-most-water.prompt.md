# Prompt — DSA / Two Pointers / Container With Most Water

Use `prompts/lesson-generation.template.md` with these slots.

- Subject: `dsa`
- Track: `two-pointers`
- Lesson id: `container-with-most-water`
- Title: `Container With Most Water`
- Difficulty: `medium`
- Problem: Given an array of heights, each a vertical line, find two lines that together with the x-axis hold the most water. Area = (distance between the two indices) × (the shorter of the two heights). Teach the two-pointer technique: start wide (one pointer at each end), compute the area, then move the pointer at the **shorter** line inward (moving the taller one can never help), tracking the best area seen.
- Use `"style": "bars"` for every visual — the values are wall heights, so bars convey the area intuition far better than boxed numbers.
- Walkthrough example: `cells = [1, 8, 6, 2, 5, 7]`. L at 0, R at 5. Area = 5 × min(1,7) = 5 → move L (shorter). L at 1: area = 4 × min(8,7) = 28 → move R (shorter). R at 4: area = 3 × min(8,5) = 15 → move R. R at 3: area = 2 × min(8,2) = 4 → move R. R at 2: area = 1 × min(8,6) = 6. Best = 28. Use a caption to track the best-so-far each step, `compare` highlights on the two pointed cells, and a `done` highlight on the winning pair at the end.
