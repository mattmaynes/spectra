# Features

- **Plugin marketplace** — `.claude-plugin/marketplace.json` exposing the `spectra` plugin.
- **`spectra-install` skill** — scaffolds `docs/`, copies protocol + personas, installs the
  reflection hook, wires up AGENTS.md.
- **`spectra-update` skill** — re-syncs Spectra-owned files; preserves the repo's own content.
- **Protocol** (`spectra/protocol.md`) — route → spec → plan → build → test → review → merge → reflect.
- **Review personas** — engineer 🔧, tester 🧪, architect 📐, security 🔒; **scoped per
  change** (triage which apply). A shared `personas/persona.md` holds the review contract
  (inline-only comments, one issue each, concrete fixes, and the canonical emoji-tagged,
  severity-graded comment format); each persona file holds only its specific, opinionated
  checklist. Major/blocker feed `learnings.md`.
- **Reflection hook** — non-blocking `pre-commit` reminder to update the living docs.
- **Test suite** (`test.sh`) — validates manifests, hook behavior, install mechanics, and
  that the README's token figures match `spectra/`.
- **Token-count guard** (repo-local, not shipped) — `scripts/token-report.sh` measures
  `spectra/` (dependency-free `~4 chars/token`) and renders the README's token table behind
  `<!-- spectra:tokens -->` markers; `--write` updates it, `--check` verifies it. A
  repo-local `pre-commit` guard blocks any commit that edits `spectra/` without refreshing
  the figures, so the README's efficiency claim can't drift.
- **Branding assets** — `assets/logo.svg` (spectrum-loop wordmark) and
  `assets/protocol-flow.svg` (the route→…→reflect loop diagram), embedded in the README.
