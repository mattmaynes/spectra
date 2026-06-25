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
    headline in `<!-- whats-new -->` / `<!-- /whats-new -->` markers, plus a "see every release"
    pointer. Seeded with the current latest release (`1.0.0`).
  - `.github/workflows/whats-new.yml` - on `release: [published]`, rewrites the block (first
    non-heading line of the notes; falls back to the release title) and lands it via an
    auto-created, self-squash-merged PR.
- **Out:**
  - Changing how releases are cut or tagged.
  - A full changelog or release-notes generator - this is a single headline, not a history.
  - Touching the `spectra:tokens` block or token report (independent README machinery).

## Approach
Mirror Trellis's `whats-new.yml`, with one deliberate divergence forced by governance:

- **Trellis** `main` has no ruleset, so its workflow commits the README change and pushes
  straight to `main`.
- **Spectra** `main` requires a pull request (`pull_request` rule) and forbids direct pushes,
  but adds **no required status checks** and **0 required approvals**. So the workflow creates a
  short-lived `chore/whats-new-<tag>` branch, opens a PR with a Conventional Commit title, and
  squash-merges it itself (with a brief retry while GitHub computes mergeability). The ruleset
  stays intact; the bot just uses the front door.

Key decisions / trade-offs:
- **Untrusted release body** is passed to Python via env vars and only ever used as a string
  (`.splitlines()`, regex `subn` on fixed markers) - never interpolated into a shell command, so
  no injection. Release notes are maintainer-authored, so markdown in the headline is low risk.
- **Least-privilege token**: `contents: write` (push the branch) + `pull-requests: write` (open
  and merge). Nothing else.
- **PR over bypass actor**: keeping every write to `main` behind a PR is more in keeping with a
  repo that deliberately runs a ruleset than weakening the ruleset with an Actions bypass.

## Acceptance
- [ ] README renders a `## What's new` section with the seeded `**1.0.0**` headline and the
      releases-page pointer.
- [ ] `<!-- whats-new -->` / `<!-- /whats-new -->` markers are present and wrap exactly the
      headline line.
- [ ] `.github/workflows/whats-new.yml` triggers on `release: [published]`, extracts the first
      non-heading note line, and updates the block.
- [ ] The workflow lands the change through a PR (no direct push to `main`).
- [ ] `test.sh` and the README token-drift check still pass (the new section is independent of
      the token block).
