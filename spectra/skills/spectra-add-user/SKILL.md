---
name: spectra-add-user
description: Add a new 👤 User (ICP) review persona for this repo through a short guided dialog — describe one customer profile you're building for and when it should weigh in, and Spectra writes docs/spectra/personas/user-<slug>.md so reviews can judge changes on that customer's behalf. Use when asked to add, define, or create a new user persona / customer profile / ICP.
---

# Add a User (ICP) persona

Capture **one customer profile** this repo serves as a review persona. A product can have several
(e.g. self-serve SMB vs. enterprise buyer); this skill adds **one** per run, written to
`docs/spectra/personas/user-<slug>.md` in the same shape as the shipped personas plus an
**Applies when / Skip when** block that tells reviews which changes this profile cares about. Once
the file exists, reviews of matching user-facing changes scope it in like any other persona. Run
from the repo root. This skill writes only that one file; it reads nothing from `$SRC`.

To **edit** an existing profile use `/spectra-update-user`; to **remove** one, `/spectra-remove-user`;
to **see** the defined profiles, `/spectra-list-users`.

## Steps

1. **Name the profile** — ask the developer which customer slice this is (a short name like
   "SMB", "Enterprise admin", "Hobbyist"). Derive a kebab-case `<slug>` from it and target
   `docs/spectra/personas/user-<slug>.md`. **If that file already exists**, stop and point the
   developer at `/spectra-update-user` (this skill only creates) — don't overwrite.

2. **Describe** — ask for an initial description of this profile: who are they, and what part of
   the product do they live in?

3. **Clarify** — ask **one focused round** of clarifying questions (not an interrogation) covering:
   who they are, their goals / jobs-to-be-done, their pain points, their technical level, what they
   value, what they'd reject, and — importantly — **when this profile should weigh in on a review
   and when it shouldn't** (which surfaces, flows, or changes are theirs vs. another profile's).

4. **Write** — ensure the directory exists (`mkdir -p docs/spectra/personas`, in case this runs
   before `spectra-install`), then create `docs/spectra/personas/user-<slug>.md` from this
   template, filling every field from the dialog and deriving the Review checklist from the
   profile. `persona.md` remains the authority on *how* to review; this template only mirrors the
   shipped personas' shape plus the applicability block:

   ```markdown
   # 👤 User (<Name>)

   See `persona.md` for how to review and comment.

   Review whether the change actually serves this customer profile.

   ## Applies when

   - <surfaces / flows / jobs-to-be-done this profile cares about — when this persona should
     be scoped into a review>

   ## Skip when

   - <slices that belong to a different profile, or changes irrelevant to this one — when this
     persona should sit out>

   ## Profile

   - **Who** — <one-line description of this customer profile>
   - **Goals (JTBD)** — <what they're trying to get done>
   - **Pain points** — <what frustrates them today / what they're escaping>
   - **Technical level** — <how technical they are; what they can/can't be expected to do>
   - **Values** — <what they care about: speed, clarity, control, price, trust…>
   - **Would reject** — <what makes them bounce or churn>

   ## Review — on the user's behalf

   - **Serves the goal** — does this advance the goals above, or only the builder's convenience?
   - **Matches their level** — is the complexity/jargon appropriate for their technical level?
   - **Eases a pain** — does it relieve a real pain point, not invent a new one?
   - **Honors their values** — does it protect what they value (e.g. clarity, control, trust)?
   - **No dealbreakers** — does it introduce anything in the "Would reject" list?
   - **Affordances** — are the docs, defaults, and error messages the user needs actually there?
   ```

5. **Confirm** — tell the developer the 👤 User (<Name>) persona is now active: it will be scoped
   into reviews whose changes match its **Applies when** block, alongside the engineer, tester,
   architect, and security personas. Mention they can add more profiles with `/spectra-add-user`.
