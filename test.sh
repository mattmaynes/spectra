#!/bin/sh
# Spectra test suite. Run before committing (protocol step 5, Test).
# Validates the marketplace/plugin manifests, skill frontmatter, the reflection hook's
# behavior, the install/update mechanics, and this repo's dogfood integrity.
# Exits non-zero on any failure.
set -eu
ROOT=$(cd "$(dirname "$0")" && pwd)
SRC="$ROOT/spectra"
fail=0
ok()  { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; fail=1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 required"; exit 1; }

# commit_capture MSG -> sets OUT (combined output) and RC (exit code), never aborts
commit_capture() { set +e; OUT=$(git commit -q -m "$1" 2>&1); RC=$?; set -e; }
warned() { printf '%s' "$OUT" | grep -q "spectra:"; }

echo "1. manifests parse"
python3 -m json.tool "$ROOT/.claude-plugin/marketplace.json" >/dev/null && ok marketplace.json || bad marketplace.json
python3 -m json.tool "$SRC/.claude-plugin/plugin.json"       >/dev/null && ok plugin.json      || bad plugin.json
src=$(ROOT="$ROOT" python3 -c 'import json,os;print(json.load(open(os.environ["ROOT"]+"/.claude-plugin/marketplace.json"))["plugins"][0]["source"])')
{ [ -d "$ROOT/$src" ] && [ -f "$ROOT/$src/.claude-plugin/plugin.json" ]; } \
  && ok "source $src resolves to a plugin" || bad "source $src missing/invalid"

echo "2. skills have frontmatter"
for f in "$SRC"/skills/*/SKILL.md; do
  [ "$(head -1 "$f")" = "---" ] && ok "$(basename "$(dirname "$f")")" || bad "$f frontmatter"
done

echo "3. reflection hook behavior"
T=$(mktemp -d); cd "$T"
git init -q; git config user.email t@t.t; git config user.name t
cp "$SRC/hooks/pre-commit" .git/hooks/pre-commit; chmod +x .git/hooks/pre-commit
mkdir -p docs/specs docs/plans docs/feedback docs/overview
git commit -q --allow-empty -m init
# warns on each work dir without an overview change, and exits 0 (non-blocking)
for dir in specs plans feedback; do
  echo x > "docs/$dir/n.md"; git add -A; commit_capture "$dir only"
  { warned && [ "$RC" -eq 0 ]; } && ok "warns + exits 0 on $dir change" || bad "$dir warn/exit"
done
# .gitkeep alone is excluded (silent)
touch docs/specs/.gitkeep; git add -A; commit_capture "gitkeep"
warned && bad "warned on .gitkeep only" || ok "silent on .gitkeep only"
# .gitkeep + a real spec still warns
touch docs/plans/.gitkeep; echo y > docs/specs/real.md; git add -A; commit_capture "gitkeep+spec"
warned && ok "warns on .gitkeep + real spec" || bad "missed real spec beside gitkeep"
# overview alone -> silent
echo o > docs/overview/project.md; git add -A; commit_capture "overview only"
warned && bad "warned on overview-only" || ok "silent on overview-only"
# work + overview together -> silent
echo z > docs/specs/z.md; echo l > docs/overview/learnings.md; git add -A; commit_capture "spec+overview"
warned && bad "warned despite overview change" || ok "silent when overview changed too"
# unrelated -> silent
echo c > main.py; git add -A; commit_capture "code"
warned && bad "warned on unrelated change" || ok "silent on unrelated change"
cd "$ROOT"; rm -rf "$T"

echo "4. install: host-block insert is idempotent and preserves surrounding content"
refresh() { # mirrors the skills' marker-inclusive replace-or-append
  awk '/<!-- spectra:start -->/{s=1} !s{print} /<!-- spectra:end -->/{s=0}' AGENTS.md > t
  printf '\n' >> t; cat "$SRC/agents.md" >> t; mv t AGENTS.md
}
T=$(mktemp -d); cd "$T"
printf '# AGENTS.md\n\nKeep me.\n' > AGENTS.md       # markers absent -> append path
refresh; refresh; refresh                             # then idempotent re-runs
{ [ "$(grep -c spectra:start AGENTS.md)" = 1 ] && [ "$(grep -c spectra:end AGENTS.md)" = 1 ]; } \
  && ok "host block idempotent (append + re-run)" || bad "host block duplicated"
grep -q "Keep me." AGENTS.md && ok "surrounding content preserved" || bad "surrounding content lost"
cd "$ROOT"; rm -rf "$T"

echo "5. update preserves the developer's own content"
T=$(mktemp -d); cd "$T"
mkdir -p docs/spectra/personas docs/specs docs/overview
printf 'MY SPEC\n'      > docs/specs/0001.md
printf 'MY LEARNINGS\n' > docs/overview/learnings.md
printf 'stale\n'        > docs/spectra/protocol.md
cp "$SRC/protocol.md" docs/spectra/protocol.md           # the update copy steps
cp "$SRC/personas/"*.md docs/spectra/personas/
{ [ "$(cat docs/specs/0001.md)" = "MY SPEC" ] && [ "$(cat docs/overview/learnings.md)" = "MY LEARNINGS" ]; } \
  && ok "specs/overview untouched" || bad "update clobbered user content"
cmp -s docs/spectra/protocol.md "$SRC/protocol.md" && ok "protocol refreshed from source" || bad "protocol not refreshed"
cd "$ROOT"; rm -rf "$T"

echo "6. dogfood integrity (this repo)"
{ [ -e "$ROOT/docs/spectra/protocol.md" ] && cmp -s "$ROOT/docs/spectra/protocol.md" "$SRC/protocol.md"; } \
  && ok "docs/spectra/protocol.md resolves to source" || bad "dogfood protocol symlink broken"
[ -e "$ROOT/docs/spectra/personas/engineer.md" ] && ok "docs/spectra/personas resolves" || bad "personas symlink broken"
a=$(sed -n '/<!-- spectra:start -->/,/<!-- spectra:end -->/p' "$ROOT/AGENTS.md"); b=$(cat "$SRC/agents.md")
[ "$a" = "$b" ] && ok "AGENTS.md block matches spectra/agents.md" || bad "host block drifted from source"

echo "7. protocol covers every stage"
miss=
for kw in Route spec plan Build Test Review Merge Reflect; do
  grep -qi "$kw" "$SRC/protocol.md" || miss="$miss $kw"
done
[ -z "$miss" ] && ok "route->spec->plan->build->test->review->merge->reflect" || bad "protocol missing:$miss"

echo "8. README token figures in sync with spectra/"
if "$ROOT/scripts/token-report.sh" --check >/dev/null 2>&1; then
  ok "token-report --check passes (README matches spectra/)"
else
  bad "README token figures stale — run scripts/token-report.sh --write"
fi

echo "9. conventional-commit validator"
ccm="$ROOT/scripts/check-commit-msg.sh"
# accepts conforming subjects (exit 0)
for m in "feat: add x" "fix(scope): y" "feat!: breaking" "chore(deps): bump" "revert: feat: x"; do
  if "$ccm" "$m" >/dev/null 2>&1; then ok "accepts '$m'"; else bad "rejected valid '$m'"; fi
done
# rejects non-conforming subjects (exit non-zero)
for m in "nope" "Add thing" "feat x" "feature: x" "feat:" "feat:   " ""; do
  if "$ccm" "$m" >/dev/null 2>&1; then bad "accepted invalid '$m'"; else ok "rejects '$m'"; fi
done

echo
[ "$fail" -eq 0 ] && echo "PASS" || { echo "FAILURES"; exit 1; }
