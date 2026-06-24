# 0009 - A presence-only text assert can't catch the regression it guards

From the 🧪 tester persona review of PR #11 (cross-agent packaging).

## Symptom
`test.sh`'s guard for tool-neutral `$SRC` checked that neutral tokens were *present*
(`grep 'SRC='`, `'plugin'`, `'other agents'`) but never that the Claude-only form was *gone*. The
tester demonstrated a false-green: a body that kept the new prose yet reverted the only executable
resolution to a bare `SRC="${CLAUDE_SKILL_DIR}/../.."` - the exact regression the assert claimed to
prevent - still passed all three greps. Two conjuncts were also near-tautological (`'plugin'`
matched incidental prose; for `spectra-update` it was satisfied by the frontmatter `description`),
so the guard effectively rested on one rewordable phrase. The spec ("carry no Claude-specific
tokens") and plan ("assert no `CLAUDE_SKILL_DIR` outside an example line") had both asked for an
absence check; it was dropped in implementation.

## Root cause
Presence and absence are different assertions. Guarding "X was removed/replaced" with "Y is
present" only holds if `Y` and the bad state are mutually exclusive. Here they weren't: neutrality
lived in *prose* while the one executable line stayed Claude-only, so the good token and the bad
state coexisted happily.

## Fix
Make the executable resolution itself tool-neutral - a `SPECTRA_SRC` override that precedes the
Claude var and fails loud (`:?`) if neither is set - then anchor the assert to that structural
line: `grep -qF 'SRC="${SPECTRA_SRC' "$sk"`. A Claude-only revert no longer matches, so the test
fails exactly when it should. (This also fixed the engineer/architect finding that the snippet
silently expanded to `/` on a non-Claude agent.)

## Learning
When a text-assert guards a *regression*, key it on the structural artifact the regression would
change - one the bad state cannot also satisfy - not on adjacent prose; and prefer making the
behavior **real** (a concrete line to grep) over guarding intent that lives only in description.
Presence-of-good ≠ absence-of-bad. Extends `feedback/0008`.
