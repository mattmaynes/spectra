# 0006 - Cross-agent support (Codex, Gemini, Cursor)

Make Spectra installable and fully command-driven from **Claude Code, OpenAI Codex, Gemini
CLI, and Cursor** - without forking the protocol, the personas, or a single command's prose.
Decisions chosen with the developer up front: **full command parity** across the four tools,
delivered via **per-tool native packaging**, with everything common kept DRY (one source,
symlinks/manifests over copies).

> **Research finding that reshapes the design (June 2026).** The four tools have *converged*
> on the same two primitives - a `SKILL.md` skill and a plugin/extension marketplace - so the
> "manual copy for Codex/Cursor" we scoped earlier is obsolete; all four get real native
> packaging. Codex's custom prompts (`~/.codex/prompts/`) are **deprecated** in favour of
> Skills; Cursor added Skills (2.4) and a Plugin Marketplace (2.6); Gemini ships Extensions.
> Gemini is the only outlier - its stable command unit is **TOML**, not `SKILL.md`.

| Tool | Command unit | Manifest / marketplace | Reads `AGENTS.md`? |
|---|---|---|---|
| Claude (today) | `skills/<n>/SKILL.md` (`name`+`description`) | `.claude-plugin/{plugin,marketplace}.json` | via `CLAUDE.md` symlink |
| Codex | `skills/<n>/SKILL.md` - **identical format** | `.codex-plugin/plugin.json` + `.agents/plugins/marketplace.json` | **natively** |
| Cursor | `skills/<n>/SKILL.md` (2.4+) | `.cursor-plugin/{plugin,marketplace}.json` | **natively** |
| Gemini | `commands/<n>.toml` (`prompt`+`description`) | `gemini-extension.json` | via `GEMINI.md` symlink / `context.fileName` |

## Problem

Spectra ships only as a Claude Code plugin, and its five commands (`spectra-install`,
`spectra-update`, `spectra-setup`, `spectra-enable`, `spectra-disable`) are Claude skills that
resolve their bundled source through `${CLAUDE_SKILL_DIR}`. The **protocol and personas are
already portable** (plain Markdown; `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` wiring already exists),
so once installed a Codex/Gemini/Cursor agent already *follows* Spectra. The gap is the two
Claude-bound layers: **distribution** (only Claude understands the plugin marketplace) and the
**commands** (`SKILL.md` + `${CLAUDE_SKILL_DIR}` only run inside Claude Code). A Codex, Gemini,
or Cursor user can neither install Spectra nor invoke its commands.

## Outcome

