#!/bin/sh
# Spectra version bump - keeps the plugin's version honest across every manifest.
#
# REPO-LOCAL TOOLING. Not part of the shippable plugin (nothing under spectra/) and never
# installed into consumer repos. The single source of truth is the root VERSION file; the
# seven manifests are derivatives this script keeps identical and `--check` enforces.
#
# Dependency-light (POSIX sh + python3 - already a test.sh dep) so it runs identically in CI
# and a local shell - same rationale as scripts/token-report.sh and check-commit-msg.sh.
#
# Each manifest contains EXACTLY ONE "version" token (top-level in the plugin.json /
# gemini-extension.json files; plugins[0].version in the marketplaces), so read and write key
# on that single token via a format-preserving surgical substitution - no JSON re-serialize
# that would reflow the hand-formatted files.
#
# Usage:
#   scripts/bump-version.sh                 print the current version (cat VERSION)
#   scripts/bump-version.sh --check         verify VERSION == every manifest's version (exit 1 on drift)
#   scripts/bump-version.sh X.Y.Z           write VERSION + all 7 manifests to X.Y.Z (semver, no v)
#   scripts/bump-version.sh -h|--help       usage
set -eu

ROOT="${SPECTRA_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

# The seven version-bearing manifests (paths relative to ROOT). Each has exactly one "version".
MANIFESTS='.claude-plugin/marketplace.json
.agents/plugins/marketplace.json
.cursor-plugin/marketplace.json
spectra/.claude-plugin/plugin.json
spectra/.codex-plugin/plugin.json
spectra/.cursor-plugin/plugin.json
spectra/gemini-extension.json'

usage() {
  echo "usage: $0 [--check | X.Y.Z]"
  echo "  (no arg)   print the current version"
  echo "  --check    verify VERSION matches every manifest's version (exit 1 on drift)"
  echo "  X.Y.Z      write VERSION + all 7 manifests to X.Y.Z (semver, no 'v' prefix)"
}

# check -> compare VERSION against every manifest's lone version token; exit 1 on any
# drift/missing/malformed, else 0 (silent-ish, like token-report --check).
check() {
  ROOT="$ROOT" MANIFESTS="$MANIFESTS" python3 - <<'PY'
import json, os, re, sys

root = os.environ["ROOT"]
manifests = os.environ["MANIFESTS"].split("\n")
drift = False

vfile = os.path.join(root, "VERSION")
try:
    want = open(vfile).read().strip()
except OSError as e:
    print(f"bump-version: cannot read VERSION: {e}", file=sys.stderr)
    sys.exit(1)

for rel in manifests:
    path = os.path.join(root, rel)
    try:
        raw = open(path).read()
    except OSError:
        print(f"bump-version: missing manifest: {rel}")
        drift = True
        continue
    try:
        json.loads(raw)
    except Exception as e:
        print(f"bump-version: {rel} does not parse as JSON: {e}")
        drift = True
        continue
    found = re.findall(r'"version"\s*:\s*"([^"]*)"', raw)
    if len(found) != 1:
        print(f"bump-version: {rel} has {len(found)} version tokens (expected exactly 1)")
        drift = True
        continue
    if found[0] != want:
        print(f"bump-version: {rel} version {found[0]} != VERSION {want}")
        drift = True

sys.exit(1 if drift else 0)
PY
}

# write NEW -> surgically substitute the single version token in each manifest, then VERSION.
write() {
  new="$1"
  # Atomic-ish: compute + validate every manifest substitution IN MEMORY first and write the
  # files only once all seven pass; write VERSION LAST. So a guard failure (a stray second
  # "version" token, a file that wouldn't parse) aborts with nothing changed on disk - never a
  # half-bumped tree where VERSION and some manifests moved but one lagged (engineer review).
  ROOT="$ROOT" MANIFESTS="$MANIFESTS" NEW="$new" python3 - <<'PY'
import json, os, re, sys

root = os.environ["ROOT"]
manifests = os.environ["MANIFESTS"].split("\n")
new = os.environ["NEW"]

pending = {}
for rel in manifests:
    path = os.path.join(root, rel)
    try:
        raw = open(path).read()
    except OSError as e:
        print(f"bump-version: missing manifest: {rel} ({e})", file=sys.stderr)
        sys.exit(1)
    # Surgical, format-preserving substitution of the one "version" VALUE only.
    updated, n = re.subn(
        r'("version"\s*:\s*")[^"]*(")',
        lambda m: m.group(1) + new + m.group(2),
        raw,
    )
    if n != 1:
        print(f"bump-version: {rel} had {n} version tokens (expected exactly 1)", file=sys.stderr)
        sys.exit(1)
    try:
        json.loads(updated)
    except Exception as e:
        print(f"bump-version: {rel} would not parse after substitution: {e}", file=sys.stderr)
        sys.exit(1)
    pending[path] = updated

# Every manifest validated -> only now commit them to disk.
for path, content in pending.items():
    open(path, "w").write(content)
PY
  # VERSION written last, after every manifest substitution validated + applied above.
  printf '%s\n' "$new" > "$ROOT/VERSION"
}

# No argument at all -> print the current version. An explicitly-empty argument ("") falls
# through to validation and is rejected, like any other non-semver.
if [ "$#" -eq 0 ]; then
  cat "$ROOT/VERSION"
  exit 0
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
  --check)
    # Explicit if/else, not `check; exit $?` - under `set -e` a drift (check -> 1) would abort
    # before `exit $?` ever ran, making it dead code on the failure path (engineer review).
    if check; then exit 0; else exit 1; fi
    ;;
  *)
    if ! printf '%s' "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      echo "bump-version: '$1' is not a semantic version." >&2
      echo "  expected: X.Y.Z   e.g. '1.2.3'   (no 'v' prefix, exactly three numeric parts)" >&2
      exit 1
    fi
    write "$1"
    # Confirm convergence with the same --check logic.
    if ! check; then
      echo "bump-version: version did not converge after write." >&2
      exit 1
    fi
    ;;
esac
