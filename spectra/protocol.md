# Spectra Protocol

Spec-driven development with learning feedback loops. Follow this for every change.

## Artifacts

| Dir | Holds | Name |
|---|---|---|
| `docs/specs/` | feature specifications | `NNNN-<slug>.md` |
| `docs/plans/` | build plans for specs/feedback | `NNNN-<slug>.md` |
| `docs/feedback/` | bugs + process feedback (learning input) | `NNNN-<slug>.md` |
| `docs/overview/` | living docs: `project` `features` `architecture` `learnings` | fixed |

`NNNN` = zero-padded, next integer in that dir. Slug = kebab-case.

## 1. Route the change

- **Trivial** (a line, a typo, an obvious fix) → implement directly. Skip to step 6.
- **Net-new feature** → write a spec (§2), get developer approval before building.
- **Bug or feedback** → write a feedback doc (§3) so it becomes a learning.

## 2. Spec (features)

Write `docs/specs/NNNN-<slug>.md`:
- **Problem** — what/why, who it's for.
- **Outcome** — observable behavior when done.
- **Scope** — in / out.
- **Approach** — sketch; key decisions & trade-offs.
- **Acceptance** — checklist proving done.

Stop and get developer review before planning.

## 3. Feedback (bugs / process)

Write `docs/feedback/NNNN-<slug>.md`:
- **Symptom** — what went wrong / what hurt.
- **Root cause** — why (best understanding).
- **Fix** — the change.
- **Learning** — what to do differently next time. Feeds `overview/learnings.md` in step 6.

## 4. Plan

If the work is multi-step, convert the spec/feedback into `docs/plans/NNNN-<slug>.md`:
ordered steps, files touched, verification. Reference the source `NNNN`.

## 5. Build, test, review, merge

1. **Build** in a **git worktree** on a new branch — `git worktree add .worktrees/<slug>
   -b <slug>` — leaving your primary checkout on `main`. A sub-agent does the build inside
   the worktree; remove it (`git worktree remove`) once merged.
2. **Test** — run the repo's test suite; fix the code or the tests until green.
   Always do this **before committing**. No suite yet? Add the test that proves this change.
3. **Commit**, then open a **PR**.
4. **Review** — first **scope it**: pick only the personas whose facet the change actually
   touches; don't run all four by reflex.
   - **engineer** — non-trivial code/logic (skip for docs/cosmetic-only or tests-only)
   - **tester** — behavior changes (skip for cosmetic/docs-only)
   - **architect** — structure, boundaries, or dependencies change
   - **security** — auth, input handling, secrets, scripts that run in consumers, or new deps

   Spawn the selected personas as sub-agents using `docs/spectra/personas/*`. Each posts
   findings **as inline comments on the PR, anchored to the relevant file and line** (general
   findings go in the review summary) — never as detached top-level comments. Use this form:
   ```
   _Spectra <Persona>_
   **<nit|minor|major|blocker>**
   <comment>
   ```
   Severity: `nit` (optional polish) · `minor` (should fix) · `major` (must fix before merge)
   · `blocker` (broken/unsafe — stop). Treat every **major** and **blocker** as feedback:
   capture it in `docs/feedback/` and roll the lesson into `overview/learnings.md` (step 6).
5. **Address** every comment; re-test; push fixes.
6. **Merge** on developer approval.

## 6. Reflect (before concluding — always)

Update only what changed:
- mission/direction shifted → `overview/project.md`
- new capability → `overview/features.md`
- structure/boundaries changed → `overview/architecture.md`
- feedback, PR friction, or "could've gone better" → `overview/learnings.md`

A `pre-commit` hook reminds you if specs/plans/feedback changed without an overview update.
The reminder is non-blocking — skip it only when truly nothing changed.
