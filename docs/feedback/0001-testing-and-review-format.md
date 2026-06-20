# 0001 — Explicit testing + standardized review comments

## Symptom
The protocol jumped from build straight to PR/commit with no explicit testing gate, and
persona review comments had no consistent shape — making severity and follow-up ambiguous.

## Root cause
First draft optimized for terseness and under-specified two things every loop needs: a
verification step before code lands, and a machine-skimmable review-comment format.

## Fix
- Added a **Test** step (protocol step 5) — run the suite and fix code/tests until green
  **before committing**; if no suite exists, add the test that proves the change. Added a repo
  `test.sh` so this repo has a real suite.
- Standardized persona comments to:
  ```
  _Spectra <Persona>_
  **<nit|minor|major|blocker>**
  <comment>
  ```
- Every **major**/**blocker** is treated as feedback: captured here and rolled into
  `overview/learnings.md`.

## Learning
Bake the verification and review-output contracts into the protocol itself — don't leave
them implicit. Recorded in `overview/learnings.md`.
