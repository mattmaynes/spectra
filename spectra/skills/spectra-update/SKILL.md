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

2. **Refresh the hook** — re-copy into the resolved hooks dir (refresh the sidecar if the
   developer chained Spectra onto a pre-existing hook):
   ```sh
   HOOKS="$(git rev-parse --git-path hooks)"
   if [ -e "$HOOKS/spectra-pre-commit" ]; then
     cp "$SRC/hooks/pre-commit" "$HOOKS/spectra-pre-commit"    # chained install
   else
     cp "$SRC/hooks/pre-commit" "$HOOKS/pre-commit"; chmod +x "$HOOKS/pre-commit"
   fi
   ```

3. **Refresh the host block** — in `AGENTS.md` (or `CLAUDE.md`), replace the existing block
   **from `<!-- spectra:start -->` through `<!-- spectra:end -->` inclusive** with the
   contents of `$SRC/agents.md` (which carries its own markers). If no markers are present,
   append the block. Never duplicate the markers.

4. **Report** what changed (a short diff summary) and remind the developer that their
   specs/plans/feedback/overview were preserved.
