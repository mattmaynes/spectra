# 0002 — Token-count guard, protocol diagram & branding

## Problem
Spectra's headline selling point is its tiny context footprint, but the README's token
figures are hand-written prose ("~2.6k") that has already drifted from reality (~2.9k) and
will rot every time `spectra/` changes. The protocol is also text-only — the
implementation flow and the learning loop are hard to grasp at a glance — and the README
under-sells the "own your protocol" angle: that Spectra is plain files you control, not a
hosted third-party tool.

## Outcome
- The README's token figures are **generated** from `spectra/` and stay accurate: a
  repo-local `pre-commit` hook **blocks** a commit that touches `spectra/` without
  refreshing the figures, and `test.sh` enforces the same.
- The protocol reads visually: an SVG in `assets/` shows the route→…→reflect flow plus the
  reflect→learnings feedback loop, linked from the README so it renders on GitHub.
- A centered logo (spectrum loop/orbit, SVG in `assets/`) tops the README.
- The README emphasizes **own your protocol** — customizable, plain files in your repo, no
  third-party runtime; opinionated defaults but flexible.

## Scope
- In: `assets/logo.svg`, `assets/protocol-flow.svg`; `scripts/token-report.sh`
  (compute / `--check` / `--write`); repo-local `pre-commit` token guard; a `test.sh`
  check; README updates (logo, token table behind markers, "own your protocol" section,
  diagram link).
- Out: shipping any of this into consumers. The guard, script, and assets are **this
  repo's** tooling — nothing under `spectra/` changes, so installs/updates are unaffected.
- Out: changing the token heuristic (keep dependency-free `chars ÷ 4`, already documented).

## Approach
- **Counts**: keep `chars ÷ 4` (no tokenizer dependency — the hook must run anywhere).
  `scripts/token-report.sh` computes three groupings (host block; protocol + personas;
  everything incl. skills) and renders a markdown table. README holds that table between
  `<!-- spectra:tokens:start/end -->` markers (mirrors the existing `spectra:start` marker
  convention). `--write` regenerates it in place; `--check` fails if README is stale.
- **Hook**: repo-local only. Extend this repo's untracked `.git/hooks/pre-commit` (which
  already carries the reflection reminder) to also run `token-report.sh --check` when
  `spectra/` is staged. Logic lives in the tracked `scripts/` file; the shipped
  `spectra/hooks/pre-commit` is untouched, so consumers never get this guard.
- **SVGs**: self-contained dark "cards" with a spectrum palette so they render identically
  under GitHub's light and dark themes; embedded via `<img>`/`<p align="center">`.

## Acceptance
- [ ] `scripts/token-report.sh --check` passes when README matches; fails when stale.
- [ ] `--write` regenerates the README token block from `spectra/`.
- [ ] Editing any `spectra/*.md` then committing without refreshing is **blocked** by the
      hook; refreshing unblocks it; commits not touching `spectra/` are unaffected.
- [ ] `test.sh` includes the token-accuracy check and still ends `PASS`.
- [ ] `assets/logo.svg` and `assets/protocol-flow.svg` exist and render on GitHub.
- [ ] README: centered logo at top, accurate token table, "own your protocol" section,
      protocol-flow diagram linked.
- [ ] Nothing under `spectra/` changed (no consumer-facing impact).
