# 0008 - README "What's new" section (plan)

Source: `docs/specs/0008-readme-whats-new.md`.

## Steps

1. **README block** (`README.md`) - add a `## What's new` section between the intro and
   `## Quick start`. Wrap the headline in `<!-- whats-new -->` / `<!-- /whats-new -->`, seed it
   with `**1.0.0** - First stable release. 🎉` (the first non-heading line of the 1.0.0 notes),
   and add the "see every release" pointer to `/releases/latest`.

2. **Workflow** (`.github/workflows/whats-new.yml`) - on `release: [published]`:
   - check out the default branch,
   - rewrite the block from the release notes (Python, untrusted body via env),
   - if README changed, open a `chore/whats-new-<tag>` PR and squash-merge it (retry loop).
   Permissions: `contents: write`, `pull-requests: write`. Concurrency group `whats-new`.

3. **Reflect** - record the new capability in `docs/overview/features.md` and the release->PR
   automation flow in `docs/overview/architecture.md`.

## Files touched
- `README.md` (new section)
- `.github/workflows/whats-new.yml` (new)
- `docs/specs/0008-readme-whats-new.md`, `docs/plans/0008-readme-whats-new.md` (new)
- `docs/overview/features.md`, `docs/overview/architecture.md` (reflect)

## Verification
- `bash test.sh` passes (token-drift + dogfood integrity unaffected).
- `scripts/token-report.sh --check` clean (the new section is outside the token block).
- `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/whats-new.yml'))"` parses
  (or `actionlint` if available).
- Marker presence: README contains exactly one `<!-- whats-new -->` / `<!-- /whats-new -->` pair.
- Workflow behavior is exercised for real at the next published release (cannot run pre-merge).
