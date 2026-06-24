# 0003 - Persona depth and a shared review contract

## Symptom
The four review personas were thin and repetitive. Each file re-stated the same comment
format and "approve only when…" boilerplate, so the **shared review contract was duplicated
four times** (and would drift). The per-persona checklists were generic ("correctness",
"coverage") - not valuable enough to change how a reviewer actually reads a diff. Comments
also gave no quick visual cue to their source.

## Root cause
The personas mixed two concerns in one file: *how to review and comment* (identical across
all four) and *what to look for* (specific to each). The shared half was copy-pasted; the
specific half was under-developed.

## Fix
Split the concerns and deepened the specifics:
- Added `spectra/personas/persona.md` - the **generic** persona doc: how to review, PR
  comment best practices (**inline only**, one issue per comment, concrete fix, no end-of-PR
  wall of text), the `_<emoji> Spectra <Persona>_` / severity format, and the approve bar.
  Each persona file now describes **only its specifics** and points here.
- Gave each persona a distinct **emoji** for at-a-glance attribution in the title line:
  🔧 Engineer · 🧪 Tester · 📐 Architect · 🔒 Security.
- Deepened each checklist to be opinionated and actionable:
  - **Engineer** - cohesion/modularity/separation of concerns; consistent paradigm (prefer
    functional/stateless, but match the file - be a chameleon); performance (tail recursion,
    vectorized ops); minimize conditionals; nullability; tight try/catch regions; logging at
    the right level; graceful failure.
  - **Tester** - smart coverage via domain partitioning; no value-less tests; honest tests
    (never pin to a bug to pass); correct mocks/abstractions; user-facing output sanity.
  - **Architect** - build-vs-buy on dependencies; design for change / reversible decisions;
    simple, normalized schemas with clear identifiers.
  - **Security** - dependency-chain vulnerabilities; PII/sensitive data; secure tokens/keys.
- Slimmed `spectra/protocol.md` step 5.4 to reference `persona.md` instead of re-embedding
  the format block.

## Learning
A repeated instruction is a single instruction in the wrong place. Factor the shared contract
out once (`persona.md`) and let each persona carry only its distinct lens. Recorded in
`overview/learnings.md`.
