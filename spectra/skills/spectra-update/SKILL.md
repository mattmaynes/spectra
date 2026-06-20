---
name: spectra-update
description: Update the Spectra protocol files in the current repo to the installed plugin version — refreshes protocol.md, personas, the AGENTS.md block, and the reflection hook, without touching your specs/plans/feedback/overview. Use after updating the spectra plugin.
---

# Update Spectra

Re-sync Spectra's **distributed** files in the current repo from the bundled source at
`${CLAUDE_SKILL_DIR}/../..` (`$SRC`). This is idempotent and **never** touches the
developer's own content: `docs/specs/`, `docs/plans/`, `docs/feedback/`, and
`docs/overview/` are left as-is.

If Spectra was never installed here, run `spectra-install` instead.

## Steps

1. **Refresh protocol + personas** (overwrite — these are Spectra-owned):
   ```sh
   SRC="${CLAUDE_SKILL_DIR}/../.."   # bundled Spectra source
   cp "$SRC/protocol.md" docs/spectra/protocol.md
   mkdir -p docs/spectra/personas && cp "$SRC/personas/"*.md docs/spectra/personas/
   ```

2. **Refresh the hook**:
   ```sh
   cp "$SRC/hooks/pre-commit" docs/spectra/hooks/pre-commit
   chmod +x docs/spectra/hooks/pre-commit
   ```
   Re-link `$(git rev-parse --git-path hooks)/pre-commit` only if it's missing.

3. **Refresh the host block** — in `AGENTS.md` (or `CLAUDE.md`), replace everything between
   `<!-- spectra:start -->` and `<!-- spectra:end -->` with `$SRC/agents.md`. If the markers
   are missing, append the block. Do not duplicate it.

4. **Report** what changed (a short diff summary) and remind the developer that their
   specs/plans/feedback/overview were preserved.
