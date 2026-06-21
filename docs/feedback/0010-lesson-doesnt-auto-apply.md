# 0010 — A written lesson doesn't auto-apply to the next guard of the same shape

From the 🧪 tester persona review of PR #12 (Gemini packaging). Companion to `feedback/0009`.

## Symptom
PR #11 had just landed `feedback/0009` — *presence-of-good ≠ absence-of-bad; key a regression
guard on the structural line the regression would change.* In the **very next PR**, the new
Gemini `test.sh` guard repeated the same hole: it `grep`-ed for `@{skills/<n>/SKILL.md}`
*anywhere* in the TOML and never parsed it, so a wrapper that lost or malformed its `prompt` key —
with the injection string surviving only in a comment — still passed. The TOML was never even
parsed (unlike the JSON manifests, which are).

## Root cause
The 0009 lesson was *documented* but not turned into an *applied* check. Writing a guard of the
same shape (a text-assert over an instruction/config file) in a sibling test didn't trigger a
re-read of the lesson; the author pattern-matched "grep the file" again.

## Fix
Parse the TOML with `tomllib` and assert the injection lives inside the `prompt` **value** (which
also makes the wrapper actually parse), plus a non-empty manifest `name` and command
`description`. A deleted or malformed `prompt` now fails the test.

## Learning
A fresh lesson is most likely to be violated in the same change that introduced it. When you add
a guard of a shape you just wrote a lesson about — here, text-asserts over config/instruction
files — re-apply that lesson as a checklist item to the new guard before moving on; recording it
once does not make it generalize on its own.
