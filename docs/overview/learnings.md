# Learnings

Process lessons and feedback distilled into guidance. Append as they arise (newest first).

- **Scope reviews; comment inline; isolate builds.** Triage which personas review (don't run
  all four by reflex); post review findings as **inline** PR comments on the relevant lines;
  build changes in a **git worktree** off `main`. — from [`feedback/0002`](../feedback/0002-review-and-workflow-refinements.md)
- **Make contracts explicit, not implicit.** Test *before* committing (protocol step 5), and
  give review comments a fixed shape (`_Spectra <Persona>_` / severity / comment). Treat
  every `major`/`blocker` as feedback. — from [`feedback/0001`](../feedback/0001-testing-and-review-format.md)
