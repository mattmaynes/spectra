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

**Persona activation — a config allowlist.** All personas ship as files in `spectra/personas/`
(the four core engineer/tester/architect/security plus the optional designer/compliance/analytics
and the shared `persona.md` contract). What's *active* is governed by
`docs/spectra/personas.config` — a developer-owned newline list of enabled slugs. A persona
participates in reviews iff its slug is listed; its file always exists, so the file's presence is
not the switch. The config is **seeded only if absent** by `spectra-install` (default: the four
core) and **never overwritten** by `spectra-update`, so it survives updates like
`specs/overview/user.md`. `spectra-enable`/`spectra-disable` add/remove a slug — including a core
one, so a repo can drop `security` and have it stick. A disabled persona's checklist never loads
into a review (it isn't scoped in), so it costs ~nothing; the always-loaded protocol names the
four core triggers plus one generic line for "other enabled personas", so the cost stays flat as
the optional set grows. The 👤 User (ICP) persona is the one **file-presence** exception:
`spectra-setup` writes `user.md` (create-on-demand, never shipped) and the protocol scopes it in
when that file exists, independent of the config.

**Update is additive; the config is the only state it won't touch.** `spectra-update` copies
*all* shipped persona files (`cp "$SRC/personas/"*.md`), so new and updated personas always
arrive, but it leaves `personas.config` alone. Separating the **files** (Spectra-owned, always
refreshed) from the **enabled set** (developer-owned, in the config) is what lets update stay a
plain additive copy while a `/spectra-disable` still persists — the two concerns that were in
tension under a file-presence model are decoupled.

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
