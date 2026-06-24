# 0005 - Build plan: optional advanced personas & enable/disable toggles

Source spec: `docs/specs/0005-advanced-personas-and-toggles.md`. Built on branch
`feat/advanced-personas`, based on `main` (#7/#8/#9 merged). All paths repo-relative.

> **Revised during review (PR #10).** The steps below describe the original "active = file
> present" / `personas/optional/` / refresh-only-present design. After the architect review it was
> replaced with a **config-allowlist** model: all personas ship flat in `spectra/personas/`, the
> enabled set lives in a developer-owned `spectra/personas.config` (seeded-if-absent, never
> overwritten), and `spectra-update` copies all persona files additively. See
> `docs/overview/architecture.md` and `feedback/0006` for the shipped mechanism.

Core mechanism (shipped): **active = slug listed in `docs/spectra/personas.config`.** All personas
ship flat in `spectra/personas/*.md`; the config (default = four core) is developer-owned. Enable =
add a slug; disable = remove a slug; `spectra-update` copies all persona files but never touches
the config. Core personas are toggleable too.

## Steps

1. **New persona files - `spectra/personas/optional/{designer,compliance,analytics}.md`.**
   Same shape as the shipped four: a `# <emoji> <Name>` title, a `See \`persona.md\` for how to
   review and comment.` line, a one-line "Review whether…" framing, then a tight `Check:` /
   bullet checklist. Keep each lean (comparable to the core persona files).
   - **`designer.md` - 🎨 Designer.** Visual consistency: consistent element sizing (buttons,
     inputs, controls); consistent spacing / margins / padding; **design tokens over ad-hoc
     custom styles**; minimal end-user confusion (no competing/duplicate CTAs, no misleading or
     ambiguous button/link text); responsive/empty/loading states look intentional.
   - **`compliance.md` - ⚖️ Compliance.** Accessibility standards (labels, contrast, keyboard,
     ARIA/semantics); **PII minimization** (collect only what's needed, justify each field);
     i18n coverage - when the repo has i18n, all user-facing strings are translated/externalized,
     none hardcoded; GDPR/CCPA obligations (consent, retention, deletion/export, lawful basis).
   - **`analytics.md` - 📊 Analytics.** Tracking coverage - events on meaningful interactions
     (clicks, inputs, submits, key state changes); every complex/multi-step action has a
     **measurable outcome** (start→success/failure); when feature gates/flags are used, success
     is measurable per variant (consistent event names/properties, no silent gaps).

2. **New skill - `spectra/skills/spectra-enable/SKILL.md`.** Terse. Frontmatter
   (`name: spectra-enable`, trigger-rich `description`: enable/turn on a review persona, list
   available personas). Body, kept minimal:
   - Resolve `SRC="${CLAUDE_SKILL_DIR}/../.."`. Catalog of toggleable personas =
     `$SRC/personas/*.md` (excluding `persona.md`) + `$SRC/personas/optional/*.md`.
     **Enable candidates** = catalog entries whose file is **not** present in
     `docs/spectra/personas/`.
   - **With an argument** `<persona>`: resolve `<persona>.md` from `$SRC/personas/<p>.md` then
     `$SRC/personas/optional/<p>.md`; `mkdir -p docs/spectra/personas && cp` it in. Reject
     `persona` (the shared contract) and any name not in the catalog.
   - **No argument**: print the enable candidates as a **numbered list** (name + the persona's
     one-line purpose, read from its title line), and act on the developer's reply (a number, or
     several / "all").
   - Confirm the active set after.

3. **New skill - `spectra/skills/spectra-disable/SKILL.md`.** Mirror of step 2, terse.
   - **Disable candidates** = personas **present** in `docs/spectra/personas/`, excluding
     `persona.md` (shared contract) and `user.md` (developer-owned - managed by `spectra-setup`,
     never auto-deleted here).
   - With an arg: `rm -f docs/spectra/personas/<p>.md` if it's a disable candidate.
   - No arg: numbered list of present toggleable personas; act on the reply. Confirm.
   - Note in body: disabling a **core** persona is allowed and persists across `spectra-update`
     (update refreshes only present files).

4. **Update skill - `spectra/skills/spectra-update/SKILL.md` (step 1).** Replace the
   `cp "$SRC/personas/"*.md` line with the **refresh-only-present** loop:
   ```sh
   cp "$SRC/protocol.md" docs/spectra/protocol.md
   mkdir -p docs/spectra/personas
   for f in docs/spectra/personas/*.md; do
     b=$(basename "$f")
     for cand in "$SRC/personas/$b" "$SRC/personas/optional/$b"; do
       [ -f "$cand" ] && cp "$cand" "$f" && break
     done
   done
   ```
   Replace the "shipped-personas-only" note with the unified rule: update **refreshes only the
   personas already present** - so disabled personas stay disabled, enabled optional ones refresh
   from `optional/`, and `user.md` (no source) is preserved. Also update the intro preserved-list
   line if needed (the `user.md` clause still holds).

5. **Protocol - `spectra/protocol.md` §5.4.** After the `user` bullet, add **one** generic
   sentence so reviewers also scope in present non-core personas, without enumerating them
   (keeps the always-loaded protocol size flat):
   > Also scope in any **other** persona present in `docs/spectra/personas/` whose facet the
   > change touches - read its title/intro to decide. (Enable/disable via `/spectra-enable`,
   > `/spectra-disable`.)

6. **Install skill - `spectra/skills/spectra-install/SKILL.md` (Confirm step).** Add a pointer
   alongside the existing `/spectra-setup` line: optionally `/spectra-enable` to turn on extra
   review personas (designer, compliance, analytics). Install still copies only the core (the
   top-level glob already skips `optional/`).

7. **Manifest - `spectra/.claude-plugin/plugin.json`.** Extend `description`:
   "Adds /spectra-install, /spectra-update, /spectra-setup, /spectra-enable, and
   /spectra-disable."

8. **Token report - `scripts/token-report.sh` (repo-local).** Stop the optional personas from
   inflating the "core" row:
   - `core_files()` → top-level personas only: `find "$SRC/personas" -maxdepth 1 -name '*.md'`
     (so the "Full protocol + core personas" row is unchanged by optional personas).
   - Add `optional_files()` = `find "$SRC/personas/optional" -name '*.md' | sort` and a new
     `row 'Optional personas (load only when enabled)'` so the README is honest that they ship
     but don't load by default.
   - `all_files()` stays recursive ("Everything" legitimately includes optional personas + the
     two new skills).

9. **Regenerate README token block.** `scripts/token-report.sh --write` (core row should be
   unchanged; new optional row appears; "Everything" grows by optional personas + 2 skills).

10. **Tests - `test.sh`.**
    - **Optional personas ship but aren't installable by the core glob:** assert each of
      `personas/optional/{designer,compliance,analytics}.md` exists, and that **no** same-named
      file exists at top-level `$SRC/personas/` (so `cp "$SRC/personas/"*.md` can't reach them).
    - **Persona shape:** each `personas/optional/*.md` has a `# ` title and references
      `persona.md` (same drift guard used for the core/setup templates).
    - **Refresh-only-present (rewrite step 5 update test):** seed an instance with `persona.md`
      + a stale `engineer.md` (present core), a stale `designer.md` (enabled optional), and
      `user.md='MY ICP'`; **omit** `security.md` (disabled core). Run the new loop. Assert:
      `engineer.md`/`designer.md` now equal their sources, `user.md` unchanged, `security.md`
      still absent (disabled stays disabled).
    - Frontmatter for the two new skills is covered by the existing step-2 `skills/*/SKILL.md`
      loop. Update any count/sanity assertions if present.

11. **Reflect - `docs/overview/`.**
    - `features.md` - add the three optional personas (off by default, enabled on demand) and the
      `/spectra-enable` `/spectra-disable` skills; note any persona (incl. core) is toggleable.
    - `architecture.md` - record the unified rule: **active = persona file present**; shipped
      default set = `personas/*.md`, optional = `personas/optional/*.md`; update refreshes only
      present files (supersedes the `0004` glob note); the protocol scopes present personas
      generically so optional ones cost zero tokens when absent.
    - `learnings.md` - the lesson: making the *active set* a property of file presence + a
      refresh-only-present update means new optional perspectives cost nothing until enabled and
      need no central registry; the token-report `core` row had to be scoped to top-level so the
      "off = free" claim stays measurable.

## Verification
- `./test.sh` ends `PASS` (new optional-not-top-level, persona-shape, refresh-only-present cases).
- `scripts/token-report.sh --check` passes; the "Full protocol + core personas" row is unchanged
  from main; a new "Optional personas" row is present.
- Manual: `spectra/personas/optional/` has the three files; `cp "$SRC/personas/"*.md` (install)
  copies only core + `persona.md`; the update loop refreshes only present files.
- Read-through of both new skills: terse, discover candidates from the source layout (no
  hardcoded persona list), refuse `persona`, leave `user.md` alone.

## Review scoping (for the PR)
- **architect** 📐 - generalizes the persona-activation model and changes update semantics
  (refresh-only-present); a new source-layout boundary (`personas/optional/`).
- **engineer** 🔧 - skill logic, the update loop, `token-report.sh` and `test.sh` edits, persona
  file correctness.
- **security** 🔒 - two new consumer-run skills that `cp`/`rm` files in the repo: check no path
  traversal from the persona argument, no unsafe shell, no deletion of developer-owned content
  (`user.md`).
- **tester** 🧪 - the new/rewritten test cases prove the invariants.
- (No `user` persona on this repo; not applicable.)

## Merge (ruleset - from #9)
`main`'s ruleset requires **all review threads resolved** + squash-only/linear history, so a
green CI run isn't sufficient. After persona review: address each finding, resolve every inline
thread (GraphQL `resolveReviewThread`), then squash-merge on developer approval. Capture every
major/blocker in `docs/feedback/` and roll into `learnings.md` before concluding.
