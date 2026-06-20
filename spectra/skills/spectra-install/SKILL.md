---
name: spectra-install
description: Install the Spectra spec-driven development protocol into the current repo — scaffolds docs/, copies the protocol + personas, installs the reflection hook, and wires up AGENTS.md. Use when a repo wants to adopt Spectra.
---

# Install Spectra

Set up the Spectra protocol in the **current repository**. Bundled source lives at
`${CLAUDE_SKILL_DIR}/../..` (call it `$SRC`). Run from the repo root.

If a previous install exists, prefer running `spectra-update` instead — it preserves work.

## Steps

1. **Scaffold dirs** (keep empties tracked):
   ```sh
   SRC="${CLAUDE_SKILL_DIR}/../.."   # bundled Spectra source
   mkdir -p docs/spectra/personas docs/specs docs/plans docs/feedback docs/overview docs/spectra/hooks
   for d in docs/specs docs/plans docs/feedback; do touch "$d/.gitkeep"; done
   ```

2. **Copy protocol + personas** (full copies — the consumer has no `$SRC` after install):
   ```sh
   cp "$SRC/protocol.md" docs/spectra/protocol.md
   cp "$SRC/personas/"*.md docs/spectra/personas/
   ```

3. **Seed overview living docs** — only if absent (never overwrite existing):
   create `docs/overview/{project,features,architecture,learnings}.md`, each a short stub
   (`# Project`, one line: "Describe the mission." etc.). These are filled in during Reflect.

4. **Install the reflection hook**:
   ```sh
   cp "$SRC/hooks/pre-commit" docs/spectra/hooks/pre-commit
   chmod +x docs/spectra/hooks/pre-commit
   HOOKS="$(git rev-parse --git-path hooks)"
   ```
   - If `$HOOKS/pre-commit` does **not** exist → link it:
     `ln -sf ../../docs/spectra/hooks/pre-commit "$HOOKS/pre-commit"` (adjust the relative
     prefix if `core.hooksPath` is customized).
   - If it exists and already references spectra → leave it.
   - If it exists and is something else → **don't clobber**. Append a guarded call
     (`sh docs/spectra/hooks/pre-commit`) to the existing hook and tell the developer.

5. **Wire up the host file** — pick `AGENTS.md` if present, else `CLAUDE.md` if present,
   else create `AGENTS.md`. Insert the block from `$SRC/agents.md`:
   - If the file already contains `<!-- spectra:start -->` … `<!-- spectra:end -->`,
     replace everything between (and including) the markers with `$SRC/agents.md`.
   - Otherwise append `$SRC/agents.md` to the end.
   - If you created `AGENTS.md`, also symlink `CLAUDE.md` and `GEMINI.md` → `AGENTS.md`
     (`ln -sf AGENTS.md CLAUDE.md`) unless those files already exist. Codex reads
     `AGENTS.md` natively.

6. **Confirm**: list the created tree and tell the developer Spectra is installed — the next
   change should follow `docs/spectra/protocol.md`.
