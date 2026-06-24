# 0007 - Skills that `rm`/`cp` on a user-supplied name need explicit validation

From the 🔒 security review of PR #10.

## Symptom
`spectra-disable` instructed the agent to `rm -f docs/spectra/personas/<persona>.md` with only a
loose "if it's a candidate" guard. A crafted or mistyped name (`../foo`, an absolute path) could
make `rm -f` delete content outside the personas directory; `spectra-enable`'s `cp` had the same
interpolation shape.

## Root cause
Because a SKILL is prose that *instructs an agent* rather than code that runs directly, the draft
leaned on the agent "being sensible" and on `[ -f <interpolated path> ]` - which an `../`
traversal still satisfies - instead of validating the input.

## Fix
Both skills now **mandate validation before acting**: the argument must match a bare-segment
shape (`^[a-z][a-z0-9-]*$` - no `/`, `..`, leading `/`, or extension) **and** be a member of the
computed catalog/candidate allowlist; only then `cp`/`rm`. Stated as an allowlist check, not a
filesystem probe of an interpolated path.

## Learning
An instruction file is an interface with untrusted input just like code is. A skill that tells an
agent to delete or copy by a user-supplied name must spell out the input contract (shape +
allowlist) explicitly - "the agent will be careful" is not an access control.
