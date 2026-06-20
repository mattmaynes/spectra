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
- **Test suite** (`test.sh`) — validates manifests, hook behavior, and install mechanics.
