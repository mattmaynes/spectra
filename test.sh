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
# Cross-agent packaging: Codex + Cursor reuse the SAME spectra/ tree via their own marketplace +
# plugin manifest. Each marketplace's plugin source must resolve to a dir holding that tool's
# plugin.json, and that plugin's "skills" pointer must resolve to the one shared skills tree.
# entry = "<repo-root marketplace path>:<tool plugin-manifest dir>"
for entry in ".agents/plugins/marketplace.json:.codex-plugin" ".cursor-plugin/marketplace.json:.cursor-plugin"; do
  mkt="${entry%%:*}"; pdir="${entry##*:}"
  python3 -m json.tool "$ROOT/$mkt" >/dev/null 2>&1 && ok "$mkt parses" || { bad "$mkt parse"; continue; }
  s=$(ROOT="$ROOT" MKT="$mkt" python3 -c 'import json,os;print(json.load(open(os.environ["ROOT"]+"/"+os.environ["MKT"]))["plugins"][0]["source"])')
  { [ -d "$ROOT/$s" ] && [ -f "$ROOT/$s/$pdir/plugin.json" ]; } \
    && ok "$mkt source $s resolves to a $pdir plugin" || { bad "$mkt source $s missing $pdir/plugin.json"; continue; }
  sk=$(ROOT="$ROOT" P="$s/$pdir/plugin.json" python3 -c 'import json,os;print(json.load(open(os.environ["ROOT"]+"/"+os.environ["P"]))["skills"])')
  { [ -d "$ROOT/$s/$sk" ] && [ -f "$ROOT/$s/$sk/spectra-install/SKILL.md" ]; } \
    && ok "$pdir skills '$sk' resolves to the shared skills tree" || bad "$pdir skills pointer broken"
done

