#!/bin/sh
# Spectra conventional-commit check — validates a commit message / PR title against the
# Conventional Commits spec (https://www.conventionalcommits.org).
#
# REPO-LOCAL TOOLING. Not part of the shippable plugin (nothing under spectra/) and never
# installed into consumer repos. Conventional commits is *this repo's* convention; it's
# enforced in CI (.github/workflows/ci.yml) on PR titles and runnable locally.
#
# Dependency-free (POSIX sh + grep) so it runs identically in CI and a local hook — same
# rationale as scripts/token-report.sh.
#
# Grammar (first line only):
#   type(optional scope)(optional !): subject
#   type ∈ feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert
#
# Usage:
#   scripts/check-commit-msg.sh "feat(parser): add array support"   # exit 0, silent
#   scripts/check-commit-msg.sh "fixed a bug"                       # exit 1, prints why
set -eu

TYPES='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'

case "${1:-}" in
  -h|--help)
    echo "usage: $0 <commit-message-or-pr-title>"
    echo "validates the first line against Conventional Commits ($TYPES)"
    exit 0
    ;;
esac

MSG=${1:-}
SUBJECT=$(printf '%s\n' "$MSG" | head -n1)

if [ -z "$SUBJECT" ]; then
  echo "check-commit-msg: empty commit message / PR title." >&2
  echo "  expected: <type>[optional scope][!]: <subject>   e.g. 'feat: add CI workflow'" >&2
  exit 1
fi

if printf '%s\n' "$SUBJECT" | grep -Eq "^(${TYPES})(\([^)]+\))?!?: .+"; then
  exit 0
fi

echo "check-commit-msg: not a Conventional Commit:" >&2
echo "  $SUBJECT" >&2
echo "  expected: <type>[optional scope][!]: <subject>" >&2
echo "  types:    $TYPES" >&2
echo "  example:  feat(ci): add conventional-commit check" >&2
exit 1
