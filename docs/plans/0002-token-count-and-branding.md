# 0002 - Plan: token-count guard, diagram & branding

Source: `docs/specs/0002-token-count-and-branding.md`. Branch: `token-count-and-branding`.

## Steps
1. **`scripts/token-report.sh`** - compute char/token counts for three groupings from
   `spectra/`; subcommands: default/`print` (render markdown table), `--write` (replace the
   README marker block in place), `--check` (exit non-zero if README block is stale).
   Portable POSIX sh + awk; thousands-separator via awk; tokens = `round(chars/4)`.
2. **README token block** - wrap the "Low token cost" table in
   `<!-- spectra:tokens:start/end -->`, run `--write` to fill it with accurate numbers,
   refresh the surrounding prose (note it's generated; fix the stale 2.6k→actual).
3. **Hook** - extend `.git/hooks/pre-commit` (repo-local, untracked): after the reflection
   reminder, if staged files match `^spectra/`, run `token-report.sh --check`; on failure
   print how to fix (`scripts/token-report.sh --write`) and exit non-zero (blocking).
4. **`test.sh`** - add a section running `token-report.sh --check` against the working tree
   so the suite enforces accuracy too.
5. **`assets/logo.svg`** - spectrum loop/orbit emblem + "Spectra" wordmark lockup,
   self-contained dark card, spectrum gradient.
6. **`assets/protocol-flow.svg`** - route→spec→plan→build→test→review→merge→reflect node
   flow with a reflect→learnings feedback arc; spectrum palette; dark card.
7. **README content** - centered logo at top; link the protocol-flow diagram in "The
   protocol"; add an "Own your protocol" section (plain files, no third-party runtime,
   opinionated-yet-flexible).
8. **Reflect** - update `docs/overview/` (features + architecture + learnings).
9. **Verify** - `sh test.sh` green; simulate the hook (stage a `spectra/` edit, confirm
   block, then `--write`, confirm pass); open PR for approval.

## Files touched
- New: `assets/logo.svg`, `assets/protocol-flow.svg`, `scripts/token-report.sh`.
- Edit: `README.md`, `test.sh`, `.git/hooks/pre-commit` (untracked), `docs/overview/*`.
- Unchanged: everything under `spectra/`.

## Verification
- `scripts/token-report.sh --check` ↔ `--write` round-trips cleanly.
- Hook blocks a `spectra/` edit until figures refreshed; ignores non-`spectra/` commits.
- `sh test.sh` ends `PASS`. SVGs are valid XML and visible in the GitHub diff/preview.