- A user of **any** of the four tools installs Spectra through that tool's native channel and
  runs all five commands (names adapted to each tool's invocation).
- After install, the landed footprint - `docs/spectra/`, `docs/overview/`, the reflection
  hook, the `AGENTS.md` block - is **identical regardless of which tool installed it**;
  `AGENTS.md` is canonical and read by all four.
- Every command's instructions live in **exactly one file**. Per-tool packaging is thin
  manifests + symlinks over the shared `spectra/` tree - **no duplicated prose anywhere**.
- The existing Claude path is unchanged (backwards compatible).

## Scope

- **In:**
  - **Tool-neutral command bodies.** Keep `spectra/skills/<name>/SKILL.md` as the single source
    for each command; strip Claude-isms - replace `${CLAUDE_SKILL_DIR}/../..` with a `$SRC`
    resolved relative to the skill/plugin root in a tool-agnostic way, and drop `/plugin`
    phrasing. These same files are consumed verbatim by Claude **and** Codex **and** Cursor
    (identical `SKILL.md` format).
  - **Per-tool manifests over one shared tree** (every plugin root = `spectra/`, so `skills/`,
    `protocol.md`, `personas/` are shared with zero copies):
    - Codex - `spectra/.codex-plugin/plugin.json` (`"skills": "./skills/"`) +
      `.agents/plugins/marketplace.json`.
    - Cursor - `spectra/.cursor-plugin/plugin.json` + `.cursor-plugin/marketplace.json`.
    - Gemini - `spectra/gemini-extension.json` + `spectra/commands/<name>.toml`: one **thin**
      TOML per command whose `prompt` injects the shared body via Gemini's `@{skills/<name>/SKILL.md}`
      file-injection, so the prose stays single-source (no second copy to maintain).
    - Claude - unchanged.
  - **Host/context wiring** in `spectra-install`/`-update`: `AGENTS.md` canonical; `CLAUDE.md`
    and `GEMINI.md` symlink to it (today's idiom); Codex and Cursor read `AGENTS.md` natively
    (documented; no extra file).
  - **README** - a per-tool "install" section (four native channels) and a note that the
    protocol/personas are the same everywhere.
  - **`test.sh` + CI** - each new manifest parses and resolves to the shared `skills/` /
    `protocol.md` / `personas/`; each Gemini TOML references the canonical body for all five
    commands; existing skill-frontmatter and dogfood cases stay green.
  - **Dogfood** - this repo adds the three new manifests + the Gemini wrappers; the
    `docs/spectra/*` symlinks are untouched.
- **Out:**
  - Forking the **protocol or persona prose** per tool - it stays single and portable.
  - Relying on Gemini's extension `skills/` bundling - newer and version-dependent; we use the
    stable TOML path and may revisit.
  - **Argument-passing parity** - Cursor command-arg interpolation is undocumented and Codex
    skills/Gemini commands differ; `spectra-enable`/`-disable` already work argument-free (they
    list a menu and act on the reply), so we lean on that no-arg flow rather than per-tool arg
    syntax.
  - **Publishing** to the public Cursor marketplace / Gemini catalog (review + open-source
    submission) - this spec produces the packaging; publication is a follow-up.
  - Auto-detecting which tool a repo uses - install is invoked *from* the chosen tool.

## Approach

- **One primitive, four wrappers.** `SKILL.md` is the universal command body; Claude, Codex,
  and Cursor consume the same files directly, and Gemini's TOML injects the same body with
  `@{...}`. *Trade-off:* Gemini needs one thin TOML per command - accepted, because TOML is
  Gemini's documented, stable command path whereas its extension `skills/` support is newer.
- **DRY via a shared tree, not copies.** The generic source is `spectra/`; because every tool's
  plugin/extension root is `spectra/`, the `skills/`, `protocol.md`, and `personas/` are shared
  with no duplication. Symlinks are used only where a tool demands content at a *tool-specific
  path/name* (the `CLAUDE.md`/`GEMINI.md` → `AGENTS.md` pattern already in place); a thin
  generated wrapper is used only where a tool demands a *different format* (Gemini TOML).
- **Tool-neutral source resolution.** The one true Claude coupling in the bodies is
  `${CLAUDE_SKILL_DIR}`. Replace it with a `$SRC` derived from the skill's own location
  (`<plugin-root>/skills/<name>/` → `$SRC = ../..`), expressed without naming any tool. Exact
  mechanism is a plan-level detail.
- **Honest single-source for Gemini (decided).** Each TOML is a thin wrapper whose `prompt` is
  `@{skills/<name>/SKILL.md}` - runtime injection, so there is literally one body and no build
  step. If injection proves unreliable on the target Gemini version, the fallback is a repo-local
  generator with a CI **drift check** (mirroring `token-report.sh --check`), but `@{}` is the
  intended mechanism.
- **Cursor wiring (decided).** Rely on `AGENTS.md`, which Cursor reads natively - no
  `.cursor/rules/*.mdc` written into the consumer. Keeps the installed footprint tool-neutral.
- **Backwards compatible.** Nothing about the Claude install/update flow changes for existing
  users.

## Acceptance

- [ ] `spectra/skills/*/SKILL.md` carry **no** Claude-specific tokens (`CLAUDE_SKILL_DIR`,
      `/plugin`); `$SRC` resolves tool-neutrally; the Claude install/update flow still works.
- [ ] **Codex** - `.codex-plugin/plugin.json` + `.agents/plugins/marketplace.json` parse and
      resolve to the shared `skills/`; a Codex user can add the marketplace and run all five
      commands.
- [ ] **Cursor** - `.cursor-plugin/plugin.json` + `.cursor-plugin/marketplace.json` parse and
      resolve to the shared `skills/`; the five commands are invokable in Cursor.
- [ ] **Gemini** - `gemini-extension.json` + `commands/*.toml` are valid; each of the five TOMLs
      carries the canonical body (via `@{}` injection or a drift-checked copy); `gemini
      extensions link .` registers them.
- [ ] After install from **any** tool, `AGENTS.md` is canonical and read by all four (Claude/
      Gemini via symlink, Codex/Cursor natively); `docs/spectra/`, `docs/overview/`, and the hook
      are identical across tools.
- [ ] **README** documents native install for each of the four tools.
- [ ] **`test.sh`** gains cases for each manifest (parse + shared-tree resolution + Gemini
      body-sync) and stays green; CI extended to match.
- [ ] `docs/overview/{architecture,features,learnings}` updated (the single-source / multi-wrapper
      design, the four-tool convergence, and the lesson from it).
