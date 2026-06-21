# 0007 — Plugin versioning & releases

## Problem
The plugin's version is hardcoded `0.1.0` in **seven** manifests (Claude/Codex/Cursor
`plugin.json`, the three repo-root marketplaces, and `gemini-extension.json`). There's no tag,
no release, and no way to bump them in sync. Each agent's update detection is driven by the
manifest `version`: when it's set, Claude Code keeps the cached copy until the string changes;
when absent it falls back to the commit SHA. So installed users are effectively **frozen at
`0.1.0`** — pushing to `main` ships them nothing until the version string moves. We need one
enforced version, with each release marked by a git tag.

## Outcome
- One source of truth — a root **`VERSION`** file holding `x.y.z` — from which all seven
  manifests are kept identical; CI fails any change where they drift.
- **`scripts/bump-version.sh X.Y.Z`** rewrites `VERSION` + all seven manifests in one shot;
  `--check` verifies they agree; it rejects a non-semver or `v`-prefixed argument.
- Merging a version bump to `main` makes CI **auto-create a git tag `x.y.z`** (bare semver, no
  `v`) at that commit and **publish a GitHub Release** whose notes are auto-generated from the
  conventional-commit PR titles since the previous tag. No `CHANGELOG.md`.
- The release job is **idempotent**: a push whose `VERSION` already has a release does nothing.
- The inaugural release is **`0.1.0`** — this PR stands up the machinery and tags the version
  that is effectively already shipping; the number is bumped on the next change.

## Scope
- **In:**
  - `VERSION` (repo root) — the canonical `x.y.z` (`0.1.0` on landing).
  - `scripts/bump-version.sh` — repo-local, POSIX + `python3` (already a `test.sh` dep). Modes:
    `X.Y.Z` writes VERSION + all 7 manifests; `--check` asserts `VERSION` == every manifest's
    lone `version` field (exit non-zero on drift); no-arg prints the current version; `--help`.
    Validates the argument against `^[0-9]+\.[0-9]+\.[0-9]+$` (semver, no `v`). Honors a
    `SPECTRA_ROOT` override so the suite can exercise it against a sandbox (mirrors the
    `SPECTRA_SRC` pattern).
  - `.github/workflows/ci.yml` — a new `release` job: `push: main` only, `needs:
    [test, readme-drift]`, **job-scoped `permissions: contents: write`** (the workflow default
    stays `contents: read`). Reads `VERSION`; if `gh release view "$VERSION"` 404s, runs
    `gh release create "$VERSION" --target "$GITHUB_SHA" --generate-notes` (creates the bare
    tag + Release + notes in one call). `gh` + `GITHUB_TOKEN` are runner built-ins.
  - `test.sh` — a step running `bump-version.sh --check` (the 7-way invariant), semver
    accept/reject cases, and a sandbox write that propagates `X.Y.Z` to copies of the real
    manifests then passes `--check` — matching the existing `check-commit-msg.sh` test pattern.
  - **Identity**: post-transfer, set marketplace `owner` and plugin `author` to **`rogueoak`**
    across the manifests (drop the personal name/email). One-time edit in the same sweep.
  - Docs: a short **"Releasing"** note in `AGENTS.md` (outside the `spectra:start/end` block —
    repo-local, never shipped); reflect in `docs/overview/` (features, architecture).
- **Out:**
  - Any *new* shipped behavior under `spectra/` beyond the version string + author field —
    protocol/skills/personas/host block untouched, so token figures and consumer install/update
    are unaffected (version & author live in JSON; `token-report` only counts Markdown).
  - A `CHANGELOG.md` (the Release's auto-notes are the changelog — git is conventional-commits).
  - Consumer-facing version pinning / release channels (users keep
    `marketplace add rogueoak/spectra`; the bumped `version` field is what delivers updates —
    `ref`/`#tag` pinning stays *available* but undocumented/unbuilt).
  - Automating the *bump number* (a human decides the next version in the PR; CI only reacts to
    the committed `VERSION`). No history rewriting / retroactive tags.

## Approach
- **Single source of truth.** `VERSION` (plain, `cat`-able) is authored; the seven manifests
  are derivatives kept equal by `bump-version.sh` and enforced by `--check`. A plain file (not a
  chosen "canonical" manifest) avoids making one manifest arbitrarily special and lets the
  release job read the version with `cat` — no JSON parsing in CI.
- **One `version` token per file.** Each manifest contains exactly one `"version"` field —
  top-level in the `plugin.json`/`gemini-extension.json` files, `plugins[0].version` in the
  marketplaces. So both read and write key on that single token (format-preserving surgical
  substitution, not a full JSON re-serialize that would reflow the hand-formatted files); the
  script guards that each file has exactly one occurrence and still parses as JSON after a write.
- **Release job.** On `push: main`, after `test`+`readme-drift` pass, an elevated job reads
  `VERSION` and, if no release exists, calls `gh release create`. That creates the bare-semver
  tag at the target commit, so there's no separate `git tag`/push, and `--generate-notes` is
  server-side so the default shallow checkout is fine. Idempotent via the `gh release view`
  guard; only fires when `VERSION` moved to an unreleased value. For the first release (`0.1.0`,
  no prior tag) the notes span all history.
- **Why the manifest `version` is the real update signal, not the tag.** The agents gate
  updates on the `version` string; the tag is the durable release marker + optional pin point.
  So the bump is mandatory and the tag is the artifact — both wired to the same `x.y.z`.
- **Least privilege.** Only the `release` job gets `contents: write`; everything else stays
  read-only. `gh` is invoked with the ambient `GITHUB_TOKEN` (no PAT), and no untrusted input is
  interpolated into the shell.

## Acceptance
- [ ] `VERSION` exists at root with a single `x.y.z` line (`0.1.0`); all 7 manifests match it.
- [ ] `bump-version.sh 9.9.9` sets `VERSION` + all 7 manifests to `9.9.9`; `--check` then exits
      0; hand-editing one manifest makes `--check` exit non-zero.
- [ ] `bump-version.sh v1.2.3` / `1.2` / `nope` / `1.2.3.4` exit non-zero (semver-only, no `v`).
- [ ] `test.sh` includes the `--check` invariant, semver cases, and the sandbox-write case, and
      still ends `PASS`.
- [ ] `ci.yml` has a `release` job: `push: main` only, `needs: [test, readme-drift]`,
      job-scoped `contents: write`, idempotent via `gh release view`.
- [ ] Merging a `VERSION` bump to `main` produces a bare-semver tag (no `v`) and a GitHub
      Release with notes from the conventional-commit titles since the prior tag; a no-bump push
      creates nothing.
- [ ] Marketplace `owner` and plugin `author` read `rogueoak`; no personal name/email remains.
- [ ] Nothing else under `spectra/` changes; README token figures unaffected.
- [ ] `AGENTS.md` documents the release flow (outside the spectra block); `docs/overview/`
      (features, architecture) updated.
