# 0007 — Multiple User (ICP) personas & CRUD commands

## Problem
Spectra supports exactly **one** User (ICP) persona: a single `docs/spectra/personas/user.md`,
created by `/spectra-setup`, scoped into reviews of user-facing changes. But many products serve
**several distinct customer profiles** — e.g. self-serve SMB vs. enterprise buyer — and a change
often serves one slice while being irrelevant (or even wrong) for another. With a single ICP,
teams either flatten all their customers into one mushy profile or pick one and ignore the rest.
There's also no way for a profile to say *when* it should weigh in, so the lone persona is judged
on existence + a whole-file read rather than on whether the change touches *its* slice.

Separately, the single `/spectra-setup` command overloads create-and-refine into one verb and has
no way to add a second profile, edit a specific one, or remove one.

## Outcome
- A team can define **multiple** ICP personas, one file per profile:
  `docs/spectra/personas/user-<slug>.md` (e.g. `user-smb.md`, `user-enterprise.md`). A legacy
  single `user.md` remains valid and untouched.
- Each ICP declares, in natural language, **when it applies** and **when to skip** it. At review
  time the scoping agent reads those sections and scopes in **every** ICP whose slice the change
  touches; if none clearly apply, **no** user persona reviews (same "absent = not used" spirit as
  today, now per-profile).
- Each ICP carries a distinct name in its title (`👤 User (SMB)`), so inline PR comment tags
  disambiguate between profiles.
- The `/spectra-setup` command is **replaced** by a CRUD-shaped command set (breaking change —
  acceptable, no consumers yet):
  - `/spectra-add-user` — create a new ICP through a guided dialog.
  - `/spectra-update-user` — list ICPs, pick one, read it back, refine it.
  - `/spectra-remove-user` — list ICPs, pick one, delete it (after confirmation).
  - `/spectra-list-users` — list the defined ICPs and their applies-when summaries.
- `/spectra-update` still **never overwrites** any `user*.md`; the guarantee generalizes from the
  single file to the family.

## Scope
- **In:**
  - **New skills** (each self-contained, tool-neutral, mirroring existing skill shape):
    - `spectra/skills/spectra-add-user/SKILL.md` — dialog: name/slug → applies-when slices →
      profile → derive Review checklist → write `docs/spectra/personas/user-<slug>.md`. If the
      slug already exists, point at `/spectra-update-user`.
    - `spectra/skills/spectra-update-user/SKILL.md` — list `user*.md`, select one, summarize it
      back, continue the dialog, rewrite. If none exist, point at `/spectra-add-user`.
    - `spectra/skills/spectra-remove-user/SKILL.md` — list, select, confirm, delete. If none
      exist, say so.
    - `spectra/skills/spectra-list-users/SKILL.md` — list each `user*.md` with its title +
      Applies-when one-liner.
  - **New commands** (thin wrappers, one per skill): `spectra/commands/spectra-add-user.toml`,
    `spectra-update-user.toml`, `spectra-remove-user.toml`, `spectra-list-users.toml`.
  - **Canonical template** (embedded in `spectra-add-user`, reused by update): the existing
    `user.md` shape **plus** an `## Applies when` and `## Skip when` section, and a profile-named
    title `# 👤 User (<Name>)`.
  - **Protocol** — `spectra/protocol.md` Review scoping: replace the single-`user.md` line with
    "for each `docs/spectra/personas/user-*.md` (and a lone `user.md`), read its Applies-when /
    Skip-when; scope in every ICP whose slice the change touches; none if none apply."
  - **Update guarantee** — `spectra/skills/spectra-update/SKILL.md`: generalize the
    developer-owned line from `personas/user.md` to `personas/user*.md`.
  - **Cross-refs** — `spectra-install/SKILL.md` (next-step pointer → `/spectra-add-user`),
    `spectra-persona-enable/SKILL.md` & `spectra-persona-disable/SKILL.md` (replace `spectra-setup`
    mentions with the new command names / the `user*.md` exclusion).
  - **Manifests** — `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`,
    `.cursor-plugin/plugin.json`, `gemini-extension.json`, and the root
    `.claude-plugin/marketplace.json` description: drop `spectra-setup`, add the four new
    commands. Bump `version` to `1.0.0` in all manifests at release.
  - **README** — Skills table (replace the `/spectra-setup` row with the four commands), persona
    table ICP row (`/spectra-add-user` instead of `/spectra-setup`), and any prose mentioning a
    single ICP. Regenerate the token block (`scripts/token-report.sh --write`).
  - **Tests** — `test.sh`: retarget the `spectra-setup` template assertions to `spectra-add-user`;
    assert the template now includes `Applies when` / `Skip when`; assert no `user*.md` ships in
    `spectra/personas/`; extend the update-preservation test to cover multiple
    `docs/spectra/personas/user-*.md` files surviving the copy steps.
  - **Reflect** — `docs/overview/` (features, architecture; learnings if any friction).
