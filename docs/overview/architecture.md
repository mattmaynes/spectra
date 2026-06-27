# Architecture

Two halves, by design:

- **`spectra/`** - the **shippable source of truth** (the plugin). Contains the skills
  (`skills/spectra-install`, `skills/spectra-update`), the protocol (`protocol.md`), the host
  block (`agents.md`), the review `personas/` (a shared `persona.md` review contract plus one
  file per persona), and the `hooks/pre-commit`. This is what a consumer installs.
- **`docs/`** - this repo's **installed instance** (Spectra dogfooding itself): the artifact
  tree (`specs/`, `plans/`, `feedback/`, `overview/`). Its `docs/spectra/` entries are
  **symlinks** back to `spectra/` - a **dogfood-only DRY convenience that is never shipped**.
  A real consumer gets plain *copies* there (what `spectra-install` writes); the layout is
  identical in shape, only this repo substitutes symlinks because it owns the source.

**Install flow:** each agent installs the plugin through its own marketplace, then
`/spectra-install` runs the skill against the target repo (in Claude Code: `/plugin marketplace
add` + `/plugin install spectra@spectra`). The skill resolves its bundled source as `$SRC` - the
**plugin root** (`<plugin>/skills/<name>/` → `../..`), tool-neutrally: in Claude that's
`${CLAUDE_SKILL_DIR}/../..`, other agents expose the skill path their own way. Removing the
hardcoded Claude env var is what lets the *same* `SKILL.md` body run under every agent.

**Cross-agent packaging - one tree, many manifests.** Three of the four agents converged on the
same two primitives: a `SKILL.md` skill and a plugin/extension marketplace. Because every tool's
plugin root is `spectra/`, the `skills/`, `protocol.md`, and `personas/` are **shared with zero
copies** - each agent adds only a thin manifest: Claude `.claude-plugin/{marketplace,plugin}.json`;
Codex `.codex-plugin/plugin.json` + repo-root `.agents/plugins/marketplace.json`; Cursor
`.cursor-plugin/plugin.json` + repo-root `.cursor-plugin/marketplace.json`. The marketplaces sit
at the **repo root** (mirroring the existing Claude pattern), each with `source: ./spectra` -
except Codex *mandates* the nested `.agents/plugins/marketplace.json` path, so it can't be
normalized to the `<tool>-plugin/` shape the others use (don't "tidy" it). The plugin manifests'
`skills: ./skills/` all resolve to the one shared tree. `test.sh` asserts every
manifest parses and that its source/skills pointers resolve there, so a broken pointer fails CI.
Manifest field names track each tool's June-2026 docs (Claude/Codex/Cursor Skills; Codex's
deprecated `~/.codex/prompts/` is deliberately avoided).

**Gemini - the one outlier, still single-source.** Gemini CLI's stable command unit is a TOML
file, not a `SKILL.md`, so it can't reuse the skill files by symlink. Instead it ships a
`gemini-extension.json` over the same `spectra/` tree plus one **thin** `commands/<name>.toml`
per skill whose `prompt` is just `@{skills/<name>/SKILL.md}` - Gemini's runtime file-injection,
so the command body stays the single shared skill (no second copy, no generator). The manifest is
a **command channel only** - it sets no `contextFileName` and ships no `GEMINI.md`, because the
protocol context lands in the *consumer* repo via `/spectra-install`'s `GEMINI.md`→`AGENTS.md`
symlink, exactly like the other three agents. `@{}` resolves
relative to the extension root (`spectra/`); this is the one assumption to confirm against a live
`gemini extensions link .` (fallback if it doesn't hold: a generated TOML with a CI drift-check,
per spec 0006). `test.sh` enforces a 1:1 map - every skill has a wrapper injecting its own body,
every wrapper maps back to a real skill - so a rename can't orphan a stale `@{}` reference.

**Hook install:** `spectra-install` **copies** `hooks/pre-commit` into the repo's resolved
hooks dir (`git rev-parse --git-path hooks`) - not a symlink to a tracked file - so the hook
that runs on commit is explicit and only changes when `/spectra-update` re-copies it, and the
resolved path is correct under `core.hooksPath`/worktrees. An existing hook (Husky, lefthook,
pre-commit framework) is **never clobbered**: Spectra drops a `spectra-pre-commit` sidecar and
chains a guarded call.

**Command discovery:** skills are auto-discovered from `spectra/skills/<name>/SKILL.md` - the
folder name becomes the `/<name>` command; `plugin.json` carries no explicit skill list.

