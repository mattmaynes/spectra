# AGENTS.md

This repo **is** the source of Spectra (see [`README.md`](README.md)). It is also built
*using* Spectra — it dogfoods its own protocol. The shippable plugin lives in `spectra/`;
this repo's installed instance lives in `docs/`.

<!-- spectra:start -->
## Spectra protocol

This repo uses **Spectra** — spec-driven development with learning feedback loops.
Read `docs/spectra/protocol.md` and follow it for every change:

- **Trivial** change → implement directly. **Feature** → spec in `docs/specs/` (get
  approval first). **Bug/feedback** → doc in `docs/feedback/`.
- Multi-step work → a plan in `docs/plans/`, built in a worktree, **tested before commit**,
  reviewed by the personas in `docs/spectra/personas/` via PR comments, merged on approval.
- **Before concluding, reflect**: update the relevant `docs/overview/` living docs
  (`project`, `features`, `architecture`, `learnings`).
<!-- spectra:end -->

## Merging

`main` is governed by a GitHub **ruleset** (not classic branch protection): squash only, linear
history, 0 required approvals, no force-push or deletion. Trellis already says pass CI and
resolve every review thread before merge; the repo-specific catches are:

- A green CI run is necessary but **not sufficient** - the ruleset also enforces
  `required_review_thread_resolution`. Resolve threads via the GraphQL `resolveReviewThread`
  mutation (REST can't); list open ones with `pullRequest.reviewThreads`. Otherwise
  `gh pr merge` fails with *"the base branch policy prohibits the merge"* even when checks pass.
- From a worktree, `gh pr merge --delete-branch` may error updating the local ref (`main` is
  checked out elsewhere) *after* the remote merge already succeeded. Verify with
  `gh pr view <n> --json state`, then remove the branch/worktree manually.

<!-- trellis:start -->
## Trellis conventions

This repo follows **Trellis** - rogueoak's shared rules for AI agents. Read the rules in
`docs/rules/` and follow them on every change:

- **`docs/rules/guidelines.md`** - how to write and ship: ASCII-only text, and code that passes
  tests, lint, and build before it merges.
- **`docs/rules/language.md`** - the voice for anything public-facing (READMEs, docs, release
  notes, user-facing strings).

Pull updates with `/trellis-update`.
<!-- trellis:end -->
