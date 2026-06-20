#!/bin/sh
# Spectra test suite. Run before committing (protocol step 5.2).
# Validates the marketplace/plugin manifests, skill frontmatter, the reflection hook's
# behavior, and the install/update mechanics. Exits non-zero on any failure.
set -eu
ROOT=$(cd "$(dirname "$0")" && pwd)
SRC="$ROOT/spectra"
fail=0
ok()  { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; fail=1; }

echo "1. manifests parse"
python3 -m json.tool "$ROOT/.claude-plugin/marketplace.json" >/dev/null && ok marketplace.json || bad marketplace.json
python3 -m json.tool "$SRC/.claude-plugin/plugin.json"       >/dev/null && ok plugin.json      || bad plugin.json
src=$(python3 -c "import json;print(json.load(open('$ROOT/.claude-plugin/marketplace.json'))['plugins'][0]['source'])")
[ -d "$ROOT/$src" ] && ok "source $src resolves" || bad "source $src missing"

echo "2. skills have frontmatter"
for f in "$SRC"/skills/*/SKILL.md; do
  [ "$(head -1 "$f")" = "---" ] && ok "$(basename "$(dirname "$f")")" || bad "$f frontmatter"
done

echo "3. reflection hook behavior"
T=$(mktemp -d); cd "$T"
git init -q; git config user.email t@t.t; git config user.name t
cp "$SRC/hooks/pre-commit" .git/hooks/pre-commit; chmod +x .git/hooks/pre-commit
mkdir -p docs/specs docs/overview
echo x > docs/specs/0001.md; git add -A
warn=$(git commit -q -m "spec only" 2>&1 || true)
echo "$warn" | grep -q "spectra:" && ok "warns on spec w/o overview" || bad "no warn on spec-only"
echo y >> docs/specs/0001.md; echo z > docs/overview/learnings.md; git add -A
warn=$(git commit -q -m "spec+overview" 2>&1 || true)
echo "$warn" | grep -q "spectra:" && bad "warned despite overview change" || ok "silent when overview changed"
echo code > main.py; git add -A
warn=$(git commit -q -m "code" 2>&1 || true)
echo "$warn" | grep -q "spectra:" && bad "warned on unrelated change" || ok "silent on unrelated change"
cd "$ROOT"; rm -rf "$T"

echo "4. install + idempotent host-block refresh"
T=$(mktemp -d); cd "$T"
git init -q
mkdir -p docs/spectra/personas
cp "$SRC/protocol.md" docs/spectra/protocol.md
cp "$SRC/personas/"*.md docs/spectra/personas/
{ [ -f docs/spectra/protocol.md ] && [ "$(ls docs/spectra/personas | wc -l | tr -d ' ')" = 4 ]; } \
  && ok "protocol + 4 personas copied" || bad "copy"
printf '# AGENTS.md\n\nKeep me.\n' > AGENTS.md; cat "$SRC/agents.md" >> AGENTS.md
refresh() {
  awk '/<!-- spectra:start -->/{s=1} !s{print} /<!-- spectra:end -->/{s=0}' AGENTS.md > t
  printf '\n' >> t; cat "$SRC/agents.md" >> t; mv t AGENTS.md
}
refresh; refresh; refresh
{ [ "$(grep -c spectra:start AGENTS.md)" = 1 ] && [ "$(grep -c spectra:end AGENTS.md)" = 1 ]; } \
  && ok "host block idempotent" || bad "host block duplicated"
grep -q "Keep me." AGENTS.md && ok "surrounding content preserved" || bad "surrounding content lost"
cd "$ROOT"; rm -rf "$T"

echo
[ "$fail" -eq 0 ] && echo "PASS" || { echo "FAILURES"; exit 1; }
