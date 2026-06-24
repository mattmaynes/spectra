# 0012 - Claude install missing `/reload-plugins` step

- **Symptom** - Following the README's Claude Code quick start, `/plugin install
  spectra@spectra` succeeds but `/spectra-install` isn't recognized in the same session: the
  newly installed plugin's commands aren't loaded yet, so the documented next step appears to
  do nothing.
- **Root cause** - In Claude Code a freshly installed plugin's slash commands only become
  available after `/reload-plugins` (or a restart). The README jumped straight from install to
  `/spectra-install`, omitting that reload - a Claude-harness step with no equivalent in the
  Codex/Gemini/Cursor flows, so it was easy to miss when authoring the shared install section.
- **Fix** - Add `/reload-plugins` between `/plugin install` and `/spectra-install` in the
  README's Claude Code block, with a one-line note on why. Released as `0.1.1`.
- **Learning** - Document the host's activation step, not just the package step. "Install"
  isn't done until the agent can see the new commands; an install walkthrough must include
  whatever the harness needs to load them.
