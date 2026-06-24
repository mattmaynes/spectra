# 0005 - A feature description was mislabeled as a "learning"

## Symptom
During the Reflect step of PR #8 (the User/ICP persona), `docs/overview/learnings.md` gained an
entry - *"Make 'don't overwrite' structural, not procedural"* - that just restated how the
newly built feature works (we never ship `user.md`, so the update glob can't reach it). The
developer flagged it inline: *"This isn't really a 'learning', this is just part of the design
of the system."*

## Root cause
The protocol's Reflect step routed "feedback, PR friction, or 'could've gone better'" to
`learnings.md`, but never said what a learning is **not**. So a design rationale that felt
insightful got written up as a lesson - even though the same point was already (correctly) in
`architecture.md`. A learning was manufactured to fill the section, rather than distilled from
any feedback or friction. Nothing had gone wrong, so there was no lesson to record.

## Fix
- Removed the entry from `docs/overview/learnings.md`.
- Clarified §6 (Reflect) of `spectra/protocol.md`: a learning is what you'd do *differently*
  next time, distilled from feedback or friction - **not** a description of what you shipped
  (that's `features.md`) or why you designed it that way (that's `architecture.md`). Added "no
  feedback, no learning - don't manufacture one."

## Learning
A learning must trace back to a *correction or friction*, not to admiring your own design. If
nothing went wrong and no feedback was given, Reflect should touch `features.md`/
`architecture.md` and leave `learnings.md` alone.
