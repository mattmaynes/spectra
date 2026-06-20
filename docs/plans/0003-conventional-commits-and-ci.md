# 0003 — Conventional commits & CI (plan)

Source spec: [`specs/0003-conventional-commits-and-ci.md`](../specs/0003-conventional-commits-and-ci.md)

Built in worktree `.worktrees/conventional-commits-ci` on branch `conventional-commits-ci`,
based on `token-count-and-branding` (which carries `test.sh` + `scripts/token-report.sh`;
`main` does not). PR targets `token-count-and-branding`.

## Steps

1. **Validator** — `scripts/check-commit-msg.sh`
   - POSIX `sh`, `set -eu`. Arg 1 = message (or first line of it); reject empty.
   - Grammar: `^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]+\))?!?: .+`
     (matched against the first line only, via `grep -Eq`).
   - On failure: print the offending subject + a one-line example, exit 1. On success: silent, exit 0.
   - Mirrors `token-report.sh` conventions (header comment marking it repo-local tooling, `--help`/usage).

2. **CI** — `.github/workflows/ci.yml`
   - `name: CI`; triggers: `push` and `pull_request`.
   - `permissions: contents: read` (least privilege).
   - Job `test`: `runs-on: ubuntu-latest`; `actions/checkout@v4`; step `./test.sh`.
     (test.sh step 8 already runs the token check, but see job `readme-drift` for an explicit gate.)
   - Job `readme-drift`: checkout; step `scripts/token-report.sh --check` — the same guard the
     local pre-commit hook applies, made explicit and independent of `test.sh`.
   - Job `commit-lint` (`if: github.event_name == 'pull_request'`): checkout; run
     `scripts/check-commit-msg.sh "$TITLE"` with `TITLE` from
     `${{ github.event.pull_request.title }}` passed via `env:` (avoid shell-injection of the title).

3. **Test coverage** — extend `test.sh`
   - New numbered step "conventional-commit validator": assert exit 0 for a set of valid
     messages (`feat: x`, `fix(scope): y`, `feat!: z`, `chore(deps): bump`) and non-zero for
     invalid ones (`nope`, `Add thing`, `feat x`, empty). Use `ok`/`bad` helpers.

4. **Docs / reflect**
   - `AGENTS.md`: add a short "Commits & PR titles" section **after** `<!-- spectra:end -->`
     (repo-local; never shipped), pointing at `scripts/check-commit-msg.sh`.
   - `docs/overview/features.md`: add CI + conventional-commits capability.
   - `docs/overview/architecture.md`: note `.github/workflows/ci.yml` and the validator under
     repo-local tooling; explain CI re-enforces the token guard for fork PRs.
   - `docs/overview/learnings.md`: enforce shared standards in CI (not just an untracked local
     hook); keep the checker dependency-free and dogfoodable.

5. **Verify, commit, PR**
   - Run `./test.sh` → `PASS`. Manually spot-check the validator both ways.
   - Validate YAML parses (`python3 -c yaml.safe_load`).
   - Commit with a conventional message (`feat: add CI workflow and conventional-commit
     checks`). Push, open PR (conventional title) targeting `token-count-and-branding`.
   - Scoped persona review: **engineer** (shell/YAML logic), **security** (workflow perms,
     untrusted PR-title handling, scripts run in CI), **architect** (new CI surface, repo-local
     boundary). Skip **tester** as a separate pass — behavior is covered by the new `test.sh` case.

## Verification checklist (from spec acceptance)
- [ ] workflow runs on push + PR; `test` runs `./test.sh`; `readme-drift` runs `--check`.
- [ ] validator: `feat: x` → 0, `nope` → non-zero; CI fails non-conventional PR title.
- [ ] `test.sh` includes the validator case and ends `PASS`.
- [ ] `AGENTS.md` documents the rule outside the spectra block.
- [ ] nothing under `spectra/` changed.
- [ ] `docs/overview/` updated.
