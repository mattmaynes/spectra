# Architecture

Two halves, by design:

- **`spectra/`** — the **shippable source of truth** (the plugin). Contains the skills
  (`skills/spectra-install`, `skills/spectra-update`), the protocol (`protocol.md`), the host
  block (`agents.md`), the review `personas/`, and the `hooks/pre-commit`. This is what a
  consumer installs.
- **`docs/`** — this repo's **installed instance** (Spectra dogfooding itself): the artifact
  tree (`specs/`, `plans/`, `feedback/`, `overview/`) plus `docs/spectra/` which **symlinks**
  back to `spectra/` to stay DRY. A normal consumer gets *copies* here instead.

**Install flow:** `/plugin marketplace add` registers the marketplace; `/plugin install
spectra@spectra` adds the skills; `/spectra-install` runs the skill against the target repo.
Skills resolve bundled files via `${CLAUDE_SKILL_DIR}/../..`.

**Host files:** `AGENTS.md` is canonical; `CLAUDE.md` and `GEMINI.md` symlink to it; Codex
reads `AGENTS.md` natively. The Spectra block is delimited by `<!-- spectra:start/end -->`
markers so updates are idempotent.
