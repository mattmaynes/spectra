---
name: spectra-disable
description: Turn off a Spectra review persona for this repo (including a core persona like security) by removing its file from docs/spectra/personas/. Run with no argument to list the personas currently enabled. Use when asked to disable, turn off, or remove a review persona.
---

# Disable a persona

A persona is active iff `docs/spectra/personas/<name>.md` exists, so disabling = removing it.
**Candidates** = persona files present in `docs/spectra/personas/`, excluding `persona.md` (the
shared contract) and `user.md` (developer-owned — manage it with `spectra-setup`, never delete
it here).

- **No argument** → number the candidates (name + title line) and ask which to disable. Act on
  the reply (a number, several, or "all").
- **`<persona>`** → **validate before removing anything**: the name must be a bare single
  segment matching `^[a-z][a-z0-9-]*$` (no `/`, `..`, leading `/`, or extension) **and** appear
  in the candidate list above. Never `rm` a path you only built by interpolating the argument —
  a crafted name like `../foo` must be refused, not deleted. Always reject `persona` and `user`.
  Only once validated, `rm -f docs/spectra/personas/<persona>.md`. If not present, say so.

Disabling a **core** persona (engineer, tester, architect, security) is allowed and **persists
across `spectra-update`** — update refreshes only personas that are present. Confirm the
now-active set.
