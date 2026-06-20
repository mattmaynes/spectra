---
name: spectra-setup
description: Define the 👤 User (ICP) review persona for this repo through a short guided dialog — describe your ideal customer / who you're building for, and Spectra writes docs/spectra/personas/user.md so reviews can judge changes on the user's behalf. Use when asked to describe my user, ideal customer, ICP, or who we're building for.
---

# Set up the User (ICP) persona

Capture **who this repo is built for** as a review persona. Through a short dialog you write
`docs/spectra/personas/user.md` — a 👤 *User (ICP)* persona in the same shape as the shipped
ones. Once it exists, reviews of user-facing changes scope it in like any other persona. Run
from the repo root. This skill writes only that one file; it reads nothing from `$SRC`.

## Steps

1. **Refine or start** — if `docs/spectra/personas/user.md` already exists, read it, summarize
   it back to the developer in a sentence or two, and frame this as a **refinement** of the
   existing persona. Otherwise start fresh.

2. **Describe** — ask the developer for an initial description of their ideal customer: who is
   this product for?

3. **Clarify** — ask **one focused round** of clarifying questions (not an interrogation) to
   make the profile concrete, covering: who they are, their goals / jobs-to-be-done, their pain
   points, their technical level, what they value, and what they'd reject.

4. **Write** — create `docs/spectra/personas/user.md` from this template, filling every field
   from the dialog and deriving the Review checklist from the profile so the persona has
   concrete things to look for:

   ```markdown
   # 👤 User (ICP)

   See `persona.md` for how to review and comment.

   Review whether the change actually serves the person this product is built for.

   ## Profile

   - **Who** — <one-line description of the ideal customer>
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

5. **Confirm** — tell the developer the 👤 User (ICP) persona is now active: it will be scoped
   into reviews of user-facing changes alongside the engineer, tester, architect, and security
   personas.
