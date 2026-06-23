---
name: spectra-remove-user
description: Remove a 👤 User (ICP) review persona from this repo — pick one of your defined customer profiles and Spectra deletes its docs/spectra/personas/user-<slug>.md, so it stops being scoped into reviews. Use when asked to remove, delete, or drop a user persona / customer profile / ICP.
---

# Remove a User (ICP) persona

Delete a customer profile so it no longer participates in reviews. (To edit one instead, use
`/spectra-update-user`; to add one, `/spectra-add-user`.) Run from the repo root.

## Steps

1. **List & select** — find the ICP personas: `docs/spectra/personas/user*.md` (a legacy single
   `user.md` and any `user-<slug>.md`). **If none exist**, say so and stop. If one exists, select
   it; if several, number them by title and ask which to remove.

2. **Confirm** — show the chosen file's title and ask the developer to confirm deletion (this is
   destructive and the profile's wording is not recoverable except from git history).

3. **Delete** — on confirmation, `rm` the selected file. Remove only that file; never touch the
   shipped personas, `persona.md`, or `personas.config`.

4. **Confirm** — tell the developer the 👤 User (<Name>) persona is removed and will no longer be
   scoped into reviews. If other ICP personas remain, list them; if it was the last one, note that
   no user persona will review until they `/spectra-add-user` again.
