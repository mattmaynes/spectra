# Features

- **Plugin marketplace** — `.claude-plugin/marketplace.json` exposing the `spectra` plugin.
- **`spectra-install` skill** — scaffolds `docs/`, copies protocol + personas, installs the
  reflection hook, wires up AGENTS.md.
- **`spectra-update` skill** — re-syncs Spectra-owned files; preserves the repo's own content.
- **Protocol** (`spectra/protocol.md`) — route → spec → plan → build → test → review → merge → reflect.
- **Review personas** — engineer, tester, architect, security; **scoped per change** (triage
  which apply), comments posted **inline** on PR lines in a fixed `_Spectra <Persona>_` /
  severity format; major/blocker feed `learnings.md`.
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
