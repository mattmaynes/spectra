# 0008 — Test the skill's text, not a re-implementation of it

From the 🧪 tester review of PR #10.

## Symptom
The `test.sh` update test re-implemented the refresh-only-present loop **inline** to exercise it.
But the suite never reads `spectra-update/SKILL.md`, so if the skill regressed to the old
`cp "$SRC/personas/"*.md` glob, the central invariant ("disabled personas survive update") would
silently break while the test stayed green.

## Root cause
The behavior lives in an **instruction file the suite can't execute**. Simulating it proves the
*simulation* works, not that the shipped skill still says to do it — the test and the artifact it
guards could drift apart with nothing to catch it.

## Fix
Added text assertions on the skill body: it **must contain** the present-only loop and **must
not contain** the bare bulk-copy glob. Also made the disabled-core case non-vacuous by asserting
the source actually ships `security.md`.

## Learning
When the thing under test is prose you can't run, assert on the prose itself —
must-contain/must-not-contain checks on the artifact — so the documented behavior and the real
behavior can't quietly diverge. A test that copies the logic instead of referencing it only
tests the copy.
