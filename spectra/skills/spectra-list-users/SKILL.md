---
name: spectra-list-users
description: List the 👤 User (ICP) review personas defined in this repo — each customer profile's name and when it applies to reviews — by reading docs/spectra/personas/user*.md. Use when asked to list, show, or see the user personas / customer profiles / ICPs.
---

# List User (ICP) personas

Show the customer profiles this repo has defined and when each one weighs in on reviews. Read-only.
Run from the repo root.

## Steps

1. **Find** — list the ICP personas: `docs/spectra/personas/user*.md` (a legacy single `user.md`
   and any `user-<slug>.md`). **If none exist**, say so and point the developer at
   `/spectra-add-user`.

2. **Summarize** — for each file, print its title (`# 👤 User (<Name>)`) and a one-line summary of
   its **Applies when** block (the surfaces/changes that scope it into a review). Keep it to a
   compact list.

3. **Point onward** — note that profiles are managed with `/spectra-add-user`,
   `/spectra-update-user`, and `/spectra-remove-user`.