echo "2. skills have frontmatter"
for f in "$SRC"/skills/*/SKILL.md; do
  [ "$(head -1 "$f")" = "---" ] && ok "$(basename "$(dirname "$f")")" || bad "$f frontmatter"
done
# install/update resolve $SRC tool-neutrally (one body works under Claude/Codex/Cursor). Guard
# against a regression to a Claude-only resolution: the body must still define $SRC AND carry the
# cross-agent guidance ("plugin" root + "other agents"), not just hardcode ${CLAUDE_SKILL_DIR}.
for s in spectra-install spectra-update; do
  sk="$SRC/skills/$s/SKILL.md"
  { grep -qF 'SRC=' "$sk" && grep -qF 'plugin' "$sk" && grep -qiF 'other agents' "$sk"; } \
    && ok "$s resolves \$SRC tool-neutrally" || bad "$s lost tool-neutral \$SRC resolution"
done
# user.md is create-on-demand (spectra-setup writes it into a consumer) — never shipped
[ ! -e "$SRC/personas/user.md" ] && ok "personas/user.md not shipped (create-on-demand)" \
  || bad "personas/user.md shipped — must be created on demand by spectra-setup"
# spectra-setup's embedded template carries the canonical persona shape (guards silent drift)
setup="$SRC/skills/spectra-setup/SKILL.md"; miss=
for h in '# 👤 User (ICP)' '## Profile' '## Review'; do
  grep -qF "$h" "$setup" || miss="$miss|$h"
done
[ -z "$miss" ] && ok "spectra-setup template has 👤 title + Profile + Review" \
  || bad "spectra-setup template missing heading(s):$miss"
# all personas ship as files in personas/ (the optional ones too); the config decides which load
for p in designer compliance analytics; do
  [ -f "$SRC/personas/$p.md" ] || bad "persona $p missing from personas/"
done
ok "optional personas designer/compliance/analytics ship in personas/"
# the shipped default config enables exactly the four core personas (off-by-default holds)
slugs=$(grep -Ev '^[[:space:]]*(#|$)' "$SRC/personas.config" | tr '\n' ' ')
[ "$slugs" = "engineer tester architect security " ] \
  && ok "personas.config default = the four core personas" \
  || bad "personas.config default drifted: [$slugs]"
# every default slug resolves to a real persona file (config can't enable a missing persona)
for s in $(grep -Ev '^[[:space:]]*(#|$)' "$SRC/personas.config"); do
  [ -f "$SRC/personas/$s.md" ] || bad "config enables '$s' but personas/$s.md is missing"
done
ok "every enabled slug resolves to a persona file"
# every persona has a title, references persona.md, and carries a checklist
miss=
for f in "$SRC"/personas/*.md; do
  b=$(basename "$f"); [ "$b" = persona.md ] && continue
  { grep -q '^# ' "$f" && grep -qF 'persona.md' "$f" && grep -q '^- ' "$f"; } || miss="$miss $b"
done
[ -z "$miss" ] && ok "every persona has a title + persona.md ref + a checklist" \
  || bad "personas missing title/contract-ref/checklist:$miss"
# enable/disable must edit personas.config and keep the slug validation (feedback/0007) — guard
# against a future edit silently dropping either (the skills are prose the suite can't execute)
for s in spectra-enable spectra-disable; do
  sk="$SRC/skills/$s/SKILL.md"
  { grep -qF 'personas.config' "$sk" && grep -qF '[a-z][a-z0-9-]' "$sk"; } \
    && ok "$s edits personas.config and validates the slug" \
    || bad "$s lost its config edit or slug validation"
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
# install seeds personas.config only if absent (symmetric to update never overwriting it):
# a regression to an unconditional cp would silently reset a developer's enabled set.
ins="$SRC/skills/spectra-install/SKILL.md"
grep -qF '[ -f docs/spectra/personas.config ] || cp' "$ins" \
  && ok "install seeds personas.config only if absent" || bad "install config seed isn't guarded by [ -f ] ||"
seed() { [ -f docs/spectra/personas.config ] || cp "$SRC/personas.config" docs/spectra/personas.config; }  # the install step
mkdir -p docs/spectra                                              # fresh install -> seed default
seed; cmp -s docs/spectra/personas.config "$SRC/personas.config" \
  && ok "fresh install seeds the default config" || bad "install didn't seed personas.config"
printf 'engineer\n' > docs/spectra/personas.config                # re-install -> must NOT reset
seed; [ "$(cat docs/spectra/personas.config)" = "engineer" ] \
  && ok "re-install preserves an existing config" || bad "install clobbered an existing personas.config"
cd "$ROOT"; rm -rf "$T"

echo "5. update copies all personas additively but preserves the config + user content"
# Assert against the real skill body: update must bulk-copy all personas (additive) and must NOT
# touch personas.config. The simulation below mirrors that; without these greps a skill that
# stopped copying personas, or that overwrote the config, could keep this test green.
upd="$SRC/skills/spectra-update/SKILL.md"
grep -qF 'cp "$SRC/personas/"*.md' "$upd" \
  && ok "update skill copies all personas (additive)" || bad "update skill no longer bulk-copies personas"
grep -qF 'personas.config' "$upd" \
  && ok "update skill documents leaving personas.config alone" || bad "update skill doesn't mention personas.config"
T=$(mktemp -d); cd "$T"
mkdir -p docs/spectra/personas docs/specs docs/overview
printf 'MY SPEC\n'      > docs/specs/0001.md
printf 'MY LEARNINGS\n' > docs/overview/learnings.md
printf 'stale\n'        > docs/spectra/protocol.md
printf 'stale\n'        > docs/spectra/personas/engineer.md      # shipped persona -> refresh
printf 'MY ICP\n'       > docs/spectra/personas/user.md          # developer-owned -> preserve
printf 'engineer\ntester\n' > docs/spectra/personas.config      # security DISABLED by developer
cp "$SRC/protocol.md" docs/spectra/protocol.md                  # update step: protocol
cp "$SRC/personas/"*.md docs/spectra/personas/                  # update step: all personas (additive)
# (update does NOT touch personas.config or user.md)
{ [ "$(cat docs/specs/0001.md)" = "MY SPEC" ] && [ "$(cat docs/overview/learnings.md)" = "MY LEARNINGS" ]; } \
  && ok "specs/overview untouched" || bad "update clobbered user content"
[ "$(cat docs/spectra/personas/user.md)" = "MY ICP" ] \
  && ok "user.md preserved (no source to overwrite it)" || bad "update clobbered user.md"
cmp -s docs/spectra/personas/engineer.md "$SRC/personas/engineer.md" \
  && ok "shipped persona refreshed from source" || bad "engineer.md not refreshed"
[ -f docs/spectra/personas/security.md ] \
  && ok "disabled persona's file still delivered (additive copy)" || bad "update didn't copy security.md"
[ "$(cat docs/spectra/personas.config)" = "$(printf 'engineer\ntester\n')" ] \
  && ok "personas.config preserved — security stays disabled across update" \
  || bad "update clobbered personas.config (would silently re-enable a disabled persona)"
cmp -s docs/spectra/protocol.md "$SRC/protocol.md" && ok "protocol refreshed from source" || bad "protocol not refreshed"
cd "$ROOT"; rm -rf "$T"

echo "6. dogfood integrity (this repo)"
{ [ -e "$ROOT/docs/spectra/protocol.md" ] && cmp -s "$ROOT/docs/spectra/protocol.md" "$SRC/protocol.md"; } \
  && ok "docs/spectra/protocol.md resolves to source" || bad "dogfood protocol symlink broken"
[ -e "$ROOT/docs/spectra/personas/engineer.md" ] && ok "docs/spectra/personas resolves" || bad "personas symlink broken"
{ [ -e "$ROOT/docs/spectra/personas.config" ] && cmp -s "$ROOT/docs/spectra/personas.config" "$SRC/personas.config"; } \
  && ok "docs/spectra/personas.config resolves to source" || bad "dogfood personas.config symlink broken"
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