- **Out:**
  - Migrating/renaming an existing `user.md` to a slug — it stays as-is (zero forced churn);
    `/spectra-add-user` simply adds alongside it.
  - Structured/declarative triggers (path globs, frontmatter tags) — applies-when stays natural
    language, consistent with today's LLM-judged scoping. No new runtime.
  - Bringing ICPs into `personas.config` toggling — presence + applies-when govern scoping
    (delete via `/spectra-remove-user` to turn one off).
  - Changing *how* reviews are spawned or the other personas' content.

## Approach
- **One file per ICP**, picked up by the existing review glob. The profile's name lives in the
  title so the `👤 User (<Name>)` tag disambiguates inline comments across profiles.
- **Applies-when is natural language.** The scoping step already reads each persona's title/intro
  to decide relevance; this gives it richer per-profile signal without any config or runtime.
  Multi-match resolves to "scope all touched, none if none" — no designated fallback ICP.
- **CRUD split.** `add` owns create-fresh; `update` owns read-back-and-refine (the half of old
  `setup` that re-ran on an existing file); `remove` owns deletion; `list` is the read verb. Each
  skill's `description` triggers on a distinct intent so the router disambiguates — notably
  `/spectra-update-user` ("refine/edit an existing user persona") vs. the unrelated
  `/spectra-update` ("update the installed Spectra plugin"); the `-user` suffix marks the object.
- **Template** extends 0004's `user.md` structure:
  ```markdown
  # 👤 User (<Name>)

  See `persona.md` for how to review and comment.

  ## Applies when
  - <surfaces / flows / JTBD this profile cares about>

  ## Skip when
  - <slices that belong to a different profile or are irrelevant here>

  ## Profile
  - **Who** … **Goals (JTBD)** … **Pain points** … **Technical level** … **Values** … **Would reject** …

  ## Review — on the user's behalf
  - <checklist derived from the profile>
  ```
- **Why no migration / no config toggles.** A lone `user.md` is already a valid member of the
  `user*.md` family, so existing installs keep working untouched. Presence-based eligibility (file
  exists → eligible; applies-when filters per review) avoids a parallel toggle surface that could
  drift from the files themselves.

## Acceptance
- [ ] `/spectra-add-user` produces a structured `docs/spectra/personas/user-<slug>.md` with a
      named 👤 title, `Applies when`, `Skip when`, `Profile`, and `Review` sections.
- [ ] `/spectra-update-user` lists existing ICPs, reads the chosen one back, and rewrites it
      (refine, not blank); points at `/spectra-add-user` when none exist.
- [ ] `/spectra-remove-user` lists, confirms, and deletes the chosen ICP file.
- [ ] `/spectra-list-users` lists each `user*.md` with its title + applies-when summary.
- [ ] `/spectra-setup` (command + skill) is removed; no references remain in skills, manifests,
      README, or tests.
- [ ] `spectra/protocol.md` scopes user personas per `user-*.md` via Applies-when / Skip-when,
      scoping all touched and none when none apply.
- [ ] `spectra-update/SKILL.md` states `personas/user*.md` is developer-owned and preserved; an
      update copy run leaves multiple `docs/spectra/personas/user-*.md` byte-for-byte intact.
- [ ] All manifests advertise the four new commands and not `spectra-setup`, at `version` 1.0.0.
- [ ] README documents the four commands; `test.sh` passes with retargeted + new assertions;
      README token figures regenerated; `docs/overview/` updated (features, architecture, learnings).
