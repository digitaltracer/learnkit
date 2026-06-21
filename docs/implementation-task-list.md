# LearnKit Implementation Task List

Status legend: `[ ]` todo, `[-]` in progress, `[x]` done.

## Current Pass

- [x] Create this task list and keep it updated as implementation progresses.
- [x] Update stale content pipeline docs and prompts to match the shipped primitive set.
- [x] Make track lesson loading report per-file failures instead of silently dropping broken lessons.
- [x] Add runtime empty-lesson handling so malformed content cannot crash `LessonPage`.
- [x] Strengthen content validation for schema rules, duplicate pointer labels, graph coordinates, and manifest consistency.
- [x] Improve lesson player accessibility for step navigation and tappable visuals.
- [x] Run the package test suite and fix any regressions.

## Later Product Work

- [x] Redesign the catalog into a learning dashboard with continue/resume, progress, search, and filtering.
- [x] Add persistent lesson progress and track completion state.
- [x] Keep the app target iOS 26+ for the Liquid Glass UI direction.
- [x] Add visual snapshot/render tests for each primitive.
