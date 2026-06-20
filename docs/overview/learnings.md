# Learnings

Process lessons and feedback distilled into guidance. Append as they arise (newest first).

- **A local-only guard isn't a guarantee — promote it to CI.** The README token-drift check
  lived solely in an *untracked* `.git/hooks/pre-commit`, so anyone without the hook (fork PRs,
  fresh clones) bypassed it silently. CI (`.github/workflows/ci.yml`) re-runs `test.sh` and the
  same `--check` so the standard is enforced where everyone can see it, not just on the
  original author's machine. Keep CI checkers dependency-free and dogfoodable
  (`check-commit-msg.sh` mirrors `token-report.sh`), and feed untrusted inputs like a PR title
  through `env:` — never interpolate them into the run command.
- **A marketing claim that can rot should be machine-checked.** The README's "low token
  cost" is a selling point, so its numbers are generated from `spectra/` and enforced by a
  `pre-commit` guard + `test.sh` rather than hand-maintained — the old hand-written "~2.6k"
  had already drifted (~2.9k actual). Generate, don't transcribe; gate drift at commit time.
- **Write hook/CI scripts for the POSIX tools actually present.** macOS ships **BSD awk**,
  which rejects multi-line strings passed via `-v` ("newline in string"). Pass multi-line
  data through a temp file read with `getline` instead. Keep the token heuristic
  dependency-free (`wc -c`, `~4 chars/token`) so the hook runs anywhere, no tokenizer.
- **Scope reviews; comment inline; isolate builds.** Triage which personas review (don't run
  all four by reflex); post review findings as **inline** PR comments on the relevant lines;
  build changes in a **git worktree** off `main`. — from [`feedback/0002`](../feedback/0002-review-and-workflow-refinements.md)
- **Make contracts explicit, not implicit.** Test *before* committing (protocol step 5), and
  give review comments a fixed shape (`_Spectra <Persona>_` / severity / comment). Treat
  every `major`/`blocker` as feedback. — from [`feedback/0001`](../feedback/0001-testing-and-review-format.md)
