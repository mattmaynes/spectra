#!/bin/sh
# "What's new" updater - keeps the README's headline current with the latest release.
#
# Shipped by Trellis's plugin-release template and OWNED by Trellis (refreshed by
# trellis-update). Do not hand-edit. Called by .github/workflows/whats-new.yml after the Release
# workflow publishes a GitHub Release.
#
# Dependency-free (POSIX sh + awk/sed) so the workflow and a local run behave identically.
# Inputs arrive via env:
#   TAG  (required) release tag, e.g. 1.2.0
#   NAME (optional) release title - fallback headline
#   BODY (optional) release notes - headline = its first non-empty, non-heading line
#
# The README must carry the marker pair once (the consumer seeds it):
#   <!-- whats-new:start -->
#   ...one line...
#   <!-- whats-new:end -->
#
# Usage:
#   scripts/whats-new.sh            print the generated block (markers inclusive)
#   scripts/whats-new.sh --write    rewrite that block inside README.md in place
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
README="$ROOT/README.md"
START='<!-- whats-new:start -->'
END='<!-- whats-new:end -->'

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
