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
# commands/<name>.toml per skill whose `prompt` injects @{skills/<name>/SKILL.md} — the shared
# body, single-source (no second copy, no generator). Validate by PARSING (manifest name; every
# TOML parses, has a non-empty description, and injects its own body INSIDE the `prompt` value)
# and a 1:1 skill<->command map. Keying on the parsed `prompt` field — not a bare grep that would
# match the string in a comment even with `prompt` deleted — is the feedback/0009 lesson applied.
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
  && ok "Gemini ext: manifest + 5 TOML wrappers parse, inject their own body, map 1:1" \
  || bad "Gemini ext invalid -> $gout"

echo "2. skills have frontmatter"
for f in "$SRC"/skills/*/SKILL.md; do
  [ "$(head -1 "$f")" = "---" ] && ok "$(basename "$(dirname "$f")")" || bad "$f frontmatter"
done
# install/update must resolve $SRC tool-neutrally so ONE body runs under Claude/Codex/Cursor. The
# discriminating guard: the executable assignment goes through the SPECTRA_SRC override FIRST, so a
# revert to a Claude-only `SRC="${CLAUDE_SKILL_DIR}/../.."` (the regression) no longer matches —
# presence of neutral prose alone is not enough to catch it (feedback/0009).
for s in spectra-install spectra-update; do
  sk="$SRC/skills/$s/SKILL.md"
  grep -qF 'SRC="${SPECTRA_SRC' "$sk" \
    && ok "$s resolves \$SRC via SPECTRA_SRC (not Claude-only)" \
    || bad "$s lost tool-neutral \$SRC resolution (Claude-only regression?)"
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

echo "10. version bump & sync"
bv="$ROOT/scripts/bump-version.sh"
# the committed tree's VERSION agrees with all 7 manifests
"$bv" --check >/dev/null 2>&1 && ok "bump-version --check passes (VERSION == all 7 manifests)" \
  || bad "bump-version --check found drift on the real tree"
# semver-only, no v-prefix: each malformed argument must be rejected (exit non-zero)
for v in "v1.2.3" "1.2" "nope" "1.2.3.4" ""; do
  if "$bv" "$v" >/dev/null 2>&1; then bad "accepted invalid version '$v'"; else ok "rejects '$v'"; fi
done
# sandbox write: copy the 7 manifests + VERSION into $T (preserving paths), bump to 9.9.9 there,
# and assert every copy + $T/VERSION moved while the REAL VERSION stays untouched.
T=$(mktemp -d)
for m in .claude-plugin/marketplace.json .agents/plugins/marketplace.json .cursor-plugin/marketplace.json \
         spectra/.claude-plugin/plugin.json spectra/.codex-plugin/plugin.json spectra/.cursor-plugin/plugin.json \
         spectra/gemini-extension.json; do
  mkdir -p "$T/$(dirname "$m")"; cp "$ROOT/$m" "$T/$m"
done
cp "$ROOT/VERSION" "$T/VERSION"
SPECTRA_ROOT="$T" "$bv" 9.9.9 >/dev/null 2>&1 && ok "sandbox bump to 9.9.9 succeeds" || bad "sandbox bump failed"
[ "$(cat "$T/VERSION")" = "9.9.9" ] && ok "sandbox VERSION -> 9.9.9" || bad "sandbox VERSION not updated"
miss=
for m in .claude-plugin/marketplace.json .agents/plugins/marketplace.json .cursor-plugin/marketplace.json \
         spectra/.claude-plugin/plugin.json spectra/.codex-plugin/plugin.json spectra/.cursor-plugin/plugin.json \
         spectra/gemini-extension.json; do
  grep -q '"version": "9.9.9"' "$T/$m" || miss="$miss $m"
done
[ -z "$miss" ] && ok "all 7 sandbox manifests -> 9.9.9" || bad "manifests not bumped:$miss"
SPECTRA_ROOT="$T" "$bv" --check >/dev/null 2>&1 && ok "sandbox --check passes after bump" || bad "sandbox --check found drift after bump"
[ "$(cat "$ROOT/VERSION")" = "0.1.0" ] && ok "real VERSION untouched by sandbox bump (still 0.1.0)" \
  || bad "real VERSION was modified by the sandbox bump"
# format preservation: a bump must rewrite ONLY the version value, never reflow the JSON. The
# real manifests are the pristine 0.1.0 reference; each bumped sandbox copy must differ from it
# by exactly one line (the version). A json.dumps()-style reserialize would change many lines.
reflow=
for m in .claude-plugin/marketplace.json .agents/plugins/marketplace.json .cursor-plugin/marketplace.json \
         spectra/.claude-plugin/plugin.json spectra/.codex-plugin/plugin.json spectra/.cursor-plugin/plugin.json \
         spectra/gemini-extension.json; do
  n=$(diff "$ROOT/$m" "$T/$m" | grep -c '^> ')
  { [ "$n" -eq 1 ] && diff "$ROOT/$m" "$T/$m" | grep -q '9.9.9'; } || reflow="$reflow $m"
done
[ -z "$reflow" ] && ok "bump changes only the version line (no JSON reflow)" || bad "bump reflowed:$reflow"
# the two read-only modes a release author relies on: no-arg prints the current version, --help exits 0
[ "$(SPECTRA_ROOT="$T" "$bv")" = "9.9.9" ] && ok "no-arg prints the current version" || bad "no-arg didn't print VERSION"
"$bv" --help 2>&1 | grep -qi usage && ok "--help prints usage" || bad "--help missing usage"
# negative case: --check must FAIL when a manifest drifts from VERSION — proves the guard bites,
# not just that it returns 0 on a clean tree. Corrupt one sandbox manifest only (real tree intact).
python3 -c 'import re,sys; p=sys.argv[1]; s=open(p).read(); open(p,"w").write(re.sub(r"(\"version\"\s*:\s*\")[^\"]*(\")", r"\g<1>0.0.0\g<2>", s, count=1))' "$T/spectra/gemini-extension.json"
SPECTRA_ROOT="$T" "$bv" --check >/dev/null 2>&1 && bad "--check passed despite a drifted manifest" \
  || ok "--check fails when a manifest drifts from VERSION"
rm -rf "$T"

echo
[ "$fail" -eq 0 ] && echo "PASS" || { echo "FAILURES"; exit 1; }
