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

**Create-on-demand persona (`user.md`):** the 👤 User (ICP) persona is **developer-owned** and
lives only in the installed instance — `spectra-setup` writes `docs/spectra/personas/user.md`
into the consumer's repo, and it is **never shipped** under `spectra/personas/`. Because the
update/install glob is `cp "$SRC/personas/"*.md` and `$SRC` has no `user.md`, the file simply
falls outside the copy: preservation is a property of the layout, not of any exclusion logic.
Absence is the default "off" state — reviews scope the persona in only when the file exists.

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
- `scripts/check-commit-msg.sh` is the dependency-free Conventional Commits validator (POSIX
  `grep -Eq` against `<type>[scope][!]: <subject>`). Same "runs anywhere, no toolchain"
  rationale as `token-report.sh`. The convention is documented in `AGENTS.md` **outside** the
  `spectra:start/end` block, so it's repo-local and never shipped.

**CI (repo-local, never shipped):** `.github/workflows/ci.yml` runs on push and PR with three
least-privilege (`contents: read`) jobs: `test` (`./test.sh`), `readme-drift`
(`token-report.sh --check`), and `commit-lint` (PR-only, validates the PR title). CI is where
the repo's local guards become *shared* gates: the token-drift check otherwise lives only in
an untracked `.git/hooks/pre-commit`, so fork PRs and fresh clones are unprotected until CI
re-runs it. The PR title is passed to the validator via an `env:` var, never interpolated into
the shell, so an untrusted title can't inject commands. Squash-merge makes the PR title the
landed commit, so linting the title (not every intermediate commit) is the high-value gate.
