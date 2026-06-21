---
name: spectra-install
description: Install the Spectra spec-driven development protocol into the current repo — scaffolds docs/, copies the protocol + personas, installs the reflection hook, and wires up AGENTS.md. Use when a repo wants to adopt Spectra.
---

# Install Spectra

Set up the Spectra protocol in the **current repository**. `$SRC` is this plugin's root — the
directory holding `protocol.md`, `personas/`, `agents.md`, and `hooks/` (the parent of this
skill's `skills/` dir). Resolve it from your skill's own location; in Claude Code that's
`${CLAUDE_SKILL_DIR}/../..`, and other agents expose the path their own way. Run from the repo root.

If a previous install exists, prefer running `spectra-update` instead — it preserves work.

## Steps

1. **Scaffold dirs** (keep empties tracked):
   ```sh
   SRC="${CLAUDE_SKILL_DIR}/../.."   # Claude Code; on other agents set $SRC to the plugin root (above)
   mkdir -p docs/spectra/personas docs/specs docs/plans docs/feedback docs/overview
   for d in docs/specs docs/plans docs/feedback; do touch "$d/.gitkeep"; done
   ```

2. **Copy protocol + personas, seed the enabled-persona config** (full copies — the consumer
   has no `$SRC` after install):
   ```sh
   cp "$SRC/protocol.md" docs/spectra/protocol.md
   cp "$SRC/personas/"*.md docs/spectra/personas/
   [ -f docs/spectra/personas.config ] || cp "$SRC/personas.config" docs/spectra/personas.config
   ```
   All persona files are copied, but only the slugs in `personas.config` (default: the four
   core personas) are *active*; the rest are available to turn on with `/spectra-enable`. The
   config is **seeded only if absent** so a re-install never resets the developer's choices.

3. **Seed overview living docs** — only if absent (never overwrite existing):
   create `docs/overview/{project,features,architecture,learnings}.md`, each a short stub
   (`# Project`, one line: "Describe the mission." etc.). These are filled in during Reflect.

4. **Install the reflection hook** — **copy** it into the repo's resolved hooks dir (not a
   symlink to a tracked file: copying keeps updates explicit and reviewable, and the
   resolved path works with `core.hooksPath` and worktrees):
   ```sh
   HOOKS="$(git rev-parse --git-path hooks)"; mkdir -p "$HOOKS"
   if [ ! -e "$HOOKS/pre-commit" ]; then
     cp "$SRC/hooks/pre-commit" "$HOOKS/pre-commit"            # no existing hook
   elif ! grep -q spectra "$HOOKS/pre-commit"; then           # existing hook → don't clobber
     cp "$SRC/hooks/pre-commit" "$HOOKS/spectra-pre-commit"
     printf '\n[ -x "%s/spectra-pre-commit" ] && "%s/spectra-pre-commit"\n' "$HOOKS" "$HOOKS" \
       >> "$HOOKS/pre-commit"                                  # chain a guarded call
   fi
   chmod +x "$HOOKS/pre-commit"
   ```
   Tell the developer if you chained onto a pre-existing hook.

5. **Wire up the host file** — pick `AGENTS.md` if present, else `CLAUDE.md` if present,
   else create `AGENTS.md`. Insert the block from `$SRC/agents.md`:
   - If the file already contains `<!-- spectra:start -->` … `<!-- spectra:end -->`,
     replace everything between (and including) the markers with `$SRC/agents.md`.
   - Otherwise append `$SRC/agents.md` to the end.
   - If you created `AGENTS.md`, also symlink `CLAUDE.md` and `GEMINI.md` → `AGENTS.md`
     (`ln -sf AGENTS.md CLAUDE.md`) unless those files already exist. **Codex and Cursor read
     `AGENTS.md` natively** (no extra file needed); the symlinks cover Claude and Gemini.

6. **Confirm**: list the created tree and tell the developer Spectra is installed — the next
   change should follow `docs/spectra/protocol.md`. Optionally, they can run `/spectra-setup`
   to add a 👤 User (ICP) persona that reviews user-facing changes on their customer's behalf,
   or `/spectra-enable` to turn on extra review personas (designer, compliance, analytics).
