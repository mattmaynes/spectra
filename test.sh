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
# Gemini ships a TOML-command extension over the SAME tree: gemini-extension.json + one thin
# commands/<name>.toml per skill whose `prompt` injects @{skills/<name>/SKILL.md} - the shared
# body, single-source (no second copy, no generator). Validate by PARSING (manifest name; every
# TOML parses, has a non-empty description, and injects its own body INSIDE the `prompt` value)
# and a 1:1 skill<->command map. Keying on the parsed `prompt` field - not a bare grep that would
# match the string in a comment even with `prompt` deleted - is the feedback/0009 lesson applied.
gout=$(SRC="$SRC" python3 <<'PY'
import os, sys, json, glob, pathlib, tomllib
SRC = os.environ["SRC"]; errs = []
try:
    m = json.load(open(f"{SRC}/gemini-extension.json"))
    if not m.get("name"): errs.append("gemini-extension.json: empty/missing name")
except Exception as e:
    errs.append(f"gemini-extension.json: {e}")
skills = {pathlib.Path(p).name for p in glob.glob(f"{SRC}/skills/*/")}
cmds   = {pathlib.Path(p).stem for p in glob.glob(f"{SRC}/commands/*.toml")}
for n in sorted(skills):                                   # every skill -> a valid wrapper
    t = f"{SRC}/commands/{n}.toml"
    if not os.path.isfile(t): errs.append(f"{n}: no command toml"); continue
    try:
        d = tomllib.load(open(t, "rb"))
    except Exception as e:
        errs.append(f"{n}.toml: parse error: {e}"); continue
    if not d.get("description"): errs.append(f"{n}.toml: empty/missing description")
    if f"@{{skills/{n}/SKILL.md}}" not in d.get("prompt", ""):
        errs.append(f"{n}.toml: prompt does not inject @{{skills/{n}/SKILL.md}}")
for c in sorted(cmds - skills):                            # no wrapper without a skill (1:1)
    errs.append(f"{c}.toml: no backing skill")
print("FAIL: " + "; ".join(errs) if errs else "OK")
sys.exit(1 if errs else 0)
PY
)
[ "$gout" = "OK" ] \
  && ok "Gemini ext: manifest + TOML wrappers parse, inject their own body, map 1:1" \
  || bad "Gemini ext invalid -> $gout"
# version is bumped across all manifests in lockstep at release - a partial bump would ship
# mismatched manifests, so assert the four plugin/extension manifests + the marketplace agree.
vers=$(ROOT="$ROOT" SRC="$SRC" python3 -c '
import json, os
ROOT, SRC = os.environ["ROOT"], os.environ["SRC"]
v = set()
for p in [f"{SRC}/.claude-plugin/plugin.json", f"{SRC}/.codex-plugin/plugin.json",
          f"{SRC}/.cursor-plugin/plugin.json", f"{SRC}/gemini-extension.json"]:
    v.add(json.load(open(p)).get("version"))
v.add(json.load(open(f"{ROOT}/.claude-plugin/marketplace.json"))["plugins"][0].get("version"))
print(next(iter(v)) if len(v) == 1 else "MISMATCH:" + ",".join(sorted(map(str, v))))
')
case "$vers" in
  MISMATCH:*) bad "manifest versions disagree -> ${vers#MISMATCH:}" ;;
  "")         bad "manifest version missing" ;;
  *)          ok "all manifests share one version ($vers)" ;;
esac

