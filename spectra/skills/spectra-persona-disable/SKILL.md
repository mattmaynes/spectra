---
name: spectra-persona-disable
description: Turn off a Spectra review persona for this repo (including a core persona like security) by removing it from docs/spectra/personas.config. Run with no argument to list the personas currently enabled. Use when asked to disable, turn off, or remove a review persona.
---

# Disable a persona

Active personas are the slugs listed in `docs/spectra/personas.config`; disabling = removing the
line (the persona file stays in `docs/spectra/personas/`, just unlisted). **Candidates** = slugs
currently in the config, excluding the 👤 User/ICP personas (`user*.md`, developer-owned — manage
them with `/spectra-add-user`, `/spectra-update-user`, `/spectra-remove-user`, `/spectra-list-users`).

- **No argument** → number the candidates (slug + title line) and ask which to disable. Act on the
  reply (a number, several, or "all").
- **`<persona>`** → **validate first**: the name must match `^[a-z][a-z0-9-]*$` (a bare slug — no
  `/`, `..`, leading `/`, or extension) **and** be a current candidate. Reject any `user`/`user-*`
  slug (ICP personas — manage with `/spectra-remove-user`). If valid,
  delete that slug's line from `docs/spectra/personas.config`. If not enabled, say so.

Disabling a **core** persona (engineer, tester, architect, security) is allowed and persists: the
config is developer-owned, so `spectra-update` never re-enables it. Confirm the now-active set.
