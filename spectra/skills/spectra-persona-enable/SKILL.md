---
name: spectra-persona-enable
description: Turn on a Spectra review persona for this repo (e.g. designer, compliance, analytics) by adding it to docs/spectra/personas.config. Run with no argument to list the personas available to enable. Use when asked to enable, turn on, or add a review persona.
---

# Enable a persona

Active personas are the slugs listed in `docs/spectra/personas.config`; the available set is the
persona files in `docs/spectra/personas/` (excluding `persona.md`, the shared contract, and the
👤 User/ICP personas `user*.md`, which are managed by their own commands — `/spectra-add-user`,
`/spectra-update-user`, `/spectra-remove-user`, `/spectra-list-users` — not the config). A persona is on iff its slug is
in the config — enabling = adding the line. **Candidates** = available personas whose slug is not
already in the config.

- **No argument** → number the candidates (slug + the title line from each persona file as its
  purpose) and ask which to enable. Act on the reply (a number, several, or "all").
- **`<persona>`** → **validate first**: the name must match `^[a-z][a-z0-9-]*$` (a bare slug — no
  `/`, `..`, leading `/`, or extension) **and** correspond to an existing
  `docs/spectra/personas/<persona>.md` (an allowlist check, never a path built by interpolating
  the argument). Reject `persona` (shared contract) and any `user`/`user-*` slug (ICP personas are
  managed by `/spectra-add-user` etc., not the config). If valid and not already listed, append the
  slug as its own line in `docs/spectra/personas.config`. If already enabled, say so.

Confirm the now-active set. Enabled personas get scoped into future reviews per the protocol.
