# 0001 — Build Spectra (plan for spec 0001)

Source: `docs/specs/0001-spectra-protocol.md`.

## Steps
1. Manifests — `.claude-plugin/marketplace.json`, `spectra/.claude-plugin/plugin.json`.
2. Protocol & personas — `spectra/protocol.md`, `spectra/agents.md`,
   `spectra/personas/{engineer,tester,architect,security}.md`.
3. Skills & hook — `spectra/skills/spectra-install`, `spectra/skills/spectra-update`,
   `spectra/hooks/pre-commit` (executable).
4. Dogfood — `docs/` tree, this spec + plan, `docs/overview/*` living docs,
   `docs/spectra/` symlinks to the shippable source.
5. Surface — `README.md`, `.gitignore`, `AGENTS.md` + `CLAUDE.md`/`GEMINI.md` symlinks.

## Verification
JSON parses; hook reminds-but-passes in a temp repo; install steps produce the expected tree;
update is idempotent (no duplicated host block). See `docs/specs/0001` acceptance.
