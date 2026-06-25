# 0008 - README "What's new" section

## Problem
The README has no at-a-glance "what changed lately" signal. A reader has to leave for the
releases page to learn whether anything new shipped, and there's no headline that says it in one
line. Trellis solved the same gap with a self-updating block; spectra should match it so the
front page stays current without manual edits on every release.

## Outcome
- The README carries a **What's new** section with a one-line headline for the latest release
  (`**<tag>** - <headline>`) and a pointer to the releases page.
- When a GitHub Release is **published**, the headline is rewritten automatically from the first
  line of that release's notes. No human edits the block by hand.
- The automation respects `main`'s ruleset: it lands the change through a pull request, not a
  direct push.

## Scope
- **In:**
  - `README.md` - a `## What's new` section between the intro and Quick start, wrapping the
    headline in `<!-- spectra:whats-new:start -->` / `<!-- spectra:whats-new:end -->` markers
    (the repo's existing marker convention, shared with the `spectra:tokens` block), plus a "see
    every release" pointer. Seeded with the current latest release (`1.0.0`).
  - `scripts/whats-new.sh` - repo-local, dependency-free (POSIX sh + awk/sed), mirroring
    `token-report.sh`: extracts the headline (first non-heading line of the notes, else the
    release title) and rewrites the block. `--write` updates README in place; no arg prints it.
    Unit-tested by `test.sh` (section 10).
  - `.github/workflows/whats-new.yml` - on `release: [published]`, calls `whats-new.sh --write`
    and lands the change via an auto-created, self-squash-merged PR.
- **Out:**
  - Changing how releases are cut or tagged.
  - A full changelog or release-notes generator - this is a single headline, not a history.
  - Touching the `spectra:tokens` block or token report (independent README machinery).

## Approach
The headline extraction and block rewrite live in `scripts/whats-new.sh` (dependency-free,
unit-tested), exactly like `token-report.sh` owns the `spectra:tokens` block - so the branching
logic is covered by `test.sh` rather than only exercised at a live release. The workflow is a
thin wrapper that feeds it the release event and lands the result.

Mirror Trellis's `whats-new.yml`, with one deliberate divergence forced by governance:

- **Trellis** `main` has no ruleset, so its workflow commits the README change and pushes
  straight to `main`.
- **Spectra** `main` requires a pull request (`pull_request` rule) and forbids direct pushes,
  but adds **no required status checks** and **0 required approvals**. So the workflow creates a
  short-lived `chore/whats-new-<tag>` branch, opens a PR with a Conventional Commit title, and
  squash-merges it itself (with a brief retry while GitHub computes mergeability). The ruleset
  stays intact; the bot just uses the front door.

Key decisions / trade-offs:
- **Untrusted release body** reaches `whats-new.sh` only through env vars and is used purely as
  string data (awk line scan, marker substitution) - never interpolated into a shell command, so
  no injection. As defense-in-depth the headline is stripped of comment markers and length-capped
  so a crafted first line can't corrupt the block region. Release notes are maintainer-authored,
  so the residual risk is low.
- **Least-privilege token**: `contents: write` (push the branch) + `pull-requests: write` (open
  and merge). Nothing else.
- **PR over bypass actor**: keeping every write to `main` behind a PR is more in keeping with a
  repo that deliberately runs a ruleset than weakening the ruleset with an Actions bypass.

## Acceptance
- [ ] README renders a `## What's new` section with the seeded `**1.0.0**` headline and the
      releases-page pointer.
- [ ] `<!-- spectra:whats-new:start -->` / `<!-- spectra:whats-new:end -->` markers are present
      and wrap exactly the headline line.
- [ ] `scripts/whats-new.sh` extracts the first non-heading note line (else the release title),
      sanitizes it, and rewrites the block; `test.sh` section 10 covers these cases.
- [ ] `.github/workflows/whats-new.yml` triggers on `release: [published]`, calls the script, and
      lands the change through a PR (no direct push to `main`).
- [ ] `test.sh` and the README token-drift check still pass (the new section is independent of
      the token block).
