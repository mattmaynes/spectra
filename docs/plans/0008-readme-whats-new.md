# 0008 - README "What's new" section (plan)

Source: `docs/specs/0008-readme-whats-new.md`.

## Steps

1. **README block** (`README.md`) - add a `## What's new` section between the intro and
   `## Quick start`. Wrap the headline in `<!-- spectra:whats-new:start -->` /
   `<!-- spectra:whats-new:end -->` (the repo's marker convention), seed it with
   `**1.0.0** - First stable release. 🎉`, and add the "see every release" pointer.

2. **Script** (`scripts/whats-new.sh`) - repo-local, dependency-free POSIX sh, mirroring
   `token-report.sh`: read `TAG`/`NAME`/`BODY` from env, extract + sanitize the headline, and
   rewrite the block (`--write`) or print it (no arg). Aborts unless exactly one marker pair.

3. **Workflow** (`.github/workflows/whats-new.yml`) - on `release: [published]`: check out the
   default branch (action pinned to a SHA), `scripts/whats-new.sh --write`, and if README
   changed open a `chore/whats-new-<tag>` PR and squash-merge it (retry loop; reuses an existing
   PR; plain `--force` push). Permissions: `contents: write`, `pull-requests: write`.

4. **Tests** (`test.sh` section 10) - marker-pair invariant + headline extraction cases
   (first-line, name-fallback, CRLF, sanitization, missing TAG).

5. **Reflect** - record the capability in `docs/overview/features.md` and the script + release->PR
   flow in `docs/overview/architecture.md`.

## Files touched
- `README.md`, `scripts/whats-new.sh`, `.github/workflows/whats-new.yml` (new)
- `test.sh` (section 10)
- `docs/specs/0008-readme-whats-new.md`, `docs/plans/0008-readme-whats-new.md` (new)
- `docs/overview/features.md`, `docs/overview/architecture.md` (reflect)

## Verification
- `bash test.sh` passes, including the new section 10 (extraction + marker invariant).
- `scripts/token-report.sh --check` clean (the new section is outside the token block).
- Workflow YAML parses; the heredoc-free wrapper just calls the script.
- The end-to-end workflow (open + self-merge PR) is exercised for real at the next published
  release (cannot run pre-merge).
