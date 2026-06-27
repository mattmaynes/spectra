# 0009 - Plugin versioning & releases

Supersedes the stale `0007-plugin-versioning-and-releases` work (closed PR #16), refreshed for
current `main`: versions have advanced to **1.0.2**, releases 1.0.0-1.0.2 already exist as tags,
and `whats-new.yml` now turns a release into the README headline.

## Problem
The plugin version lives hardcoded in **seven** manifests with no single source of truth and no
enforcement that they agree. Bumps are done by hand, one file at a time - and they drift: two
marketplace manifests were stranded at `0.1.1` across three releases until #27. Each agent's
update detection is driven by the manifest `version` string, so a stranded manifest can freeze
installed users on an old version. Releases are also cut by hand (`gh release create`), which is
easy to forget and to do inconsistently. We need one enforced version and an automated release.

## Outcome
- One source of truth - a root **`VERSION`** file holding `x.y.z` (`1.0.2` on landing) - from
  which all seven manifests are kept identical; CI fails any change where they drift.
- **`scripts/bump-version.sh X.Y.Z`** rewrites `VERSION` + all seven manifests in one shot;
  `--check` verifies they agree; it rejects a non-semver or `v`-prefixed argument.
- Merging a `VERSION` bump to `main` makes CI **auto-create the bare-semver git tag `x.y.z`** at
  that commit and **publish a GitHub Release**. Release notes come from `docs/releases/<x.y.z>.md`
  when that file exists (so the author controls the headline), otherwise from `--generate-notes`.
- The release job is **idempotent**: a push whose `VERSION` already has a release does nothing
  (so existing 1.0.0-1.0.2 are untouched; the job first fires on the next bump).
- The release composes with `whats-new.yml`: publishing the Release fires the `release` event,
  which rewrites the README "What's new" headline from the notes' first non-heading line.
- Identity: marketplace `owner` and plugin `author` read **`rogueoak`** (personal name/email
  dropped), post org-transfer.

## Scope
- **In:**
  - `VERSION` (repo root) - canonical `x.y.z`, `1.0.2` on landing.
  - `scripts/bump-version.sh` - repo-local, POSIX + `python3` (already a `test.sh` dep). Modes:
    `X.Y.Z` writes VERSION + all 7 manifests; `--check` asserts `VERSION` == every manifest's
    lone `version` field (exit non-zero on drift/missing); no-arg prints the current version;
    `--help`. Validates the argument against `^[0-9]+\.[0-9]+\.[0-9]+$` (semver, no `v`). Honors
    a `SPECTRA_ROOT` override so the suite can run it against a sandbox (mirrors `SPECTRA_SRC`).
  - `.github/workflows/ci.yml` - a new `release` job: `if: github.event_name == 'push'`,
    `needs: [test, readme-drift]`, **job-scoped `permissions: contents: write`** (workflow
    default stays `contents: read`). Reads `VERSION`; if `gh release view "$VERSION"` 404s, runs
    `gh release create "$VERSION" --target "$GITHUB_SHA"` with `--notes-file
    docs/releases/$VERSION.md` if that file exists, else `--generate-notes`.
  - `docs/releases/` - per-version notes. `<x.y.z>.md`'s first non-heading line is the README
    "What's new" headline; the rest is the Release body. A short `docs/releases/README.md`
    documents the convention. (Back-seeding 1.0.0-1.0.2 is out; those releases already exist.)
  - `test.sh` - a step running `bump-version.sh --check` (the 7-way invariant), semver
    accept/reject cases, and a `SPECTRA_ROOT` sandbox write - matching the `check-commit-msg.sh`
    test pattern.
  - **Identity**: set marketplace `owner` and plugin `author` to `rogueoak` (drop personal
    name/email) across the manifests. One-time edit in the same sweep.
  - Docs: a **"Releasing"** note in `AGENTS.md` (outside the `spectra:start/end` block -
    repo-local, never shipped); reflect in `docs/overview/` (features, architecture).
- **Out:**
  - Any *new* shipped behavior under `spectra/` beyond the version string + author field -
    protocol/skills/personas/host block untouched, so token figures and consumer install/update
    are unaffected (version & author live in JSON; `token-report` only counts Markdown).
  - A `CHANGELOG.md` (the Releases are the changelog).
  - Back-filling release notes for 1.0.0-1.0.2 (already published).
  - Consumer-facing version pinning / release channels; automating the *bump number* (a human
    picks the next version in the PR; CI only reacts to the committed `VERSION`).

## Approach
- **Single source of truth.** `VERSION` (plain, `cat`-able) is authored; the seven manifests are
  derivatives kept equal by `bump-version.sh` and enforced by `--check`. A plain file (not a
  chosen "canonical" manifest) avoids making one manifest special and lets the release job read
  the version with `cat` - no JSON parsing in CI.
- **One `version` token per file.** Each manifest has exactly one `"version"` (top-level in the
  `plugin.json`/`gemini-extension.json` files, `plugins[0].version` in the marketplaces), so both
  read and write key on that single token (format-preserving surgical substitution via `python3`,
  not a full re-serialize that would reflow hand-formatted files); the script guards exactly one
  occurrence and that the file still parses as JSON after a write.
- **Release job composes with whats-new.** On `push: main`, after `test`+`readme-drift`, an
  elevated job reads `VERSION` and, if no release exists, calls `gh release create` (tag created
  at the target commit - no separate `git tag`/push). Notes prefer the hand-written
  `docs/releases/<v>.md` so the README headline stays human; `--generate-notes` is the fallback.
  Publishing fires the `release` event that `whats-new.yml` already handles end-to-end (it needs
  Actions-create-PR, now enabled org-wide).
- **Why the manifest `version` is the real update signal, not the tag.** Agents gate updates on
  the `version` string; the tag is the durable release marker. Both wired to the same `x.y.z`.
- **Least privilege.** Only the `release` job gets `contents: write`; everything else stays
  read-only. `gh` uses the ambient `GITHUB_TOKEN` (no PAT); no untrusted input is interpolated.

## Acceptance
- [ ] `VERSION` exists at root with a single `x.y.z` line (`1.0.2`); all 7 manifests match it.
- [ ] `bump-version.sh 9.9.9` sets `VERSION` + all 7 manifests to `9.9.9`; `--check` then exits
      0; hand-editing one manifest makes `--check` exit non-zero.
- [ ] `bump-version.sh v1.2.3` / `1.2` / `nope` / `1.2.3.4` / `""` exit non-zero.
- [ ] `test.sh` includes the `--check` invariant, semver cases, and the sandbox-write case, and
      still ends `PASS`.
- [ ] `ci.yml` has a `release` job: push-only, `needs: [test, readme-drift]`, job-scoped
      `contents: write`, idempotent via `gh release view`, notes from `docs/releases/<v>.md` when
      present else `--generate-notes`.
- [ ] A `docs/releases/README.md` documents the per-version notes convention (first non-heading
      line = README headline).
- [ ] Marketplace `owner` and plugin `author` read `rogueoak`; no personal name/email remains;
      all 7 manifests still parse as JSON.
- [ ] Nothing else under `spectra/` changes; README token figures unaffected.
- [ ] `AGENTS.md` documents the release flow (outside the spectra block); `docs/overview/`
      (features, architecture) updated.
