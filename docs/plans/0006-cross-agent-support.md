# 0006 — Cross-agent support: build plan

Source: spec `docs/specs/0006-cross-agent-support.md`. Delivered as **two PRs** (developer's
call). Both follow the protocol: worktree → test before commit → PR → persona review → merge →
reflect.

## Design recap (the load-bearing facts)

- All four tools share the **`SKILL.md` skill** primitive *except Gemini*, which uses **TOML
  commands**. All four read **`AGENTS.md`** (Claude/Gemini via symlink, Codex/Cursor natively).
- Every tool's plugin/extension **root is `spectra/`**, so `skills/`, `protocol.md`, and
  `personas/` are shared by every manifest with **zero copies**. New per-tool files are only
  *manifests* (and Gemini's thin TOML wrappers).
- Repo-root marketplaces mirror the existing Claude pattern (`.claude-plugin/marketplace.json`
  at root + `spectra/.claude-plugin/plugin.json`):

  | Tool | Marketplace (repo root) | Plugin/ext manifest (in `spectra/`) | Command files |
  |---|---|---|---|
  | Claude (today) | `.claude-plugin/marketplace.json` | `.claude-plugin/plugin.json` | `skills/*/SKILL.md` |
  | Codex | `.agents/plugins/marketplace.json` | `.codex-plugin/plugin.json` | shared `skills/*/SKILL.md` |
  | Cursor | `.cursor-plugin/marketplace.json` | `.cursor-plugin/plugin.json` | shared `skills/*/SKILL.md` |
  | Gemini | — (`gemini extensions link/install`) | `gemini-extension.json` | `commands/*.toml` (inject shared body) |

---

## PR 1 — `feat/cross-agent-codex-cursor`: neutralize bodies + Codex + Cursor

The high-leverage PR: once the bodies are tool-neutral, Codex and Cursor reuse the **exact same
`SKILL.md` files** — they need only manifests.

1. **Neutralize the source path in the two skills that use it** (`spectra-install`,
   `spectra-update`). Replace `${CLAUDE_SKILL_DIR}/../..` with a tool-agnostic instruction: *"`$SRC`
   is this plugin's root — the directory containing `protocol.md`, `personas/`, `agents.md`,
   `hooks/` (the parent of this skill's `skills/` dir). Resolve it from your skill's location; in
   Claude Code that is `${CLAUDE_SKILL_DIR}/../..`."* The agent does the resolution per its own
   tool, so one body works everywhere; Claude keeps a concrete hint. Drop `/plugin`-specific
   phrasing where it implies Claude-only. `setup`/`enable`/`disable` need no change.
2. **Codex manifests:**
   - `spectra/.codex-plugin/plugin.json` — `{name, version, description, "skills": "./skills/"}`.
   - `.agents/plugins/marketplace.json` (repo root) — `{name, plugins:[{name, source:"./spectra",
     description}]}`.
3. **Cursor manifests:**
   - `spectra/.cursor-plugin/plugin.json` — `{name, version, description, "skills": "./skills/"}`.
   - `.cursor-plugin/marketplace.json` (repo root) — `{plugins:[{name, source:"./spectra",
     description}]}`.
4. **Install/update host wiring** — `AGENTS.md` stays canonical. Add a one-line note that **Codex
   and Cursor read `AGENTS.md` natively** (no extra file written); keep the `CLAUDE.md`/`GEMINI.md`
   symlinks. No `.cursor/rules/*.mdc` (decided).
5. **README** — new "Install (per tool)" section: Claude (today), Codex (`codex plugin marketplace
   add mattmaynes/spectra`), Cursor (`/add-plugin` or marketplace). Note the protocol/personas are
   identical across tools.
6. **`test.sh`** — extend step 1 ("manifests parse"):
   - `.agents/plugins/marketplace.json`, `.cursor-plugin/marketplace.json`,
     `spectra/.codex-plugin/plugin.json`, `spectra/.cursor-plugin/plugin.json` parse as JSON.
   - each marketplace `source` resolves to a dir containing its tool's plugin manifest.
   - each plugin manifest's `skills` path resolves to `spectra/skills/` (the shared tree).
   - assert the neutralized bodies carry **no** `CLAUDE_SKILL_DIR` literal outside an explicit
     "in Claude Code …" example line, and still define `$SRC` (guards a regression that drops
     source resolution).
7. **CI** — `.github/workflows/ci.yml`: the `test` job already runs `./test.sh`, so new manifest
   cases are covered; confirm no extra wiring needed.
8. **Reflect** — `docs/overview/architecture.md` (multi-manifest-over-one-tree, the four-tool
   table, tool-neutral `$SRC`), `features.md` (Spectra installs from four agents), `learnings.md`
   (the convergence + "the deprecated path we almost shipped"). Regenerate README token block
   (`scripts/token-report.sh --write`) — the new manifests/README rows shift counts.

**Verify before commit:** `./test.sh` green; `scripts/token-report.sh --check`;
`scripts/check-commit-msg.sh` on the intended PR title. Manually eyeball each JSON manifest.

**Review personas (scope):** engineer (manifest correctness, `$SRC` resolution), architect
(the one-tree/many-manifests boundary), security (consumer-run install + new manifests + JSON
parsed in `test.sh`), tester (the new `test.sh` cases). Designer/compliance/analytics/user:
n/a (no UI, no PII, no tracking, internal tooling).

---

## PR 2 — `feat/cross-agent-gemini` (branch from merged `main`)

1. **`spectra/gemini-extension.json`** — `{name:"spectra", version, description, contextFileName:
   "GEMINI.md"}`. (Extension root = `spectra/`; reuses the shared tree.)
2. **`spectra/commands/<name>.toml`** — five thin wrappers (`spectra-install`, `-update`,
   `-setup`, `-enable`, `-disable`). Each: `description = "<one-line>"` and
   `prompt = """\n@{skills/<name>/SKILL.md}\n"""` — runtime injection of the shared body (decided;
   no generator, no second copy).
3. **Gemini namespacing check** — confirm `commands/spectra-install.toml` → `/spectra-install`
   (flat, no subdir) so command names match the other tools.
4. **Install/update host wiring** — `GEMINI.md` symlink already handled; note Gemini can also set
   `context.fileName:["AGENTS.md","GEMINI.md"]` as an alternative. No body changes.
5. **README** — add Gemini install (`gemini extensions install https://github.com/mattmaynes/spectra`
   / `gemini extensions link .` for local dev).
6. **`test.sh`** — assert: `gemini-extension.json` parses; exactly the five `commands/*.toml`
   exist; each TOML has a `description` and a `prompt` that injects its matching
   `@{skills/<name>/SKILL.md}` (the body that actually exists). This is the drift guard that keeps
   the wrappers honest without a generator.
7. **Reflect** — `architecture.md` (Gemini = TOML wrapper injecting the shared body; the lone
   non-`SKILL.md` tool), `features.md` (now four tools incl. Gemini), `learnings.md` if anything
   surfaced. Regenerate token block.

**Verify before commit:** `./test.sh` green; token `--check`; commit-msg lint; eyeball each TOML.

**Review personas (scope):** engineer (TOML correctness + injection path), tester (the drift
guard), architect (the wrapper-vs-shared-body boundary). security: light (no new consumer-run
script; static manifest).

---

## Risks / watch-items

- **Tool-neutral `$SRC`** is the one behavioral change to existing Claude skills — the `test.sh`
  assertion (step 6) + a manual Claude `spectra-install` sanity check guard against breaking it.
- **Codex/Cursor manifest field names** (`skills` path form, marketplace `source`) are from
  June-2026 docs and may be version-sensitive — `test.sh` validates structure, not live install;
  note the doc source in `architecture.md` so a future drift is traceable.
- **Gemini `@{}` path resolution** relative to the extension root is the PR 2 assumption; if a
  real `gemini extensions link .` shows it doesn't resolve, fall back to the generator+drift-check
  named in the spec (kept out of scope unless needed).
