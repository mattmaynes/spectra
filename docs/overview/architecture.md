# Architecture

Two halves, by design:

- **`spectra/`** — the **shippable source of truth** (the plugin). Contains the skills
  (`skills/spectra-install`, `skills/spectra-update`), the protocol (`protocol.md`), the host
  block (`agents.md`), the review `personas/` (a shared `persona.md` review contract plus one
  file per persona), and the `hooks/pre-commit`. This is what a consumer installs.
- **`docs/`** — this repo's **installed instance** (Spectra dogfooding itself): the artifact
  tree (`specs/`, `plans/`, `feedback/`, `overview/`). Its `docs/spectra/` entries are
  **symlinks** back to `spectra/` — a **dogfood-only DRY convenience that is never shipped**.
  A real consumer gets plain *copies* there (what `spectra-install` writes); the layout is
  identical in shape, only this repo substitutes symlinks because it owns the source.

**Install flow:** `/plugin marketplace add` registers the marketplace; `/plugin install
spectra@spectra` adds the skills; `/spectra-install` runs the skill against the target repo.
Skills resolve bundled files via `${CLAUDE_SKILL_DIR}/../..`.

**Hook install:** `spectra-install` **copies** `hooks/pre-commit` into the repo's resolved
hooks dir (`git rev-parse --git-path hooks`) — not a symlink to a tracked file — so the hook
that runs on commit is explicit and only changes when `/spectra-update` re-copies it, and the
resolved path is correct under `core.hooksPath`/worktrees. An existing hook (Husky, lefthook,
pre-commit framework) is **never clobbered**: Spectra drops a `spectra-pre-commit` sidecar and
chains a guarded call.

**Command discovery:** skills are auto-discovered from `spectra/skills/<name>/SKILL.md` — the
folder name becomes the `/<name>` command; `plugin.json` carries no explicit skill list.

**Host files:** `AGENTS.md` is canonical; `CLAUDE.md` and `GEMINI.md` symlink to it; Codex
reads `AGENTS.md` natively. The Spectra block is delimited by `<!-- spectra:start/end -->`
markers so updates are idempotent.

**Repo-local tooling (never shipped):** `scripts/` and `assets/` are this repo's own
presentation/QA layer — explicitly *not* under `spectra/`, so `spectra-install`/`update`
never touch a consumer with them.
- `scripts/token-report.sh` is the single source of the README's token figures: it measures
  `spectra/` and rewrites a marker-delimited block (`<!-- spectra:tokens:start/end -->`),
  reusing the same idempotent-marker pattern as the host block. `--check` is wired into both
  `test.sh` (step 8) and this repo's `.git/hooks/pre-commit` (a *second*, blocking guard
  added beside the shipped non-blocking reflection reminder — gated on `spectra/` being
  staged). The shipped `spectra/hooks/pre-commit` is untouched.
- `assets/*.svg` are self-contained dark "cards" (own background + spectrum palette) so they
  render identically under GitHub's light and dark themes, embedded via `<img>`.
