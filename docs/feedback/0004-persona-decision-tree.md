# 0004 — Terse persona decision tree for review scoping

## Symptom
Step 5's persona selection was a four-bullet prose list. To decide the review set you read
all four descriptions, and the cheap happy path — pure docs/cosmetic changes that need **no**
personas — was buried as a parenthetical skip note rather than the first thing you check.
Each persona is a sub-agent that reads two files and re-reads the diff, so over-spawning is
the single biggest review-time token cost.

## Root cause
The selection guidance optimized for *describing* each persona, not for *deciding fast*. There
was no early-exit gate, so the common no-persona / one-persona cases cost as much thinking as
the full four-way review.

## Fix
Replaced the bullet list in step 5.4 of both `spectra/protocol.md` (shippable) and
`docs/spectra/protocol.md` (installed instance) with a terse gated decision tree:
- **Gate first** on "pure docs/comments/formatting, no behavior change?" → no personas,
  self-review, skip to address/merge.
- Otherwise add each persona whose trigger fires (engineer / tester / architect / security),
  decided **from the diff alone, before reading any persona file**.
- Stated the default (typical code change = engineer + tester) so architect/security are
  opt-in on a trigger, not opt-out.
- Preserved the prior list's `non-trivial` qualifier and `tests-only` skip on the engineer
  trigger (an engineer-persona review of this very change caught that the first draft had
  silently dropped them).

## Learning
Put the cheapest outcome first and make selection decidable before paying for it — gate on the
no-op case before enumerating the work. Recorded in `overview/learnings.md`.
