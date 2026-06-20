# 0004 — Build plan: dynamic `user` (ICP) persona & `spectra-setup`

Source spec: `docs/specs/0004-user-persona-and-setup.md`. Built on branch
`user-persona-and-setup`. All paths below are repo-relative.

## Steps

1. **New skill — `spectra/skills/spectra-setup/SKILL.md`.**
   YAML frontmatter (`name: spectra-setup`, trigger-rich `description`). Body:
   - Resolve nothing from `$SRC` (this skill writes the consumer's own file).
   - Step "Refine or start": if `docs/spectra/personas/user.md` exists, read it, play it back,
     frame as refinement; else fresh.
   - Step "Describe": ask the developer for an initial ICP description.
   - Step "Clarify": one focused round of clarifying questions covering who / goals (JTBD) /
     pain points / technical level / values / would-reject.
   - Step "Write": create `docs/spectra/personas/user.md` from the embedded canonical
     structure — `# 👤 User (ICP)`, a `See \`persona.md\`…` line, a **Profile** section (the six
     fields), and a **Review** checklist derived from the profile.
   - Step "Confirm": tell the developer the persona is now active in reviews.
   - Embed the `user.md` template inside the SKILL (fenced block), self-contained like the
     other skills — no sibling files.

2. **Protocol — `spectra/protocol.md`.** In §5.4 (Review scoping list) add a fifth bullet:
   `**user** — user-facing behavior or experience, **only when \`docs/spectra/personas/user.md\`
   exists** (a developer ran \`spectra-setup\`)`. Keep the "don't run all by reflex" framing.

3. **Update skill — `spectra/skills/spectra-update/SKILL.md`.** In the intro sentence about
   preserved content, add `docs/spectra/personas/user.md` to the developer-owned list, and add a
   one-line note in step 1 that the persona copy is shipped-personas-only, so a configured
   `user.md` is never clobbered.

4. **Install skill — `spectra/skills/spectra-install/SKILL.md`.** In the final "Confirm" step,
   add a pointer: optionally run `/spectra-setup` to add a 👤 User (ICP) persona. Do **not**
   create `user.md` during install.

5. **Manifest — `spectra/.claude-plugin/plugin.json`.** Append `/spectra-setup` to the
   `description` ("Adds /spectra-install, /spectra-update, and /spectra-setup.").

6. **Tests — `test.sh`.**
   - In step 2 area (or a small dedicated check): assert `spectra/personas/user.md` does **not**
     exist — create-on-demand invariant.
   - In step 5 (update preserves content): also write `docs/spectra/personas/user.md` with
     custom bytes before the `cp "$SRC/personas/"*.md` step, and assert it is unchanged after.

7. **Regenerate README token block.** Run `scripts/token-report.sh --write` (new skill grows the
   "Everything" figure). Repo-local only; nothing shipped changes numerically except file count.

8. **Reflect — `docs/overview/`.**
   - `features.md` — add the `spectra-setup` skill and the dynamic 👤 User (ICP) persona; note
     reviews now have an optional fifth, consumer-defined persona.
   - `architecture.md` — record the create-on-demand pattern: a *developer-owned* persona that
     lives only in the instance, never shipped, so update can't touch it.
   - `learnings.md` — the design lesson: "make 'don't overwrite' structural, not procedural" —
     by never shipping the file, preservation is automatic; the doc + test only guard drift.

## Verification
- `./test.sh` ends `PASS` (incl. new user.md-absent and update-preserves cases).
- `scripts/token-report.sh --check` passes (README regenerated).
- `spectra/personas/` has no `user.md`; the four shipped personas are unchanged.
- `spectra-setup/SKILL.md` has valid frontmatter (step 2 of the suite).
- Manual read-through: protocol lists `user` 👤 gated on file existence; update + install docs
  reference `user.md` / `spectra-setup` correctly.

## Review scoping (for the PR)
- **architect** 📐 — adds a persona class + create-on-demand boundary; touches protocol structure.
- **engineer** 🔧 — skill logic, test.sh edits, doc correctness.
- **security** 🔒 — the new skill writes a file from a dialog into the repo; sanity-check no unsafe
  shell, no path traversal, no clobbering of developer content.
- **tester** 🧪 — new test cases prove the invariants (absent-by-default, preserved-on-update).
