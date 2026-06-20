# 0003 — Conventional commits & CI

## Problem
This repo has no automated quality gate: `test.sh` and the README token guard only run if a
contributor remembers to (the token guard lives in an *untracked* `.git/hooks/pre-commit`, so
a fresh clone or a PR from a fork is unprotected). Commit and PR-title style is also
unspecified and inconsistent (`Add …`, `Bootstrap …`, `Refine …`), so history isn't
machine-readable and offers no shared convention. Two gaps, one theme: the standards this repo
already cares about aren't enforced where everyone can see them — in CI.

## Outcome
- Every PR and push runs a **GitHub Actions** workflow that (a) runs `test.sh` and (b) runs
  the README-drift check (`scripts/token-report.sh --check`) — the same guard the local
  pre-commit hook applies — so a stale README or a failing suite **blocks the merge**, not just
  the local committer.
- Every **PR title** is validated against the [Conventional Commits](https://www.conventionalcommits.org)
  spec by a dependency-free check; a non-conforming title fails CI.
- The convention is **documented** so humans and the coding agent both follow it: the host
  block / `AGENTS.md` states that commits and PR titles use conventional commits, and the
  reasoning is captured in the living docs.

## Scope
- **In:**
  - `.github/workflows/ci.yml` — runs on `push` and `pull_request`; jobs: `test` (runs
    `./test.sh`) and `readme-drift` (`scripts/token-report.sh --check`), plus a
    `pull_request`-only `commit-lint` job validating the PR title.
  - `scripts/check-commit-msg.sh` — repo-local, dependency-free POSIX validator: takes a
    message string, exits non-zero if it doesn't match the conventional-commits grammar.
    Reused by CI and runnable locally.
  - Documentation: a short conventional-commits rule in `AGENTS.md` (this repo's own host
    block region, **not** under `spectra/`), and a `CONTRIBUTING.md` note or README pointer if
    warranted.
  - A `test.sh` case covering `check-commit-msg.sh` (valid/invalid examples) so the validator
    itself is tested.
- **Out:**
  - **Anything under `spectra/`.** Conventional commits is **this repo's** convention; the
    shipped protocol, personas, and host block are untouched, so consumers and the README
    token figures are unaffected (decided with the developer).
  - Rewriting existing git history.
  - Auto-fixing/normalizing commit messages, commitlint config files, or a Node/JS toolchain.
  - A third-party PR-title action (decided: dependency-free shell, matching the repo's
    "own it, no third-party dependency" ethos).
  - Enforcing the convention on *every* commit in a PR (squash-merge makes the **PR title** the
    landed commit, so that's the high-value gate). The validator can still be run on a message
    locally.

## Approach
- **Workflow** (`.github/workflows/ci.yml`): `ubuntu-latest` (ships `python3`, `awk`, `git` —
  everything `test.sh` and `token-report.sh` need). Triggers: `push` and `pull_request`.
  - `test` job: `./test.sh`. (Its step 8 already covers token drift, but a dedicated
    `readme-drift` step makes the "README hasn't drifted" guarantee explicit and independently
    legible — mirrors the local hook's intent.)
  - `commit-lint` job (`if: github.event_name == 'pull_request'`): pass
    `${{ github.event.pull_request.title }}` to `scripts/check-commit-msg.sh`.
- **Validator** (`scripts/check-commit-msg.sh`): a POSIX `grep -Eq` against the conventional
  grammar — `type(optional scope)(optional !): subject` — with the standard type set
  (`feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`). On failure it prints the
  offending message and a one-line example, then exits 1. Dependency-free so it runs in CI and
  in a local hook identically (same rationale as `token-report.sh`).
- **Docs**: add a one-line "Commits & PR titles use Conventional Commits" rule to this repo's
  `AGENTS.md` (outside the `spectra:start/end` block, so it's repo-local and never shipped),
  pointing at `scripts/check-commit-msg.sh`. Reflect the new capability/decision in
  `docs/overview/` (`features`, `architecture`, `learnings`).
- **Testing**: extend `test.sh` with a step that feeds `check-commit-msg.sh` a few conforming
  messages (expect 0) and non-conforming ones (expect non-zero), keeping the script honest.

## Acceptance
- [ ] `.github/workflows/ci.yml` runs on push and PR; the `test` job runs `./test.sh` and the
      `readme-drift` job runs `scripts/token-report.sh --check`.
- [ ] A PR whose README token block is stale (or whose `test.sh` fails) gets a **red** check.
- [ ] `scripts/check-commit-msg.sh "feat: x"` exits 0; `scripts/check-commit-msg.sh "nope"`
      exits non-zero. CI fails a PR with a non-conventional title.
- [ ] `test.sh` includes a `check-commit-msg.sh` case and still ends `PASS`.
- [ ] `AGENTS.md` documents the conventional-commits rule (outside the spectra block).
- [ ] **Nothing under `spectra/` changed** — token figures and consumer install/update are
      unaffected.
- [ ] `docs/overview/` updated (features, architecture, learnings).
