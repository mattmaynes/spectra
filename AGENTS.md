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

## Commits & PR titles

This repo uses **[Conventional Commits](https://www.conventionalcommits.org)**: every commit
message **and** PR title is `<type>[optional scope][!]: <subject>` (types: `feat`, `fix`,
`docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`). Because PRs
squash-merge, the **PR title** becomes the landed commit and is checked in CI. Validate a
message locally with `scripts/check-commit-msg.sh "<message>"`. (Repo-local convention; not
part of the shipped plugin.)

## Merging

`main` is governed by a GitHub **ruleset** (not classic branch protection), so a green CI run
is necessary but **not sufficient** to merge. The ruleset requires:

- **All review threads resolved** (`required_review_thread_resolution`). After a persona
  review, resolve every inline thread once its finding is addressed — otherwise
  `gh pr merge` fails with *"the base branch policy prohibits the merge"* even when checks pass.
  Resolve via the GraphQL `resolveReviewThread` mutation (REST can't); list open threads with
  the `pullRequest.reviewThreads` query.
- **Squash only**, **linear history**, **0 required approvals**; no force-push or deletion of
  `main`.

When merging from a worktree, `gh pr merge --delete-branch` may error trying to update the
local ref (`main` is checked out elsewhere) *after* the remote merge already succeeded — verify
with `gh pr view <n> --json state`, then remove the branch/worktree manually. (Repo-local
operational note; not part of the shipped plugin.)
