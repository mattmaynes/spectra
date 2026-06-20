---
name: spectra-enable
description: Turn on a Spectra review persona for this repo (e.g. designer, compliance, analytics, or a previously disabled core persona) by copying its file into docs/spectra/personas/. Run with no argument to list the personas available to enable. Use when asked to enable, turn on, or add a review persona.
---

# Enable a persona

A persona is active iff `docs/spectra/personas/<name>.md` exists. This copies one in from the
bundled source `SRC="${CLAUDE_SKILL_DIR}/../.."`. Catalog = `$SRC/personas/*.md` (excluding
`persona.md`) plus `$SRC/personas/optional/*.md`. **Candidates** = catalog names not already
present in `docs/spectra/personas/`.

- **No argument** → number the candidates (name + the title line from each file as its purpose)
  and ask which to enable. Act on the reply (a number, several, or "all").
- **`<persona>`** → **first validate the name**: it must be a bare single segment matching
  `^[a-z][a-z0-9-]*$` (no `/`, `..`, leading `/`, or extension) **and** be a member of the
  catalog computed above — an allowlist check, not just `[ -f ]` of an interpolated path, so a
  crafted name can't reach a file outside the persona set. Reject `persona` (shared contract).
  Then resolve `<persona>.md` from `$SRC/personas/` (falling back to `$SRC/personas/optional/`)
  and `mkdir -p docs/spectra/personas && cp` it in. If already present, say so.

Confirm the now-active set. Enabled personas get scoped into future reviews per the protocol.
