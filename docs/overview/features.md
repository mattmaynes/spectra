# Features

- **Plugin marketplace** — `.claude-plugin/marketplace.json` exposing the `spectra` plugin.
- **`spectra-install` skill** — scaffolds `docs/`, copies protocol + personas, installs the
  reflection hook, wires up AGENTS.md.
- **`spectra-update` skill** — re-syncs Spectra-owned files; **refreshes only the personas
  already present** in the repo, so disabled personas stay off and a configured
  `docs/spectra/personas/user.md` is preserved.
- **`spectra-setup` skill** — a guided dialog that defines the repo's 👤 *User (ICP)* persona,
  written to `docs/spectra/personas/user.md`. Re-running refines the existing persona.
- **`spectra-enable` / `spectra-disable` skills** — toggle any review persona on or off by
  copying its file into / removing it from `docs/spectra/personas/`. Run with no argument to
  pick from a numbered list. Any persona is toggleable, including the core four.
- **Protocol** (`spectra/protocol.md`) — route → spec → plan → build → test → review → merge → reflect.
- **Review personas** — engineer 🔧, tester 🧪, architect 📐, security 🔒 on by default, plus
  **optional** designer 🎨, compliance ⚖️, and analytics 📊 (shipped but off until enabled) and
  a consumer-defined user 👤 (ICP, present once `spectra-setup` writes `user.md`). A persona is
  **active iff its file exists** in `docs/spectra/personas/`; the active set is **scoped per
  change** (triage which apply) and tuned with `spectra-enable`/`spectra-disable`. A shared
  `personas/persona.md` holds the review contract (inline-only comments, one issue each,
  concrete fixes, and the canonical emoji-tagged, severity-graded comment format); each persona
  file holds only its specific, opinionated checklist. Major/blocker feed `learnings.md`.
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
- **CI** (repo-local, `.github/workflows/ci.yml`) — on push and PR: runs `test.sh`, re-runs
  the README token-drift guard (`token-report.sh --check`) so fork PRs and fresh clones are
  covered even though the local hook is untracked, and validates the PR title against
  Conventional Commits.
- **Conventional Commits** — commit messages and PR titles follow
  `<type>[scope][!]: <subject>`, checked by the dependency-free `scripts/check-commit-msg.sh`
  (repo-local; documented in `AGENTS.md`, enforced by CI on PR titles).
