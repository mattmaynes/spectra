# 0004 — Dynamic `user` (ICP) persona & `spectra-setup`

## Problem
Spectra's four review personas (engineer, tester, architect, security) all judge a change from
the *builder's* side — correctness, structure, safety. None of them ask the question a customer
would: *does this change actually serve the person we're building for?* Every team has a
different ideal customer, so this perspective can't be a fixed, shipped checklist — it has to be
described per repo. Today there's no way for a consumer to teach Spectra who their user is and
fold that voice into reviews.

## Outcome
- A consumer runs **`/spectra-setup`** and has a short, guided dialog: they describe their ideal
  customer, the agent asks clarifying questions, and the result is written to
  **`docs/spectra/personas/user.md`** — a 👤 *User (ICP)* persona in the same shape as the
  others (review contract + opinionated checklist), grounded in *their* customer.
- Once that file exists, the **user persona participates in reviews like any other** — scoped in
  when a change touches user-facing behavior or experience. While the file is **absent** (the
  default), reviews simply don't include it. No marker, no inert state: absent = not used.
- Re-running `/spectra-setup` **refines** an existing `user.md` (reads it, plays it back,
  continues the dialog) rather than starting from scratch.
- **`/spectra-update` never overwrites `user.md`.** It is developer-owned, like
  `specs/plans/feedback/overview` — the update glob already excludes it (it isn't a shipped
  persona), and that guarantee is stated explicitly in the skill and locked by a test.

## Scope
- **In:**
  - `spectra/skills/spectra-setup/SKILL.md` — new skill: dialog flow + the canonical `user.md`
    structure it fills, written into `docs/spectra/personas/user.md`. Refines on re-run.
  - `spectra/protocol.md` — add `user` 👤 to the Review persona-scoping list, noting it applies
    **only when `docs/spectra/personas/user.md` exists** (configured via `spectra-setup`).
  - `spectra/skills/spectra-update/SKILL.md` — one explicit line: `personas/user.md` is
    developer-owned and preserved (alongside specs/plans/feedback/overview).
  - `spectra/skills/spectra-install/SKILL.md` — confirmation step points the developer at
    `/spectra-setup` as an optional next step (install does **not** create `user.md`).
  - `spectra/.claude-plugin/plugin.json` — description mentions `/spectra-setup`.
  - `test.sh` — (a) assert `spectra/personas/` ships **no** `user.md` (create-on-demand holds);
    (b) extend the update test to prove a developer's `docs/spectra/personas/user.md` survives
    the update copy steps.
  - Repo-local: regenerate the README token block (`scripts/token-report.sh --write`) since the
    new skill grows the "Everything" figure. Reflect into `docs/overview/`.
- **Out:**
  - Shipping a `user.md` file in `spectra/personas/` (decided: create-on-demand; absent = unused).
  - An "inactive/stub persona" marker mechanism (unneeded once the file is simply absent).
  - Auto-running the personas / changing *how* reviews are spawned — only *which* personas are
    eligible. Wiring a real ICP into *this* repo's own dogfood reviews (optional, not required).
  - Any non-markdown runtime, or changes to the other four persona files' content.

## Approach
- **`spectra-setup` skill.** Frontmatter `name: spectra-setup` + a description that triggers on
  "describe my user / ideal customer / ICP." Body instructs the agent to:
  1. If `docs/spectra/personas/user.md` exists, read it, summarize it back, and frame the dialog
     as a refinement; else start fresh.
  2. Ask the developer for an initial description, then ask **clarifying questions** until the
     profile is concrete (who they are, goals/JTBD, pain points, technical level, what they
     value, what they'd reject). One focused round, not an interrogation.
  3. Write `docs/spectra/personas/user.md` using the canonical structure — a `# 👤 User (ICP)`
     title, a `See persona.md…` line (matching the other personas), a **Profile** section, and a
     **Review** checklist derived from the profile so the persona has concrete things to look
     for. The template structure is embedded in `SKILL.md` (self-contained, like the other
     skills — no extra files).
  4. Confirm the file was written and that it will now be picked up in reviews.
- **Why create-on-demand (not a shipped stub).** The ICP is per-consumer and starts unknown; an
  absent file is the simplest possible "off" state. It also means `spectra-update`'s
  `cp "$SRC/personas/"*.md` can't touch it (the source has no `user.md`), so the
  "don't overwrite" requirement falls out of the design rather than needing exclusion logic. The
  explicit doc line + test guard the guarantee against future drift.
- **Protocol scoping.** The Review step gains a fifth, conditional entry: `user` 👤 — user-facing
  behavior or experience, **when `user.md` exists**. Reviewers read `persona.md` + `user.md` just
  like any other persona.
- **Testing.** `test.sh` step 2 already validates every skill's frontmatter, so `spectra-setup`
  is covered there. Add: a check that `spectra/personas/user.md` does **not** exist; and in the
  update test, drop a custom `docs/spectra/personas/user.md`, run the update's persona-copy step,
  and assert the custom content is unchanged.

## Acceptance
- [ ] `spectra/skills/spectra-setup/SKILL.md` exists with valid frontmatter; running the skill
      produces a structured `docs/spectra/personas/user.md` (👤 title, Profile + Review sections).
- [ ] Re-running the skill on an existing `user.md` refines it (reads + plays back) rather than
      blanking it.
- [ ] `spectra/personas/` contains **no** `user.md` (create-on-demand); a fresh `spectra-install`
      does not create one.
- [ ] After the `spectra-update` copy steps, a developer's `docs/spectra/personas/user.md` is
      byte-for-byte preserved; `spectra-update/SKILL.md` states this explicitly.
- [ ] `spectra/protocol.md` lists `user` 👤 as a review persona, gated on the file existing.
- [ ] `plugin.json` mentions `/spectra-setup`.
- [ ] `test.sh` passes (new user.md-absent + update-preserves-user.md cases included), README
      token figures regenerated, `docs/overview/` updated (features, architecture, learnings).
