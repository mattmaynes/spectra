# 0002 — Review scoping, inline comments, worktree builds

## Symptom
The protocol ran **all four** review personas on every change (wasteful when a change only
touches one facet), left the review-comment delivery unspecified (they landed as detached
top-level PR comments), and described worktree builds only loosely — the first build ran on a
checked-out branch instead of a worktree off `main`.

## Root cause
The review and build steps under-specified *how* to scope, deliver, and isolate work — they
named the actors but not the mechanics.

## Fix
Amended `spectra/protocol.md` step 5:
- **Triage** — first pick only the personas whose facet the change touches (engineer / tester
  / architect / security), with skip heuristics (tests-only → skip engineer; cosmetic/docs →
  skip tester; no structural change → skip architect; no security surface → skip security).
- **Inline comments** — personas post findings as **inline PR comments anchored to the
  relevant file and line** (general points in the review summary), never detached top-level
  comments.
- **Worktree builds** — build in a `git worktree` on a new branch (`git worktree add
  .worktrees/<slug> -b <slug>`), leaving the primary checkout on `main`; remove the worktree
  after merge. Added `.worktrees/` to `.gitignore`.

## Learning
Specify the *mechanics* of each protocol step, not just the actors. Recorded in
`overview/learnings.md`.
