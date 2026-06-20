#!/bin/sh
# Spectra token report — keeps the README's "Low token cost" figures honest.
#
# REPO-LOCAL TOOLING. This is not part of the shippable plugin (nothing under spectra/)
# and is never installed into consumer repos. It exists only to measure this repo's own
# spectra/ source and keep README.md in sync.
#
# Heuristic: ~4 chars/token (dependency-free — no tokenizer needed, so the pre-commit hook
# runs anywhere). Counts are grouped to mirror what actually loads into an agent's context.
#
# Usage:
#   scripts/token-report.sh           print the generated markdown block (incl. markers)
#   scripts/token-report.sh --write   rewrite that block inside README.md in place
#   scripts/token-report.sh --check   exit non-zero if README.md's block is stale
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC="$ROOT/spectra"
README="$ROOT/README.md"
START='<!-- spectra:tokens:start -->'
END='<!-- spectra:tokens:end -->'

# chars_of FILE... -> total character count across the given files
chars_of() { cat "$@" | wc -c | tr -d ' '; }

# tokens N -> round(N / 4)
tokens() { awk -v c="$1" 'BEGIN{ printf "%d", int(c/4 + 0.5) }'; }

# commas N -> N with thousands separators (portable; no locale dependency)
commas() {
  awk -v n="$1" 'BEGIN{
    s=sprintf("%d", n); out=""; c=0
    for (i=length(s); i>=1; i--) { out=substr(s,i,1) out; c++; if (c%3==0 && i>1) out="," out }
    print out
  }'
}

# row LABEL CHARS -> a markdown table row "| LABEL | chars | **tokens** |"
row() { printf '| %s | %s | **%s** |\n' "$1" "$(commas "$2")" "$(commas "$(tokens "$2")")"; }

# Groupings (sorted for determinism)
host_files()  { echo "$SRC/agents.md"; }
proto_files() { echo "$SRC/protocol.md"; }
core_files()  { echo "$SRC/protocol.md"; find "$SRC/personas" -name '*.md' | sort; }
all_files()   { find "$SRC" -name '*.md' | sort; }

generate() {
  HOST=$(chars_of $(host_files))
  PROTO=$(chars_of $(proto_files))
  CORE=$(chars_of $(core_files))
  ALL=$(chars_of $(all_files))
  echo "$START"
  echo '| What loads into context | Characters | Tokens (≈4 ch) |'
  echo '|---|---|---|'
  row 'Always-on host block (in `AGENTS.md`)' "$HOST"
  row 'Protocol only (no personas needed)' "$PROTO"
  row 'Full protocol + all four personas' "$CORE"
  row 'Everything, incl. install/update skills' "$ALL"
  echo "$END"
}

# current block as it appears in README (markers inclusive); empty if markers absent
current() { awk "/${START}/{f=1} f{print} /${END}/{f=0}" "$README"; }

case "${1:-print}" in
  print|--print) generate ;;
  check|--check)
    if [ "$(current)" = "$(generate)" ]; then exit 0; fi
    echo "token-report: README.md token figures are stale." >&2
    echo "  fix: scripts/token-report.sh --write" >&2
    exit 1
    ;;
  write|--write)
    grep -qF "$START" "$README" || { echo "token-report: markers not found in README.md" >&2; exit 1; }
    BLOCKF=$(mktemp); generate > "$BLOCKF"
    # Read the (multi-line) block from a file via getline — BSD awk rejects multi-line -v.
    awk -v bf="$BLOCKF" -v s="$START" -v e="$END" '
      index($0, s) { while ((getline ln < bf) > 0) print ln; close(bf); skip=1; next }
      index($0, e) { skip=0; next }
      !skip { print }
    ' "$README" > "$README.tmp"
    mv "$README.tmp" "$README"; rm -f "$BLOCKF"
    echo "token-report: README.md updated."
    ;;
  *) echo "usage: $0 [print|--write|--check]" >&2; exit 2 ;;
esac
