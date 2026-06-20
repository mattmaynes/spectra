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
- **`<persona>`** → resolve `<persona>.md` from `$SRC/personas/` then `$SRC/personas/optional/`;
  `mkdir -p docs/spectra/personas && cp` it in. Reject `persona` (shared contract) and any name
  not in the catalog. If already present, say so.

Confirm the now-active set. Enabled personas get scoped into future reviews per the protocol.
