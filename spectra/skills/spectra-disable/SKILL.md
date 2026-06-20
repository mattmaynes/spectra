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
- **`<persona>`** → if it's a candidate, `rm -f docs/spectra/personas/<persona>.md`. Reject
  `persona` and `user`; if not present, say so.

Disabling a **core** persona (engineer, tester, architect, security) is allowed and **persists
across `spectra-update`** — update refreshes only personas that are present. Confirm the
now-active set.
