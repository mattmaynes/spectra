# 0014 - One-off, feature-specific notes were logged as "learnings"

## Symptom
Across several Reflect steps, `docs/overview/learnings.md` accumulated entries that were genuine
"do it differently next time" corrections but applied only to the single feature that produced
them - facts that will never guide another change. The store began filling with lessons that
won't recur, diluting the ones that continually improve how the project is built.

## Root cause
The protocol's §6 definition guarded two failure modes - a learning isn't a *feature
description* (`features.md` / `architecture.md`) and you shouldn't *manufacture* one - but it
never required a learning to **generalize**. A real correction that's specific to one feature
and won't transfer passed every existing test, so it got logged. The missing axis was
transferability: a learning has to improve the development lifecycle going forward, not just
record how one feature turned out.

## Fix
- Clarified §6 (Reflect) of `spectra/protocol.md`: a learning is a rule you'd apply differently
  next time **that outlives the change that taught it** - general guidance that improves how the
  project is built from here on. A lesson that only ever applies to the feature you just shipped
  belongs in that feature's story (`features.md` / `architecture.md`), not `learnings.md`.
- Tightened the §3 feedback-doc field: **Learning** is "the general rule to apply next time, not
  just this one fix."

## Learning
A learning must **generalize past the change that taught it** - it earns its place only if it
will guide a future change in some other context. If a correction is real but applies only to
the one feature you just shipped, it is part of that feature's story, not a learning. Test every
candidate against "would this guide work elsewhere?" before logging it.
