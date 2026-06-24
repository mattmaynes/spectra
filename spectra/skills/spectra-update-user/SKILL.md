---
name: spectra-update-user
description: Refine an existing 👤 User (ICP) review persona for this repo — pick one of your defined customer profiles, Spectra reads it back, and a short dialog updates docs/spectra/personas/user-<slug>.md (profile details or when it applies). Use when asked to refine, edit, or update an existing user persona / customer profile / ICP. (Not the same as /spectra-update, which updates the Spectra plugin itself.)
---

# Refine a User (ICP) persona

Edit a customer profile that already exists. This skill **only refines** existing personas — to
create a new one use `/spectra-add-user`; to delete one, `/spectra-remove-user`. Run from the repo
root. It writes only the selected persona file; it reads nothing from `$SRC`.

## Steps

1. **List & select** — find the ICP personas: `docs/spectra/personas/user*.md` (a legacy single
   `user.md` and any `user-<slug>.md`). **If none exist**, stop and point the developer at
   `/spectra-add-user`. If one exists, select it; if several, number them by title and ask which
   to refine.

2. **Play back** — read the chosen file and summarize it back in a sentence or two (who the
   profile is and when it applies), framing this as a **refinement** of that persona.

3. **Clarify** — ask what should change. Cover the same dimensions as creation when relevant: who
   they are, goals / JTBD, pain points, technical level, values, would-reject, and **when this
   profile should weigh in on a review vs. sit out** (its Applies when / Skip when). One focused
   round, not an interrogation.

4. **Rewrite** — write the file back in the canonical structure — the **exact template block in
   `spectra-add-user`'s SKILL.md** (the `# 👤 User (<Name>)` title, `See persona.md…` line,
   **Applies when**, **Skip when**, **Profile**, and **Review** sections) is the single source of
   that shape; reproduce it rather than inventing a variant. Preserve everything that didn't change
   and fold in the updates. Don't blank fields the dialog didn't touch.

5. **Confirm** — tell the developer the refined 👤 User (<Name>) persona is saved and which
   reviews it now applies to.
