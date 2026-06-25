#!/bin/sh
# Spectra "What's new" updater - keeps the README's headline current with the latest release.
#
# REPO-LOCAL TOOLING. This is not part of the shippable plugin (nothing under spectra/) and is
# never installed into consumer repos. It exists only to refresh this repo's README from a
# published GitHub Release, and is called by .github/workflows/whats-new.yml.
#
# Dependency-free (POSIX sh + awk/sed), same rationale as token-report.sh: the workflow and a
# local run behave identically and need no toolchain. Inputs arrive via env (as the release
# event provides them):
#   TAG  (required) release tag, e.g. 1.2.0
#   NAME (optional) release title - fallback headline
#   BODY (optional) release notes - headline = its first non-empty, non-heading line
#
# Usage:
#   scripts/whats-new.sh            print the generated block (markers inclusive)
#   scripts/whats-new.sh --write    rewrite that block inside README.md in place
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
README="$ROOT/README.md"
START='<!-- spectra:whats-new:start -->'
END='<!-- spectra:whats-new:end -->'

TAG="${TAG:-}"
NAME="${NAME:-}"
BODY="${BODY:-}"

# headline -> the one-line summary for the block. First non-empty, non-heading line of the
# release notes; falls back to the release title, then a generic line.
headline() {
  h=$(printf '%s\n' "$BODY" | awk '
    { sub(/\r$/, "") }             # tolerate CRLF release bodies
    /^[[:space:]]*$/ { next }      # skip blank lines
    /^[[:space:]]*#/ { next }      # skip markdown headings
    { sub(/^[[:space:]]+/, ""); sub(/[[:space:]]+$/, ""); print; exit }
  ')
  [ -n "$h" ] || h="$NAME"
  [ -n "$h" ] || h="New release available."
  # Defense-in-depth: a release publisher is trusted (publishing needs write access), but strip
  # the comment markers so a crafted first line can't corrupt the block region on the next run,
  # and cap the length so the README stays a one-liner.
  printf '%s' "$h" | sed 's/<!--//g; s/-->//g' | cut -c1-200
}

generate() {
  [ -n "$TAG" ] || { echo "whats-new: TAG is required" >&2; exit 2; }
  printf '%s\n' "$START"
  printf '**%s** - %s\n' "$TAG" "$(headline)"
  printf '%s\n' "$END"
}

case "${1:-print}" in
  print|--print) generate ;;
  write|--write)
    # The block must exist exactly once, or a rewrite would silently drop/duplicate content.
    if [ "$(grep -cF "$START" "$README")" != 1 ] || [ "$(grep -cF "$END" "$README")" != 1 ]; then
      echo "whats-new: expected exactly one '$START' / '$END' pair in README.md" >&2
      exit 1
    fi
    BLOCKF=$(mktemp); generate > "$BLOCKF"
    # Read the (multi-line) block from a file via getline - BSD awk rejects multi-line -v.
    awk -v bf="$BLOCKF" -v s="$START" -v e="$END" '
      index($0, s) { while ((getline ln < bf) > 0) print ln; close(bf); skip=1; next }
      index($0, e) { skip=0; next }
      !skip { print }
    ' "$README" > "$README.tmp"
    mv "$README.tmp" "$README"; rm -f "$BLOCKF"
    echo "whats-new: README.md updated."
    ;;
  *) echo "usage: $0 [print|--write]" >&2; exit 2 ;;
esac