**Persona activation - a config allowlist.** All personas ship as files in `spectra/personas/`
(the four core engineer/tester/architect/security plus the optional designer/compliance/analytics
and the shared `persona.md` contract). What's *active* is governed by
`docs/spectra/personas.config` - a developer-owned newline list of enabled slugs. A persona
participates in reviews iff its slug is listed; its file always exists, so the file's presence is
not the switch. The config is **seeded only if absent** by `spectra-install` (default: the four
core) and **never overwritten** by `spectra-update`, so it survives updates like
`specs/overview` and the `user*.md` ICP personas. `spectra-persona-enable`/`spectra-persona-disable` add/remove a slug - including a core
one, so a repo can drop `security` and have it stick. A disabled persona's checklist never loads
into a review (it isn't scoped in), so it costs ~nothing; the always-loaded protocol names the
four core triggers plus one generic line for "other enabled personas", so the cost stays flat as
the optional set grows. The 👤 User (ICP) personas are the **file-presence** exception: a repo can
define **many**, one file per customer profile (`user-<slug>.md`, plus a legacy single `user.md`),
each created on demand by `spectra-add-user` (never shipped). They live outside `personas.config`
entirely - managed by their own CRUD commands (`spectra-add-user`/`-update-user`/`-remove-user`/
`-list-users`) - and the protocol scopes each one in per its **Applies when / Skip when** block:
every profile whose slice the change touches reviews, none if none match. Natural-language
applicability keeps scoping LLM-judged, with no globs/tags or new runtime.

**Update is additive; the config is the only state it won't touch.** `spectra-update` copies
*all* shipped persona files (`cp "$SRC/personas/"*.md`), so new and updated personas always
arrive, but it leaves `personas.config` alone. Separating the **files** (Spectra-owned, always
refreshed) from the **enabled set** (developer-owned, in the config) is what lets update stay a
plain additive copy while a `/spectra-persona-disable` still persists - the two concerns that were in
tension under a file-presence model are decoupled.

**Host files:** `AGENTS.md` is canonical; `CLAUDE.md` and `GEMINI.md` symlink to it; **Codex and
Cursor read `AGENTS.md` natively** (no extra file written). The Spectra block is delimited by
`<!-- spectra:start/end -->` markers so updates are idempotent.

**Repo-local tooling (never shipped):** `scripts/` and `assets/` are this repo's own
presentation/QA layer - explicitly *not* under `spectra/`, so `spectra-install`/`update`
never touch a consumer with them.
- `scripts/token-report.sh` is the single source of the README's token figures: it measures
  `spectra/` and rewrites a marker-delimited block (`<!-- spectra:tokens:start/end -->`),
  reusing the same idempotent-marker pattern as the host block. `--check` is wired into both
  `test.sh` (step 8) and this repo's `.git/hooks/pre-commit` (a *second*, blocking guard
  added beside the shipped non-blocking reflection reminder - gated on `spectra/` being
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

**Release automation (repo-local, never shipped):** `scripts/whats-new.sh` owns the README's
`<!-- spectra:whats-new:start/end -->` block exactly as `token-report.sh` owns the
`spectra:tokens` block - same dependency-free POSIX-sh + marker-rewrite pattern, so its headline
extraction is unit-tested by `test.sh` (section 10) rather than only exercised live.
`.github/workflows/whats-new.yml` is a thin wrapper: on `release: [published]` it runs the script
with the release event in `env:`. Because `main`'s ruleset forbids direct pushes, it can't commit
back the way an unprotected repo would; instead it opens a `chore/whats-new-<tag>` branch and
squash-merges its own PR (the ruleset sets 0 required approvals and no required status checks, so
a bot PR is immediately mergeable). The untrusted release body reaches the script only through
`env:` vars and is used purely as string data (and the headline is marker-stripped and
length-capped), mirroring the injection-safe PR-title handling in `ci.yml`. Token
(`contents: write` + `pull-requests: write`) is the minimum to push the branch and merge the PR.
The checkout action is pinned to a full commit SHA since the job carries write tokens.

**Versioning & release publishing (repo-local, never shipped):** the plugin version has one
source of truth - the root `VERSION` file - and the seven manifests (three repo-root
marketplaces, three `spectra/*plugin.json`, `spectra/gemini-extension.json`) are derivatives.
`scripts/bump-version.sh` (POSIX sh + `python3`, the `token-report.sh` dependency rationale)
keeps them identical: `X.Y.Z` rewrites all eight files via a *format-preserving surgical
substitution* of the single `"version"` token (never a JSON re-serialize that would reflow the
hand-formatted files), validating every manifest in memory and writing `VERSION` last so a guard
failure can't leave a half-bumped tree; `--check` is the inverse invariant and is wired into
`test.sh` (section 11), the guard that would have caught the two manifests stranded at `0.1.1`
(`feedback` #27). A fourth `ci.yml` job, `release`, closes the loop: push-only, `needs: [test,
readme-drift]`, and the *only* job elevated to `contents: write` (job-scoped; the workflow stays
read-only). It reads `VERSION` and, when no release for it exists yet (idempotent `gh release
view` guard), runs `gh release create "$VERSION" --target "$GITHUB_SHA"` - creating the
bare-semver tag at the merge commit in one call - with `--notes-file docs/releases/$VERSION.md`
when the author wrote one (so the headline stays human and feeds `whats-new.yml`), else
`--generate-notes`. So a single `VERSION` bump merged to `main` fans out to: tag -> Release ->
README "What's new". The manifest `version` is the real update signal each agent gates on; the
tag is the durable marker - both wired to the same `x.y.z`. Identity across the manifests is
`rogueoak` (owner/author), the personal name/email dropped post org-transfer.