echo "2. skills have frontmatter"
for f in "$SRC"/skills/*/SKILL.md; do
  [ "$(head -1 "$f")" = "---" ] && ok "$(basename "$(dirname "$f")")" || bad "$f frontmatter"
done
# install/update must resolve $SRC tool-neutrally so ONE body runs under Claude/Codex/Cursor. The
# discriminating guard: the executable assignment goes through the SPECTRA_SRC override FIRST, so a
# revert to a Claude-only `SRC="${CLAUDE_SKILL_DIR}/../.."` (the regression) no longer matches -
# presence of neutral prose alone is not enough to catch it (feedback/0009).
for s in spectra-install spectra-update; do
  sk="$SRC/skills/$s/SKILL.md"
  grep -qF 'SRC="${SPECTRA_SRC' "$sk" \
    && ok "$s resolves \$SRC via SPECTRA_SRC (not Claude-only)" \
    || bad "$s lost tool-neutral \$SRC resolution (Claude-only regression?)"
done
# User/ICP personas are create-on-demand (spectra-add-user writes them into a consumer) - none ship
if ls "$SRC"/personas/user*.md >/dev/null 2>&1; then
  bad "personas/user*.md shipped - ICP personas must be created on demand by spectra-add-user"
else
  ok "no personas/user*.md shipped (create-on-demand)"
fi
# spectra-add-user's embedded template carries the canonical persona shape + applies-when block
add="$SRC/skills/spectra-add-user/SKILL.md"; miss=
for h in '# 👤 User (' '## Applies when' '## Skip when' '## Profile' '## Review'; do
  grep -qF "$h" "$add" || miss="$miss|$h"
done
[ -z "$miss" ] && ok "spectra-add-user template has 👤 title + Applies/Skip when + Profile + Review" \
  || bad "spectra-add-user template missing heading(s):$miss"
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
# enable/disable must edit personas.config and keep the slug validation (feedback/0007) - guard
# against a future edit silently dropping either (the skills are prose the suite can't execute)
for s in spectra-persona-enable spectra-persona-disable; do
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
printf 'LEGACY ICP\n'   > docs/spectra/personas/user.md          # legacy single ICP -> preserve
printf 'SMB ICP\n'      > docs/spectra/personas/user-smb.md      # multi-ICP profile -> preserve
printf 'ENT ICP\n'      > docs/spectra/personas/user-enterprise.md  # multi-ICP profile -> preserve
printf 'engineer\ntester\n' > docs/spectra/personas.config      # security DISABLED by developer
cp "$SRC/protocol.md" docs/spectra/protocol.md                  # update step: protocol
cp "$SRC/personas/"*.md docs/spectra/personas/                  # update step: all personas (additive)
# (update does NOT touch personas.config or any user*.md)
{ [ "$(cat docs/specs/0001.md)" = "MY SPEC" ] && [ "$(cat docs/overview/learnings.md)" = "MY LEARNINGS" ]; } \
  && ok "specs/overview untouched" || bad "update clobbered user content"
{ [ "$(cat docs/spectra/personas/user.md)" = "LEGACY ICP" ] \
  && [ "$(cat docs/spectra/personas/user-smb.md)" = "SMB ICP" ] \
  && [ "$(cat docs/spectra/personas/user-enterprise.md)" = "ENT ICP" ]; } \
  && ok "every user*.md preserved (no source to overwrite them)" || bad "update clobbered a user*.md ICP persona"
cmp -s docs/spectra/personas/engineer.md "$SRC/personas/engineer.md" \
  && ok "shipped persona refreshed from source" || bad "engineer.md not refreshed"
[ -f docs/spectra/personas/security.md ] \
  && ok "disabled persona's file still delivered (additive copy)" || bad "update didn't copy security.md"
[ "$(cat docs/spectra/personas.config)" = "$(printf 'engineer\ntester\n')" ] \
  && ok "personas.config preserved - security stays disabled across update" \
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
  bad "README token figures stale - run scripts/token-report.sh --write"
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

echo "10. What's new block + headline extraction"
wn="$ROOT/scripts/whats-new.sh"
wnstart='<!-- spectra:whats-new:start -->'; wnend='<!-- spectra:whats-new:end -->'
# The block the workflow rewrites must exist exactly once, or a future README edit that drops a
# marker passes CI yet breaks the next release (the rewrite aborts on a missing/duplicate pair).
{ [ "$(grep -cF "$wnstart" "$ROOT/README.md")" = 1 ] && [ "$(grep -cF "$wnend" "$ROOT/README.md")" = 1 ]; } \
  && ok "README has exactly one What's new marker pair" || bad "README What's new markers missing or duplicated"
# headline = first non-empty, non-heading line of the release body
out=$(TAG=9.9.9 NAME="t" BODY="$(printf '## Heading\nFirst real line.\nsecond')" "$wn" print)
printf '%s\n' "$out" | grep -qF '**9.9.9** - First real line.' \
  && ok "extracts first non-heading line" || bad "headline extraction (first line) wrong"
# heading-only / empty body -> falls back to the release name
out=$(TAG=9.9.9 NAME="Fallback name" BODY="# only a heading" "$wn" print)
printf '%s\n' "$out" | grep -qF '**9.9.9** - Fallback name' \
  && ok "falls back to release name when body has no usable line" || bad "headline name-fallback wrong"
# CRLF release bodies: the trailing CR is stripped from the headline
out=$(TAG=9.9.9 BODY="$(printf 'CRLF line\r\nsecond')" "$wn" print)
printf '%s\n' "$out" | grep -qF '**9.9.9** - CRLF line' || bad "headline keeps a trailing CR on CRLF bodies"
printf '%s\n' "$out" | grep -qF '**9.9.9** - CRLF line' && ok "strips trailing CR from CRLF bodies"
# defense-in-depth: a crafted first line can't smuggle comment markers into the block
hl=$(TAG=9.9.9 NAME="" BODY="evil <!-- spectra:whats-new:end --> tail" "$wn" print | grep '^\*\*9.9.9\*\*')
case "$hl" in *'<!--'*|*'-->'*) bad "headline not sanitized (comment markers leaked)";; *) ok "sanitizes comment markers in the headline";; esac
# missing TAG is a hard error, not a silent empty block
TAG="" BODY="x" "$wn" print >/dev/null 2>&1 && bad "whats-new.sh accepted an empty TAG" || ok "whats-new.sh requires TAG"

echo "11. version sync across all 7 manifests (VERSION + bump-version.sh)"
bv="$ROOT/scripts/bump-version.sh"
# The seven version-bearing manifests (paths relative to ROOT) - kept in lockstep with the
# script's own list; if a manifest is added/removed both must move together.
mans='.claude-plugin/marketplace.json
.agents/plugins/marketplace.json
.cursor-plugin/marketplace.json
spectra/.claude-plugin/plugin.json
spectra/.codex-plugin/plugin.json
spectra/.cursor-plugin/plugin.json
spectra/gemini-extension.json'
# the committed tree agrees: VERSION == every manifest's lone version token
if "$bv" --check >/dev/null 2>&1; then ok "bump-version --check passes (all 7 manifests match VERSION)"; else bad "manifests drift from VERSION - run scripts/bump-version.sh \$(cat VERSION)"; fi
# semver gate: reject a v-prefix, too-few/too-many parts, garbage, and empty
for v in "v1.2.3" "1.2" "1.2.3.4" "nope" ""; do
  if "$bv" "$v" >/dev/null 2>&1; then bad "bump-version accepted invalid '$v'"; else ok "bump-version rejects '$v'"; fi
done
# sandbox write: propagates X.Y.Z to all 7 + VERSION, converges under --check, and never
# touches the real tree (SPECTRA_ROOT override, mirroring the SPECTRA_SRC pattern).
real_before=$(cat "$ROOT/VERSION")
T=$(mktemp -d)
for f in $mans VERSION; do mkdir -p "$T/$(dirname "$f")"; cp "$ROOT/$f" "$T/$f"; done
if SPECTRA_ROOT="$T" "$bv" 9.9.9 >/dev/null 2>&1; then ok "bump-version 9.9.9 writes the sandbox"; else bad "bump-version 9.9.9 failed in sandbox"; fi
synced=1; [ "$(cat "$T/VERSION")" = "9.9.9" ] || synced=0
for f in $mans; do [ "$(grep -c '"version": *"9.9.9"' "$T/$f")" = 1 ] || synced=0; done
[ "$synced" = 1 ] && ok "all 7 manifests + VERSION now read 9.9.9" || bad "bump-version 9.9.9 left a manifest unsynced"
SPECTRA_ROOT="$T" "$bv" --check >/dev/null 2>&1 && ok "sandbox --check converges after write" || bad "sandbox --check did not converge"
[ "$(cat "$ROOT/VERSION")" = "$real_before" ] && ok "real VERSION untouched by the sandbox write" || bad "sandbox write leaked into the real VERSION"
rm -rf "$T"

echo
[ "$fail" -eq 0 ] && echo "PASS" || { echo "FAILURES"; exit 1; }
