# 0011 — Orient on the overview docs before changing anything

- **Symptom** — The protocol told agents to **write** the `overview/` living docs (§6
  Reflect) but never to **read** them before starting work. `learnings.md` — the entire point
  of the "learning feedback loop" — was write-only in practice: an agent could re-make a
  mistake already logged there because nothing instructed it to consult past lessons. Same for
  `features.md`/`architecture.md` as orientation: an agent could duplicate or break existing
  structure it never read.
- **Root cause** — The protocol treated `overview/` as an output sink, not an input source.
  The feedback loop was left open — lessons were recorded but never fed back into the next
  change, so the "learning" half of "spec-driven development with learning feedback loops"
  didn't actually run.
- **Fix** — Add **§0 Orient**: before routing any change, read `learnings.md` (and **apply**
  it), `features.md`, and `architecture.md`. Cross-link §6 Reflect as the write side of the
  same loop ("the docs you read in are the docs you write back"). One source of truth — the
  dogfooded `docs/spectra/protocol.md` is a symlink to the shipped `spectra/protocol.md`, so a
  single edit covers both.
- **Learning** — A feedback loop only closes when the lessons are read back in. Recording a
  learning is half the loop; the protocol has to make the *next* agent consult it, or the
  store is write-only and the same mistake recurs. Feeds `overview/learnings.md` (§6). Sibling
  of [`feedback/0010`](0010-lesson-doesnt-auto-apply.md) (landed same day on PR #12): that one
  found a just-written lesson going un-applied in the next change; §0 Orient is the structural
  fix — make reading the store a standing first step rather than relying on memory.
