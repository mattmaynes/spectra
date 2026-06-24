# 0007 - Plan: Multiple User (ICP) personas & CRUD commands

Source: `docs/specs/0007-multiple-user-personas.md`.

## Steps

1. **Add the four CRUD skills** (`spectra/skills/`), each with valid frontmatter + a distinct
   trigger description, mirroring the existing skill shape:
   - `spectra-add-user/SKILL.md` - guided create; embeds the canonical template (named 👤 title,
     `Applies when`, `Skip when`, `Profile`, `Review`); writes `docs/spectra/personas/user-<slug>.md`;
     on existing slug → point at `/spectra-update-user`.
   - `spectra-update-user/SKILL.md` - list `user*.md`, select, read back, refine, rewrite; none → `/spectra-add-user`.
   - `spectra-remove-user/SKILL.md` - list, select, confirm, `rm`; none → say so.
   - `spectra-list-users/SKILL.md` - list each `user*.md` title + Applies-when one-liner.

2. **Add the four command wrappers** (`spectra/commands/*.toml`) - thin `@{skills/<name>/SKILL.md}`
   injectors, one per new skill. **Delete** `spectra/commands/spectra-setup.toml` and
   `spectra/skills/spectra-setup/`.

3. **Protocol** (`spectra/protocol.md`) - replace the single-`user.md` scoping clause with the
   multi-`user-*.md` rule (read each file's Applies-when/Skip-when; scope all touched, none if none).

4. **Cross-refs** - `spectra-install/SKILL.md` next-step pointer (`/spectra-setup` → `/spectra-add-user`);
   `spectra-update/SKILL.md` generalize `user.md` → `user*.md` (developer-owned, preserved);
   `spectra-persona-enable`/`disable` SKILLs swap `spectra-setup` mention for the new command set
   and the `user*.md` exclusion.

5. **Manifests** - drop `spectra-setup`, add the four commands in the description of
   `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`,
   `gemini-extension.json`. (Version bump to 1.0.0 happens at release, step 9.)

6. **README** - Skills table: replace the `/spectra-setup` row with the four commands; persona
   table ICP row references `/spectra-add-user`; fix any single-ICP prose. Then
   `scripts/token-report.sh --write`.

7. **Tests** (`test.sh`) - retarget setup template block to `spectra-add-user`; add `Applies when`
   / `Skip when` heading checks; keep "no `user*.md` ships" (broaden the existing `user.md` check
   to the `user-*.md` glob); extend the update test to drop two `user-*.md` and assert both survive.

8. **Verify** - run `./test.sh` until green (it covers manifests, skill frontmatter, the
   1:1 command↔skill map, update preservation, and token-figure sync).

9. **Reflect** - update `docs/overview/features.md` + `architecture.md` (the ICP model and command
   surface changed); add a learning only if real friction surfaced.

10. **PR → review → merge** - open PR with a conventional `feat!:` title; scope persona review
    (engineer, architect, tester, plus user 👤 - this changes the ICP mechanism); resolve threads;
    squash-merge.

11. **Release** - bump `version` to `1.0.0` across all manifests + the marketplace; tag/release
    `v1.0.0`.

## Verification
- `./test.sh` → `PASS`.
- Manual: confirm no `spectra-setup` references remain (`grep -rn spectra-setup`).
- Each new `*.toml` injects its own `@{skills/<name>/SKILL.md}` (enforced by test step 1).
